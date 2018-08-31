// ----------------------------------------------------------------------------
#include "my_common.h"
#include <fcntl.h>						// open
#include <sys/ioctl.h>					// ioctl
#include <sys/stat.h>					// struct stat,lstat
// ----------------------------------------------------------------------------
int my_fopen(FILE ** stream, const char *path, const char *mode)
{
	if ((*stream = fopen(path, mode)) == NULL) {
		my_perror(errno, "error: %s: %s: %s\n", __FUNCTION__, "fopen", path);
		return -errno;
	}
	return 0;
}

// ----------------------------------------------------------------------------
int my_fclose(FILE * stream)
{
	if (fclose(stream) == EOF) {
		my_perror(errno, "error: %s: %s\n", __FUNCTION__, "fclose");
		return -errno;
	}
	return 0;
}

// ----------------------------------------------------------------------------
ssize_t my_fread(void *ptr, size_t size, size_t nmemb, FILE * stream)
{
	size_t ret;
	ret = fread(ptr, size, nmemb, stream);
	if (ferror(stream)) {
		my_perror(errno, "error: %s: %s\n", __FUNCTION__, "fread");
		return -errno;
	}
	if (feof(stream))
		return 0;
	return ret;
}

// ----------------------------------------------------------------------------
ssize_t my_fwrite(const void *ptr, size_t size, size_t nmemb, FILE * stream)
{
	size_t ret;
	ret = fwrite(ptr, size, nmemb, stream);
	if (ferror(stream)) {
		my_perror(errno, "error: %s: %s\n", __FUNCTION__, "fread");
		return -errno;
	}
	return ret;
}

// ----------------------------------------------------------------------------
ssize_t my_fgets(char *s, int size, FILE * stream)
{
	fgets(s, size, stream);
	if (ferror(stream)) {
		my_perror(errno, "error: %s: %s\n", __FUNCTION__, "fgets");
		return -errno;
	}
	if (feof(stream))
		return 0;
	return strlen(s);
}

// ----------------------------------------------------------------------------
ssize_t my_fputs(const char *s, FILE * stream)
{
	fputs(s, stream);
	if (ferror(stream)) {
		my_perror(errno, "error: %s: %s\n", __FUNCTION__, "fputs");
		return -errno;
	}
	return strlen(s);
}

// ----------------------------------------------------------------------------
off_t my_stat(const char *pathname)
{
	struct stat sb;						// file system status
	if (lstat(pathname, &sb)) {
		my_perror(errno, "error: %s: %s: %s\n", __FUNCTION__, "stat", pathname);
		return -1;
	}
	return sb.st_size;
}

// ----------------------------------------------------------------------------
int my_open(const char *pathname, int flags, mode_t mode)
{
	int fd;
	if ((fd = open(pathname, flags, mode)) < 0)
		my_perror(errno, "error: %s: %s: %s\n", __FUNCTION__, "open", pathname);
	return fd;
}

// ----------------------------------------------------------------------------
int my_close(int fd)
{
	int res;
	if ((res = close(fd)) < 0)
		my_perror(errno, "error: %s: %s\n", __FUNCTION__, "close");
	return res;
}

// ----------------------------------------------------------------------------
off_t my_lseek(int fd, off_t offset, int whence)
{
	off_t res;
	if ((res = lseek(fd, offset, whence)) < 0)
		my_perror(errno, "error: %s: %s\n", __FUNCTION__, "lseek");
	return res;
}

// ----------------------------------------------------------------------------
ssize_t my_read(int fd, void *buf, size_t count)
{
	ssize_t res;
	if ((res = read(fd, buf, count)) < 0)
		my_perror(errno, "error: %s: %s\n", __FUNCTION__, "read");
	return res;
}

// ----------------------------------------------------------------------------
ssize_t my_write(int fd, const void *buf, size_t count)
{
	ssize_t res;
	if ((res = write(fd, buf, count)) < 0)
		my_perror(errno, "error: %s: %s\n", __FUNCTION__, "write");
	return res;
}

// ----------------------------------------------------------------------------
ssize_t my_pread(int fd, void *buf, size_t count, off_t offset)
{
	ssize_t res;
	if ((res = pread(fd, buf, count, offset)) < 0)
		my_perror(errno, "error: %s: %s\n", __FUNCTION__, "pread");
	return res;
}

// ----------------------------------------------------------------------------
ssize_t my_pwrite(int fd, const void *buf, size_t count, off_t offset)
{
	ssize_t res;
	if ((res = pwrite(fd, buf, count, offset)) < 0)
		my_perror(errno, "error: %s: %s\n", __FUNCTION__, "pwrite");
	return res;
}

// ----------------------------------------------------------------------------
int my_ioctl(int fd, unsigned long request, char *argp)
{
	int res;
	if ((res = ioctl(fd, request, argp)) < 0)
		my_perror(errno, "error: %s: %s\n", __FUNCTION__, "ioctl");
	return res;
}

// ----------------------------------------------------------------------------
