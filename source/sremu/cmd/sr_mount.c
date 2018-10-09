// ****************************************************************************
// SCSI cdrom (sr) emulation driver
// ****************************************************************************

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#define DEBUG

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#include <stdio.h>						// fprintf,perror
#include <errno.h>						// errno
#include <limits.h>						// INT_MAX
#include <fcntl.h>						// open
#include <unistd.h>						// close,read,write
#include <sys/stat.h>					// struct stat,lstat
#include <sys/ioctl.h>					// ioctl
#include <linux/limits.h>				// PATH_MAX,NAME_MAX
#include <linux/cdrom.h>				// struct sr_toc,struct cdemu_unit, ...
#include <string.h>						// memset,strncpy,strlen,strchr,strstr
#include <stdlib.h>						// free
#include <stdarg.h>						// va_start,va_end
#include <iconv.h>						// iconv_t,iconv
#include "sr_emu.h"						// SCSI cdrom (sr) emulation driver's header

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
int sr_perror(int errnum, const char *format, ...)
{
	va_list ap;
	char buf[BUFF_MAX];
	char str[BUFF_MAX];

	if (strerror_r(errnum, buf, sizeof(buf)))
		snprintf(buf, sizeof(buf), "Unknown error %d\n", errnum);
	va_start(ap, format);
	vsnprintf(str, sizeof(str), format, ap);
	va_end(ap);
	fprintf(stderr, "%s: %s", buf, str);
	errno = errnum;
	return errnum;
}

// ----------------------------------------------------------------------------
int sr_sjis2utf8(const char *src, char *dst, size_t len)
{
	iconv_t conv;						// conversion descriptor
	char buf[BUFF_MAX];
	char *src_buf = buf;
	char *dst_buf = dst;
	size_t src_len = strlen(src);
	size_t dst_len = len - 1;
	int ret = 0;

	strncpy(buf, src, sizeof(buf));
	if ((conv = iconv_open("UTF-8", "SHIFT-JIS")) == (iconv_t) - 1)
		return -sr_perror(errno, "error: %s: %s\n", __FUNCTION__, "iconv open");
	if (iconv(conv, &src_buf, &src_len, &dst_buf, &dst_len) == (size_t) - 1)
		ret = -sr_perror(errno, "error: %s: %s\n", __FUNCTION__, "iconv");
	*dst_buf = '\0';
	if (iconv_close(conv) == -1)
		ret = -sr_perror(errno, "error: %s: %s\n", __FUNCTION__, "iconv_close");
	return ret;
}

// ----------------------------------------------------------------------------
void sr_dirname(const char *path, char *dname, size_t dname_len, char *fname, size_t fname_len)
{
	char buf[BUFF_MAX];
	char *p;
	char *s = buf;
	char c = '/';

	strncpy(buf, path, sizeof(buf));
	if ((p = strrchr(s, c)) == NULL) {
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

// ----------------------------------------------------------------------------
void sr_basename(const char *path, char *bname, size_t bname_len, char *ename, size_t ename_len)
{
	char buf[BUFF_MAX];
	char *p;
	char *s = buf;
	char c = '.';

	strncpy(buf, path, sizeof(buf));
	if ((p = strrchr(s, c)) == NULL) {
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

// ----------------------------------------------------------------------------
int sr_open(const char *pathname, int flags, mode_t mode)
{
	int fd;

	if ((fd = open(pathname, flags, mode)) < 0)
		return -sr_perror(errno, "error: %s: %s: %s\n", __FUNCTION__, "open", pathname);
	return fd;
}

// ----------------------------------------------------------------------------
int sr_close(int fd)
{
	int res;

	if ((res = close(fd)) < 0)
		return -sr_perror(errno, "error: %s: %s\n", __FUNCTION__, "close");
	return res;
}

// ----------------------------------------------------------------------------
off_t sr_lseek(int fd, off_t offset, int whence)
{
	off_t res;

	if ((res = lseek(fd, offset, whence)) < 0)
		return -sr_perror(errno, "error: %s: %s\n", __FUNCTION__, "lseek");
	return res;
}

// ----------------------------------------------------------------------------
ssize_t sr_read(int fd, void *buf, size_t count)
{
	ssize_t res;

	if ((res = read(fd, buf, count)) < 0)
		return -sr_perror(errno, "error: %s: %s\n", __FUNCTION__, "read");
	return res;
}

// ----------------------------------------------------------------------------
ssize_t sr_write(int fd, const void *buf, size_t count)
{
	ssize_t res;

	if ((res = write(fd, buf, count)) < 0)
		return -sr_perror(errno, "error: %s: %s\n", __FUNCTION__, "write");
	return res;
}

// ----------------------------------------------------------------------------
ssize_t sr_pread(int fd, void *buf, size_t count, off_t offset)
{
	ssize_t res;

	if ((res = pread(fd, buf, count, offset)) < 0)
		return -sr_perror(errno, "error: %s: %s\n", __FUNCTION__, "pread");
	return res;
}

// ----------------------------------------------------------------------------
ssize_t sr_pwrite(int fd, const void *buf, size_t count, off_t offset)
{
	ssize_t res;

	if ((res = pwrite(fd, buf, count, offset)) < 0)
		return -sr_perror(errno, "error: %s: %s\n", __FUNCTION__, "pwrite");
	return res;
}

// ----------------------------------------------------------------------------
int sr_ioctl(int fd, unsigned long request, void *argp)
{
	int res;

	if ((res = ioctl(fd, request, argp)) < 0)
		return -sr_perror(errno, "error: %s: %s\n", __FUNCTION__, "ioctl");
	return res;
}

// ----------------------------------------------------------------------------
off_t sr_fstat(int fd)
{
	struct stat sb;						// file system status

	if (fstat(fd, &sb) < 0)
		return -sr_perror(errno, "error: %s: %s\n", __FUNCTION__, "fstat");
	return sb.st_size;
}

// ----------------------------------------------------------------------------
off_t sr_stat(const char *pathname)
{
	struct stat sb;						// file system status

	if (lstat(pathname, &sb))
		return -sr_perror(errno, "error: %s: %s: %s\n", __FUNCTION__, "stat", pathname);
	return sb.st_size;
}

// ----------------------------------------------------------------------------
int sr_msf2frame(const char *msf, int *m, int *s, int *f)
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
	return sr_msf2lba(*m, *s, *f);
}

// ----------------------------------------------------------------------------
int sr_read_toc(struct sr_toc *toc)
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
	if (realpath(toc->path_cue, pathname) == NULL)
		return -sr_perror(errno, "error: %s: %s: %s\n", __FUNCTION__, "realpath", toc->path_cue);
	memset(toc, 0, sizeof(struct sr_toc));
	strncpy(toc->path_cue, pathname, sizeof(toc->path_cue));
	sr_dirname(pathname, dname, sizeof(dname), NULL, 0);
	// ------------------------------------------------------------------------
	if ((fd = sr_open(pathname, O_RDONLY, 0)) < 0)
		return fd;
	// ------------------------------------------------------------------------
	while (1) {
		memset(buf, 0, sizeof(buf));
		len = sr_pread(fd, buf, sizeof(buf) - 1, offset);
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
				if ((ret = sr_sjis2utf8((s + 1), fname, sizeof(fname))) < 0) {
					err = ret;
					break;
				}
				snprintf(toc->path_bin, sizeof(toc->path_bin), "%s/%s", dname, fname);
				if ((size = sr_stat(toc->path_bin)) < 0) {
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
					if (!toc->tochdr.cdth_trk0)
						toc->tochdr.cdth_trk0 = strtol((s + 1), NULL, 10);
					toc->tochdr.cdth_trk1 = strtol((s + 1), NULL, 10);
				}
			}
			continue;
		}
		// "INDEX",index number,time and frame(msf) ---------------------------
		if ((p = strstr(buf, "INDEX")) != NULL) {
			if ((s = strchr(p, ' ')) != NULL && (t = strchr((s + 1), ' ')) != NULL) {
				if (n >= 0 && n < TRACK_MAX) {
					if ((lba = sr_msf2frame((t + 1), &min, &sec, &frm)) < 0) {
						err = lba;
						break;
					}
					toc->tocentry[n].cdte_track = toc->tochdr.cdth_trk1;
					toc->tocentry[n].cdte_adr = 1;
					toc->tocentry[n].cdte_ctrl = 0;
					toc->tocentry[n].cdte_format = CDROM_MSF;
					if (toc->tocentry[n].cdte_format == CDROM_MSF) {
						toc->tocentry[n].cdte_addr.msf.minute = min;
						toc->tocentry[n].cdte_addr.msf.second = sec;
						toc->tocentry[n].cdte_addr.msf.frame = frm;
					} else {
						toc->tocentry[n].cdte_addr.lba = lba;
					}
					toc->tocentry[n].cdte_datamode = (toc->tocentry[n].cdte_ctrl & 0x04) ? 1 : 0;
				}
			}
			continue;
		}
	}
	// ------------------------------------------------------------------------
	if ((ret = sr_close(fd)) < 0)
		err = ret;
	// ------------------------------------------------------------------------
	return err;
}

// ============================================================================
int main(int argc, char *argv[])
{
	int err = 0, ret;
	struct sr_toc toc;
	char *dev_name;
	int fd;

	if (argc != 3) {
		fprintf(stderr, "usage: %s [cue file name] [special device name]\n", argv[0]);
		return 1;
	}

	strncpy(toc.path_cue, argv[1], sizeof(toc.path_cue));
	dev_name = argv[2];

	if ((err = sr_read_toc(&toc)) < 0)
		return err;

	if ((fd = sr_open(dev_name, O_RDWR | O_NONBLOCK, 0)) < 0)
		return fd;

	if ((ret = sr_ioctl(fd, SR_MEDIA_LOAD, &toc)) < 0)
		err = ret;

	if ((ret = close(fd)) < 0)
		err = ret;

	return err;
}

// *** EOF ********************************************************************
