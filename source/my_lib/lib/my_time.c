// ----------------------------------------------------------------------------
#include "my_common.h"
#include <time.h>						// clock_gettime,ctime_r
// ----------------------------------------------------------------------------
int64_t my_get_current_time(void)
{
	uint64_t now;
	struct timespec tp;

//  pr_devel("enter: %s\n", __FUNCTION__);
	// ------------------------------------------------------------------------
	if (clock_gettime(CLOCK_REALTIME, &tp) < 0)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "clock_gettime");
	now = (((int64_t) tp.tv_sec) * (int64_t) 1000000000) + (int64_t) tp.tv_nsec;
	// ------------------------------------------------------------------------
	return now;
}

// ----------------------------------------------------------------------------
int my_get_time_string(int64_t time, char *buf)
{
	time_t timep;

	timep = (time_t) (time / 1000000000LL);
	if (ctime_r(&timep, buf) == NULL)
		return -my_perror(errno, "error: %s: %s\n", __FUNCTION__, "ctime_r");
	my_rm_crlf(buf);
	return 0;
}

// ----------------------------------------------------------------------------
