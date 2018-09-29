// ----------------------------------------------------------------------------
#include "my_common.h"
#include <stdarg.h>						// va_start,va_end
#include <iconv.h>						// iconv_t,iconv
// ----------------------------------------------------------------------------
int my_perror(int errnum, const char *format, ...)
{
	va_list ap;
	char buf[BUFF_MAX];
	char str[BUFF_MAX];

	if (strerror_r(errnum, buf, sizeof(buf))) {
		snprintf(buf, sizeof(buf), "Unknown error %d\n", errnum);
	}
	va_start(ap, format);
	vsnprintf(str, sizeof(str), format, ap);
	va_end(ap);
	pr_err("%s: %s", buf, str);
	errno = errnum;
	return errnum;
}

// ----------------------------------------------------------------------------
void my_rm_crlf(char *s)
{
	char *p;							// returns a pointer CR or LF

	while ((p = strchr(s, '\r')) || (p = strchr(s, '\n')))
		*p = '\0';
}

// ----------------------------------------------------------------------------
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
	if ((conv = iconv_open("UTF-8", "SHIFT-JIS")) == (iconv_t) - 1) {
		my_perror(errno, "error: %s: %s\n", __FUNCTION__, "iconv open");
		return -errno;
	}
	if (iconv(conv, &src_buf, &src_len, &dst_buf, &dst_len) == (size_t) - 1) {
		my_perror(errno, "error: %s: %s\n", __FUNCTION__, "iconv");
		ret = -errno;
	}
	*dst_buf = '\0';
	if (iconv_close(conv) == -1) {
		my_perror(errno, "error: %s: %s\n", __FUNCTION__, "iconv_close");
		ret = -errno;
	}
	return ret;
}

// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
