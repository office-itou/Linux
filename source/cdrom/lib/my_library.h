// ****************************************************************************
// my library
// ****************************************************************************

#ifndef __MY_LIBRARY_H__
#define __MY_LIBRARY_H__

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#include <linux/limits.h>				// PATH_MAX,NAME_MAX

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#ifndef _G_BUFSIZ
#define _G_BUFSIZ			8192
#endif

#ifndef _IO_BUFSIZ
#define _IO_BUFSIZ			_G_BUFSIZ
#endif

#ifndef BUFSIZ
#define BUFSIZ				_IO_BUFSIZ
#endif

#if BUFSIZ > PATH_MAX
#define BUFF_MAX			BUFSIZ
#else
#define BUFF_MAX			PATH_MAX
#endif

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#ifndef MODULE

// ============================================================================
extern int my_perror(int errnum, const char *format, ...);
extern int my_sjis2utf8(const char *src, char *dst, size_t len);

// ============================================================================
extern void my_dirname(const char *path, char *dname, size_t dname_len, char *fname, size_t fname_len);
extern void my_basename(const char *path, char *bname, size_t bname_len, char *ename, size_t ename_len);

// ============================================================================
extern int my_open(const char *pathname, int flags, mode_t mode);
extern int my_close(int fd);
extern off_t my_lseek(int fd, off_t offset, int whence);
extern ssize_t my_read(int fd, void *buf, size_t count);
extern ssize_t my_write(int fd, const void *buf, size_t count);
extern ssize_t my_pread(int fd, void *buf, size_t count, off_t offset);
extern ssize_t my_pwrite(int fd, const void *buf, size_t count, off_t offset);
extern int my_ioctl(int fd, unsigned long request, void *argp);
extern off_t my_fstat(int fd);
extern off_t my_stat(const char *pathname);

// ============================================================================
#endif							// MODULE

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#endif							// __MY_LIBRARY_H__

// *** EOF ********************************************************************
