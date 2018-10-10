// ****************************************************************************
// SCSI cdrom (sr) emulation driver
// ****************************************************************************

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#define DEBUG

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#include <linux/module.h>				// module_init,module_exit, ...
#include <linux/cdrom.h>				// struct cdrom_device_ops, ...
#include <linux/file.h>					// fput
#include <scsi/scsi.h>					//
#include <scsi/scsi_ioctl.h>			//
#include <scsi/scsi_cmnd.h>				//
#include <scsi/scsi_driver.h>			// scsi_register_driver, ...
#include <scsi/scsi_eh.h>				// scsi_block_when_processing_errors, ...
#include <scsi/sg.h>					// SG command
#include "sr_emu.h"						// SCSI cdrom (sr) emulation driver's header

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#define VENDOR				"NECCDEMU"
#define PRODUCT				"CD-emulator (SR)"
#define REVISION			"1.00"
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

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
// 0x12: Inquiry
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
	memcpy(&bufp[0x08], VENDOR, 8);		//  8: Vendor Identification (8bytes)
	memcpy(&bufp[0x10], PRODUCT, 16);	// 16: Product Identification (16bytes)
	memcpy(&bufp[0x20], REVISION, 4);	// 32: Product Revision Level (4bytes)

	return 0;
}

// ============================================================================
// 0x28: Read 10
static int sr_gpcmd_read_10(const struct scsi_cd *cd, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int ret = 0, res;
	struct sr_toc *toc = cd->toc;
	struct file *file;
	unsigned long lba, len;

	if (!cd->toc->initial)
		return -ENOMEDIUM;

	lba = ((unsigned long) cmdp[2] << 24) + ((unsigned long) cmdp[3] << 16) + ((unsigned long) cmdp[4] << 8) + ((unsigned long) cmdp[5]);
	len = ((unsigned long) cmdp[7] << 8) + ((unsigned long) cmdp[8]);

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
// 0x42: Read Subchannel
static int sr_gpcmd_read_subchannel(const struct scsi_cd *cd, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int ret = -ENOSYS, len;

	if (!cd->toc->initial)
		return -ENOMEDIUM;

	if (!(cmdp[2] & 0x40)) {			// SubQ
		len = 0;
		bufp[0x00] = 0x00;				//  0: Reserved
		bufp[0x01] = 0x15;				//  1: Audio Status
		bufp[0x02] = len >> 8;			//  2: Sub-channel Data Length
		bufp[0x03] = len;				//  3: 
		return 0;
	}

	switch (cmdp[3]) {					// Sub-channel Data Format
	case 0x01:							// CD current position Mandatory
		break;
	case 0x02:							// Media catalogue number (UPC/bar code) Mandatory
		len = 20;
		bufp[0x00] = 0x00;				//  0: Reserved
		bufp[0x01] = 0x15;				//  1: Audio Status
		bufp[0x02] = len >> 8;			//  2: Sub-channel Data Length
		bufp[0x03] = len;				//  3: 
		bufp[0x04] = 0x02;				//  0: Sub Channel Data Format Code
		bufp[0x05] = 0x00;				//  1: Reserved
		bufp[0x06] = 0x00;				//  2: Reserved
		bufp[0x07] = 0x00;				//  3: Reserved
		bufp[0x08] = 0x00;				//  4: Media Catalogue Number (UPC/Bar Code)
		bufp[0x09] = 0x00;				//  5: 
		bufp[0x0a] = 0x00;				//  6: 
		bufp[0x0b] = 0x00;				//  7: 
		bufp[0x0c] = 0x00;				//  8: 
		bufp[0x0d] = 0x00;				//  9: 
		bufp[0x0e] = 0x00;				// 10: 
		bufp[0x0f] = 0x00;				// 11: 
		bufp[0x10] = 0x00;				// 12: 
		bufp[0x11] = 0x00;				// 13: 
		bufp[0x12] = 0x00;				// 14: 
		bufp[0x13] = 0x00;				// 15: 
		bufp[0x14] = 0x00;				// 16: 
		bufp[0x15] = 0x00;				// 17: 
		bufp[0x16] = 0x00;				// 18: 
		bufp[0x17] = 0x00;				// 19: 
		ret = 0;
		break;
	case 0x03:							// Track international standard recording code (ISRC) Mandatory
		break;
	}

	return ret;
}

// ============================================================================
// 0x43: Read Table of Contents
static int sr_gpcmd_read_toc_pma_atip(const struct scsi_cd *cd, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	struct sr_toc *toc = cd->toc;
	struct cdrom_tochdr *thdr = &toc->tochdr;
	struct cdrom_tocentry *tent = toc->tocentry;
	int i, n, o, len, trk, trk0, trk1, lout, lba, lba0, lba1, m, s, f;

	if (!cd->toc->initial)
		return -ENOMEDIUM;

	trk0 = thdr->cdth_trk0;
	trk1 = thdr->cdth_trk1;
	lout = toc->leadout;

	switch (cmdp[2] & 0x0f) {			// Format
	case 0x00:							// TOC
		if (cmdp[0x06] == 0x00)			// from first track to end track (lead out)
			trk = trk0;
		else							// from select track to end track (lead out)
			trk = cmdp[0x06];
		len = 2 + 8 * (trk1 - trk + 2);
		o = 0;
		bufp[o++] = len >> 8;			//  0: TOC Data Length
		bufp[o++] = len;				//  1: 
		bufp[o++] = trk0;				//  2: First Track Number
		bufp[o++] = trk1;				//  3: Last Track Number
		for (i = trk0, n = 0; i <= trk1 && n <= TRACK_MAX; i++, n++, tent++) {
			if (tent->cdte_track != trk)
				continue;
			for (; i <= trk1 && n <= TRACK_MAX; i++, n++, tent++) {
				trk = tent->cdte_track;
				lba = sr_msf2lba(tent->cdte_addr.msf.minute, tent->cdte_addr.msf.second, tent->cdte_addr.msf.frame);
				bufp[o++] = 0x00;		//  0: Reserved
				bufp[o++] = 0x10;		//  1: ADR | Control 
				bufp[o++] = trk;		//  2: Track Number
				bufp[o++] = 0x00;		//  3: Reserved
				bufp[o++] = lba >> 24;	//  4: Track Start Address
				bufp[o++] = lba >> 16;	//  5: 
				bufp[o++] = lba >> 8;	//  6: 
				bufp[o++] = lba;		//  7: 
			}
		}
		lba = lout;
		bufp[o++] = 0x00;				//  0: Reserved
		bufp[o++] = 0x10;				//  1: ADR | Control 
		bufp[o++] = 0xaa;				//  2: Track Number
		bufp[o++] = 0x00;				//  3: Reserved
		bufp[o++] = lba >> 24;			//  4: Track Start Address
		bufp[o++] = lba >> 16;			//  5: 
		bufp[o++] = lba >> 8;			//  6: 
		bufp[o++] = lba;				//  7: 
		return 0;
	case 0x01:							// Session Information
		len = 0x0a;
		o = 0;
		lba = 0;
		bufp[o++] = len >> 8;			//  0: TOC Data Length (0Ah)
		bufp[o++] = len;				//  1: 
		bufp[o++] = 0x01;				//  2: First Complete Session Number (Hex)
		bufp[o++] = 0x01;				//  3: Last Complete Session Number (Hex)
		bufp[o++] = 0x00;				//  0: Reserved
		bufp[o++] = 0x10;				//  1: ADR | Control
		bufp[o++] = 0x01;				//  2: First Track Number in Last Complete Session
		bufp[o++] = 0x00;				//  3: Reserved
		bufp[o++] = lba >> 24;			//  4: Start Address of First Track in Last Session
		bufp[o++] = lba >> 16;			//  5: 
		bufp[o++] = lba >> 8;			//  6: 
		bufp[o++] = lba;				//  7: 
		return 0;
	case 0x02:							// Full TOC
		if (cmdp[0x06] == 0xaa) {		// Lead-out area
			len = 2 + 11;
			o = 0;
			sr_lba2msf(lout + 75 * 2, &m, &s, &f);

			bufp[o++] = len >> 8;		//  0: TOC Data Length
			bufp[o++] = len;			//  1: 
			bufp[o++] = 0x01;			//  2: First Complete Session Number
			bufp[o++] = 0x01;			//  3: Last Complete Session Number
			bufp[o++] = 0x01;			//  4:  0: Session Number
			bufp[o++] = 0x10;			//  5:  1: ADR | Control
			bufp[o++] = 0x00;			//  6:  2: Byte 1 or TNO
			bufp[o++] = 0xa0;			//  7:  3: Byte 2 or Point
			bufp[o++] = 0x00;			//  8:  4: Byte 3 or Min
			bufp[o++] = 0x00;			//  9:  5: Byte 4 or Sec
			bufp[o++] = 0x00;			// 10:  6: Byte 5 or Frame
			bufp[o++] = 0x00;			// 11:  7: Byte 6 or Zero
			bufp[o++] = m;				// 12:  8: Byte 7 or PMin
			bufp[o++] = s;				// 13:  9: Byte 8 or PSec
			bufp[o++] = f;				// 14: 10: Byte 9 or PFrame

			return 0;
		}

		len = 2 + 11 * (3 + trk1 - trk0 + 1);
		o = 0;
		bufp[o++] = len >> 8;			//  0: TOC Data Length
		bufp[o++] = len;				//  1: 
		bufp[o++] = 0x01;				//  2: First Complete Session Number
		bufp[o++] = 0x01;				//  3: Last Complete Session Number

		for (i = 0; i < 3; i++) {
			bufp[o++] = 0x01;			//  0: Session Number
			bufp[o++] = 0x10;			//  1: ADR | Control (Sub-channel Q encodes current position data | 2 Audio without Pre-emphasis)
			bufp[o++] = 0x00;			//  2: Byte 1 or TNO
			bufp[o++] = 0xa0 + i;		//  3: Byte 2 or Point (Point: First Track number,Last Track number,Lead-out)
			bufp[o++] = 0x00;			//  4: Byte 3 or Min
			bufp[o++] = 0x00;			//  5: Byte 4 or Sec
			bufp[o++] = 0x00;			//  6: Byte 5 or Frame
			bufp[o++] = 0x00;			//  7: Byte 6 or Zero
			m = s = f = 0;
			if (i == 0) {				// First Track number
				m = trk0;
			} else if (i == 1) {		// Last Track number
				m = trk1;
			} else if (i == 2) {		// Lead-out
				sr_lba2msf(lout + 75 * 2, &m, &s, &f);
			}
			bufp[o++] = m;				//  8: Byte 7 or PMin
			bufp[o++] = s;				//  9: Byte 8 or PSec
			bufp[o++] = f;				// 10: Byte 9 or PFrame
		}

		for (i = trk0, n = 0; i <= trk1 && n <= TRACK_MAX; i++, n++, tent++) {
			trk = tent->cdte_track;
			if (tent->cdte_format == CDROM_MSF)
				lba = sr_msf2lba(tent->cdte_addr.msf.minute, tent->cdte_addr.msf.second, tent->cdte_addr.msf.frame);
			else
				lba = tent->cdte_addr.lba;
			sr_lba2msf(lba + 75 * 2, &m, &s, &f);
			bufp[o++] = 0x01;			//  0: Session Number
			bufp[o++] = 0x10;			//  1: ADR | Control (Sub-channel Q encodes current position data | 2 Audio without Pre-emphasis)
			bufp[o++] = 0x00;			//  2: Byte 1 or TNO
			bufp[o++] = trk;			//  3: Byte 2 or Point (Point: First Track number)
			bufp[o++] = 0x00;			//  4: Byte 3 or Min
			bufp[o++] = 0x00;			//  5: Byte 4 or Sec
			bufp[o++] = 0x00;			//  6: Byte 5 or Frame
			bufp[o++] = 0x00;			//  7: Byte 6 or Zero
			bufp[o++] = m;				//  8: Byte 7 or PMin
			bufp[o++] = s;				//  9: Byte 8 or PSec
			bufp[o++] = f;				// 10: Byte 9 or PFrame
		}

		return 0;
	case 0x03:							// PMA
		o = 0;
		len = 2 + 11 * (3 + trk1 - trk0 + 1);
		bufp[o++] = len >> 8;			//  0: PMA Data Length
		bufp[o++] = len;				//  1: 
		bufp[o++] = 0x00;				//  2: Reserved
		bufp[o++] = 0x00;				//  3: Reserved

		lba0 = 0;
		for (i = trk0, n = 0; i <= trk1 && n < TRACK_MAX; i++, n++, tent++) {
			trk = tent->cdte_track;
			if (tent->cdte_format == CDROM_MSF)
				lba1 = sr_msf2lba(tent->cdte_addr.msf.minute, tent->cdte_addr.msf.second, tent->cdte_addr.msf.frame);
			else
				lba1 = tent->cdte_addr.lba;

			bufp[o++] = 0x00;			//  0: Reserved
			bufp[o++] = 0x10;			//  1: ADR | Control (Sub-channel Q encodes current position data | 2 Audio without Pre-emphasis)
			bufp[o++] = 0x00;			//  2: Byte 1 or TNO
			bufp[o++] = trk;			//  3: Byte 2 or Point (Point: First Track number)

			sr_lba2msf(lba1 + 75 * 2, &m, &s, &f);
			bufp[o++] = m;				//  4: Byte 3 or Min
			bufp[o++] = s;				//  5: Byte 4 or Sec
			bufp[o++] = f;				//  6: Byte 5 or Frame

			bufp[o++] = 0x00;			//  7: Byte 6 or Zero

			sr_lba2msf(lba1 - lba0 + 75 * 2, &m, &s, &f);
			bufp[o++] = m;				//  8: Byte 7 or PMin
			bufp[o++] = s;				//  9: Byte 8 or PSec
			bufp[o++] = f;				// 10: Byte 9 or PFrame

			lba0 = lba1;
		}
		return 0;
	case 0x04:							// ATIP
		o = 0;
		len = 0x1a;
		bufp[o++] = len >> 8;			//  0: ATIP Data Length
		bufp[o++] = len;				//  1: 
		bufp[o++] = 0x00;				//  2: Reserved
		bufp[o++] = 0x00;				//  3: Reserved
		bufp[o++] = 0xd1;				//  0: 
		bufp[o++] = 0x00;				//  1: 
		bufp[o++] = 0xc6;				//  2: 
		bufp[o++] = 0x00;				//  3: Reserved
		bufp[o++] = 0x61;				//  4: ATIP Start Time of Lead-in (Min)
		bufp[o++] = 0x0a;				//  5: ATIP Start Time of Lead-in (Sec)
		bufp[o++] = 0x00;				//  6: ATIP Start Time of Lead-in (Frame)
		bufp[o++] = 0x00;				//  7: Reserved
		bufp[o++] = 0x4f;				//  8: ATIP Last Possible Start Time of Lead-out (Min)
		bufp[o++] = 0x3b;				//  9: ATIP Last Possible Start Time of Lead-out (Sec)
		bufp[o++] = 0x4a;				// 10: ATIP Last Possible Start Time of Lead-out (Frame)
		bufp[o++] = 0x00;				// 11: Reserved
		bufp[o++] = 0x02;				// 12: A1 Values
		bufp[o++] = 0x4a;				// 13: 
		bufp[o++] = 0xb0;				// 14: 
		bufp[o++] = 0x00;				// 15: Reserved
		bufp[o++] = 0x5c;				// 16: A2 Values
		bufp[o++] = 0xc6;				// 17: 
		bufp[o++] = 0x26;				// 18: 
		bufp[o++] = 0x00;				// 19: Reserved
		bufp[o++] = 0xff;				// 20: A3 Values
		bufp[o++] = 0xff;				// 21: 
		bufp[o++] = 0xff;				// 22: 
		bufp[o++] = 0x00;				// 23: Reserved
		return 0;
	case 0x05:							// CD-Text
		len = 0x02;
		o = 0;
		bufp[o++] = len >> 8;			//  0: CD-Text Data Length
		bufp[o++] = len;				//  1: 
		bufp[o++] = 0x00;				//  2: Reserved
		bufp[o++] = 0x00;				//  3: Reserved
		return 0;
	}

	return -ENOSYS;
}

// ============================================================================
// 0x45: Play Audio 10
static int sr_gpcmd_play_audio_10(const struct scsi_cd *cd, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	if (!cd->toc->initial)
		return -ENOMEDIUM;

	return 0;
}

// ============================================================================
// 0x51: Read Disc Info
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
// 0x55: Mode Select 10
static int sr_gpcmd_mode_select_10(const struct scsi_cd *cd, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	return 0;
}

// ============================================================================
// 0x5a: Mode Sense 10
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
		bufp[0x09] = 0x26;				//  9:  1: Page Length (18h)
		bufp[0x0a] = 0x3f;				// 10:  2: Read media
		bufp[0x0b] = 0x37;				// 11:  3: Write media
		bufp[0x0c] = 0xf1;				// 12:  4: Media Function Capabilities
		bufp[0x0d] = 0x63;				// 13:  5:
		bufp[0x0e] = 0x2b;				// 14:  6:
		bufp[0x0f] = 0x23;				// 15:  7:
		bufp[0x10] = 0x10;				// 16:  8: Obsolete
		bufp[0x11] = 0x89;				// 17:  9:
		bufp[0x12] = 0x01;				// 18: 10: Number of Volume Levels Supported
		bufp[0x13] = 0x00;				// 19: 11:
		bufp[0x14] = 0x0f;				// 20: 12: Buffer Size supported by Logical Unit (in KBytes)
		bufp[0x15] = 0xa0;				// 21: 13:
		bufp[0x16] = 0x10;				// 22: 14: Obsolete
		bufp[0x17] = 0x89;				// 23: 15:
		bufp[0x18] = 0x00;				// 24: 16: Obsolete
		bufp[0x19] = 0x00;				// 25: 17: Digital Output Format
		bufp[0x1a] = 0x02;				// 26: 18: Obsolete
		bufp[0x1b] = 0xc2;				// 27: 19:
		bufp[0x1c] = 0x02;				// 28: 20: Obsolete
		bufp[0x1d] = 0xc2;				// 29: 21:
		bufp[0x1e] = 0x00;				// 30: 22: Copy Management Revision Supported
		bufp[0x1f] = 0x01;				// 31: 23:
		bufp[0x20] = 0x00;				// 32: 24: Reserved
		bufp[0x21] = 0x00;				// 33: 25: Reserved
		bufp[0x22] = 0x00;				// 
		bufp[0x23] = 0x00;				// 
		bufp[0x24] = 0x02;				// 
		bufp[0x25] = 0xc2;				// 
		bufp[0x26] = 0x00;				// 
		bufp[0x27] = 0x02;				// 
		bufp[0x28] = 0x00;				// 
		bufp[0x29] = 0x00;				// 
		bufp[0x2a] = 0x1b;				// 
		bufp[0x2b] = 0x90;				// 
		bufp[0x2c] = 0x00;				// 
		bufp[0x2d] = 0x00;				// 
		bufp[0x2e] = 0x02;				// 
		bufp[0x2f] = 0xc2;				// 
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
// 0xbe: Read CD
static int sr_gpcmd_read_cd(const struct scsi_cd *cd, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int ret = 0, res, m, s, f;
	struct sr_toc *toc = cd->toc;
	struct file *file;
	unsigned long lba = 0, len = 0, o = 0, cnt, l;
	int sector_type, header_code, error_flag, sub_channel;

	if (!cd->toc->initial)
		return -ENOMEDIUM;

	lba = ((unsigned long) cmdp[2] << 24) + ((unsigned long) cmdp[3] << 16) + ((unsigned long) cmdp[4] << 8) + ((unsigned long) cmdp[5]);
	sr_lba2msf(lba, &m, &s, &f);
	// Expected Sector Type
	sector_type = (cmdp[1] >> 2) & 0x07;
	switch (sector_type) {
	case 0x00:							// Any Type      : 
	case 0x01:							// CD DA         : 2352
		len = 2352;
		break;
	case 0x02:							// Mode 1        : 2048
		len = 2048;
		break;
	case 0x03:							// Mode 2        : 2336
		len = 2336;
		break;
	case 0x04:							// Mode 2 Form 1 : 2048
		len = 2048;
		break;
	case 0x05:							// Mode 2 Form 2 : 2328
		len = 2328;
		break;
	default:
		return -EINVAL;
	}
	// Header(s) Code
	header_code = (cmdp[9] >> 5) & 0x03;
	switch (header_code) {
	case 0x00:							// None
		break;
	case 0x01:							// HdrOnly
		break;
	case 0x02:							// SubheaderOnly
		break;
	case 0x03:							// All Headers
		break;
	default:
		return -EINVAL;
	}
	// Error Flag(s)
	error_flag = (cmdp[9] >> 1) & 0x03;
	switch (error_flag) {
	case 0x00:							// None
		break;
	case 0x01:							// C2 Error Flag data
		break;
	case 0x02:							// C2 & Block Error Flags
		break;
	default:
		return -EINVAL;
	}
	// Sub-Channel Data Selection Bits
	sub_channel = cmdp[10] & 0x03;
	switch (sub_channel) {
	case 0x00:							// No Sub-channel Data
		break;
	case 0x01:							// RAW
		break;
	case 0x02:							// Q
		break;
	case 0x04:							// R - W
		break;
	default:
		return -EINVAL;
	}

	file = filp_open(toc->path_bin, O_RDONLY | O_LARGEFILE, 0);
	if (IS_ERR(file))
		return PTR_ERR(file);

	cnt = ((unsigned long) cmdp[6] << 16) + ((unsigned long) cmdp[7] << 8) + ((unsigned long) cmdp[8]);

	for (l = 0; l < cnt; l++) {
		res = kernel_read(file, lba, &bufp[o], len);
		if (res < 0) {
			ret = -EIO;
			break;
		}
	}

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
#ifdef DEBUG
	for (i = 0; i < sizeof(packet_command_texts) / sizeof(packet_command_texts[0]); i++) {
		if (packet_command_texts[i].packet_command == cmdp[0]) {
			b = packet_command_texts[i].text;
			break;
		}
	}
	pr_devel(DEVICE_NAME ": %s: %02x: %s\n", __FUNCTION__, *cmdp, b);
	pr_devel(DEVICE_NAME ": %s: cmdp: %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x\n", __FUNCTION__, cmdp[0], cmdp[1], cmdp[2], cmdp[3], cmdp[4], cmdp[5], cmdp[6], cmdp[7], cmdp[8], cmdp[9], cmdp[10], cmdp[11]);
#endif
	switch (cmdp[0]) {
	case GPCMD_TEST_UNIT_READY:		// 0x00: Test Unit Ready --------------
		ret = 0;
		break;
	case GPCMD_INQUIRY:				// 0x12: Inquiry ----------------------
		ret = sr_gpcmd_inquiry(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_10:				// 0x28: Read 10 ----------------------
		ret = sr_gpcmd_read_10(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_SUBCHANNEL:		// 0x42: Read Subchannel --------------
		ret = sr_gpcmd_read_subchannel(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_TOC_PMA_ATIP:		// 0x43: Read Table of Contents -------
		ret = sr_gpcmd_read_toc_pma_atip(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_PLAY_AUDIO_10:			// 0x45: Play Audio 10 ----------------
		ret = sr_gpcmd_play_audio_10(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_DISC_INFO:			// 0x51: Read Disc Info ---------------
		ret = sr_gpcmd_read_disc_info(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_MODE_SELECT_10:			// 0x55: Mode Select 10 ---------------
		ret = sr_gpcmd_mode_select_10(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_MODE_SENSE_10:			// 0x5a: Mode Sense 10 ----------------
		ret = sr_gpcmd_mode_sense_10(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_12:				// 0xa8: Read 12 ----------------------
		ret = sr_gpcmd_read_12(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_CD_MSF:			// 0xb9: Read CD MSF ------------------
		ret = sr_gpcmd_read_cd_msf(cd, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_CD:				// 0xbe: Read CD ----------------------
		ret = sr_gpcmd_read_cd(cd, io_hdr, cmdp, bufp);
		break;
	default:
		for (i = 0; i < sizeof(packet_command_texts) / sizeof(packet_command_texts[0]); i++) {
			if (packet_command_texts[i].packet_command == cmdp[0]) {
				b = packet_command_texts[i].text;
				break;
			}
		}
		pr_err(DEVICE_NAME ": %s: %02x: %s\n", __FUNCTION__, *cmdp, b);
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
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_set_transform(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_get_transform(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_set_reserved_size(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_get_reserved_size(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_get_scsi_id(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_set_force_low_dma(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_get_low_dma(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_set_force_pack_id(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_get_pack_id(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_get_num_waiting(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_get_sg_tablesize(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_get_version_num(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_scsi_reset(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_io(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	int ret;
	void __user *argp = (void __user *) arg;
	struct sg_io_hdr io_hdr;

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
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_set_keep_orphan(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_get_keep_orphan(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_get_access_count(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_set_timeout(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_get_timeout(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_get_command_q(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_set_command_q(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_set_debug(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_next_cmd_len(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_scsi_ioctl_get_idlun(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_scsi_ioctl_probe_host(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_scsi_ioctl_get_bus_number(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_scsi_ioctl_get_pci(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
}

// ============================================================================
static int sr_cdrommultisession(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	void __user *argp = (void __user *) arg;

	return scsi_cmd_ioctl(bdev->bd_disk->queue, bdev->bd_disk, mode, cmd, argp);
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
