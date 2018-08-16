#include <stdint.h>				// uint16_t,uint32_t,uint64_t,...
#include <stdio.h>				// FILE,fopen,fclose,...
#include <stdlib.h>				// strtoul
#include <string.h>				// strdup,strtok
#include <sys/stat.h>			// stat
#include <linux/cdrom.h>		// CD_FRAMES,CD_SECS,...
#include <linux/limits.h>		// PATH_MAX
#include <iconv.h>				// iconv_t,iconv
#include <unistd.h>				// getopt

#define DBGPRINT(s1,s2,s3) fprintf(stderr, "%s: %s: %d\n", s1, s2, s3)

#define arrayof(a) (sizeof(a)/sizeof(a[0]))

#if (PATH_MAX > BUFSIZ)
#define STR_MAX (PATH_MAX+1)
#else
#define STR_MAX (BUFSIZ+1)
#endif

typedef struct trackdata {
	char track[4];				// track number
	char mode[16];				// track mode
	char index[4];				// index number
	char time[16];				// time and frame
	int frame_start;			// start frame number
	int frame_end;				// end frame number
	int frame_size;				// frame size
	uint64_t fsize;				// file size
} trackdata_t;

typedef struct cuedata {
	char dname[PATH_MAX];		// directory
	char fname_cue[PATH_MAX];	// cue file name
	char fname_bin[PATH_MAX];	// bin file name
	uint64_t fsize_bin;			// bin file size
	char ftype[16];				// file type (binary or ?)
	char basename[PATH_MAX];	// file name: basename
	char extension[PATH_MAX];	// file name: extension
	int frame_len;				// frame size
	trackdata_t trk[100];		// track data
} cuedata_t;

#define WAVE_HEADER_LEN 36
#define WAVE_DATA_LEN    8

typedef struct wave_header {
	char riff_hdr[4];			// RIFF header: "RIFF"
	uint32_t length;			// length of file, starting from WAVE: (xx xx xx xx) (file size - 8)
	char wave_hdr[4];			// WAVE header: "WAVE"
	char fmt_hdr[4];			// FORMAT header: "fmt "
	uint32_t fmt_len;			// length of FORMAT header 16(10 00 00 00)
	uint16_t constant;			// constant: 1(01 00)
	uint16_t channels;			// channels: 2(02 00)
	uint32_t samplerate;		// sample rate: 44100(44 AC 00 00)
	uint32_t bytespersec;		// bytes per second: 176400(10 B1 02 00)
	uint16_t blockalign;		// bytes per sample: 4(04 00)
	uint16_t bitspersample;		// bits per channel: 16(10 00)
} __attribute__ ((__packed__)) wave_header_t;

typedef struct wave_data {
	char data_hdr[4];			// DATA header: "data"
	uint32_t length;			// length of wave data
//  char *data;                 // wave data
} __attribute__ ((__packed__)) wave_data_t;

int main(int argc, char *argv[]);
void dbg_print(const cuedata_t * cuedata);
int sjis2utf8(const char *src, char *dst, size_t len);
void str_rm_crlf(char *s);
void str_dirname(const char *path, char *dname, const size_t dname_len, char *fname, const size_t fname_len);
void str_basename(const char *path, char *bname, const size_t bname_len, char *ename, const size_t ename_len);
int msf2frame(const char *time);
int get_cuedata(cuedata_t * cuedata);
int get_bindata(const cuedata_t * cuedata);

int flg_disp = 0;				// 1: cue data print display
int flg_wave = 0;				// 1: output to wave data

int main(int argc, char *argv[])
{
	cuedata_t cuedata;			// cue data
	char *extension = "cdr";	// extension
	int opt;					// option character
	int i;

	while ((opt = getopt(argc, argv, "wd")) != -1) {
		switch (opt) {
		case 'w':
			flg_wave = 1;
			extension = "wav";
			break;
		case 'd':
			flg_disp = 1;
			break;
		case 'h':
		case '?':
			fprintf(stderr, "usage: %s [cue file name]\n", argv[0]);
			return 0;
			break;
		default:
			break;
		}
	}

	if (argc - optind < 1) {
		fprintf(stderr, "usage: %s [cue file name]\n", argv[0]);
		return -1;
	}

	for (i = optind; i < argc; i++) {
		memset(&cuedata, 0, sizeof(cuedata));
		str_dirname(argv[i], cuedata.dname, sizeof(cuedata.dname), cuedata.fname_cue, sizeof(cuedata.fname_cue));
		str_basename(cuedata.fname_cue, cuedata.basename, sizeof(cuedata.basename), NULL, 0);
		strncpy(cuedata.extension, extension, sizeof(cuedata.extension));

		if (get_cuedata(&cuedata))
			return -1;

		if (flg_disp) {
			dbg_print(&cuedata);
			continue;
		}

		if (get_bindata(&cuedata))
			return -1;
	}

	return 0;
}

void dbg_print(const cuedata_t * cuedata)
{
	int i;

	printf("directory    : [%s]\n", cuedata->dname);
	printf("cue file name: [%s]\n", cuedata->fname_cue);
	printf("bin file name: [%s]\n", cuedata->fname_bin);
	printf("bin file size: [%lu]\n", cuedata->fsize_bin);
	printf("file type    : [%s]\n", cuedata->ftype);
	printf("|TRK| MODE |IDX|   TIME   |  f-START |  f-END   |  f-SIZE  |\n");
	for (i = 0; i < arrayof(cuedata->trk); i++) {
		if (!strlen(cuedata->trk[i].track))
			break;
		printf("|%3.3s|%-6.6s|%3.3s|%10.10s|%10d|%10d|%10d|\n", cuedata->trk[i].track, cuedata->trk[i].mode, cuedata->trk[i].index, cuedata->trk[i].time, cuedata->trk[i].frame_start, cuedata->trk[i].frame_end, cuedata->trk[i].frame_size);
	}
}

int sjis2utf8(const char *src, char *dst, size_t len)
{
	iconv_t conv;				// conversion descriptor
	char str_buf[STR_MAX];
	char *src_buf;
	char *dst_buf;
	size_t src_len = strlen(src);
	size_t dst_len = len - 1;
	int ret = 0;

	strncpy(str_buf, src, sizeof(str_buf));
	src_buf = str_buf;
	dst_buf = dst;

	if ((conv = iconv_open("UTF-8", "SHIFT-JIS")) == (iconv_t) - 1) {
		perror("iconv open");
		return -1;
	}

	if (iconv(conv, &src_buf, &src_len, &dst_buf, &dst_len) == (size_t) - 1) {
		perror("iconv");
		ret = -1;
	}

	*dst_buf = '\0';

	if (iconv_close(conv) == -1) {
		perror("iconv_close");
		ret = -1;
	}

	return ret;
}

void str_rm_crlf(char *s)
{
	char *p;					// returns a pointer CR or LF

	while ((p = strchr(s, '\r')) || (p = strchr(s, '\n')))
		*p = '\0';
}

void str_dirname(const char *path, char *dname, const size_t dname_len, char *fname, const size_t fname_len)
{
	char str_buf[STR_MAX];
	char *p, *s;
	char c = '/';

	strncpy(str_buf, path, sizeof(str_buf));
	s = str_buf;
	p = strrchr(s, c);

	if (p == NULL) {
		if (dname != NULL)
			strncpy(dname, ".", dname_len);
		if (fname != NULL)
			strncpy(fname, s, fname_len);
	} else {
		*p = '\0';
		if (dname != NULL)
			strncpy(dname, s, dname_len);
		if (fname != NULL)
			strncpy(fname, (p + 1), fname_len);
	}
}

void str_basename(const char *path, char *bname, const size_t bname_len, char *ename, const size_t ename_len)
{
	char str_buf[STR_MAX];
	char *p, *s;
	char c = '.';

	strncpy(str_buf, path, sizeof(str_buf));
	s = str_buf;
	p = strrchr(s, c);

	if (p == NULL) {
		if (bname != NULL)
			strncpy(bname, s, bname_len);
		if (ename != NULL)
			strncpy(ename, "", ename_len);
	} else {
		*p = '\0';
		if (bname != NULL)
			strncpy(bname, s, bname_len);
		if (ename != NULL)
			strncpy(ename, (p + 1), ename_len);
	}
}

int msf2frame(const char *time)
{
	char str_buf[STR_MAX] = "";
	char *p, *t;				// time (string)
	int m = 0, s = 0, f = 0;	// min, sec, frame

	strncpy(str_buf, time, strlen(time));
	p = str_buf;

	if ((t = strchr(p, ':')) == NULL)
		return -1;
	*t = '\0';
	m = atoi(p);

	p = t + 1;
	if ((t = strchr(p, ':')) == NULL)
		return -1;
	*t = '\0';
	s = atoi(p);

	p = t + 1;
	f = atoi(p);

	return (CD_FRAMES * (m * CD_SECS + s) + f);
}

int get_cuedata(cuedata_t * cuedata)
{
	FILE *fp;					// file pointer
	char path[PATH_MAX];		// path name
	char str_buf[STR_MAX];		// read data
	char *p, *s, *t;			// work pointer
	int n = -1;					// track number (numeric)
	struct stat sb;				// file system status

	snprintf(path, sizeof(path), "%s/%s", cuedata->dname, cuedata->fname_cue);
	fprintf(stderr, "reading file: %s\n", path);

	if ((fp = fopen(path, "r")) == NULL) {
		perror("fopen");
		fprintf(stderr, "%s: fopen: %s\n", __FUNCTION__, path);
		return -1;
	}

	while (1) {
		if (fgets(str_buf, sizeof(str_buf), fp) == NULL)
			break;
		s = str_buf;
		str_rm_crlf(s);			// remove CR/LF
		// "FILE",bin file name,file type
		if ((p = strstr(s, "FILE")) != NULL) {
			strtok(p, "\"");
			if ((t = strtok(NULL, "\"")) == NULL) {
				fprintf(stderr, "not found bin file name in %s\n", path);
				if (fclose(fp) == EOF)
					perror("fclose");
				return -1;
			}
			// file name convert: sjis->utf-8
			if (sjis2utf8(t, cuedata->fname_bin, sizeof(cuedata->fname_bin)) < 0) {
				if (fclose(fp) == EOF)
					perror("fclose");
				return -1;
			}
			t = strtok(NULL, " ");
			strncpy(cuedata->ftype, t, sizeof(cuedata->ftype));
			continue;
		}
		// "TRACK",track number (string/numeric-1)
		if ((p = strstr(s, "TRACK")) != NULL) {
			strtok(p, " ");
			t = strtok(NULL, " ");
			n = atoi(t) - 1;
			if (n >= arrayof(cuedata->trk)) {
				fprintf(stderr, "track number: %s > %lu\n", s, arrayof(cuedata->trk));
				if (fclose(fp) == EOF)
					perror("fclose");
				return -1;
			}
			// track number,track mode
			strncpy(cuedata->trk[n].track, t, sizeof(cuedata->trk[n].track));
			strncpy(cuedata->trk[n].mode, strtok(NULL, " "), sizeof(cuedata->trk[n].mode));
			continue;
		}
		// "INDEX",index number,time and frame(msf)
		if ((p = strstr(s, "INDEX")) != NULL) {
			strtok(p, " ");
			strncpy(cuedata->trk[n].index, strtok(NULL, " "), sizeof(cuedata->trk[n].index));
			strncpy(cuedata->trk[n].time, strtok(NULL, " "), sizeof(cuedata->trk[n].time));
			// msf->frame
			if ((cuedata->trk[n].frame_start = msf2frame(cuedata->trk[n].time)) < 0) {
				if (fclose(fp) == EOF)
					perror("fclose");
				return -1;
			}
			// frame size
			if (n > 0) {
				cuedata->trk[n - 1].frame_end = cuedata->trk[n].frame_start - 1;
				cuedata->trk[n - 1].frame_size = cuedata->trk[n - 1].frame_end - cuedata->trk[n - 1].frame_start + 1;
				cuedata->trk[n - 1].fsize = cuedata->trk[n - 1].frame_size * CD_FRAMESIZE_RAW;
			}
			continue;
		}
	}

	if (fclose(fp) == EOF) {
		perror("fclose");
		return -1;
	}

	if (n < 0)
		return -1;

	snprintf(path, sizeof(path), "%s/%s", cuedata->dname, cuedata->fname_bin);

	if (stat(path, &sb)) {
		perror("stat");
		fprintf(stderr, "%s: stat: %s\n", __FUNCTION__, path);
		return -1;
	}
	// file size
	cuedata->fsize_bin = sb.st_size;
	// last track frame status
	cuedata->trk[n].frame_end = cuedata->fsize_bin / CD_FRAMESIZE_RAW - 1;
	cuedata->trk[n].frame_size = cuedata->trk[n].frame_end - cuedata->trk[n].frame_start + 1;
	cuedata->trk[n].fsize = cuedata->trk[n].frame_size * CD_FRAMESIZE_RAW;

	fprintf(stderr, "readed\n");

	return 0;
}

int get_bindata(const cuedata_t * cuedata)
{
	FILE *ifp, *ofp;			// file pointer
	char ipath[PATH_MAX];		// path name
	char opath[PATH_MAX];		// path name
	char buf[CD_FRAMESIZE_RAW];	// track data
	size_t blen = sizeof(buf);	// buffer size
	int sect = 0;				// current sector number
	int ret = 0;				// status
	int i, j;					// work
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

	snprintf(ipath, sizeof(ipath), "%s/%s", cuedata->dname, cuedata->fname_bin);
	fprintf(stderr, "reading file: %s\n", ipath);

	if ((ifp = fopen(ipath, "rb")) == NULL) {
		perror("fopen");
		fprintf(stderr, "%s: fopen: %s\n", __FUNCTION__, ipath);
		return -1;
	}

	for (i = 0; i < arrayof(cuedata->trk); i++) {
		if (!strlen(cuedata->trk[i].track))
			break;

		snprintf(opath, sizeof(opath), "%s/%s.tr%s.%s", cuedata->dname, cuedata->basename, cuedata->trk[i].track, cuedata->extension);
		fprintf(stderr, "writing file: %s\n", opath);

		if ((ofp = fopen(opath, "wb")) == NULL) {
			perror("fopen");
			fprintf(stderr, "%s: fopen: %s\n", __FUNCTION__, opath);
			ret = -1;
			break;
		}
		// wave data header
		if (flg_wave) {
			wave_data.length = cuedata->trk[i].fsize;
			wave_header.length = WAVE_HEADER_LEN + WAVE_DATA_LEN + wave_data.length - 8;

			fwrite(&wave_header, sizeof(wave_header), 1, ofp);
			if (ferror(ofp)) {
				fprintf(stderr, "\n");
				perror("fwrite");
				ret = -1;
				break;
			}

			fwrite(&wave_data, sizeof(wave_data), 1, ofp);
			if (ferror(ofp)) {
				fprintf(stderr, "\n");
				perror("fwrite");
				ret = -1;
				break;
			}
		}
		// wave data
		for (j = 0; j < cuedata->trk[i].frame_size; j++) {
			fread(buf, blen, 1, ifp);
			if (ferror(ifp)) {
				fprintf(stderr, "\n");
				perror("fread");
				ret = -1;
				break;
			}
			if (feof(ifp)) {
				fprintf(stderr, "\n");
				break;
			}

			fwrite(buf, blen, 1, ofp);
			if (ferror(ofp)) {
				fprintf(stderr, "\n");
				perror("fwrite");
				ret = -1;
				break;
			}

			sect++;
		}

		if (fclose(ofp) == EOF) {
			perror("fclose");
			ret = -1;
			break;
		}
	}

	if (fclose(ifp) == EOF) {
		perror("fclose");
		ret = -1;
	}

	fprintf(stderr, "readed\n");

	return ret;
}
