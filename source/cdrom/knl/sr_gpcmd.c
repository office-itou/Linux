// ****************************************************************************
// SCSI cdrom (sr) device driver
// ****************************************************************************

// ::: debug ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#define DEBUG

// ::: include ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#include "sr_module.h"					// SCSI cdrom (sr) device driver's header

// ::: global :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

// ::: sr_gpcmd.c :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
// === 0x00: GPCMD_TEST_UNIT_READY ============================================
static int sr_gpcmd_test_unit_ready(const struct my_toc *toc, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return result;
}

// === 0x12: GPCMD_INQUIRY ====================================================
static int sr_gpcmd_inquiry(const struct my_toc *toc, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);

	bufp[0x00] = 0x05;					//  0: C/DVD Logical Unit (ROM, R, RW, RAM and +RW types)
	bufp[0x01] = 0x80;					//  1: RMB
	bufp[0x02] = 0x05;					//  2: ANSI Version
	bufp[0x03] = 0x32;					//  3:
	bufp[0x04] = 0x1f;					//  4: Additional Length
	bufp[0x05] = 0x00;					//  5:
	bufp[0x06] = 0x00;					//  6:
	bufp[0x07] = 0x00;					//  7:
	memcpy(&bufp[0x08], SR_VENDOR, 8);	//  8: Vendor Identification (8bytes)
	memcpy(&bufp[0x10], SR_PRODUCT, 16);	// 16: Product Identification (16bytes)
	memcpy(&bufp[0x20], SR_REVISION, 4);	// 32: Product Revision Level (4bytes)

	return result;
}

// === 0x1b: GPCMD_START_STOP_UNIT ============================================
static int sr_gpcmd_start_stop_unit(const struct my_toc *toc, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return result;
}

// === 0x28: GPCMD_READ_10 ====================================================
static int sr_gpcmd_read_10(const struct my_toc *toc, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return result;
}

// === 0x42: GPCMD_READ_SUBCHANNEL ============================================
static int sr_gpcmd_read_subchannel(const struct my_toc *toc, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;
	const struct cdrom_tochdr *thdr = &toc->tochdr;
	const struct cdrom_tocentry *tent = toc->tocentry;
	int len, o, i, n;
	int msf = 0, trk = 0, trk0 = 0, trk1 = 0, m = 0, s = 0, f = 0;
	long lba0 = 0, lba1 = 0, lout;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	if (!toc->initial)
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
	default:
		result = -ENOSYS;
		break;
	case 0x01:							// CD current position Mandatory
		msf = cmdp[1] & 0x02;
		trk = cmdp[6];

		trk0 = thdr->cdth_trk0;
		trk1 = thdr->cdth_trk1;
		lout = toc->leadout;

		for (i = trk0, n = 0; i <= trk1 && n < TRACK_MAX; i++, n++, tent++) {
			if (tent->cdte_track == trk) {
				lba0 = my_msf2lba(tent->cdte_addr.msf.minute, tent->cdte_addr.msf.second, tent->cdte_addr.msf.frame);
				if (i == trk1) {
					lba1 = lout;
				} else {
					tent++;
					lba1 = my_msf2lba(tent->cdte_addr.msf.minute, tent->cdte_addr.msf.second, tent->cdte_addr.msf.frame) - 1;
				}
				break;
			}
		}

		len = 12;
		o = 0;
		bufp[o++] = 0x00;				//  0: Reserved
		bufp[o++] = 0x15;				//  1: Audio Status
		bufp[o++] = len >> 8;			//  2: Sub-channel Data Length
		bufp[o++] = len;				//  3: 
		bufp[o++] = 0x01;				//  0: Sub Channel Data Format Code
		bufp[o++] = 0x00;				//  1: ADR / Control
		bufp[o++] = trk;				//  2: Track Number
		bufp[o++] = 0x01;				//  3: Index Number
		if (msf) {						// MSF
			my_lba2msf(lba0, &m, &s, &f, 1);
			bufp[o++] = 0x00;			//  4: Absolute CD Address
			bufp[o++] = m;				//  5: 
			bufp[o++] = s;				//  6: 
			bufp[o++] = f;				//  7: 
			my_lba2msf(lba1, &m, &s, &f, 1);
			bufp[o++] = 0x00;			//  8:  Track Relative CD Address
			bufp[o++] = m;				//  9: 
			bufp[o++] = s;				// 10: 
			bufp[o++] = f;				// 11: 
		} else {
			bufp[o++] = lba0 >> 24;		//  4: Absolute CD Address
			bufp[o++] = lba0 >> 16;		//  5: 
			bufp[o++] = lba0 >> 8;		//  6: 
			bufp[o++] = lba0;			//  7: 
			bufp[o++] = lba1 >> 24;		//  8: Track Relative CD Address
			bufp[o++] = lba1 >> 16;		//  9: 
			bufp[o++] = lba1 >> 8;		// 10: 
			bufp[o++] = lba1;			// 11: 
		}
		result = 0;
		break;
	case 0x02:							// Media catalogue number (UPC/bar code) Mandatory
		len = 20;
		o = 0;
		bufp[o++] = 0x00;				//  0: Reserved
		bufp[o++] = 0x15;				//  1: Audio Status
		bufp[o++] = len >> 8;			//  2: Sub-channel Data Length
		bufp[o++] = len;				//  3: 
		bufp[o++] = 0x02;				//  0: Sub Channel Data Format Code
		bufp[o++] = 0x00;				//  1: Reserved
		bufp[o++] = 0x00;				//  2: Reserved
		bufp[o++] = 0x00;				//  3: Reserved
		bufp[o++] = 0x00;				//  4: Media Catalogue Number (UPC/Bar Code)
		bufp[o++] = 0x00;				//  5: 
		bufp[o++] = 0x00;				//  6: 
		bufp[o++] = 0x00;				//  7: 
		bufp[o++] = 0x00;				//  8: 
		bufp[o++] = 0x00;				//  9: 
		bufp[o++] = 0x00;				// 10: 
		bufp[o++] = 0x00;				// 11: 
		bufp[o++] = 0x00;				// 12: 
		bufp[o++] = 0x00;				// 13: 
		bufp[o++] = 0x00;				// 14: 
		bufp[o++] = 0x00;				// 15: 
		bufp[o++] = 0x00;				// 16: 
		bufp[o++] = 0x00;				// 17: 
		bufp[o++] = 0x00;				// 18: 
		bufp[o++] = 0x00;				// 19: 
		result = 0;
		break;
	case 0x03:							// Track international standard recording code (ISRC) Mandatory
		len = 20;
		o = 0;
		bufp[o++] = 0x00;				//  0: Reserved
		bufp[o++] = 0x15;				//  1: Audio Status
		bufp[o++] = len >> 8;			//  2: Sub-channel Data Length
		bufp[o++] = len;				//  3: 
		bufp[o++] = 0x03;				//  0: Sub Channel Data Format Code (03h)
		bufp[o++] = 0x30;				//  1: ADR (03) | Control
		bufp[o++] = 0x01;				//  2: Track Number
		bufp[o++] = 0x01;				//  3: Reserved
		bufp[o++] = 0x80;				//  4: TCVal
		bufp[o++] = 0x30;				//  5: I01 (Country Code)
		bufp[o++] = 0x30;				//  6: I02
		bufp[o++] = 0x30;				//  7: I03 (Owner Code)
		bufp[o++] = 0x30;				//  8: I04
		bufp[o++] = 0x30;				//  9: I05
		bufp[o++] = 0x30;				// 10: I06 (Year of Recording)
		bufp[o++] = 0x30;				// 11: I07
		bufp[o++] = 0x30;				// 12: I08 (Serial Number)
		bufp[o++] = 0x30;				// 13: I09
		bufp[o++] = 0x30;				// 14: I10
		bufp[o++] = 0x30;				// 15: I11
		bufp[o++] = 0x30;				// 16: I12
		bufp[o++] = 0x00;				// 17: Zero
		bufp[o++] = 0x00;				// 18: AFrame
		bufp[o++] = 0x00;				// 19: Reserved
		result = 0;
		break;
	}

	return result;
}

// === 0x43: GPCMD_READ_TOC_PMA_ATIP ==========================================
static int sr_gpcmd_read_toc_pma_atip(const struct my_toc *toc, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;
	const struct cdrom_tochdr *thdr = &toc->tochdr;
	const struct cdrom_tocentry *tent = toc->tocentry;
	int i, n, o, len, trk, trk0, trk1, m, s, f;
	long lout, lba, lba0, lba1;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	if (!toc->initial)
		return -ENOMEDIUM;

	trk0 = thdr->cdth_trk0;
	trk1 = thdr->cdth_trk1;
	lout = toc->leadout;

	switch (cmdp[2] & 0x0f) {			// Format
	default:
		return -ENOSYS;
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
		for (i = trk0, n = 0; i <= trk1 && n < TRACK_MAX; i++, n++, tent++) {
			if (tent->cdte_track != trk)
				continue;
			for (; i <= trk1 && n <= TRACK_MAX; i++, n++, tent++) {
				trk = tent->cdte_track;
				lba = my_msf2lba(tent->cdte_addr.msf.minute, tent->cdte_addr.msf.second, tent->cdte_addr.msf.frame);
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
		bufp[o++] = 0x00;				//  0: Reserved
		bufp[o++] = 0x10;				//  1: ADR | Control 
		bufp[o++] = 0xaa;				//  2: Track Number
		bufp[o++] = 0x00;				//  3: Reserved
		bufp[o++] = lout >> 24;			//  4: Track Start Address
		bufp[o++] = lout >> 16;			//  5: 
		bufp[o++] = lout >> 8;			//  6: 
		bufp[o++] = lout;				//  7: 
		break;
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
		break;
	case 0x02:							// Full TOC
		if (cmdp[0x06] == 0xaa) {		// Lead-out area
			len = 2 + 11;
			o = 0;
			my_lba2msf(lout, &m, &s, &f, 1);

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

			break;
		}

		len = 2 + 11 * (6 + trk1 - trk0 + 1);
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
				my_lba2msf(lout, &m, &s, &f, 1);
			}
			bufp[o++] = m;				//  8: Byte 7 or PMin
			bufp[o++] = s;				//  9: Byte 8 or PSec
			bufp[o++] = f;				// 10: Byte 9 or PFrame
		}

		for (i = trk0, n = 0; i <= trk1 && n <= TRACK_MAX; i++, n++, tent++) {
			trk = tent->cdte_track;
			if (tent->cdte_format == CDROM_MSF)
				lba = my_msf2lba(tent->cdte_addr.msf.minute, tent->cdte_addr.msf.second, tent->cdte_addr.msf.frame);
			else
				lba = tent->cdte_addr.lba;
			my_lba2msf(lba, &m, &s, &f, 1);
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

		break;
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
				lba1 = my_msf2lba(tent->cdte_addr.msf.minute, tent->cdte_addr.msf.second, tent->cdte_addr.msf.frame);
			else
				lba1 = tent->cdte_addr.lba;

			bufp[o++] = 0x00;			//  0: Reserved
			bufp[o++] = 0x10;			//  1: ADR | Control (Sub-channel Q encodes current position data | 2 Audio without Pre-emphasis)
			bufp[o++] = 0x00;			//  2: Byte 1 or TNO
			bufp[o++] = trk;			//  3: Byte 2 or Point (Point: First Track number)

			my_lba2msf(lba1, &m, &s, &f, 1);
			bufp[o++] = m;				//  4: Byte 3 or Min
			bufp[o++] = s;				//  5: Byte 4 or Sec
			bufp[o++] = f;				//  6: Byte 5 or Frame

			bufp[o++] = 0x00;			//  7: Byte 6 or Zero

			my_lba2msf(lba1 - lba0, &m, &s, &f, 1);
			bufp[o++] = m;				//  8: Byte 7 or PMin
			bufp[o++] = s;				//  9: Byte 8 or PSec
			bufp[o++] = f;				// 10: Byte 9 or PFrame

			lba0 = lba1;
		}

		break;
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

		break;
	case 0x05:							// CD-Text
		len = 0x02;
		o = 0;
		bufp[o++] = len >> 8;			//  0: CD-Text Data Length
		bufp[o++] = len;				//  1: 
		bufp[o++] = 0x00;				//  2: Reserved
		bufp[o++] = 0x00;				//  3: Reserved

		break;
	}

	return result;
}

// === 0x45: GPCMD_PLAY_AUDIO_10 ==============================================
static int sr_gpcmd_play_audio_10(const struct my_toc *toc, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return result;
}

// === 0x47: GPCMD_PLAY_AUDIO_MSF =============================================
static int sr_gpcmd_play_audio_msf(const struct my_toc *toc, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return result;
}

// === 0x4b: GPCMD_PAUSE_RESUME ===============================================
static int sr_gpcmd_pause_resume(const struct my_toc *toc, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return result;
}

// === 0x51: GPCMD_READ_DISC_INFO =============================================
static int sr_gpcmd_read_disc_info(const struct my_toc *toc, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;
	const struct cdrom_tochdr *thdr = &toc->tochdr;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	if (!toc->initial)
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

	return result;
}

// === 0x55: GPCMD_MODE_SELECT_10 =============================================
static int sr_gpcmd_mode_select_10(const struct my_toc *toc, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return result;
}

// === 0x5a: GPCMD_MODE_SENSE_10 ==============================================
static int sr_gpcmd_mode_sense_10(const struct my_toc *toc, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);

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
	case 0x20 ... 0x29:				// 20h - 29h, Vendor-specific
		break;
	case 0x2a:							// 0x2Ah C/DVD Capabilities & Mechanical Status
		bufp[0x08] = 0x2a;				//  8:  0: Page Code (2Ah)
		bufp[0x09] = 0x26;				//  9:  1: Page Length (30+4*(maximum number of n))
		bufp[0x0a] = 0x3f;				// 10:  2: Read media
		bufp[0x0b] = 0x37;				// 11:  3: Write media
		bufp[0x0c] = 0xf1;				// 12:  4: Media Function Capabilities
		bufp[0x0d] = 0x63;				// 13:  5:
		bufp[0x0e] = 0x29;				// 14:  6:
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
		bufp[0x21] = 0x00;				// 33: 25: 
		bufp[0x22] = 0x00;				// 34: 26: 
		bufp[0x23] = 0x00;				// 35: 27: Rotation Control Selected
		bufp[0x24] = 0x02;				// 36: 28: Current Write Speed Selected (kbytes/sec)
		bufp[0x25] = 0xc2;				// 37: 29: 
		bufp[0x26] = 0x00;				// 38: 30: Number of logical unit Write Speed Performance Descriptor Tables (n)
		bufp[0x27] = 0x02;				// 39: 31: 
		bufp[0x28] = 0x00;				// 40: 32: Logical unit Write Speed Performance Descriptor Block #1
		bufp[0x29] = 0x00;				// 41: 33: 
		bufp[0x2a] = 0x1b;				// 42: 34: 
		bufp[0x2b] = 0x90;				// 43: 35: 
		bufp[0x2c] = 0x00;				// 44: 36: Logical unit Write Speed Performance Descriptor Block #2
		bufp[0x2d] = 0x00;				// 45: 37: 
		bufp[0x2e] = 0x02;				// 46: 38: 
		bufp[0x2f] = 0xc2;				// 47: 39: 
		break;
	case 0x2b ... 0x3e:				// 2Bh - 3Eh Vendor-specific
		break;
	case 0x3f:							// 3Fh Return all Pages
		break;
	}

	return result;
}

// === 0xa3: GPCMD_SEND_KEY ===================================================
static int sr_gpcmd_send_key(const struct my_toc *toc, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return result;
}

// === 0xa4: GPCMD_REPORT_KEY =================================================
static int sr_gpcmd_report_key(const struct my_toc *toc, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return result;
}

// === 0xad: GPCMD_READ_DVD_STRUCTURE =========================================
static int sr_gpcmd_read_dvd_structure(const struct my_toc *toc, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return result;
}

// === 0xb9: GPCMD_READ_CD_MSF ================================================
static int sr_gpcmd_read_cd_msf(const struct my_toc *toc, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;
	loff_t lba0 = 0, lba1 = 0, blk = 0, len = 0;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	if (!toc->initial)
		return -ENOMEDIUM;

	lba0 = (loff_t) my_msf2lba(cmdp[3], cmdp[4], cmdp[5]);	// Starting Logical Block Address
	lba1 = (loff_t) my_msf2lba(cmdp[6], cmdp[7], cmdp[8]);	// Ending Logical Block Address
	len = lba1 - lba0 + 1;				// Transfer Length in Blocks

	switch (cmdp[9]) {
	case 0x58:
		blk = CD_FRAMESIZE_RAW0;
		break;
	case 0x78:
		blk = CD_FRAMESIZE_RAW1;
		break;
	case 0xf8:
		blk = CD_FRAMESIZE_RAW;
		break;
	default:
		blk = CD_FRAMESIZE;
		break;
	}

	switch (cmdp[10]) {
	case 0x00:
		break;
	case 0x01:
	case 0x04:
		blk += CD_FRAMESIZE_SUB;
		break;
	}

	lba0 *= blk;
	len *= blk;
	result = sr_do_read_media(toc, lba0, bufp, len);
	return result;
}

// === 0xbb: GPCMD_SET_SPEED ==================================================
static int sr_gpcmd_set_speed(const struct my_toc *toc, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return result;
}

// === 0xbe: GPCMD_READ_CD ====================================================
static int sr_gpcmd_read_cd(const struct my_toc *toc, const struct sg_io_hdr *io_hdr, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;
	loff_t lba = 0, blk = 0, len = 0;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	if (!toc->initial)
		return -ENOMEDIUM;

	lba = ((loff_t) cmdp[2] << 24) + ((loff_t) cmdp[3] << 16) + ((loff_t) cmdp[4] << 8) + ((loff_t) cmdp[5]);	// Starting Logical Block Address
	len = ((loff_t) cmdp[6] << 16) + ((loff_t) cmdp[7] << 8) + ((loff_t) cmdp[8]);	// Transfer Length in Blocks

	switch (cmdp[9]) {
	case 0x58:
		blk = CD_FRAMESIZE_RAW0;
		break;
	case 0x78:
		blk = CD_FRAMESIZE_RAW1;
		break;
	case 0xf8:
		blk = CD_FRAMESIZE_RAW;
		break;
	default:
		blk = CD_FRAMESIZE;
		break;
	}

	switch (cmdp[10]) {
	case 0x00:
		break;
	case 0x01:
	case 0x04:
		blk += CD_FRAMESIZE_SUB;
		break;
	}

	lba *= blk;
	len *= blk;
	result = sr_do_read_media(toc, lba, bufp, len);
	return result;
}

// ::: do command :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
int sr_do_load_media(struct my_toc *toc, const unsigned long arg)
{
	int result = 0;
	void __user *argp = (void __user *) arg;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	if (copy_from_user(toc, argp, sizeof(*toc)))
		return -EFAULT;
#ifdef DEBUG
	{
		struct cdrom_tochdr *thdr = &toc->tochdr;
		struct cdrom_tocentry *tent = toc->tocentry;
		int i;

		pr_devel(SR_DEV_NAME ": fcue: %s\n", toc->path_cue);
		pr_devel(SR_DEV_NAME ": fbin: %s\n", toc->path_bin);
		pr_devel(SR_DEV_NAME ": lout: %ld\n", toc->leadout);
		pr_devel(SR_DEV_NAME ": size: %lld\n", toc->size);
		pr_devel(SR_DEV_NAME ": init: %d\n", toc->initial);
		pr_devel(SR_DEV_NAME ": chag: %d\n", toc->mchange);
		pr_devel(SR_DEV_NAME ": trk0: %d\n", thdr->cdth_trk0);
		pr_devel(SR_DEV_NAME ": trk1: %d\n", thdr->cdth_trk1);
		for (i = thdr->cdth_trk0; i <= thdr->cdth_trk1; i++, tent++) {
			pr_devel(SR_DEV_NAME ": %02d : %02x : %02x : %02x : %02d:%02d.%02d : %02x\n", tent->cdte_track, tent->cdte_adr, tent->cdte_ctrl, tent->cdte_format, tent->cdte_addr.msf.minute, tent->cdte_addr.msf.second, tent->cdte_addr.msf.frame, tent->cdte_datamode);
		}
	}
#endif
	toc->initial = 1;
	toc->mchange = 1;

	return result;
}

// ============================================================================
int sr_do_read_media(const struct my_toc *toc, loff_t lba, unsigned char *bufp, loff_t len)
{
	ssize_t result = 0;
	struct file *file;
	loff_t pos = lba;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	if (!toc->initial)
		return -ENOMEDIUM;

//  pr_devel(SR_DEV_NAME ": %s: [%s]\n", __FUNCTION__, toc->path_bin);

	file = filp_open(toc->path_bin, O_RDONLY | O_LARGEFILE, 0);
	if (IS_ERR(file))
		return PTR_ERR(file);
#if LINUX_VERSION_CODE < KERNEL_VERSION(4, 14, 0)
	result = kernel_read(file, pos, bufp, len);
#else
	result = kernel_read(file, bufp, len, &pos);
#endif
	fput(file);

//	pr_devel(SR_DEV_NAME ": %s: lba: %lld: len: %lld: ret: %ld\n", __FUNCTION__, lba, len, result);

//	if (result == len)
		return 0;

//	return -EFAULT;
}

// ============================================================================
int sr_do_read_tochdr(const struct my_toc *toc, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;
	const struct cdrom_tochdr *tochdr = &toc->tochdr;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	if (!toc->initial)
		return -ENOMEDIUM;

	if (copy_to_user(bufp, tochdr, sizeof(*tochdr)))
		return -EFAULT;

	return result;
}

// ============================================================================
int sr_do_read_tocentry(const struct my_toc *toc, const unsigned char *cmdp, unsigned char *bufp)
{
	int result = 0;
	struct cdrom_tocentry *tocentryp;
	int n, track, format;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	if (!toc->initial)
		return -ENOMEDIUM;

	tocentryp = kzalloc(sizeof(*tocentryp), GFP_KERNEL);
	if (IS_ERR_OR_NULL(tocentryp))
		return PTR_ERR(tocentryp);

	if (copy_from_user(tocentryp, bufp, sizeof(*tocentryp))) {
		kfree(tocentryp);
		return -EFAULT;
	}

	track = tocentryp->cdte_track;
	format = tocentryp->cdte_format;

	if ((track != CDROM_LEADOUT) && (track < toc->tochdr.cdth_trk0 || track > toc->tochdr.cdth_trk1)) {
		kfree(tocentryp);
		return -EIO;
	}

	result = 0;
	if (track == CDROM_LEADOUT) {
		memcpy(tocentryp, &toc->tocentry[0], sizeof(*tocentryp));
		tocentryp->cdte_track = track;
		tocentryp->cdte_format = format;

		if (format != CDROM_MSF)
			tocentryp->cdte_addr.lba = toc->leadout;
		else
			my_lba2msf(toc->leadout, (int *) &tocentryp->cdte_addr.msf.minute, (int *) &tocentryp->cdte_addr.msf.second, (int *) &tocentryp->cdte_addr.msf.frame, 1);
	} else {
		for (n = 0; n < TRACK_MAX; n++) {
			if (toc->tocentry[n].cdte_track == track) {
				memcpy(tocentryp, &toc->tocentry[n], sizeof(*tocentryp));
				tocentryp->cdte_format = format;
				if (format != CDROM_MSF)
					tocentryp->cdte_addr.lba = my_msf2lba(toc->tocentry[n].cdte_addr.msf.minute, toc->tocentry[n].cdte_addr.msf.second, toc->tocentry[n].cdte_addr.msf.frame);
				break;
			}
		}
	}

	if (!result)
		if (copy_to_user(bufp, tocentryp, sizeof(*tocentryp)))
			result = -EFAULT;

	kfree(tocentryp);

	return result;
}

// ============================================================================
int sr_do_read_track_tocentry(const struct my_toc *toc, int trk, struct cdrom_tocentry *tentry)
{
	int result = 0;
	const struct cdrom_tochdr *thdr = &toc->tochdr;
	const struct cdrom_tocentry *tent = toc->tocentry;
	int i, n, trk0, trk1, m, s, f;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	if (!toc->initial)
		return -ENOMEDIUM;

	trk0 = thdr->cdth_trk0;
	trk1 = thdr->cdth_trk1;

	memcpy(tentry, tent, sizeof(*tentry));
	tentry->cdte_track = trk;
	tentry->cdte_format = CDROM_LBA;
	tentry->cdte_addr.lba = toc->leadout;

	for (i = trk0, n = 0; i <= trk1 && n < TRACK_MAX; i++, n++, tent++) {
		if (tent->cdte_track == trk) {
			memcpy(tentry, tent, sizeof(*tentry));
			if (tentry->cdte_format == CDROM_MSF) {
				m = tentry->cdte_addr.msf.minute;
				s = tentry->cdte_addr.msf.second;
				f = tentry->cdte_addr.msf.frame;
				tentry->cdte_addr.lba = my_msf2lba(m, s, f);
				tentry->cdte_format = CDROM_LBA;
			}
			return 0;
		}
	}

	return result;
}

// ============================================================================
int sr_do_gpcmd(struct my_toc *toc, struct scsi_cd *cd, struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	int result = 0;
	void __user *argp = (void __user *) arg;
	struct sg_io_hdr *io_hdr;
	unsigned char *cmdp, *bufp;
	ssize_t bsiz = 1024;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);

	io_hdr = kzalloc(sizeof(*io_hdr), GFP_KERNEL);
	if (IS_ERR_OR_NULL(io_hdr))
		return PTR_ERR(io_hdr);

	if (copy_from_user(io_hdr, argp, sizeof(*io_hdr))) {
		kfree(io_hdr);
		return -EFAULT;
	}

	if (io_hdr->interface_id != SG_INTERFACE_ID_ORIG) {
		kfree(io_hdr);
		return -ENOSYS;
	}
	// ------------------------------------------------------------------------
	if (io_hdr->dxfer_len) {
		switch (io_hdr->dxfer_direction) {
		default:
			kfree(io_hdr);
			return -EINVAL;
		case SG_DXFER_TO_DEV:
		case SG_DXFER_TO_FROM_DEV:
		case SG_DXFER_FROM_DEV:
			break;
		}
	}

	if (bsiz < io_hdr->dxfer_len)
		bsiz = io_hdr->dxfer_len;

	cmdp = kzalloc(io_hdr->cmd_len, GFP_KERNEL);
	if (IS_ERR_OR_NULL(cmdp)) {
		kfree(io_hdr);
		return PTR_ERR(cmdp);
	}

	bufp = kzalloc(bsiz, GFP_KERNEL);
	if (IS_ERR_OR_NULL(bufp)) {
		kfree(cmdp);
		kfree(io_hdr);
		return PTR_ERR(bufp);
	}

	if (copy_from_user(cmdp, io_hdr->cmdp, io_hdr->cmd_len)) {
		result = -EFAULT;
		goto exit;
	}

	if (copy_from_user(bufp, io_hdr->dxferp, io_hdr->dxfer_len)) {
		result = -EFAULT;
		goto exit;
	}
//  pr_devel(SR_DEV_NAME ": %s: %04x: %s\n", __FUNCTION__, cmdp[0], my_msg_packet_cmd(cmdp[0]));
//  pr_devel(SR_DEV_NAME ": %s:     : %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x                      ", __FUNCTION__, cmdp[0x00], cmdp[0x01], cmdp[0x02], cmdp[0x03], cmdp[0x04], cmdp[0x05], cmdp[0x06], cmdp[0x07], cmdp[0x08], cmdp[0x09], cmdp[0x0a], cmdp[0x0b]);
//  pr_devel(SR_DEV_NAME ": %s:     : %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x\n", __FUNCTION__, bufp[0x00], bufp[0x01], bufp[0x02], bufp[0x03], bufp[0x04], bufp[0x05], bufp[0x06], bufp[0x07], bufp[0x08], bufp[0x09], bufp[0x0a], bufp[0x0b], bufp[0x0c], bufp[0x0d], bufp[0x0e], bufp[0x0f]);
	result = -ENOSYS;
	switch (cmdp[0]) {
	default:
		pr_devel(SR_DEV_NAME ": %s: %04x: %s\n", __FUNCTION__, cmdp[0], my_msg_packet_cmd(cmdp[0]));
//      result = cdrom_ioctl(&cd->cdi, bdev, mode, cmd, arg);
//      result = scsi_cmd_ioctl(cd->disk->queue, cd->disk, mode, cmd, argp);
		break;
	case GPCMD_TEST_UNIT_READY:		// 0x00: 
		result = sr_gpcmd_test_unit_ready(toc, io_hdr, cmdp, bufp);
		break;
	case GPCMD_INQUIRY:				// 0x12: 
		result = sr_gpcmd_inquiry(toc, io_hdr, cmdp, bufp);
		break;
	case GPCMD_START_STOP_UNIT:		// 0x1b
		result = sr_gpcmd_start_stop_unit(toc, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_10:				// 0x28
		result = sr_gpcmd_read_10(toc, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_SUBCHANNEL:		// 0x42: 
		result = sr_gpcmd_read_subchannel(toc, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_TOC_PMA_ATIP:		// 0x43: 
		result = sr_gpcmd_read_toc_pma_atip(toc, io_hdr, cmdp, bufp);
		break;
	case GPCMD_PLAY_AUDIO_10:			// 0x45
		result = sr_gpcmd_play_audio_10(toc, io_hdr, cmdp, bufp);
		break;
	case GPCMD_PLAY_AUDIO_MSF:			// 0x47
		result = sr_gpcmd_play_audio_msf(toc, io_hdr, cmdp, bufp);
		break;
	case GPCMD_PAUSE_RESUME:			// 0x4b
		result = sr_gpcmd_pause_resume(toc, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_DISC_INFO:			// 0x51
		result = sr_gpcmd_read_disc_info(toc, io_hdr, cmdp, bufp);
		break;
	case GPCMD_MODE_SELECT_10:			// 0x55
		result = sr_gpcmd_mode_select_10(toc, io_hdr, cmdp, bufp);
		break;
	case GPCMD_MODE_SENSE_10:			// 0x5a
		result = sr_gpcmd_mode_sense_10(toc, io_hdr, cmdp, bufp);
		break;
	case GPCMD_SEND_KEY:				// 0xa3
		result = sr_gpcmd_send_key(toc, io_hdr, cmdp, bufp);
		break;
	case GPCMD_REPORT_KEY:				// 0xa4
		result = sr_gpcmd_report_key(toc, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_DVD_STRUCTURE:		// 0xad
		result = sr_gpcmd_read_dvd_structure(toc, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_CD_MSF:			// 0xb9: 
		result = sr_gpcmd_read_cd_msf(toc, io_hdr, cmdp, bufp);
		break;
	case GPCMD_SET_SPEED:				// 0xbb: 
		result = sr_gpcmd_set_speed(toc, io_hdr, cmdp, bufp);
		break;
	case GPCMD_READ_CD:				// 0xbe: 
		result = sr_gpcmd_read_cd(toc, io_hdr, cmdp, bufp);
		break;
	}
  exit:
	if (result >= 0 && io_hdr->dxfer_len) {
//      pr_devel(SR_DEV_NAME ": %s:     : %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x\n", __FUNCTION__, bufp[0x00], bufp[0x01], bufp[0x02], bufp[0x03], bufp[0x04], bufp[0x05], bufp[0x06], bufp[0x07], bufp[0x08], bufp[0x09], bufp[0x0a], bufp[0x0b], bufp[0x0c], bufp[0x0d], bufp[0x0e], bufp[0x0f]);
		if (copy_to_user(io_hdr->dxferp, bufp, io_hdr->dxfer_len))
			result = -EFAULT;
		if (copy_to_user(argp, io_hdr, sizeof(*io_hdr)))
			result = -EFAULT;
	}
	kfree(bufp);
	kfree(cmdp);
	// ------------------------------------------------------------------------
	kfree(io_hdr);
	return result;
}

// *** EOF ********************************************************************
