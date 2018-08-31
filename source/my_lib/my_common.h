// ----------------------------------------------------------------------------
#ifndef __MY_COMMON_H__
#define __MY_COMMON_H__
// ----------------------------------------------------------------------------
#define _XOPEN_SOURCE 700
#include <features.h>
#include <unistd.h>
#include <stdint.h>						// uint16_t,uint32_t,uint64_t,...
#include <syslog.h>						// syslog
#include <errno.h>						// errno
#include <stdio.h>						// FILE,fopen,fclose,...
#include <string.h>						// memset,strncpy,strlen,strchr,strstr
#include <stdlib.h>						// free
#include <linux/limits.h>				// PATH_MAX
#include <linux/cdrom.h>				// CD_FRAMES,CD_SECS,...
// ----------------------------------------------------------------------------
#if BUFSIZ > PATH_MAX
#define BUFF_MAX BUFSIZ
#else
#define BUFF_MAX PATH_MAX
#endif
#define DBGPRINT(s1,s2,s3) fprintf(stderr, "%s: %d: %s\n", s1, s2, s3)
#ifdef OSYSLOG
#define no_syslog(pri, fmt, ...)				\
({												\
	do {										\
		if (0)									\
			syslog(pri, fmt, ##__VA_ARGS__);	\
	} while (0);								\
	0;											\
})
#define pr_emerg(fmt, ...)		syslog(LOG_EMERG, fmt, ##__VA_ARGS__)
#define pr_alert(fmt, ...)		syslog(LOG_ALERT, fmt, ##__VA_ARGS__)
#define pr_crit(fmt, ...)		syslog(LOG_CRIT, fmt, ##__VA_ARGS__)
#define pr_err(fmt, ...)		syslog(LOG_ERR, fmt, ##__VA_ARGS__)
#define pr_warning(fmt, ...)	syslog(LOG_WARNING, fmt, ##__VA_ARGS__)
#define pr_warn					pr_warning
#define pr_notice(fmt, ...)		syslog(LOG_NOTICE, fmt, ##__VA_ARGS__)
#define pr_info(fmt, ...)		syslog(LOG_INFO, fmt, ##__VA_ARGS__)
#define pr_cont(fmt, ...)		syslog(LOG_CONT, fmt, ##__VA_ARGS__)
#ifdef DEBUG
#define pr_devel(fmt, ...)		syslog(LOG_DEBUG, fmt, ##__VA_ARGS__)
#else
#define pr_devel(fmt, ...)		no_syslog(LOG_DEBUG, fmt, ##__VA_ARGS__)
#endif
#else
#define no_fprintf(fmt, ...)				\
({												\
	do {										\
		if (0)									\
			fprintf(stderr, fmt, ##__VA_ARGS__);\
	} while (0);								\
	0;											\
})
#define pr_emerg(fmt, ...)		fprintf(stderr, fmt, ##__VA_ARGS__)
#define pr_alert(fmt, ...)		fprintf(stderr, fmt, ##__VA_ARGS__)
#define pr_crit(fmt, ...)		fprintf(stderr, fmt, ##__VA_ARGS__)
#define pr_err(fmt, ...)		fprintf(stderr, fmt, ##__VA_ARGS__)
#define pr_warning(fmt, ...)	fprintf(stderr, fmt, ##__VA_ARGS__)
#define pr_warn					pr_warning
#define pr_notice(fmt, ...)		fprintf(stderr, fmt, ##__VA_ARGS__)
#define pr_info(fmt, ...)		fprintf(stderr, fmt, ##__VA_ARGS__)
#define pr_cont(fmt, ...)		fprintf(stderr, fmt, ##__VA_ARGS__)
#ifdef DEBUG
#define pr_devel(fmt, ...)		fprintf(stderr, fmt, ##__VA_ARGS__)
#else
#define pr_devel(fmt, ...)		no_fprintf(fmt, ##__VA_ARGS__)
#endif
#endif
// --- my_string.c ------------------------------------------------------------
extern void my_perror(int errnum, const char *format, ...);
extern void my_rm_crlf(char *s);
extern int my_sjis2utf8(const char *src, char *dst, size_t len);
extern int my_dirname(const char *path, char *dname, size_t dname_len, char *fname, size_t fname_len);
extern int my_basename(const char *path, char *bname, size_t bname_len, char *ename, size_t ename_len);
// --- my_file.c --------------------------------------------------------------
extern int my_fopen(FILE ** stream, const char *path, const char *mode);
extern int my_fclose(FILE * stream);
extern ssize_t my_fread(void *ptr, size_t size, size_t nmemb, FILE * stream);
extern ssize_t my_fwrite(const void *ptr, size_t size, size_t nmemb, FILE * stream);
extern ssize_t my_fgets(char *s, int size, FILE * stream);
extern ssize_t my_fputs(const char *s, FILE * stream);
extern off_t my_stat(const char *pathname);
// --- my_cdrom.c -------------------------------------------------------------
typedef struct {
	int trk;							// track number
	int ind;							// index number
	int min0;							// start minute
	int sec0;							// start second
	int frm0;							// start frame
	int min1;							// end minute
	int sec1;							// end second
	int frm1;							// end frame
	int lba0;							// start lba
	int lba1;							// end lba
	int flg;							// flag (1:audio,...)
} trkdata_t;
typedef struct {
	char fname_cue[PATH_MAX];			// cue file name
	char fname_bin[PATH_MAX];			// bin file name
	off_t fsize_bin;					// bin file size
	int frame_len;						// frame size
	int trk0;							// start track
	int trk1;							// end track
	int flg;							// flag (1:binary,...)
	trkdata_t td[99];					// track data
} cuedata_t;
#define WAVE_HEADER_LEN 36
#define WAVE_DATA_LEN    8
typedef struct wave_header {
	char riff_hdr[4];					// RIFF header: "RIFF"
	uint32_t length;					// length of file, starting from WAVE: (xx xx xx xx) (file size - 8)
	char wave_hdr[4];					// WAVE header: "WAVE"
	char fmt_hdr[4];					// FORMAT header: "fmt "
	uint32_t fmt_len;					// length of FORMAT header 16(10 00 00 00)
	uint16_t constant;					// constant: 1(01 00)
	uint16_t channels;					// channels: 2(02 00)
	uint32_t samplerate;				// sample rate: 44100(44 AC 00 00)
	uint32_t bytespersec;				// bytes per second: 176400(10 B1 02 00)
	uint16_t blockalign;				// bytes per sample: 4(04 00)
	uint16_t bitspersample;				// bits per channel: 16(10 00)
} __attribute__ ((__packed__)) wave_header_t;
typedef struct wave_data {
	char data_hdr[4];					// DATA header: "data"
	uint32_t length;					// length of wave data
//  char *data;                         // wave data
} __attribute__ ((__packed__)) wave_data_t;
extern void my_lba2msf(int lba, int *m, int *s, int *f);
extern int my_msf2lba(int m, int s, int f);
extern int my_msf2frame(const char *buf, int *m, int *s, int *f);
extern int my_get_cuedata(cuedata_t * cuedata);
extern int my_get_bindata(const cuedata_t * cuedata, int flg_wave);
// ----------------------------------------------------------------------------
#endif									// __MY_COMMON_H__
// ----------------------------------------------------------------------------
// gcc -Wall t_cdrom.c my_cdrom.c my_file.c my_string.c -o t_cdrom -g
// valgrind --leak-check=full --track-origins=yes
// ----------------------------------------------------------------------------
