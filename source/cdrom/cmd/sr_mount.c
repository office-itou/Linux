// ****************************************************************************
// SCSI cdrom (sr) device driver
// ****************************************************************************

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#define NDEBUG

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#include <stdio.h>						// fprintf,perror
#include <string.h>						// memset,strncpy,strlen,strchr,strstr
#include <fcntl.h>						// For O_* constants
#include <sys/stat.h>					// For mode constants
#include "my_library.h"					// my library's header
#include "my_cdrom.h"					// my cdrom's header
#include "sr_module.h"					// SCSI cdrom (sr) device driver's header

// ::: sr_mount.c :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
int main(int argc, char *argv[])
{
	int err = 0, ret;
	struct my_toc toc;
	char *dev_name;
	int fd;

	if (argc != 3) {
		fprintf(stderr, "usage: %s [cue file name] [special device name]\n", argv[0]);
		return 1;
	}

	strncpy(toc.path_cue, argv[1], sizeof(toc.path_cue));
	dev_name = argv[2];

	if ((err = my_read_toc(&toc)) < 0)
		return err;

	if ((fd = my_open(dev_name, O_RDWR | O_NONBLOCK, 0)) < 0)
		return fd;

	if ((ret = my_ioctl(fd, SR_LOAD_MEDIA, &toc)) < 0)
		err = ret;

	if ((ret = my_close(fd)) < 0)
		err = ret;

	return err;
}

// *** EOF ********************************************************************
