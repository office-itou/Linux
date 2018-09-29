// ----------------------------------------------------------------------------
#include "my_common.h"
#include <sys/ioctl.h>					// ioctl
#include <sys/stat.h>					// struct stat,lstat
// ----------------------------------------------------------------------------
int my_fopen(FILE ** stream, const char *path, const char *mode)
{
	if ((*stream = fopen(path, mode)) == NULL)
		return -my_perror(errno, "error: %s: %s: %s\n", __FUNCTION__, "fopen", path);
	return 0;
}

// ----------------------------------------------------------------------------
int my_fclose(FILE * stream)
{
	if (fclose(stream) == EOF)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "fclose");
	return 0;
}

// ----------------------------------------------------------------------------
ssize_t my_fread(void *ptr, size_t size, size_t nmemb, FILE * stream)
{
	size_t ret;

	ret = fread(ptr, size, nmemb, stream);
	if (ferror(stream))
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "fread");
	if (feof(stream))
		return 0;
	return ret;
}

// ----------------------------------------------------------------------------
ssize_t my_fwrite(const void *ptr, size_t size, size_t nmemb, FILE * stream)
{
	size_t ret;

	ret = fwrite(ptr, size, nmemb, stream);
	if (ferror(stream))
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "fread");
	return ret;
}

// ----------------------------------------------------------------------------
ssize_t my_fgets(char *s, int size, FILE * stream)
{
	fgets(s, size, stream);
	if (ferror(stream))
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "fgets");
	if (feof(stream))
		return 0;
	return strlen(s);
}

// ----------------------------------------------------------------------------
ssize_t my_fputs(const char *s, FILE * stream)
{
	fputs(s, stream);
	if (ferror(stream))
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "fputs");
	return strlen(s);
}

// ----------------------------------------------------------------------------
off_t my_stat(const char *pathname)
{
	struct stat sb;						// file system status

	if (lstat(pathname, &sb))
		return -my_perror(errno, "error: %s: %s: %s\n", __FUNCTION__, "stat", pathname);
	return sb.st_size;
}

// ----------------------------------------------------------------------------
int my_open(const char *pathname, int flags, mode_t mode)
{
	int fd;

	if ((fd = open(pathname, flags, mode)) < 0)
		return -my_perror(errno, "error: %s: %s: %s\n", __FUNCTION__, "open", pathname);
	return fd;
}

// ----------------------------------------------------------------------------
int my_close(int fd)
{
	int res;

	if ((res = close(fd)) < 0)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "close");
	return res;
}

// ----------------------------------------------------------------------------
off_t my_lseek(int fd, off_t offset, int whence)
{
	off_t res;

	if ((res = lseek(fd, offset, whence)) < 0)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "lseek");
	return res;
}

// ----------------------------------------------------------------------------
ssize_t my_read(int fd, void *buf, size_t count)
{
	ssize_t res;

	if ((res = read(fd, buf, count)) < 0)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "read");
	return res;
}

// ----------------------------------------------------------------------------
ssize_t my_write(int fd, const void *buf, size_t count)
{
	ssize_t res;

	if ((res = write(fd, buf, count)) < 0)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "write");
	return res;
}

// ----------------------------------------------------------------------------
ssize_t my_pread(int fd, void *buf, size_t count, off_t offset)
{
	ssize_t res;

	if ((res = pread(fd, buf, count, offset)) < 0)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "pread");
	return res;
}

// ----------------------------------------------------------------------------
ssize_t my_pwrite(int fd, const void *buf, size_t count, off_t offset)
{
	ssize_t res;

	if ((res = pwrite(fd, buf, count, offset)) < 0)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "pwrite");
	return res;
}

// ----------------------------------------------------------------------------
int my_ioctl(int fd, unsigned long request, char *argp)
{
	int res;

	if ((res = ioctl(fd, request, argp)) < 0)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "ioctl");
	return res;
}

// ----------------------------------------------------------------------------
off_t my_fstat(int fd)
{
	struct stat sb;						// file system status

	if (fstat(fd, &sb) < 0)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "fstat");
	return sb.st_size;
}

// ----------------------------------------------------------------------------
int my_copy(const char *ipath, const char *opath)
{
	int err = 0;
	int ifd, ofd;
	char buf[102400];
	size_t blen = sizeof(buf);
	off_t fsize, res, i;

	if ((ifd = my_open(ipath, O_RDONLY, 0)) < 0)
		return -errno;

	if ((fsize = my_fstat(ifd)) < 0) {
		err = -errno;
	} else {
		if ((ofd = my_open(opath, O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR)) < 0) {
			err = -errno;
		} else {
			for (i = 0; i < (fsize / blen + ! !(fsize % blen)) * blen && !err; i += blen) {
				if ((res = my_read(ifd, buf, blen)) < 0) {
					err = -errno;
				} else if ((res = my_write(ofd, buf, res)) < 0) {
					err = -errno;
				}
			}
			if (my_close(ofd) < 0)
				err = -errno;
		}
	}

	if (my_close(ifd) < 0)
		err = -errno;

	return err;
}

// ----------------------------------------------------------------------------
