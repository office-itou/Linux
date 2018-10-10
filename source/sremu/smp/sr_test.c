#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <assert.h>
#include <sys/ioctl.h>
#include <glob.h>
#include <asm/param.h>
#include <scsi/scsi.h>
#include <scsi/sg.h>
#include <linux/cdrom.h>				// struct cdrom_device_ops, ...

#ifndef SG_MAX_SENSE
#define SG_MAX_SENSE			16
#endif

#define CDRDAO_DEFAULT_TIMEOUT	30000

#define group(opcode)			(((opcode) >> 5) & 7)

#define RESERVED_GROUP			0
#define VENDOR_GROUP			1

static const char unknown[] = "UNKNOWN";

static const char *group_0_commands[] = {
/* 00-03 */ "Test Unit Ready", "Rezero Unit", unknown, "Request Sense",
/* 04-07 */ "Format Unit", "Read Block Limits", unknown, "Reasssign Blocks",
/* 08-0d */ "Read (6)", unknown, "Write (6)", "Seek (6)", unknown, unknown,
/* 0e-12 */ unknown, "Read Reverse", "Write Filemarks", "Space", "Inquiry",
/* 13-16 */ "Verify", "Recover Buffered Data", "Mode Select", "Reserve",
/* 17-1b */ "Release", "Copy", "Erase", "Mode Sense", "Start/Stop Unit",
/* 1c-1d */ "Receive Diagnostic", "Send Diagnostic",
/* 1e-1f */ "Prevent/Allow Medium Removal", unknown,
};

static const char *group_1_commands[] = {
/* 20-22 */ unknown, unknown, unknown,
/* 23-28 */ unknown, "Define window parameters", "Read Capacity", unknown, unknown, "Read (10)",
/* 29-2d */ "Read Generation", "Write (10)", "Seek (10)", "Erase", "Read updated block",
/* 2e-31 */ "Write Verify", "Verify", "Search High", "Search Equal",
/* 32-34 */ "Search Low", "Set Limits", "Prefetch or Read Position",
/* 35-37 */ "Synchronize Cache", "Lock/Unlock Cache", "Read Defect Data",
/* 38-3c */ "Medium Scan", "Compare", "Copy Verify", "Write Buffer", "Read Buffer",
/* 3d-3f */ "Update Block", "Read Long", "Write Long",
};

static const char *group_2_commands[] = {
/* 40-41 */ "Change Definition", "Write Same",
/* 42-44 */ "Read sub-channel", "Read TOC", "Read header",
/* 45-47 */ "Play audio (10)", "Get configuration", "Play audio msf",
/* 48    */ "Play audio track/index",
/* 49-4a */ "Play track relative (10)", "Get event/status notification",
/* 4b    */ "Pause/resume",
/* 4c-4f */ "Log Select", "Log Sense", "Stop play/scan", unknown,
/* 50-55 */ unknown, "Read disc information", "Read track information", "Reserve track", "Send OPC information", "Mode Select (10)",
/* 56-5b */ unknown, unknown, "Repair track", unknown, "Mode Sense (10)", "Close track/session",
/* 5c-5f */ "Read buffer capacity", "Send cue sheet", unknown,
};

/* The following are 12 byte commands in group 5 */
static const char *group_5_commands[] = {
/* a0-a5 */ unknown, "Blank", unknown, "Send key", "Report key", "Move medium/play audio(12)",
/* a6-a9 */ "Exchange medium", "Set read ahead", "Read(12)", "Play track relative(12)",
/* aa-ae */ "Write(12)", "Read media s/n", "Erase(12)", "Read disc structure", "Write and verify(12)",
/* af-b1 */ "Verify(12)", "Search data high(12)", "Search data equal(12)",
/* b2-b4 */ "Search data low(12)", "Set limits(12)", unknown,
/* b5-b6 */ "Request volume element address", "Send volume tag",
/* b7-b9 */ "Read defect data(12)", "Read element status", "Read CD MSF",
/* ba-bf */ unknown, "Set CD speed", unknown, "Mechanism status", "Read CD", "Send disc structure",
};

static const char **commands[] = {
	group_0_commands,
	group_1_commands,
	group_2_commands,
	(const char **) RESERVED_GROUP,
	(const char **) RESERVED_GROUP,
	group_5_commands,
	(const char **) VENDOR_GROUP,
	(const char **) VENDOR_GROUP
};

static struct ScsiIfImpl {
	char *filename;						// user provided device name
	int fd;
	unsigned char sense_buffer[SG_MAX_SENSE];
	unsigned char sense_buffer_length;
	unsigned char last_sense_buffer_length;
	unsigned char last_command_status;
	int timeout_ms;
} impl;

#define TRACK_MAX			99
int leadout;							// last frame number (set track = CDROM_LEADOUT)
struct cdrom_tochdr tochdr;
struct cdrom_tocentry tocentry[TRACK_MAX];

long Msf(int min, int sec, int frac)
{
	return min * 4500 + sec * 75 + frac;
}

const char *sg_strcommand(unsigned char opcode)
{
	static char buf[8];
	const char **table = commands[group(opcode)];

	switch ((unsigned long) table) {
	case RESERVED_GROUP:
	case VENDOR_GROUP:
		break;
	default:
		if (table[opcode & 0x1f] != unknown)
			return table[opcode & 0x1f];
		break;
	}
	sprintf(buf, "0x%02x", opcode);
	return buf;
}

const char *sg_strcmdopts(const unsigned char *cdb)
{
	static char buf[32];

	switch (cdb[0]) {
	case 0x1a:
	case 0x5a:
		snprintf(buf, sizeof(buf), " (page %02x.%02x len %d)", cdb[2] & 0x3f, cdb[3], cdb[8]);
		return buf;
	case 0x43:
		snprintf(buf, sizeof(buf), " (fmt %d num %d)", cdb[2] & 0x0f, cdb[6]);
		return buf;
	default:
		return "";
	}
}

int sendCmd(const unsigned char *cmd, int cmdLen, const unsigned char *dataOut, int dataOutLen, unsigned char *dataIn, int dataInLen, int disp)
{
	sg_io_hdr_t io_hdr;

	memset(&io_hdr, 0, sizeof(io_hdr));

	// Check SCSI cdb length.
	assert(cmdLen >= 0 && cmdLen <= 16);
	// Can't both input and output data.
	assert(!(dataOut && dataIn));

	io_hdr.interface_id = 'S';
	io_hdr.cmd_len = cmdLen;
	io_hdr.cmdp = (unsigned char *) cmd;
	io_hdr.timeout = impl.timeout_ms;
	io_hdr.sbp = impl.sense_buffer;
	io_hdr.mx_sb_len = impl.sense_buffer_length;
	io_hdr.flags = 1;

	if (dataOut) {
		io_hdr.dxferp = (void *) dataOut;
		io_hdr.dxfer_len = dataOutLen;
		io_hdr.dxfer_direction = SG_DXFER_TO_DEV;
	} else if (dataIn) {
		io_hdr.dxferp = dataIn;
		io_hdr.dxfer_len = dataInLen;
		io_hdr.dxfer_direction = SG_DXFER_FROM_DEV;
	}

	if (disp)
		printf("%s: Initiating SCSI command %s%s\n", impl.filename, sg_strcommand(cmd[0]), sg_strcmdopts(cmd));

	if (ioctl(impl.fd, SG_IO, &io_hdr) < 0) {
		printf("%s: SG_IO ioctl failed: %s\n", impl.filename, strerror(errno));
		return 1;
	}

	if (disp)
		printf("%s: SCSI command %s (0x%02x) executed in %u ms, status=%d\n", impl.filename, sg_strcommand(cmd[0]), cmd[0], io_hdr.duration, io_hdr.status);

	impl.last_sense_buffer_length = io_hdr.sb_len_wr;
	impl.last_command_status = io_hdr.status;

	if (io_hdr.status) {
		if (io_hdr.sb_len_wr > 0)
			return 2;
		else
			return 1;
	}

	return 0;
}

void dumpPrint(unsigned long dataLen, const unsigned char *data)
{
	unsigned long i;

	printf("%s: addr: ", impl.filename);
	for (i = 0; i < dataLen + 2; i++)
		printf("%02lx ", (i & 0xff));
	printf("\n");

	printf("%s: data: ", impl.filename);
	for (i = 0; i < dataLen + 2; i++, data++)
		printf("%02x ", *data);
	printf("\n");
}

int main(int argc, char *argv[])
{
	char *raw_filename = NULL;
	unsigned char cmd[12], data[10240];
	unsigned long dataLen = 0, sect = 0, lout = 0, trk = 0, idx = 0, n = 0;
	int sg_version = 0;
	int requestedSize, maxTransferLength;
	int ret, fd, i, o;

	// ------------------------------------------------------------------------
	(void) trk;
	(void) idx;
	// ------------------------------------------------------------------------
	if (argc < 2 || argc > 3) {
		printf("%s [device] [raw file]\n", argv[0]);
		return 1;
	}
	impl.filename = argv[1];
	impl.sense_buffer_length = SG_MAX_SENSE;
	impl.timeout_ms = CDRDAO_DEFAULT_TIMEOUT;
	if (argv[2] != NULL)
		raw_filename = argv[2];

	// ------------------------------------------------------------------------
	impl.fd = open(impl.filename, O_RDWR | O_NONBLOCK);
	if (impl.fd < 0) {
		ret = errno;
		printf("%s: open failed: %s\n", impl.filename, strerror(errno));
		return -ret;
	}
	// ------------------------------------------------------------------------
	if (ioctl(impl.fd, SG_GET_VERSION_NUM, &sg_version) < 0)
		printf("%s: SG_GET_VERSION_NUM ioctl failed: %s\n", impl.filename, strerror(errno));
	printf("%s: Detected SG driver version: %d.%d.%d\n", impl.filename, sg_version / 10000, (sg_version / 100) % 100, sg_version % 100);
	if (sg_version < 30000)
		printf("%s: SG interface under 3.0 not supported.\n", impl.filename);

	// ------------------------------------------------------------------------
	requestedSize = 64 * 1024;
	if (ioctl(impl.fd, SG_SET_RESERVED_SIZE, &requestedSize) < 0)
		printf("%s: SG_SET_RESERVED_SIZE ioctl failed: %s\n", impl.filename, strerror(errno));
	if (ioctl(impl.fd, SG_GET_RESERVED_SIZE, &maxTransferLength) < 0)
		printf("%s: SG_GET_RESERVED_SIZE ioctl failed: %s\n", impl.filename, strerror(errno));
	printf("%s: SG: Maximum transfer length: %d\n", impl.filename, maxTransferLength);

	// --- Inquiry ------------------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 0xfe;
	cmd[0] = 0x12;						// Inquiry
	cmd[1] = 0x00;						// 
	cmd[4] = dataLen;
	if (!sendCmd(cmd, 6, NULL, 0, data, dataLen, 1)) {
		dumpPrint(data[4] + 3, data);
		printf("%s: %8.8s : %16.16s : %4.4s\n", impl.filename, &data[8], &data[16], &data[32]);
	}
	// --- Inquiry ------------------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 0xfe;
	cmd[0] = 0x12;						// Inquiry
	cmd[1] = 0x01;						// 
	cmd[4] = dataLen;
	if (!sendCmd(cmd, 6, NULL, 0, data, dataLen, 1)) {
		dumpPrint(data[4] + 3, data);
		printf("%s: %8.8s : %16.16s : %4.4s\n", impl.filename, &data[8], &data[16], &data[32]);
	}
	// --- Inquiry ------------------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 0x2c;
	cmd[0] = 0x12;						// Inquiry
	cmd[1] = 0x00;						// 
	cmd[4] = dataLen;
	if (!sendCmd(cmd, 6, NULL, 0, data, dataLen, 1)) {
		dumpPrint(data[4] + 3, data);
		printf("%s: %8.8s : %16.16s : %4.4s\n", impl.filename, &data[8], &data[16], &data[32]);
	}
	// --- Mode Sense 10 ------------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 0x08;
	cmd[0] = 0x5a;						// Mode Sense 10
	cmd[2] = 0x2a;						// C/DVD Capabilities & Mechanical Status
	cmd[7] = dataLen >> 8;
	cmd[8] = dataLen;
	if (!sendCmd(cmd, 10, NULL, 0, data, dataLen, 1))
		dumpPrint(((unsigned int) data[0] << 8) + (unsigned int) data[1], data);

	// --- Mode Sense 10 ------------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 0x30;
	cmd[0] = 0x5a;						// Mode Sense 10
	cmd[2] = 0x2a;						// C/DVD Capabilities & Mechanical Status
	cmd[7] = dataLen >> 8;
	cmd[8] = dataLen;
	if (!sendCmd(cmd, 10, NULL, 0, data, dataLen, 1))
		dumpPrint(((unsigned int) data[0] << 8) + (unsigned int) data[1], data);

	// --- unknoun ------------------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	cmd[0] = 0x01;						// unknoun
	if (!(ret = sendCmd(cmd, 6, NULL, 0, NULL, 0, 1)))
		printf("%s: return code  : %02x\n", impl.filename, ret);

	// --- unknoun ------------------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	cmd[0] = 0x01;						// unknoun
	if (!(ret = sendCmd(cmd, 6, NULL, 0, NULL, 0, 1)))
		printf("%s: return code  : %02x\n", impl.filename, ret);

	// --- Test Unit Ready ----------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	cmd[0] = 0x00;						// Test Unit Ready
	if (!(ret = sendCmd(cmd, 6, NULL, 0, NULL, 0, 1)))
		printf("%s: return code  : %02x\n", impl.filename, ret);

	// --- unknoun ------------------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	cmd[0] = 0x01;						// unknoun
	if (!(ret = sendCmd(cmd, 6, NULL, 0, NULL, 0, 1)))
		printf("%s: return code  : %02x\n", impl.filename, ret);

	// --- unknoun ------------------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	cmd[0] = 0x01;						// unknoun
	if (!(ret = sendCmd(cmd, 6, NULL, 0, NULL, 0, 1)))
		printf("%s: return code  : %02x\n", impl.filename, ret);

	// --- Read Disc Info -----------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 0x22;
	cmd[0] = 0x51;						// Read Disc Info
	cmd[7] = dataLen >> 8;
	cmd[8] = dataLen;
	if (!sendCmd(cmd, 10, NULL, 0, data, dataLen, 1))
		dumpPrint(((unsigned int) data[0] << 8) + (unsigned int) data[1], data);

	// ---- Read Table of Contents [0x01] -------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 0x0c;
	cmd[0] = 0x43;						// Read Table of Contents
	cmd[2] = 0x01;						// Session Information
	cmd[6] = 0;							// Track / Session Number
	cmd[7] = dataLen >> 8;
	cmd[8] = dataLen;
	if (!sendCmd(cmd, 10, NULL, 0, data, dataLen, 1)) {
		dumpPrint(((unsigned int) data[0] << 8) + (unsigned int) data[1], data);
		//  4: Start Address of First Track in Last Session
		printf("%s: Last Session : %ld\n", impl.filename, ((unsigned long) data[8] << 24) + ((unsigned long) data[9] << 16) + ((unsigned long) data[10] << 8) + (unsigned long) data[11]);
	}
	// ---- Read Table of Contents [0x04] -------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 0x1c;
	cmd[0] = 0x43;						// Read Table of Contents
	cmd[2] = 0x04;						// ATIP
	cmd[6] = 0;							// Track / Session Number
	cmd[7] = dataLen >> 8;
	cmd[8] = dataLen;
	if (!sendCmd(cmd, 10, NULL, 0, data, dataLen, 1))
		dumpPrint(((unsigned int) data[0] << 8) + (unsigned int) data[1], data);

	// --- Read Disc Info -----------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 0x22;
	cmd[0] = 0x51;						// Read Disc Info
	cmd[7] = dataLen >> 8;
	cmd[8] = dataLen;
	if (!sendCmd(cmd, 10, NULL, 0, data, dataLen, 1))
		dumpPrint(((unsigned int) data[0] << 8) + (unsigned int) data[1], data);

	// ---- Read Table of Contents [0x01] -------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 0x0c;
	cmd[0] = 0x43;						// Read Table of Contents
	cmd[2] = 0x01;						// Session Information
	cmd[6] = 0;							// Track / Session Number
	cmd[7] = dataLen >> 8;
	cmd[8] = dataLen;
	if (!sendCmd(cmd, 10, NULL, 0, data, dataLen, 1)) {
		dumpPrint(((unsigned int) data[0] << 8) + (unsigned int) data[1], data);
		//  4: Start Address of First Track in Last Session
		printf("%s: Last Session : %ld\n", impl.filename, ((unsigned long) data[8] << 24) + ((unsigned long) data[9] << 16) + ((unsigned long) data[10] << 8) + (unsigned long) data[11]);
	}
	// ---- Read Table of Contents [0x04] -------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 0x1c;
	cmd[0] = 0x43;						// Read Table of Contents
	cmd[2] = 0x04;						// ATIP
	cmd[6] = 0;							// Track / Session Number
	cmd[7] = dataLen >> 8;
	cmd[8] = dataLen;
	if (!sendCmd(cmd, 10, NULL, 0, data, dataLen, 1))
		dumpPrint(((unsigned int) data[0] << 8) + (unsigned int) data[1], data);

	// ---- Read Table of Contents [0x00] -------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 0x04;
	cmd[0] = 0x43;						// Read Table of Contents
	cmd[2] = 0x00;						// TOC
	cmd[6] = 0;							// Track / Session Number
	cmd[7] = dataLen >> 8;
	cmd[8] = dataLen;
	if (!sendCmd(cmd, 10, NULL, 0, data, dataLen, 1)) {
		dataLen = ((unsigned int) data[0] << 8) + (unsigned int) data[1];
		n = dataLen + 2;
		dumpPrint(dataLen, data);
		printf("%s: First Track  : %d\n", impl.filename, data[2]);
		printf("%s: Last Track   : %d\n", impl.filename, data[3]);
		printf("%s: Last Session : %ld\n", impl.filename, ((unsigned long) data[n - 4] << 24) + ((unsigned long) data[n - 3] << 16) + ((unsigned long) data[n - 2] << 8) + (unsigned long) data[n - 1]);
		for (i = 0, o = 4; i < dataLen; i += 8, o += 8) {
			if (data[2 + o] < 100)
				printf("%s: Track, Addr  : %02d, %6ld\n", impl.filename, data[2 + o], ((unsigned long) data[4 + o] << 24) + ((unsigned long) data[5 + o] << 16) + ((unsigned long) data[6 + o] << 8) + (unsigned long) data[7 + o]);
			else
				printf("%s: Track, Addr  : %02x, %6ld\n", impl.filename, data[2 + o], ((unsigned long) data[4 + o] << 24) + ((unsigned long) data[5 + o] << 16) + ((unsigned long) data[6 + o] << 8) + (unsigned long) data[7 + o]);
		}
	}
	// ---- Read Table of Contents [0x00] -------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 0x24;
	cmd[0] = 0x43;						// Read Table of Contents
	cmd[2] = 0x00;						// TOC
	cmd[6] = 0;							// Track / Session Number
	cmd[7] = dataLen >> 8;
	cmd[8] = dataLen;
	if (!sendCmd(cmd, 10, NULL, 0, data, dataLen, 1)) {
		dataLen = ((unsigned int) data[0] << 8) + (unsigned int) data[1];
		n = dataLen + 2;
		lout = ((unsigned long) data[n - 4] << 24) + ((unsigned long) data[n - 3] << 16) + ((unsigned long) data[n - 2] << 8) + (unsigned long) data[n - 1];
		dumpPrint(dataLen, data);
		printf("%s: First Track  : %d\n", impl.filename, data[2]);
		printf("%s: Last Track   : %d\n", impl.filename, data[3]);
		printf("%s: Last Session : %ld\n", impl.filename, lout);
		for (i = 0, o = 4; i < dataLen; i += 8, o += 8) {
			if (data[2 + o] < 100)
				printf("%s: Track, Addr  : %02d, %6ld\n", impl.filename, data[2 + o], ((unsigned long) data[4 + o] << 24) + ((unsigned long) data[5 + o] << 16) + ((unsigned long) data[6 + o] << 8) + (unsigned long) data[7 + o]);
			else
				printf("%s: Track, Addr  : %02x, %6ld\n", impl.filename, data[2 + o], ((unsigned long) data[4 + o] << 24) + ((unsigned long) data[5 + o] << 16) + ((unsigned long) data[6 + o] << 8) + (unsigned long) data[7 + o]);
		}
	}
	// ---- Read Table of Contents [0x02] -------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 0x04;
	cmd[0] = 0x43;						// Read Table of Contents
	cmd[2] = 0x02;						// Full TOC
	cmd[6] = 0;							// Track / Session Number
	cmd[7] = dataLen >> 8;
	cmd[8] = dataLen;
	if (!sendCmd(cmd, 10, NULL, 0, data, dataLen, 1))
		dumpPrint(((unsigned int) data[0] << 8) + (unsigned int) data[1], data);

	// ---- Read Table of Contents [0x02] -------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 0x46;
	cmd[0] = 0x43;						// Read Table of Contents
	cmd[2] = 0x02;						// Full TOC
	cmd[6] = 0;							// Track / Session Number
	cmd[7] = dataLen >> 8;
	cmd[8] = dataLen;
	if (!sendCmd(cmd, 10, NULL, 0, data, dataLen, 1))
		dumpPrint(((unsigned int) data[0] << 8) + (unsigned int) data[1], data);

	// ---- Read CD -----------------------------------------------------------
	if (raw_filename != NULL) {
		fd = open(raw_filename, O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
		if (fd < 0) {
			printf("%s: open failed: %s\n", impl.filename, strerror(errno));
		} else {
			memset(cmd, 0, sizeof(cmd));
			memset(data, 0, sizeof(data));
			cmd[0] = 0xbb;				// SET CD SPEED
			cmd[2] = 0xff;				// Logical unit Read Speed (kBytes/sec)
			cmd[3] = 0xff;
			cmd[4] = 0xff;				// Logical unit Write Speed (kBytes/sec)
			cmd[5] = 0xff;
			if (!sendCmd(cmd, 12, NULL, 0, data, dataLen, 1)) {
				dataLen = 0x01;
				for (sect = 0; sect < lout; sect++) {
					memset(cmd, 0, sizeof(cmd));
					memset(data, 0, sizeof(data));
					cmd[0] = 0xbe;		// Read CD
					cmd[1] = 0x00;		// Expected Sector Type
					cmd[2] = sect >> 24;	// Starting Logical Block Address
					cmd[3] = sect >> 16;
					cmd[4] = sect >> 8;
					cmd[5] = sect;
					cmd[6] = dataLen >> 16;	// Transfer Length in Blocks
					cmd[7] = dataLen >> 8;
					cmd[8] = dataLen;
					cmd[9] = 0xf8;		// Header(s) Code | Error Flag(s)
					cmd[10] = 0x02;		// Sub-Channel Data Selection Bits
					if (!sendCmd(cmd, 12, NULL, 0, data, dataLen, 0)) {
//                      dumpPrint(32, data);
						if (write(fd, data, 2352) < 0) {
							ret = errno;
							printf("%s: write failed: %s\n", impl.filename, strerror(errno));
							break;
						}
					} else {
						printf("%s: break: %ld/%ld\n", impl.filename, sect, lout);
						break;
					}
				}
			}
			close(fd);
		}
	}
	// ---- Read Table of Contents [0x05] -------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 0x04;
	cmd[0] = 0x43;						// Read Table of Contents
	cmd[2] = 0x05;						// CD-Text
	cmd[7] = dataLen >> 8;
	cmd[8] = dataLen;
	if (!sendCmd(cmd, 10, NULL, 0, data, dataLen, 1))
		dumpPrint(((unsigned int) data[0] << 8) + (unsigned int) data[1], data);

	// --- Read Subchannel ----------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 0x18;
	cmd[0] = 0x42;						// Read Subchannel
	cmd[2] = 0x40;						// SubQ
	cmd[3] = 0x02;						// Sub-channel Data Format: Media catalogue number
	cmd[7] = dataLen >> 8;
	cmd[8] = dataLen;
	if (!sendCmd(cmd, 10, NULL, 0, data, dataLen, 1))
		dumpPrint(((unsigned int) data[0] << 8) + (unsigned int) data[1], data);

	// --- unknoun ------------------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	cmd[0] = 0x01;						// unknoun
	if (!(ret = sendCmd(cmd, 6, NULL, 0, NULL, 0, 1)))
		printf("%s: return code  : %02x\n", impl.filename, ret);

	// ------------------------------------------------------------------------
	close(impl.fd);
	return 0;
}
