// ----------------------------------------------------------------------------
#include "my_common.h"
#include <sys/stat.h>					// struct stat,stat
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
	if (stat(pathname, &sb)) {
		my_perror(errno, "error: %s: %s: %s\n", __FUNCTION__, "stat", pathname);
		return -1;
	}
	return sb.st_size;
}

// ----------------------------------------------------------------------------
