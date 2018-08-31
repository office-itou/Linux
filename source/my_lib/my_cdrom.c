// ----------------------------------------------------------------------------
#include "my_common.h"
// ----------------------------------------------------------------------------
void my_lba2msf(int lba, int *m, int *s, int *f)
{
	lba += CD_MSF_OFFSET;
	lba &= 0xffffff;  /* negative lbas use only 24 bits */
	*m = lba / (CD_SECS * CD_FRAMES);
	lba %= (CD_SECS * CD_FRAMES);
	*s = lba / CD_FRAMES;
	*f = lba % CD_FRAMES;
}

// ----------------------------------------------------------------------------
int my_msf2lba(int m, int s, int f)
{
	return (((m * CD_SECS) + s) * CD_FRAMES + f);
}

// ----------------------------------------------------------------------------
int my_msf2frame(const char *msf, int *m, int *s, int *f)
{
	char buf[BUFF_MAX];					// work
	char *p = buf, *t;					// time (string)
	// ------------------------------------------------------------------------
	*m = 0;								// min
	*s = 0;								// sec
	*f = 0;								// frame
	// ------------------------------------------------------------------------
	strncpy(p, msf, sizeof(buf));
	// --- min ----------------------------------------------------------------
	if ((t = strchr(p, ':')) == NULL)
		return -1;
	*t = '\0';
	*m = atoi(p);
	// --- sec ----------------------------------------------------------------
	p = t + 1;
	if ((t = strchr(p, ':')) == NULL)
		return -1;
	*t = '\0';
	*s = atoi(p);
	// --- frame --------------------------------------------------------------
	p = t + 1;
	*f = atoi(p);
	// ------------------------------------------------------------------------
	return my_msf2lba(*m, *s, *f);
}

// ----------------------------------------------------------------------------
int my_get_cuedata(cuedata_t * cuedata)
{
	FILE *fp;							// file pointer
	char buf[BUFF_MAX];					// read data
	char *p, *s, *t;					// work pointer
	char dname[PATH_MAX];				// work directory name
	char fname[PATH_MAX];				// work file name
	int n = -1;							// work
	int ret;							// work
	// bin file name
	memset(cuedata->fname_bin, 0, sizeof(cuedata->fname_bin));
	cuedata->fsize_bin = 0;				// bin file size
	// frame size (CD-DA)
	cuedata->frame_len = CD_FRAMESIZE_RAW;
	cuedata->trk0 = 0;					// start track
	cuedata->trk1 = 0;					// end track
	cuedata->flg = 0;					// flag (1:binary,...)
	// track data
	memset(cuedata->td, 0, sizeof(cuedata->td));
	if (my_dirname(cuedata->fname_cue, dname, sizeof(dname), NULL, 0) < 0)
		return -1;
	if (my_fopen(&fp, cuedata->fname_cue, "r") < 0)
		return -1;
	while ((ret = my_fgets(buf, sizeof(buf), fp)) > 0) {
		my_rm_crlf(buf);				// remove CR/LF
		// "FILE",bin file name,file type
		if ((p = strstr(buf, "FILE")) != NULL) {
			if ((s = strchr(p, '"')) != NULL && (t = strchr((s + 1), '"')) != NULL) {
				*t = '\0';
				if ((ret = my_sjis2utf8((s + 1), fname, sizeof(fname))) < 0)
					break;
				if (strstr(t + 1, "BINARY") != NULL)
					cuedata->flg |= 1;
				snprintf(cuedata->fname_bin, sizeof(cuedata->fname_bin), "%s/%s", dname, fname);
				if ((cuedata->fsize_bin = my_stat(cuedata->fname_bin)) < 0) {
					ret = -1;
					break;
				}
			}
			continue;
		}
		// "TRACK",track number (string/numeric-1)
		if ((p = strstr(buf, "TRACK")) != NULL) {
			if ((s = strchr(p, ' ')) != NULL && (t = strchr((s + 1), ' ')) != NULL) {
				*t = '\0';
				n++;
				if (n >= 0 && n < sizeof(cuedata->td) / sizeof(cuedata->td[0])) {
					cuedata->td[n].trk = atoi(s + 1);
					if (strstr(t + 1, "AUDIO") != NULL)
						cuedata->td[n].flg |= 1;
					if (!cuedata->trk0)
						cuedata->trk0 = cuedata->td[n].trk;
					cuedata->trk1 = cuedata->td[n].trk;
				}
			}
			continue;
		}
		// "INDEX",index number,time and frame(msf)
		if ((p = strstr(buf, "INDEX")) != NULL) {
			if ((s = strchr(p, ' ')) != NULL && (t = strchr((s + 1), ' ')) != NULL) {
				*t = '\0';
				if (n >= 0 && n < sizeof(cuedata->td) / sizeof(cuedata->td[0])) {
					cuedata->td[n].ind = atoi(s + 1);
					if ((ret = my_msf2frame((t + 1), &cuedata->td[n].min0, &cuedata->td[n].sec0, &cuedata->td[n].frm0)) < 0)
						break;
					cuedata->td[n].lba0 = ret;
				}
			}
			continue;
		}
	}
	if (my_fclose(fp) < 0)
		return -1;
	if (ret)
		return ret;
	for (n = 1; n < sizeof(cuedata->td) / sizeof(cuedata->td[0]) && cuedata->td[n].trk > 0; n++) {
		cuedata->td[n - 1].lba1 = cuedata->td[n].lba0 - 1;
		my_lba2msf(cuedata->td[n - 1].lba1, &cuedata->td[n - 1].min1, &cuedata->td[n - 1].sec1, &cuedata->td[n - 1].frm1);
		if (cuedata->td[n].trk == cuedata->trk1) {
			cuedata->td[n].lba1 = cuedata->fsize_bin / cuedata->frame_len + cuedata->fsize_bin % cuedata->frame_len;
			my_lba2msf(cuedata->td[n].lba1, &cuedata->td[n].min1, &cuedata->td[n].sec1, &cuedata->td[n].frm1);
			break;
		}
	}
	return 0;
}

// ----------------------------------------------------------------------------
int my_get_bindata(const cuedata_t * cuedata, int flg_wave)
{
	FILE *ifp, *ofp;			// file pointer
	char bname[PATH_MAX];		// path name
	char opath[PATH_MAX];		// path name
	char buf[CD_FRAMESIZE_RAW];	// track data
	size_t blen = sizeof(buf);	// buffer size
	int ret = 0;				// status
	int i, j;					// work
	// ------------------------------------------------------------------------
	wave_header_t wave_header;	// wave_header
	wave_data_t wave_data;		// wave data
	memset(&wave_header, 0, sizeof(wave_header));
	memcpy(wave_header.riff_hdr, "RIFF", sizeof(wave_header.riff_hdr));
	memcpy(wave_header.wave_hdr, "WAVE", sizeof(wave_header.wave_hdr));
	memcpy(wave_header.fmt_hdr, "fmt ", sizeof(wave_header.fmt_hdr));
	wave_header.fmt_len = 16;
	wave_header.constant = 1;
	wave_header.channels = 2;
	wave_header.samplerate = 44100;
	wave_header.bytespersec = (2 * 2 * wave_header.samplerate);
	wave_header.blockalign = 4;
	wave_header.bitspersample = 16;
	memset(&wave_data, 0, sizeof(wave_data));
	memcpy(wave_data.data_hdr, "data", sizeof(wave_data.data_hdr));
	// ------------------------------------------------------------------------
	if (my_basename(cuedata->fname_bin, bname, sizeof(bname), NULL, 0) < 0)
		return -1;
	if ((my_fopen(&ifp, cuedata->fname_bin, "rb")) < 0)
		return -1;
	for (i = 0; i < sizeof(cuedata->td) / sizeof(cuedata->td[0]) && cuedata->td[i].trk > 0; i++) {
		if (flg_wave)
			snprintf(opath, sizeof(opath), "%s.tr%02d.wav", bname, cuedata->td[i].trk);
		else
			snprintf(opath, sizeof(opath), "%s.tr%02d.cdr", bname, cuedata->td[i].trk);
		if ((ret = my_fopen(&ofp, opath, "wb")) < 0)
			break;
		// wave data header
		if (flg_wave) {
			wave_data.length = (cuedata->td[i].lba1 - cuedata->td[i].lba0 + 1) * CD_FRAMESIZE_RAW;
			wave_header.length = WAVE_HEADER_LEN + WAVE_DATA_LEN + wave_data.length - 8;
			if ((ret = fwrite(&wave_header, sizeof(wave_header), 1, ofp)) <= 0)
				break;
			if ((ret = fwrite(&wave_data, sizeof(wave_data), 1, ofp)) <= 0)
				break;
		}
		// wave data
		for (j = 0; j < cuedata->td[i].lba1 - cuedata->td[i].lba0 + 1; j++) {
			if ((ret = my_fread(buf, blen, 1, ifp)) <= 0)
				break;
			if ((ret = my_fwrite(buf, blen, 1, ofp)) <= 0)
				break;
		}
		if ((ret = my_fclose(ofp)) < 0)
			break;
	}
	if (my_fclose(ifp) < 0)
		return -1;
	return ret;
}

// ----------------------------------------------------------------------------
