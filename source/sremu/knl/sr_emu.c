// ****************************************************************************
// SCSI cdrom (sr) emulation driver
// ****************************************************************************

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#define DEBUG

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#include <linux/module.h>				// module_init,module_exit, ...
#include <linux/cdrom.h>				// struct cdrom_device_ops, ...
#include <linux/file.h>					// fput
#include <scsi/scsi_driver.h>			// scsi_register_driver, ...
#include <scsi/scsi_eh.h>				// scsi_block_when_processing_errors, ...
#include <scsi/sg.h>					// SG command
#include "sr_emu.h"						// SCSI cdrom (sr) emulation driver's header

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#define SR_HARD_SECTOR		CD_FRAMESIZE_RAW
#define SR_MINORS			1

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

#define MAX_RETRIES			3
#define SR_TIMEOUT			(30 * HZ)

#define IOCTL_RETRIES		3

#define VENDOR_TIMEOUT		(30 * HZ)
#define VENDOR_SCSI3		1			// default: scsi-3 mmc
#define VENDOR_NEC			2
#define VENDOR_TOSHIBA		3
#define VENDOR_WRITER		4			// pre-scsi3 writers

// ============================================================================
struct scsi_cd {
	struct cdrom_device_info *cdi;
	struct gendisk *disk;
	struct request_queue *rq;
	struct sr_toc *toc;
};

// ============================================================================
static struct scsi_cd cd;
static int sr_major = 0;
static int sr_minor = 0;

static DEFINE_MUTEX(sr_mutex);
static DEFINE_SPINLOCK(sr_lock);
static LIST_HEAD(sr_deferred);

#define SR_VERSION_STR "1.00.00"
static int sr_version_num = 100000;

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
// 0x12
static int sr_gpcmd_inquiry(const struct scsi_cd *cd, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	bufp[0x00] = 0x05;					//  0: C/DVD Logical Unit (ROM, R, RW, RAM and +RW types)
	bufp[0x01] = 0x80;					//  1: RMB
	bufp[0x02] = 0x05;					//  2: ANSI Version
	bufp[0x03] = 0x32;					//  3:
	bufp[0x04] = 0x1f;					//  4: Additional Length
	bufp[0x05] = 0x00;					//  5:
	bufp[0x06] = 0x00;					//  6:
	bufp[0x07] = 0x00;					//  7:
	bufp[0x08] = 'N';					//  8: Vendor Identification (8bytes)
	bufp[0x09] = 'E';					//  9:
	bufp[0x0a] = 'C';					// 10:
	bufp[0x0b] = 'c';					// 11:
	bufp[0x0c] = 'd';					// 12:
	bufp[0x0d] = 'e';					// 13:
	bufp[0x0e] = 'm';					// 14:
	bufp[0x0f] = 'u';					// 15:
	bufp[0x10] = 'C';					// 16: Product Identification (16bytes)
	bufp[0x11] = 'D';					// 17:
	bufp[0x12] = '-';					// 18:
	bufp[0x13] = 'E';					// 19:
	bufp[0x14] = 'm';					// 20:
	bufp[0x15] = 'u';					// 21:
	bufp[0x16] = ' ';					// 22:
	bufp[0x17] = 'I';					// 23:
	bufp[0x18] = 'D';					// 24:
	bufp[0x19] = 'E';					// 25:
	bufp[0x1a] = ' ';					// 26:
	bufp[0x1b] = 'C';					// 27:
	bufp[0x1c] = 'D';					// 28:
	bufp[0x1d] = 'R';					// 29:
	bufp[0x1e] = '1';					// 30:
	bufp[0x1f] = '0';					// 31:
	bufp[0x20] = '1';					// 32: Product Revision Level (4bytes)
	bufp[0x21] = '.';					// 33:
	bufp[0x22] = '0';					// 34:
	bufp[0x23] = '0';					// 35:

	return 0;
}

// ============================================================================
// 0x28
static int sr_gpcmd_read_10(const struct scsi_cd *cd, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	return 0;
}

// ============================================================================
// 0x42
static int sr_gpcmd_read_subchannel(const struct scsi_cd *cd, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	return 0;
}

// ============================================================================
// 0x43: READ TOC,READ TOC/PMA/ATIP
static int sr_gpcmd_read_toc_pma_atip(const struct scsi_cd *cd, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	struct sr_toc *toc = cd->toc;
	struct cdrom_tochdr *thdr = &toc->tochdr;
	struct cdrom_tocentry *tent = toc->tocentry;
	int i, n, o, len, trk, lba, lba0, lba1, m, s, f;

	if (!cd->toc->initial)
		return -ENOMEDIUM;

	switch (cmdp[2] & 0x0f) {			// Format
	case 0x00:							// TOC
		len = 3 + 8 * thdr->cdth_trk1 + 7;
		bufp[0x00] = len >> 8;			//  0: TOC Data Length
		bufp[0x01] = len;				//  1: 
		bufp[0x02] = thdr->cdth_trk0;	//  2: 
		bufp[0x03] = thdr->cdth_trk1;	//  3: 
		bufp[0x04] = 0x00;				//  4: 

		for (i = thdr->cdth_trk0, n = 0, o = 0; i <= thdr->cdth_trk1 && n <= TRACK_MAX; i++, n++, o += 8, tent++) {
			trk = tent->cdte_track;
			if (tent->cdte_format == CDROM_MSF)
				lba = sr_msf2lba(tent->cdte_addr.msf.minute, tent->cdte_addr.msf.second, tent->cdte_addr.msf.frame);
			else
				lba = tent->cdte_addr.lba;
			bufp[0x05 + o] = 0x10;		//  0: 
			bufp[0x06 + o] = trk;		//  1: 
			bufp[0x07 + o] = 0x00;		//  2: 
			bufp[0x08 + o] = lba >> 24;	//  3: 
			bufp[0x09 + o] = lba >> 16;	//  4: 
			bufp[0x0a + o] = lba >> 8;	//  5: 
			bufp[0x0b + o] = lba;		//  6: 
			bufp[0x0c + o] = 0x00;		//  7: 
		}

		lba = toc->leadout;
		bufp[0x05 + o] = 0x10;			//  0
		bufp[0x06 + o] = 0xaa;			//  1
		bufp[0x07 + o] = 0x00;			//  2
		bufp[0x08 + o] = lba >> 24;		//  3
		bufp[0x09 + o] = lba >> 16;		//  4
		bufp[0x0a + o] = lba >> 8;		//  5
		bufp[0x0b + o] = lba;			//  6
		break;
	case 0x01:							// Session Information
		len = 0x0a;
		bufp[0x00] = len >> 8;			//  0: TOC Data Length
		bufp[0x01] = len;				//  1: 
		bufp[0x02] = 0x01;				//  2: 
		bufp[0x03] = 0x01;				//  3: 
		bufp[0x04] = 0x00;				//  4: 
		bufp[0x05] = 0x10;				//  5: 
		bufp[0x06] = 0x01;				//  6: 
		bufp[0x07] = 0x00;				//  7: 
		bufp[0x08] = 0x00;				//  8: 
		bufp[0x09] = 0x00;				//  9: 
		bufp[0x0a] = 0x00;				// 10: 
		bufp[0x0b] = 0x00;				// 11: 
		break;
	case 0x02:							// Full TOC
		lba = toc->leadout + 75 * 2;
		sr_lba2msf(lba, &m, &s, &f);
		len = 2 + 11 * 3 + 11 * thdr->cdth_trk1;
		bufp[0x00] = len >> 8;			//  0: TOC Data Length
		bufp[0x01] = len;				//  1: 
		bufp[0x02] = 0x01;				//  2: 
		bufp[0x03] = 0x01;				//  3: 

		bufp[0x04] = 0x01;				//  0:
		bufp[0x05] = 0x10;				//  1:
		bufp[0x06] = 0x00;				//  2:
		bufp[0x07] = 0xa0;				//  3:
		bufp[0x08] = 0x00;				//  4:
		bufp[0x09] = 0x00;				//  5:
		bufp[0x0a] = 0x00;				//  6:
		bufp[0x0b] = 0x00;				//  7:
		bufp[0x0c] = thdr->cdth_trk0;	//  8:
		bufp[0x0d] = 0x00;				//  9:
		bufp[0x0e] = 0x00;				// 10:

		bufp[0x0f] = 0x01;				//  0:
		bufp[0x10] = 0x10;				//  1:
		bufp[0x11] = 0x00;				//  2:
		bufp[0x12] = 0xa1;				//  3:
		bufp[0x13] = 0x00;				//  4:
		bufp[0x14] = 0x00;				//  5:
		bufp[0x15] = 0x00;				//  6:
		bufp[0x16] = 0x00;				//  7:
		bufp[0x17] = thdr->cdth_trk1;	//  8:
		bufp[0x18] = 0x00;				//  9:
		bufp[0x19] = 0x00;				// 10:

		bufp[0x1a] = 0x01;				//  0:
		bufp[0x1b] = 0x10;				//  1:
		bufp[0x1c] = 0x00;				//  2:
		bufp[0x1d] = 0xa2;				//  3:
		bufp[0x1e] = 0x00;				//  4:
		bufp[0x1f] = 0x00;				//  5:
		bufp[0x20] = 0x00;				//  6:
		bufp[0x21] = 0x00;				//  7:
		bufp[0x22] = m;					//  8:
		bufp[0x23] = s;					//  9:
		bufp[0x24] = f;					// 10:

		for (i = thdr->cdth_trk0, n = 0, o = 0; i <= thdr->cdth_trk1 && n <= TRACK_MAX; i++, n++, o += 11, tent++) {
			trk = tent->cdte_track;
			if (tent->cdte_format == CDROM_MSF)
				lba = sr_msf2lba(tent->cdte_addr.msf.minute, tent->cdte_addr.msf.second, tent->cdte_addr.msf.frame);
			else
				lba = tent->cdte_addr.lba;
			lba += 75 * 2;
			sr_lba2msf(lba, &m, &s, &f);
			bufp[0x25 + o] = 0x01;		//  0:
			bufp[0x26 + o] = 0x10;		//  1:
			bufp[0x27 + o] = 0x00;		//  2:
			bufp[0x28 + o] = trk;		//  3:
			bufp[0x29 + o] = 0x00;		//  4:
			bufp[0x2a + o] = 0x00;		//  5:
			bufp[0x2b + o] = 0x00;		//  6:
			bufp[0x2c + o] = 0x00;		//  7:
			bufp[0x2d + o] = m;			//  8:
			bufp[0x2e + o] = s;			//  9:
			bufp[0x2f + o] = f;			// 10:
		}
		bufp[0x25 + o] = 0x01;			//  0:
		break;
	case 0x03:							// PMA
		len = 2 + 11 * thdr->cdth_trk1 + 11;
		bufp[0x00] = len >> 8;			//  0: TOC Data Length
		bufp[0x01] = len;				//  1: 
		bufp[0x02] = 0x00;				//  2: 
		bufp[0x03] = 0x00;				//  3: 

		lba0 = 0;
		for (i = thdr->cdth_trk0, n = 0, o = 0; i <= thdr->cdth_trk1 && n <= TRACK_MAX; i++, n++, o += 11, tent++) {
			trk = tent->cdte_track;
			if (tent->cdte_format == CDROM_MSF)
				lba1 = sr_msf2lba(tent->cdte_addr.msf.minute, tent->cdte_addr.msf.second, tent->cdte_addr.msf.frame);
			else
				lba1 = tent->cdte_addr.lba;
			lba1 += 75 * 2;
			bufp[0x04 + o] = 0x00;		//  0: 
			bufp[0x05 + o] = 0x10;		//  1: 
			bufp[0x06 + o] = 0x00;		//  2: 
			bufp[0x07 + o] = trk;		//  3: 

			sr_lba2msf(lba1, &m, &s, &f);
			bufp[0x08 + o] = m;			//  4: 
			bufp[0x09 + o] = s;			//  5: 
			bufp[0x0a + o] = f;			//  6: 

			bufp[0x0b + o] = 0x00;		//  7: 

			sr_lba2msf(lba1 - lba0, &m, &s, &f);
			bufp[0x0c + o] = m;			//  8: 
			bufp[0x0d + o] = s;			//  9: 
			bufp[0x0e + o] = f;			// 10: 

			lba0 = lba1;
		}

		bufp[0x04 + o] = 0x00;			//  0: 
		bufp[0x05 + o] = 0x20;			//  1: 
		bufp[0x06 + o] = 0x00;			//  2: 
		bufp[0x07 + o] = 0x00;			//  3: 
		bufp[0x08 + o] = 0x00;			//  4: 
		bufp[0x09 + o] = 0x00;			//  5: 
		bufp[0x0a + o] = 0x00;			//  6: 
		bufp[0x0b + o] = 0x00;			//  7: 
		bufp[0x0c + o] = 0x00;			//  8: 
		bufp[0x0d + o] = 0x00;			//  9: 
		bufp[0x0e + o] = 0x00;			// 10: 
		break;
	case 0x04:							// ATIP
		len = 0x1a;
		bufp[0x00] = len >> 8;			//  0: TOC Data Length
		bufp[0x01] = len;				//  1: 
		bufp[0x02] = 0x00;				//  2: 
		bufp[0x03] = 0x00;				//  3: 
		bufp[0x04] = 0x00;				//  4: 
		bufp[0x05] = 0x00;				//  5: 
		bufp[0x06] = 0x00;				//  6: 
		bufp[0x07] = 0x00;				//  7: 
		bufp[0x08] = 0x00;				//  8: 
		bufp[0x09] = 0x00;				//  9: 
		bufp[0x0a] = 0x00;				// 10: 
		bufp[0x0b] = 0x00;				// 11: 
		bufp[0x0c] = 0x00;				// 12: 
		bufp[0x0d] = 0x00;				// 13: 
		bufp[0x0e] = 0x00;				// 14: 
		bufp[0x0f] = 0x00;				// 15: 
		bufp[0x10] = 0x00;				// 16: 
		bufp[0x11] = 0x00;				// 17: 
		bufp[0x12] = 0x00;				// 18: 
		bufp[0x13] = 0x00;				// 19: 
		bufp[0x14] = 0x00;				// 20: 
		bufp[0x15] = 0x00;				// 21: 
		bufp[0x16] = 0x00;				// 22: 
		bufp[0x17] = 0x00;				// 23: 
		bufp[0x18] = 0x00;				// 24: 
		bufp[0x19] = 0x00;				// 25: 
		break;
	case 0x05:							// CD-Text
		len = 0x02;
		bufp[0x00] = len >> 8;			//  0: TOC Data Length
		bufp[0x01] = len;				//  1: 
		bufp[0x02] = 0x00;				//  2: 
		bufp[0x03] = 0x00;				//  3: 
		break;
	}

	return 0;
}

// ============================================================================
// 0x45: PLAY AUDIO
static int sr_gpcmd_play_audio_10(const struct scsi_cd *cd, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	if (!cd->toc->initial)
		return -ENOMEDIUM;

	return 0;
}

// ============================================================================
// 0x51: READ DISK INFORMATION
static int sr_gpcmd_read_disc_info(const struct scsi_cd *cd, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	struct sr_toc *toc = cd->toc;
	struct cdrom_tochdr *thdr = &toc->tochdr;

	if (!cd->toc->initial)
		return -ENOMEDIUM;

	bufp[0x00] = 0x00;					//  0: Disc Information length 
	bufp[0x01] = 0x20;					//  1: 
	bufp[0x02] = 0x1e;					//  2: Erasable Status of Last, Session/Border, Disc Status
	bufp[0x03] = thdr->cdth_trk0;		//  3: Number of First Track/RZone on Disc
	bufp[0x04] = 0x01;					//  4: Number of Sessions/Borders (LSB)
	bufp[0x05] = thdr->cdth_trk0;		//  5: First Track/RZone Number in Last Session/Border (LSB)
	bufp[0x06] = thdr->cdth_trk1;		//  6: Last Track/RZone Number in Last Session/Border (LSB)
	bufp[0x07] = 0x80;					//  7: DID_V, DBC_V, URU
	bufp[0x08] = 0x00;					//  8: Disc Type
	bufp[0x09] = 0x00;					//  9: Number of Sessions/Borders (MSB)
	bufp[0x0a] = 0x00;					// 10: First Track/RZone Number in Last Session/Border (MSB)
	bufp[0x0b] = 0x00;					// 11: Last Track/RZone Number in Last Session/Border (MSB)
	bufp[0x0c] = 0x00;					// 12: Disc Identification
	bufp[0x0d] = 0x00;					// 13: 
	bufp[0x0e] = 0x00;					// 14: 
	bufp[0x0f] = 0x00;					// 15: 
	bufp[0x10] = 0xff;					// 16: Lead-in Start Time of Last Sessiona MSF
	bufp[0x11] = 0xff;					// 17: 
	bufp[0x12] = 0xff;					// 18: 
	bufp[0x13] = 0xff;					// 19: 
	bufp[0x14] = 0xff;					// 20: Last Possible Start Time for Start of Lead-outa MSF
	bufp[0x15] = 0xff;					// 21: 
	bufp[0x16] = 0xff;					// 22: 
	bufp[0x17] = 0xff;					// 23: 
	bufp[0x18] = 0x00;					// 24: Disc Bar Code
	bufp[0x19] = 0x00;					// 25: 
	bufp[0x1a] = 0x00;					// 26: 
	bufp[0x1b] = 0x00;					// 27: 
	bufp[0x1c] = 0x00;					// 28: 
	bufp[0x1d] = 0x00;					// 29: 
	bufp[0x1e] = 0x00;					// 30: 
	bufp[0x1f] = 0x00;					// 31: 
	bufp[0x20] = 0x00;					// 32: Reserved
	bufp[0x21] = 0x00;					// 33: Number of OPC Table Entries

	return 0;
}

// ============================================================================
// 0x5a
static int sr_gpcmd_mode_sense_10(const struct scsi_cd *cd, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	bufp[0x00] = 0x00;					//  0: Mode Data Length 1
	bufp[0x01] = 0x2e;					//  1:
	bufp[0x02] = 0x00;					//  2: Obsolete (Medium Type Code)
	bufp[0x03] = 0x00;					//  3: Reserved
	bufp[0x04] = 0x00;					//  4: Reserved
	bufp[0x05] = 0x00;					//  5: Reserved
	bufp[0x06] = 0x00;					//  6: Block Descriptor Length 0 (8 for legacy SCSI Logical Units)
	bufp[0x07] = 0x00;					//  7:
	switch (cmdp[2] & 0x3f) {			// Mode Page Codes
	case 0x00:							// 00h Vendor-specific
		break;
	case 0x01:							// 01h Read/Write Error Recovery Parameters
		break;
	case 0x05:							// 05h Write Parameters
		break;
	case 0x0e:							// 0Eh CD Audio Control
		break;
	case 0x1a:							// 1Ah Power Condition
		break;
	case 0x1c:							// 1Ch Fault / Failure Reporting
		break;
	case 0x1d:							// 1Dh Time-out & Protect
		break;
	case 0x20:							// 20h - 29h, Vendor-specific
		break;
	case 0x21:
	case 0x22:
	case 0x23:
	case 0x24:
	case 0x25:
	case 0x26:
	case 0x27:
	case 0x28:
	case 0x29:
		break;
	case 0x2a:							// 0x2Ah C/DVD Capabilities & Mechanical Status
		bufp[0x08] = 0x2a;				//  8:  0: Page Code (2Ah)
		bufp[0x09] = 0x18;				//  9:  1: Page Length (18h)
		bufp[0x0a] = 0x3f;				// 10:  2: Read media
		bufp[0x0b] = 0x3f;				// 11:  3: Write media
		bufp[0x0c] = 0x71;				// 12:  4: Media Function Capabilities
		bufp[0x0d] = 0xef;				// 13:  5:
		bufp[0x0e] = 0x2b;				// 14:  6:
		bufp[0x0f] = 0x3f;				// 15:  7:
		bufp[0x10] = 0x00;				// 16:  8: Obsolete
		bufp[0x11] = 0x00;				// 17:  9:
		bufp[0x12] = 0x00;				// 18: 10: Number of Volume Levels Supported
		bufp[0x13] = 0x00;				// 19: 11:
		bufp[0x14] = 0x00;				// 20: 12: Buffer Size supported by Logical Unit (in KBytes)
		bufp[0x15] = 0x00;				// 21: 13:
		bufp[0x16] = 0x00;				// 22: 14: Obsolete
		bufp[0x17] = 0x00;				// 23: 15:
		bufp[0x18] = 0x00;				// 24: 16: Obsolete
		bufp[0x19] = 0xc2;				// 25: 17: Digital Output Format
		bufp[0x1a] = 0x00;				// 26: 18: Obsolete
		bufp[0x1b] = 0x00;				// 27: 19:
		bufp[0x1c] = 0x00;				// 28: 20: Obsolete
		bufp[0x1d] = 0x00;				// 29: 21:
		bufp[0x1e] = 0x00;				// 30: 22: Copy Management Revision Supported
		bufp[0x1f] = 0x00;				// 31: 23:
		bufp[0x20] = 0x00;				// 32: 24: Reserved
		bufp[0x21] = 0x00;				// 33: 25: Reserved
		break;
	case 0x2b:							// 2Bh - 3Eh Vendor-specific
	case 0x2c:
	case 0x2d:
	case 0x2e:
	case 0x2f:
	case 0x30:
	case 0x31:
	case 0x32:
	case 0x33:
	case 0x34:
	case 0x35:
	case 0x36:
	case 0x37:
	case 0x38:
	case 0x39:
	case 0x3a:
	case 0x3b:
	case 0x3c:
	case 0x3d:
	case 0x3e:
		break;
	case 0x3f:							// 3Fh Return all Pages
		break;
	}

	return 0;
}

// ============================================================================
// 0xa8: Read 12
static int sr_gpcmd_read_12(const struct scsi_cd *cd, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	if (!cd->toc->initial)
		return -ENOMEDIUM;

	return 0;
}

// ============================================================================
// 0xb9: Read CD MSF
static int sr_gpcmd_read_cd_msf(const struct scsi_cd *cd, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	if (!cd->toc->initial)
		return -ENOMEDIUM;

	return 0;
}

// ============================================================================
// 0xbe: READ CD
static int sr_gpcmd_read_cd(const struct scsi_cd *cd, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int ret = 0, res;
	struct sr_toc *toc = cd->toc;
	struct file *file;
	unsigned long lba, len;

	if (!cd->toc->initial)
		return -ENOMEDIUM;

	lba = ((unsigned long) cmdp[2] << 24) + ((unsigned long) cmdp[3] << 16) + ((unsigned long) cmdp[4] << 8) + ((unsigned long) cmdp[5]);
	len = ((unsigned long) cmdp[6] << 16) + ((unsigned long) cmdp[7] << 8) + ((unsigned long) cmdp[8]);

	file = filp_open(toc->path_bin, O_RDONLY | O_LARGEFILE, 0);
	if (IS_ERR(file))
		return PTR_ERR(file);

	res = kernel_read(file, lba, bufp, len);
	if (res < 0)
		ret = -EIO;

	fput(file);

	return ret;
}

// ============================================================================
static int sr_do_ioctl(struct scsi_cd *cd, struct sg_io_hdr *io_hdr)
{
	int ret = 0, i;
	unsigned char *cmdp, *bufp;
	ssize_t bsiz = 1024;
	char *b = "unknoun";

#if 0
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	pr_devel(DEVICE_NAME ": %s: interface_id   : %c\n", __FUNCTION__, io_hdr->interface_id);
	pr_devel(DEVICE_NAME ": %s: cmd_len        : %d\n", __FUNCTION__, io_hdr->cmd_len);
	pr_devel(DEVICE_NAME ": %s: cmdp           : %016lx\n", __FUNCTION__, (unsigned long) io_hdr->cmdp);
	pr_devel(DEVICE_NAME ": %s: timeout        : %d\n", __FUNCTION__, io_hdr->timeout);
	pr_devel(DEVICE_NAME ": %s: sbp            : %016lx\n", __FUNCTION__, (unsigned long) io_hdr->sbp);
	pr_devel(DEVICE_NAME ": %s: mx_sb_len      : %d\n", __FUNCTION__, io_hdr->mx_sb_len);
	pr_devel(DEVICE_NAME ": %s: flags          : %d\n", __FUNCTION__, io_hdr->flags);
	pr_devel(DEVICE_NAME ": %s: dxferp         : %016lx\n", __FUNCTION__, (unsigned long) io_hdr->dxferp);
	pr_devel(DEVICE_NAME ": %s: dxfer_len      : %d\n", __FUNCTION__, io_hdr->dxfer_len);
	pr_devel(DEVICE_NAME ": %s: dxfer_direction: %s\n", __FUNCTION__, io_hdr->dxfer_direction == SG_DXFER_TO_DEV ? "SG_DXFER_TO_DEV" : "SG_DXFER_FROM_DEV");
#endif

	if (io_hdr->interface_id != 'S')
		return -ENOSYS;

	cmdp = kzalloc(io_hdr->cmd_len, GFP_KERNEL);
	if (IS_ERR_OR_NULL(cmdp))
		return PTR_ERR(cmdp);

	if (bsiz < io_hdr->dxfer_len)
		bsiz = io_hdr->dxfer_len;
	bufp = kzalloc(bsiz, GFP_KERNEL);
	if (IS_ERR_OR_NULL(bufp)) {
		kfree(cmdp);
		return PTR_ERR(bufp);
	}

	if (copy_from_user(cmdp, io_hdr->cmdp, io_hdr->cmd_len)) {
		ret = -EFAULT;
		goto exit;
	}

	if (copy_from_user(bufp, io_hdr->dxferp, io_hdr->dxfer_len)) {
		ret = -EFAULT;
		goto exit;
	}

	switch (cmdp[0]) {
	case GPCMD_TEST_UNIT_READY:		// 0x00 -------------------------------
		break;
	case GPCMD_INQUIRY:				// 0x12 -------------------------------
		ret = sr_gpcmd_inquiry(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_10:				// 0x28: Read 10
		ret = sr_gpcmd_read_10(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_SUBCHANNEL:		// 0x42
		ret = sr_gpcmd_read_subchannel(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_TOC_PMA_ATIP:		// 0x43: READ TOC,READ TOC/PMA/ATIP ---
		ret = sr_gpcmd_read_toc_pma_atip(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_PLAY_AUDIO_10:			// 0x45: PLAY AUDIO
		ret = sr_gpcmd_play_audio_10(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_DISC_INFO:			// 0x51: READ DISK INFORMATION
		ret = sr_gpcmd_read_disc_info(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_MODE_SENSE_10:			// 0x5a
		ret = sr_gpcmd_mode_sense_10(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_12:				// 0xa8: Read 12
		ret = sr_gpcmd_read_12(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_CD_MSF:			// 0xb9: Read CD MSF
		ret = sr_gpcmd_read_cd_msf(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_CD:				// 0xbe: READ CD
		ret = sr_gpcmd_read_cd(cd, io_hdr, cmdp, bufp);
		break;
	default:
		for (i = 0; i < sizeof(packet_command_texts) / sizeof(packet_command_texts[0]); i++) {
			if (packet_command_texts[i].packet_command == cmdp[0]) {
				b = packet_command_texts[i].text;
				pr_devel(DEVICE_NAME ": %s: %02x: %s\n", __FUNCTION__, *cmdp, b);
				break;
			}
		}
		break;
	}

  exit:
	if (!ret && io_hdr->dxfer_len)
		if (copy_to_user(io_hdr->dxferp, bufp, io_hdr->dxfer_len))
			ret = -EFAULT;

	kfree(bufp);
	kfree(cmdp);

	return ret;
}

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
static int sr_media_load(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	if (copy_from_user(cd.toc, argp, sizeof(struct sr_toc)))
		return -EFAULT;
	cd.toc->initial = 1;
	return 0;
}

// ============================================================================
static int sr_emulated_host(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_set_transform(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_get_transform(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_set_reserved_size(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_get_reserved_size(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_get_scsi_id(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_set_force_low_dma(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_get_low_dma(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_set_force_pack_id(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_get_pack_id(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_get_num_waiting(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_get_sg_tablesize(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_get_version_num(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;
	int __user *ip = argp;

	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return put_user(sr_version_num, ip);
}

// ============================================================================
static int sr_scsi_reset(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_io(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	int ret;
	void __user *argp = (void __user *) arg;
	struct sg_io_hdr io_hdr;

#if 0
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
#endif
	if (copy_from_user(&io_hdr, argp, sizeof(struct sg_io_hdr)))
		return -EFAULT;

	if ((ret = sr_do_ioctl(&cd, &io_hdr)))
		return ret;

	if (copy_to_user(argp, &io_hdr, sizeof(struct sg_io_hdr)))
		return -EFAULT;

	return 0;
}

// ============================================================================
static int sr_get_request_table(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_set_keep_orphan(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_get_keep_orphan(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_get_access_count(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_set_timeout(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_get_timeout(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_get_command_q(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_set_command_q(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_set_debug(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_next_cmd_len(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_scsi_ioctl_get_idlun(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_scsi_ioctl_probe_host(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_scsi_ioctl_get_bus_number(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_scsi_ioctl_get_pci(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_cdrommultisession(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
static int sr_bdops_ioctl(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	int ret = 0;

	mutex_lock(&sr_mutex);
	switch (cmd) {
	case SR_MEDIA_LOAD:
		ret = sr_media_load(bdev, mode, cmd, arg);
		break;
	case SG_EMULATED_HOST:
		ret = sr_emulated_host(bdev, mode, cmd, arg);
		break;
	case SG_SET_TRANSFORM:
		ret = sr_set_transform(bdev, mode, cmd, arg);
		break;
	case SG_GET_TRANSFORM:
		ret = sr_get_transform(bdev, mode, cmd, arg);
		break;
	case SG_SET_RESERVED_SIZE:
		ret = sr_set_reserved_size(bdev, mode, cmd, arg);
		break;
	case SG_GET_RESERVED_SIZE:
		ret = sr_get_reserved_size(bdev, mode, cmd, arg);
		break;
	case SG_GET_SCSI_ID:
		ret = sr_get_scsi_id(bdev, mode, cmd, arg);
		break;
	case SG_SET_FORCE_LOW_DMA:
		ret = sr_set_force_low_dma(bdev, mode, cmd, arg);
		break;
	case SG_GET_LOW_DMA:
		ret = sr_get_low_dma(bdev, mode, cmd, arg);
		break;
	case SG_SET_FORCE_PACK_ID:
		ret = sr_set_force_pack_id(bdev, mode, cmd, arg);
		break;
	case SG_GET_PACK_ID:
		ret = sr_get_pack_id(bdev, mode, cmd, arg);
		break;
	case SG_GET_NUM_WAITING:
		ret = sr_get_num_waiting(bdev, mode, cmd, arg);
		break;
	case SG_GET_SG_TABLESIZE:
		ret = sr_get_sg_tablesize(bdev, mode, cmd, arg);
		break;
	case SG_GET_VERSION_NUM:
		ret = sr_get_version_num(bdev, mode, cmd, arg);
		break;
	case SG_SCSI_RESET:
		ret = sr_scsi_reset(bdev, mode, cmd, arg);
		break;
	case SG_IO:
		ret = sr_io(bdev, mode, cmd, arg);
		break;
	case SG_GET_REQUEST_TABLE:
		ret = sr_get_request_table(bdev, mode, cmd, arg);
		break;
	case SG_SET_KEEP_ORPHAN:
		ret = sr_set_keep_orphan(bdev, mode, cmd, arg);
		break;
	case SG_GET_KEEP_ORPHAN:
		ret = sr_get_keep_orphan(bdev, mode, cmd, arg);
		break;
	case SG_GET_ACCESS_COUNT:
		ret = sr_get_access_count(bdev, mode, cmd, arg);
		break;
	case SG_SET_TIMEOUT:
		ret = sr_set_timeout(bdev, mode, cmd, arg);
		break;
	case SG_GET_TIMEOUT:
		ret = sr_get_timeout(bdev, mode, cmd, arg);
		break;
	case SG_GET_COMMAND_Q:
		ret = sr_get_command_q(bdev, mode, cmd, arg);
		break;
	case SG_SET_COMMAND_Q:
		ret = sr_set_command_q(bdev, mode, cmd, arg);
		break;
	case SG_SET_DEBUG:
		ret = sr_set_debug(bdev, mode, cmd, arg);
		break;
	case SG_NEXT_CMD_LEN:
		ret = sr_next_cmd_len(bdev, mode, cmd, arg);
		break;
	case SCSI_IOCTL_GET_IDLUN:
		ret = sr_scsi_ioctl_get_idlun(bdev, mode, cmd, arg);
		break;
	case SCSI_IOCTL_PROBE_HOST:
		ret = sr_scsi_ioctl_probe_host(bdev, mode, cmd, arg);
		break;
	case SCSI_IOCTL_GET_BUS_NUMBER:
		ret = sr_scsi_ioctl_get_bus_number(bdev, mode, cmd, arg);
		break;
	case SCSI_IOCTL_GET_PCI:
		ret = sr_scsi_ioctl_get_pci(bdev, mode, cmd, arg);
		break;
	case CDROMMULTISESSION:
		ret = sr_cdrommultisession(bdev, mode, cmd, arg);
		break;
	default:
		pr_err(DEVICE_NAME ": x%04x: x%016lx: x%08x\n", cmd, arg, mode);
		ret = -ENOSYS;
		break;
	}
	mutex_unlock(&sr_mutex);
	return ret;
}

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
static struct cdrom_device_ops sr_ops = {
};

// ============================================================================
static const struct block_device_operations sr_bdops = {
	.owner = THIS_MODULE,
	.ioctl = sr_bdops_ioctl,
};

// ============================================================================
static void sr_request(struct request_queue *rq)
{
	struct request *req;

	while ((req = blk_fetch_request(rq)) != NULL) {
		if (req->cmd_type != REQ_TYPE_FS) {
			__blk_end_request_all(req, -EIO);
			continue;
		}
		if (rq_data_dir(req) != READ) {
			__blk_end_request_all(req, -EIO);
			continue;
		}
		list_add_tail(&req->queuelist, &sr_deferred);
	}
}

// ============================================================================
static int probe_sr(void)
{
	struct cdrom_device_info *cdi;
	struct gendisk *disk;
	struct request_queue *rq;
	struct sr_toc *toc;
	struct cdrom_device_ops *cdo;
	int *change_capability;

	// ------------------------------------------------------------------------
	sr_major = register_blkdev(0, DEVICE_NAME);
	if (sr_major < 0)
		return sr_major;
	pr_info(DEVICE_NAME ": Registered with major number %d\n", sr_major);
	// ------------------------------------------------------------------------
	cd.toc = kzalloc(sizeof(struct sr_toc), GFP_KERNEL);
	toc = cd.toc;
	if (IS_ERR_OR_NULL(toc)) {
		unregister_blkdev(sr_major, DEVICE_NAME);
		return PTR_ERR(toc);
	}
	// ------------------------------------------------------------------------
	cd.cdi = kzalloc(sizeof(struct cdrom_device_info), GFP_KERNEL);
	cdi = cd.cdi;
	if (IS_ERR_OR_NULL(cdi)) {
		kfree(toc);
		unregister_blkdev(sr_major, DEVICE_NAME);
		return PTR_ERR(cdi);
	}
	cdi->ops = &sr_ops;
	cdi->capacity = 1;
	snprintf(cdi->name, sizeof(cdi->name), "%s%d", DEVICE_NAME, sr_minor);
	cdi->mask = 0;
	cdo = cdi->ops;
	change_capability = (int *) &cdo->capability;
	*change_capability = SR_CAPABILITIES;
	// ------------------------------------------------------------------------
	cd.disk = alloc_disk(SR_MINORS);
	disk = cd.disk;
	if (IS_ERR_OR_NULL(disk)) {
		kfree(cdi);
		kfree(toc);
		unregister_blkdev(sr_major, DEVICE_NAME);
		return PTR_ERR(disk);
	}
	disk->major = sr_major;
	disk->first_minor = sr_minor;
	disk->minors = SR_MINORS;
	snprintf(disk->disk_name, sizeof(disk->disk_name), "%s%d", DEVICE_NAME, sr_minor);
	disk->fops = &sr_bdops;
	// ------------------------------------------------------------------------
	cd.rq = blk_init_queue(sr_request, &sr_lock);
	rq = cd.rq;
	if (IS_ERR_OR_NULL(rq)) {
		del_gendisk(disk);
		put_disk(disk);
		kfree(cdi);
		kfree(toc);
		unregister_blkdev(sr_major, DEVICE_NAME);
		return PTR_ERR(rq);
	}
	blk_queue_logical_block_size(rq, SR_HARD_SECTOR);
	blk_queue_max_segments(rq, 1);
	blk_queue_max_segment_size(rq, 0x40000);
	disk->queue = rq;
	// ------------------------------------------------------------------------
	add_disk(disk);
	pr_info(DEVICE_NAME ": Attached scsi CD-ROM %s\n", cdi->name);
	return 0;
}

// ============================================================================
static void remove_sr(void)
{
	struct cdrom_device_info *cdi = cd.cdi;
	struct gendisk *disk = cd.disk;
	struct request_queue *rq = cd.rq;
	struct sr_toc *toc = cd.toc;

	blk_cleanup_queue(rq);
	del_gendisk(disk);
	put_disk(disk);
	kfree(cdi);
	kfree(toc);
	unregister_blkdev(sr_major, DEVICE_NAME);
}

// ============================================================================
static int __init init_sr(void)
{
	int ret;

	ret = probe_sr();
	if (!ret)
		pr_info(DEVICE_NAME ": %s initialised\n", DESCRIPTION);
	return ret;
}

// ============================================================================
static void __exit exit_sr(void)
{
	remove_sr();
	pr_info(DEVICE_NAME ": %s releases\n", DESCRIPTION);
}

// ============================================================================
module_init(init_sr);
module_exit(exit_sr);

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
MODULE_DESCRIPTION(DESCRIPTION);
MODULE_LICENSE("GPL");
MODULE_AUTHOR(AUTHOR);

// *** EOF ********************************************************************
