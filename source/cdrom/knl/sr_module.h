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
#include <linux/kobject.h>				// kobject_del, ...
#include <linux/module.h>				// module_init,module_exit, ...
#include <linux/platform_device.h>		// struct platform_driver, ...
#include <linux/version.h>				// LINUX_VERSION_CODE, ...
#include <scsi/scsi.h>					// 
#include <scsi/scsi_cmnd.h>				// struct block_device_operations
#include <scsi/scsi_driver.h>			// struct scsi_driver
#include <scsi/scsi_eh.h>				// scsi_block_when_processing_errors, ...
#include <scsi/scsi_ioctl.h>			// scsi_ioctl, ...
#include <scsi/sg.h>					// SG command

// ::: global :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#define SR_VENDOR			"NECcdemu"
#define SR_PRODUCT			"CD-emu IDE CDR10"
#define SR_REVISION			"1.00"
#define SR_TIMEOUT			(30 * HZ)
#define SR_MAX_RETRIES		3
#define SR_HARD_SECTOR		2048
#define SR_DISKS			256
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
#define SR_MASK				( CDC_CLOSE_TRAY     \
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

#define VENDOR_SCSI3		1			// default: scsi-3 mmc
#define VENDOR_NEC			2
#define VENDOR_TOSHIBA		3
#define VENDOR_WRITER		4			// pre-scsi3 writers

#ifndef BLK_STS_OK
#define BLK_STS_OK			0
#endif

#ifndef BLK_STS_IOERR
#define BLK_STS_IOERR		-EIO
#endif

// ============================================================================
struct scsi_cd {
//	struct scsi_driver *driver;
//	unsigned capacity;					// size in blocks
//	struct scsi_device *device;
	unsigned int vendor;				// vendor code, see sr_vendor.c
//	unsigned long ms_offset;			// for reading multisession-CD's
//	unsigned writeable:1;
//	unsigned use:1;						// is this device still supportable
//	unsigned xa_flag:1;					// CD has XA sectors ?
//	unsigned readcd_known:1;			// drive supports READ_CD (0xbe)
//	unsigned readcd_cdda:1;				// reading audio data using READ_CD
//	unsigned media_present:1;			// media is present

	// GET_EVENT spurious event handling, blk layer guarantees exclusion
//	int tur_mismatch;					// nr of get_event TUR mismatches
//	bool tur_changed:1;					// changed according to TUR
//	bool get_event_changed:1;			// changed according to GET_EVENT
//	bool ignore_get_event:1;			// GET_EVENT is unreliable, use TUR

	struct cdrom_device_info cdi;
	// We hold gendisk and scsi_device references on probe and use the refs on this kref to decide when to release them
//	struct kref kref;
	struct gendisk *disk;
};

// ::: do command :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
extern int sr_do_load_media(struct my_toc *toc, const unsigned long arg);
extern int sr_do_read_media(const struct my_toc *toc, loff_t lba, unsigned char *bufp, loff_t len);
extern int sr_do_read_tochdr(const struct my_toc *toc, const unsigned char *cmdp, unsigned char *bufp);
extern int sr_do_read_tocentry(const struct my_toc *toc, const unsigned char *cmdp, unsigned char *bufp);
extern int sr_do_read_track_tocentry(const struct my_toc *toc, int trk, struct cdrom_tocentry *tentry);
extern int sr_do_gpcmd(struct my_toc *toc, struct scsi_cd *cd, struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg);

// ============================================================================
#endif							// MODULE

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#endif							// __SR_MODULE_H__

// *** EOF ********************************************************************
