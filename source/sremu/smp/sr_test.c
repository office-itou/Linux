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
/* 23-28 */ unknown, "Define window parameters", "Read Capacity",
	unknown, unknown, "Read (10)",
/* 29-2d */ "Read Generation", "Write (10)", "Seek (10)", "Erase",
	"Read updated block",
/* 2e-31 */ "Write Verify", "Verify", "Search High", "Search Equal",
/* 32-34 */ "Search Low", "Set Limits", "Prefetch or Read Position",
/* 35-37 */ "Synchronize Cache", "Lock/Unlock Cache", "Read Defect Data",
/* 38-3c */ "Medium Scan", "Compare", "Copy Verify", "Write Buffer",
	"Read Buffer",
/* 3d-3f */ "Update Block", "Read Long", "Write Long",
};

static const char *group_2_commands[] = {
/* 40-41 */ "Change Definition", "Write Same",
/* 42-44 */ "Read sub-channel", "Read TOC", "Read header",
/* 45-47 */ "Play audio (10)", "Get configuration", "Play audio msf",
/* 48 */ "Play audio track/index",
/* 49-4a */ "Play track relative (10)", "Get event/status notification",
/* 4b */ "Pause/resume",
/* 4c-4f */ "Log Select", "Log Sense", "Stop play/scan", unknown,
/* 50-55 */ unknown, "Read disc information", "Read track information",
	"Reserve track", "Send OPC information", "Mode Select (10)",
/* 56-5b */ unknown, unknown, "Repair track", unknown, "Mode Sense (10)",
	"Close track/session",
/* 5c-5f */ "Read buffer capacity", "Send cue sheet", unknown,
};


/* The following are 12 byte commands in group 5 */
static const char *group_5_commands[] = {
/* a0-a5 */ unknown, "Blank", unknown, "Send key", "Report key",
	"Move medium/play audio(12)",
/* a6-a9 */ "Exchange medium", "Set read ahead", "Read(12)", "Play track relative(12)",
/* aa-ae */ "Write(12)", "Read media s/n", "Erase(12)", "Read disc structure",
	"Write and verify(12)",
/* af-b1 */ "Verify(12)", "Search data high(12)", "Search data equal(12)",
/* b2-b4 */ "Search data low(12)", "Set limits(12)", unknown,
/* b5-b6 */ "Request volume element address", "Send volume tag",
/* b7-b9 */ "Read defect data(12)", "Read element status", "Read CD MSF",
/* ba-bf */ unknown, "Set CD speed", unknown, "Mechanism status", "Read CD",
	"Send disc structure",
};

static const char **commands[] = {
	group_0_commands, group_1_commands, group_2_commands,
	(const char **) RESERVED_GROUP, (const char **) RESERVED_GROUP,
	group_5_commands, (const char **) VENDOR_GROUP,
	(const char **) VENDOR_GROUP
};

static const char reserved[] = "RESERVED";
static const char vendor[] = "VENDOR SPECIFIC";

static struct ScsiIfImpl {
	char *filename;						// user provided device name
	int fd;

	unsigned char sense_buffer[SG_MAX_SENSE];
	unsigned char sense_buffer_length;

	unsigned char last_sense_buffer_length;
	unsigned char last_command_status;

	int timeout_ms;
} impl;

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

int sendCmd(const unsigned char *cmd, int cmdLen, const unsigned char *dataOut, int dataOutLen, unsigned char *dataIn, int dataInLen)
{
	int status;
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

	printf("%s: Initiating SCSI command %s%s\n", impl.filename, sg_strcommand(cmd[0]), sg_strcmdopts(cmd));

	if (ioctl(impl.fd, SG_IO, &io_hdr) < 0) {
		perror("ioctl");
		return 1;
	}

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
	int i;

	printf("%s: addr: ", impl.filename);
	for (i = 0; i < dataLen + 2; i++)
		printf("%02x ", i);
	printf("\n");

	printf("%s: data: ", impl.filename);
	for (i = 0; i < dataLen + 2; i++, data++)
		printf("%02x ", *data);
	printf("\n");
}

int main(int argc, char *argv[])
{
	unsigned char cmd[BUFSIZ], data[BUFSIZ];
	unsigned long dataLen = 0, lba = 0;
	int ret, i, sessionNr;

	// ------------------------------------------------------------------------
	impl.filename = argv[1];
	impl.sense_buffer_length = SG_MAX_SENSE;
	impl.timeout_ms = CDRDAO_DEFAULT_TIMEOUT;
	// ------------------------------------------------------------------------
	impl.fd = open(impl.filename, O_RDWR);
	if (impl.fd < 0) {
		perror("open");
		return -errno;
	}
	// ------------------------------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	cmd[0] = 0x01;						// unknoun
	if (!(ret = sendCmd(cmd, 6, NULL, 0, NULL, 0)))
		printf("%s: addr: %02x\n", impl.filename, ret);
	// ------------------------------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 44;
	cmd[0] = 0x12;						// Inquiry
	cmd[4] = dataLen;
	if (!sendCmd(cmd, 6, NULL, 0, data, dataLen))
		dumpPrint(data[4] + 3, data);
	// ------------------------------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 48;
	cmd[0] = 0x5a;						// Mode Sense 10
	cmd[2] = 0x2a;
	cmd[7] = dataLen >> 8;
	cmd[8] = dataLen;
	if (!sendCmd(cmd, 10, NULL, 0, data, dataLen))
		dumpPrint(((int) data[0] << 8) + (int) data[1], data);
	// ------------------------------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	cmd[0] = 0x00;						// Test Unit Ready
	if (!(ret = sendCmd(cmd, 6, NULL, 0, NULL, 0)))
		printf("%s: addr: %02x\n", impl.filename, ret);
	// ------------------------------------------------------------------------
	memset(cmd, 0, sizeof(cmd));
	memset(data, 0, sizeof(data));
	dataLen = 34;
	cmd[0] = 0x51;						// Read Disc Info
	cmd[7] = dataLen >> 8;
	cmd[8] = dataLen;
	if (!sendCmd(cmd, 10, NULL, 0, data, dataLen))
		dumpPrint(((int) data[0] << 8) + (int) data[1], data);
	// ------------------------------------------------------------------------
	for (i = 0; i <= 5; i++) {
		memset(cmd, 0, sizeof(cmd));
		memset(data, 0, sizeof(data));
		dataLen = 60;
		cmd[0] = 0x43;					// Read Table of Contents
		cmd[2] = i;
		cmd[7] = dataLen >> 8;
		cmd[8] = dataLen;
		if (!sendCmd(cmd, 10, NULL, 0, data, dataLen))
			dumpPrint(((int) data[0] << 8) + (int) data[1], data);
	}
	// ------------------------------------------------------------------------
	close(impl.fd);
	return 0;
}
