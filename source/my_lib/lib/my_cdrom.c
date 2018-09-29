// ----------------------------------------------------------------------------
#include "my_common.h"
// ----------------------------------------------------------------------------
void my_lba2msf(int lba, int *m, int *s, int *f)
{
//  lba += CD_MSF_OFFSET;
	lba &= 0xffffff;					/* negative lbas use only 24 bits */
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
	*m = strtol(p, NULL, 10);
	// --- sec ----------------------------------------------------------------
	p = t + 1;
	if ((t = strchr(p, ':')) == NULL)
		return -1;
	*t = '\0';
	*s = strtol(p, NULL, 10);
	// --- frame --------------------------------------------------------------
	p = t + 1;
	*f = strtol(p, NULL, 10);
	// ------------------------------------------------------------------------
	return my_msf2lba(*m, *s, *f);
}

// ----------------------------------------------------------------------------
int my_get_cuedata(cuedata_t * cuedata)
{
	int err = 0, ret = 0;				// return code
	FILE *fp;							// file pointer
	char pathname[PATH_MAX];			// cue file name
	ssize_t len;						// return value (length or error)
	char buf[BUFF_MAX];					// read data
	int frame_len = CD_FRAMESIZE_RAW;	// frame size (CD-DA)
	char *p, *s, *t;					// work
	int n = -1, min, sec, frm, lba;		// work
	char dname[PATH_MAX];				// work directory name
	char fname[PATH_MAX];				// work file name
	off_t size;							// work file size

	// ------------------------------------------------------------------------
	strncpy(pathname, cuedata->fname_cue, sizeof(pathname));
	memset(cuedata, 0, sizeof(cuedata_t));
	strncpy(cuedata->fname_cue, pathname, sizeof(cuedata->fname_cue));
	cuedata->frame_len = frame_len;		// frame size
	my_dirname(pathname, dname, sizeof(dname), NULL, 0);
	// ------------------------------------------------------------------------
	if ((ret = my_fopen(&fp, pathname, "r")) < 0)
		return ret;
	// ------------------------------------------------------------------------
	while (1) {
		len = my_fgets(buf, sizeof(buf), fp);
		if (!len)						// file end
			break;
		if (len < 0) {					// read error
			err = len;
			break;
		}
		my_rm_crlf(buf);
		// "FILE",bin file name,file type -------------------------------------
		if ((p = strstr(buf, "FILE")) != NULL) {
			if ((s = strchr(p, '"')) != NULL && (t = strchr((s + 1), '"')) != NULL) {
				*t = '\0';
				if ((ret = my_sjis2utf8((s + 1), fname, sizeof(fname))) < 0) {
					err = ret;
					break;
				}
				if (strstr(t + 1, "BINARY") != NULL)
					cuedata->flg |= 1;
				snprintf(cuedata->fname_bin, sizeof(cuedata->fname_bin), "%s/%s", dname, fname);
				if ((size = my_stat(cuedata->fname_bin)) < 0) {
					err = size;
					break;
				}
				cuedata->fsize_bin = size;
				cuedata->leadout = size / cuedata->frame_len;
			}
			continue;
		}
		// "TRACK",track number (string/numeric-1) ----------------------------
		if ((p = strstr(buf, "TRACK")) != NULL) {
			if ((s = strchr(p, ' ')) != NULL && (t = strchr((s + 1), ' ')) != NULL) {
				*t = '\0';
				n++;
				if (n >= 0 && n < TRACK_MAX) {
					cuedata->td[n].trk = strtol((s + 1), NULL, 10);
					if (strstr(t + 1, "AUDIO") != NULL)
						cuedata->td[n].flg |= 1;
					if (!cuedata->trk0)
						cuedata->trk0 = cuedata->td[n].trk;
					cuedata->trk1 = cuedata->td[n].trk;
				}
			}
			continue;
		}
		// "INDEX",index number,time and frame(msf) ---------------------------
		if ((p = strstr(buf, "INDEX")) != NULL) {
			if ((s = strchr(p, ' ')) != NULL && (t = strchr((s + 1), ' ')) != NULL) {
				*t = '\0';
				if (n >= 0 && n < TRACK_MAX) {
					cuedata->td[n].ind = strtol((s + 1), NULL, 10);
					if ((lba = my_msf2frame((t + 1), &min, &sec, &frm)) < 0) {
						err = lba;
						break;
					}
					cuedata->td[n].lba0 = lba;
					cuedata->td[n].min0 = min;
					cuedata->td[n].sec0 = sec;
					cuedata->td[n].frm0 = frm;
					if (n > 0) {
						lba--;
						my_lba2msf(lba, &min, &sec, &frm);
						cuedata->td[n - 1].lba1 = lba;
						cuedata->td[n - 1].min1 = min;
						cuedata->td[n - 1].sec1 = sec;
						cuedata->td[n - 1].frm1 = frm;
					}
				}
			}
			continue;
		}
	}
	// ------------------------------------------------------------------------
	if ((ret = my_fclose(fp)) < 0)
		err = ret;
	// ------------------------------------------------------------------------
	if (!err) {
		if ((n = cuedata->trk1 - 1) < 0) {
			err = -EINVAL;
		} else {
			lba = cuedata->leadout;
			my_lba2msf(lba, &min, &sec, &frm);
			cuedata->td[n].lba1 = lba;
			cuedata->td[n].min1 = min;
			cuedata->td[n].sec1 = sec;
			cuedata->td[n].frm1 = frm;
		}
	}
	// ------------------------------------------------------------------------
	return err;
}

// ----------------------------------------------------------------------------
int my_get_bindata(const cuedata_t * cuedata, int flg_wave)
{
	FILE *ifp, *ofp;					// file pointer
	char bname[PATH_MAX];				// path name
	char opath[PATH_MAX];				// path name
	char buf[CD_FRAMESIZE_RAW];			// track data
	size_t blen = sizeof(buf);			// buffer size
	int ret = 0;						// status
	int i, j;							// work

	// ------------------------------------------------------------------------
	wave_header_t wave_header;			// wave_header
	wave_data_t wave_data;				// wave data

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
	my_basename(cuedata->fname_bin, bname, sizeof(bname), NULL, 0);
	if ((my_fopen(&ifp, cuedata->fname_bin, "rb")) < 0)
		return -1;
	for (i = 0; i < TRACK_MAX && cuedata->td[i].trk > 0; i++) {
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
int my_read_toc(tocdata_t * toc)
{
	int err = 0, ret = 0;				// return code
	int fd;								// file descriptor
	char pathname[PATH_MAX];			// cue file name
	ssize_t len;						// return value (length or error)
	char buf[BUFF_MAX];					// read data
	off_t offset = 0;					// offset (from the start of the file)
	char *p, *s, *t;					// work
	int n = -1, min, sec, frm, lba;		// work
	char dname[PATH_MAX];				// work directory name
	char fname[PATH_MAX];				// work file name
	off_t size;							// work file size

	// ------------------------------------------------------------------------
	strncpy(pathname, toc->cue, sizeof(pathname));
	memset(toc, 0, sizeof(tocdata_t));
	strncpy(toc->cue, pathname, sizeof(toc->cue));
	my_dirname(pathname, dname, sizeof(dname), NULL, 0);
	// ------------------------------------------------------------------------
	if ((fd = my_open(pathname, O_RDONLY, 0)) < 0)
		return fd;
	// ------------------------------------------------------------------------
	while (1) {
		memset(buf, 0, sizeof(buf));
		len = my_pread(fd, buf, sizeof(buf) - 1, offset);
		if (!len)						// file end
			break;
		if (len < 0) {					// read error
			err = len;
			break;
		}
		if ((p = strchr(buf, '\n')) != NULL)
			*(p + 1) = '\0';
		offset += strlen(buf);
		// --------------------------------------------------------------------
		while ((p = strchr(buf, '\r')) || (p = strchr(buf, '\n')))
			*p = '\0';
		// "FILE",bin file name,file type -------------------------------------
		if ((p = strstr(buf, "FILE")) != NULL) {
			if ((s = strchr(p, '"')) != NULL && (t = strchr((s + 1), '"')) != NULL) {
				*t = '\0';
				if ((ret = my_sjis2utf8((s + 1), fname, sizeof(fname))) < 0) {
					err = ret;
					break;
				}
				snprintf(toc->bin, sizeof(toc->bin), "%s/%s", dname, fname);
				if ((size = my_stat(toc->bin)) < 0) {
					err = size;
					break;
				}
				toc->leadout = size / CD_FRAMESIZE_RAW;
			}
			continue;
		}
		// "TRACK",track number (string/numeric-1) ----------------------------
		if ((p = strstr(buf, "TRACK")) != NULL) {
			if ((s = strchr(p, ' ')) != NULL && (t = strchr((s + 1), ' ')) != NULL) {
				*t = '\0';
				n++;
				if (n >= 0 && n < TRACK_MAX) {
					if (!toc->first)
						toc->first = strtol((s + 1), NULL, 10);
					toc->last = strtol((s + 1), NULL, 10);
				}
			}
			continue;
		}
		// "INDEX",index number,time and frame(msf) ---------------------------
		if ((p = strstr(buf, "INDEX")) != NULL) {
			if ((s = strchr(p, ' ')) != NULL && (t = strchr((s + 1), ' ')) != NULL) {
				if (n >= 0 && n < TRACK_MAX) {
					if ((lba = my_msf2frame((t + 1), &min, &sec, &frm)) < 0) {
						err = lba;
						break;
					}
					toc->entry[n] = lba;
				}
			}
			continue;
		}
	}
	// ------------------------------------------------------------------------
	if ((ret = my_close(fd)) < 0)
		err = ret;
	// ------------------------------------------------------------------------
	return err;
}

// ----------------------------------------------------------------------------
