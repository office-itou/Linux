// ****************************************************************************
// my cdrom
// ****************************************************************************

#ifndef __MY_CDROM_H__
#define __MY_CDROM_H__

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#include <linux/cdrom.h>				// struct my_toc,struct cdemu_unit, ...
#include <scsi/scsi.h>					// SCSI commands, ...
#include <scsi/sg.h>					// SG commands, ...
#include "my_library.h"					// my library's header

// ============================================================================
#define TRACK_MAX			99
struct my_toc {
	int initial;						// initial flag
	int mchange;						// media change flag
	char path_cue[PATH_MAX];			// cue file name
	char path_bin[PATH_MAX];			// bin file name
	long leadout;						// last frame number (set track = CDROM_LEADOUT)
	struct cdrom_tochdr tochdr;
	struct cdrom_tocentry tocentry[TRACK_MAX];
};

struct my_msg_list {
	unsigned id;
	char *msg;
};

#ifndef SG_GET_ACCESS_COUNT
#define SG_GET_ACCESS_COUNT	0x2289
#endif

#ifndef SCSI_IOCTL_GET_PCI
#define SCSI_IOCTL_GET_PCI	0x5387
#endif

// ::: my_cdrom.c :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
extern void my_lba2msf(int lba, int *m, int *s, int *f, int o);
extern int my_msf2lba(int m, int s, int f);

#ifndef MODULE
extern int my_msf2frame(const char *msf, int *m, int *s, int *f);
extern int my_read_toc(struct my_toc *toc);
#endif							// MODULE

extern char *my_msg_ioctl_cmd(unsigned id);
extern char *my_msg_packet_cmd(unsigned id);

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#endif							// __MY_CDROM_H__

// *** EOF ********************************************************************
