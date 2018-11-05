// ****************************************************************************
// my library
// ****************************************************************************

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#define NDEBUG

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#include <stdio.h>						// fprintf,perror
#include <errno.h>						// errno
#include <limits.h>						// INT_MAX
#include <fcntl.h>						// open
#include <unistd.h>						// close,read,write
#include <sys/stat.h>					// struct stat,lstat
#include <sys/ioctl.h>					// ioctl
#include <linux/cdrom.h>				// struct my_toc,struct cdemu_unit, ...
#include <string.h>						// memset,strncpy,strlen,strchr,strstr
#include <stdlib.h>						// free
#include <stdarg.h>						// va_start,va_end
#include <iconv.h>						// iconv_t,iconv
#include "my_library.h"					// my library's header

// ::: my_library.c :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
int my_perror(int errnum, const char *format, ...)
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

// ============================================================================
int my_sjis2utf8(const char *src, char *dst, size_t len)
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
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "iconv open");
	if (iconv(conv, &src_buf, &src_len, &dst_buf, &dst_len) == (size_t) - 1)
		ret = -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "iconv");
	*dst_buf = '\0';
	if (iconv_close(conv) == -1)
		ret = -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "iconv_close");
	return ret;
}

// ============================================================================
void my_dirname(const char *path, char *dname, size_t dname_len, char *fname, size_t fname_len)
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

// ============================================================================
void my_basename(const char *path, char *bname, size_t bname_len, char *ename, size_t ename_len)
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

// ============================================================================
int my_open(const char *pathname, int flags, mode_t mode)
{
	int fd;

	if ((fd = open(pathname, flags, mode)) < 0)
		return -my_perror(errno, "error: %s: %s: %s\n", __FUNCTION__, "open", pathname);
	return fd;
}

// ============================================================================
int my_close(int fd)
{
	int res;

	if ((res = close(fd)) < 0)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "close");
	return res;
}

// ============================================================================
off_t my_lseek(int fd, off_t offset, int whence)
{
	off_t res;

	if ((res = lseek(fd, offset, whence)) < 0)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "lseek");
	return res;
}

// ============================================================================
ssize_t my_read(int fd, void *buf, size_t count)
{
	ssize_t res;

	if ((res = read(fd, buf, count)) < 0)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "read");
	return res;
}

// ============================================================================
ssize_t my_write(int fd, const void *buf, size_t count)
{
	ssize_t res;

	if ((res = write(fd, buf, count)) < 0)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "write");
	return res;
}

// ============================================================================
ssize_t my_pread(int fd, void *buf, size_t count, off_t offset)
{
	ssize_t res;

	if ((res = pread(fd, buf, count, offset)) < 0)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "pread");
	return res;
}

// ============================================================================
ssize_t my_pwrite(int fd, const void *buf, size_t count, off_t offset)
{
	ssize_t res;

	if ((res = pwrite(fd, buf, count, offset)) < 0)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "pwrite");
	return res;
}

// ============================================================================
int my_ioctl(int fd, unsigned long request, void *argp)
{
	int res;

	if ((res = ioctl(fd, request, argp)) < 0)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "ioctl");
	return res;
}

// ============================================================================
off_t my_fstat(int fd)
{
	struct stat sb;						// file system status

	if (fstat(fd, &sb) < 0)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "fstat");
	return sb.st_size;
}

// ============================================================================
off_t my_stat(const char *pathname)
{
	struct stat sb;						// file system status

	if (lstat(pathname, &sb))
		return -my_perror(errno, "error: %s: %s: %s\n", __FUNCTION__, "stat", pathname);
	return sb.st_size;
}

// *** EOF ********************************************************************
