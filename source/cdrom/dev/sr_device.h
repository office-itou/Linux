// ****************************************************************************
// SCSI cdrom (sr) device driver
// ****************************************************************************

#ifndef __SR_DEVICE_H__
#define __SR_DEVICE_H__

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#include "../lib/my_library.h"			// my library's header
#include "../lib/my_cdrom.h"			// my cdrom's header

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#define AUTHOR				"Jun Itou"
#define DEVICE_NAME			"srdev"
#define DESCRIPTION			"SCSI cdrom ("DEVICE_NAME") device driver"
enum {									// IOCTL commands
	SR_NO_COMMAND = 0,
	SR_LOAD_MEDIA,
};

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#ifdef MODULE

// ============================================================================
#include <linux/file.h> 				// fput
#include <linux/module.h>				// module_init,module_exit, ...
#include <linux/platform_device.h>		// struct platform_driver, ...
#include <linux/version.h>				// LINUX_VERSION_CODE, ...
#include <scsi/scsi_cmnd.h> 			// struct block_device_operations
#include <scsi/sg.h>					// SG command

// ============================================================================
#define VENDOR				"NECcdemu"
#define PRODUCT				"CD-emu IDE CDR10"
#define REVISION			"1.00"
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

// ============================================================================
struct scsi_cd {
	struct cdrom_device_info cdi;
	struct gendisk *disk;
	struct request_queue *rq;
	struct my_toc toc;
};

// === do command =============================================================
extern int sr_do_load_media(struct scsi_cd *cd, const unsigned char *bufp);
extern int sr_do_read_media(const struct scsi_cd *cd, unsigned long lba, unsigned char *bufp, unsigned long blk, unsigned long len);
extern int sr_do_read_tochdr(const struct scsi_cd *cd, const unsigned char *cmdp, unsigned char *bufp);
extern int sr_do_read_tocentry(const struct scsi_cd *cd, const unsigned char *cmdp, unsigned char *bufp);
extern int sr_do_read_track_tocentry(const struct scsi_cd *cd, int trk, struct cdrom_tocentry *tentry);
extern int sr_do_gpcmd(struct scsi_cd *cd, void __user * argp);

// ============================================================================
#endif							// MODULE

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#endif							// __SR_DEVICE_H__

// *** EOF ********************************************************************
