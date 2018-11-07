// ****************************************************************************
// SCSI cdrom (sr) device driver
// ****************************************************************************

#ifndef __SR_MODULE_H__
#define __SR_MODULE_H__

// ::: include ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#include "../lib/my_library.h"			// my library's header
#include "../lib/my_cdrom.h"			// my cdrom's header

// ::: global :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#define SR_LOAD_MEDIA		0x53ff
#define SR_AUTHOR			"Jun Itou"
#define SR_DEV_NAME			"sremu"
#define SR_DESCRIPTION		"SCSI cdrom ("SR_DEV_NAME") device driver"

// ****************************************************************************
#ifdef MODULE

// ::: include ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#include <linux/file.h>					// fput
#include <linux/module.h>				// module_init,module_exit, ...
#include <linux/platform_device.h>		// struct platform_driver, ...
#include <linux/version.h>				// LINUX_VERSION_CODE, ...
#include <scsi/scsi_cmnd.h>				// struct block_device_operations
#include <scsi/sg.h>					// SG command

// ::: global :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#define SR_VENDOR			"NECcdemu"
#define SR_PRODUCT			"CD-emu IDE CDR10"
#define SR_REVISION			"1.00"
#define SR_TIMEOUT			(30 * HZ)
#define SR_HARD_SECTOR		2048
#define SR_CAPABILITIES		( CDC_CLOSE_TRAY     \
							| CDC_OPEN_TRAY      \
							| CDC_LOCK           \
							| CDC_SELECT_SPEED   \
							| CDC_SELECT_DISC    \
							| CDC_MULTI_SESSION  \
							| CDC_MCN            \
							| CDC_MEDIA_CHANGED  \
							| CDC_PLAY_AUDIO     \
							| CDC_RESET          \
							| CDC_DRIVE_STATUS   \
							| CDC_GENERIC_PACKET \
							| CDC_CD_R           \
							| CDC_CD_RW          \
							| CDC_DVD            \
							| CDC_DVD_R          \
							| CDC_DVD_RAM        \
							| CDC_MO_DRIVE       \
							| CDC_MRW            \
							| CDC_MRW_W          \
							| CDC_RAM )

#ifndef BLK_STS_OK
#define BLK_STS_OK			0
#endif

#ifndef BLK_STS_IOERR
#define BLK_STS_IOERR		-EIO
#endif

// ============================================================================
struct sr_unit {
	struct cdrom_device_info *cdi;
	struct gendisk *disk;
	struct request_queue *rq;
	struct my_toc *toc;
};

// ::: do command :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
int sr_do_load_media(struct sr_unit *sr, const unsigned char *bufp);
int sr_do_read_media(const struct sr_unit *sr, unsigned long lba, unsigned char *bufp, unsigned long blk, unsigned long len);
int sr_do_read_tochdr(const struct sr_unit *sr, const unsigned char *cmdp, unsigned char *bufp);
int sr_do_read_tocentry(const struct sr_unit *sr, const unsigned char *cmdp, unsigned char *bufp);
int sr_do_read_track_tocentry(const struct sr_unit *sr, int trk, struct cdrom_tocentry *tentry);
int sr_do_gpcmd(struct sr_unit *sr, void __user * argp);

// ============================================================================
#endif							// MODULE

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#endif							// __SR_MODULE_H__

// *** EOF ********************************************************************
