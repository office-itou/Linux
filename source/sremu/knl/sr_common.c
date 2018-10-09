// ****************************************************************************
// SCSI cdrom (sr) emulation driver
// ****************************************************************************

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#define DEBUG

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#include <linux/cdrom.h>				// struct cdrom_device_ops, ...
#include "sr_emu.h"						// SCSI cdrom (sr) emulation driver's header

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
void sr_lba2msf(int lba, int *m, int *s, int *f)
{
//  lba += CD_MSF_OFFSET;
	lba &= 0xffffff;					// negative lbas use only 24 bits
	*m = lba / (CD_SECS * CD_FRAMES);
	lba %= (CD_SECS * CD_FRAMES);
	*s = lba / CD_FRAMES;
	*f = lba % CD_FRAMES;
}

// ============================================================================
int sr_msf2lba(int m, int s, int f)
{
	return (((m * CD_SECS) + s) * CD_FRAMES + f);
}

// *** EOF ********************************************************************
