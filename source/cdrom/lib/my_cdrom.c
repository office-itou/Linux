// ****************************************************************************
// my cdrom
// ****************************************************************************

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#define NDEBUG

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#ifndef MODULE
#include <errno.h>						// errno
#include <stdio.h>						// fprintf,perror
#include <string.h>						// memset,strncpy,strlen,strchr,strstr
#include <stdlib.h>						// free
#include <fcntl.h>						// For O_* constants
#include <sys/stat.h>					// For mode constants
#endif							// MODULE
#include "my_cdrom.h"					// my cdrom's header

// ::: my_main.c ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
void my_lba2msf(int lba, int *m, int *s, int *f, int o)
{
	if (o)
		lba += CD_MSF_OFFSET;
	lba &= 0xffffff;					// negative lbas use only 24 bits
	*m = lba / (CD_SECS * CD_FRAMES);
	lba %= (CD_SECS * CD_FRAMES);
	*s = lba / CD_FRAMES;
	*f = lba % CD_FRAMES;
}

// ============================================================================
int my_msf2lba(int m, int s, int f)
{
	return (((m * CD_SECS) + s) * CD_FRAMES + f);
}

// ============================================================================
#ifndef MODULE
int my_msf2frame(const char *msf, int *m, int *s, int *f)
{
	char buf[BUFF_MAX];					// work
	char *p = buf, *t;					// time (string)

	// ------------------------------------------------------------------------
	*m = 0;								// min
	*s = 0;								// sec
	*f = 0;								// frame
	// ------------------------------------------------------------------------
	strncpy(p, msf, sizeof(buf));
	// --- min ----------------------------------------------------------------
	if ((t = strchr(p, ':')) == NULL)
		return -1;
	*t = '\0';
	*m = strtol(p, NULL, 10);
	// --- sec ----------------------------------------------------------------
	p = t + 1;
	if ((t = strchr(p, ':')) == NULL)
		return -1;
	*t = '\0';
	*s = strtol(p, NULL, 10);
	// --- frame --------------------------------------------------------------
	p = t + 1;
	*f = strtol(p, NULL, 10);
	// ------------------------------------------------------------------------
	return my_msf2lba(*m, *s, *f);
}
#endif							// MODULE

// ============================================================================
#ifndef MODULE
int my_read_toc(struct my_toc *toc)
{
	int err = 0, ret = 0;				// return code
	int fd;								// file descriptor
	char pathname[PATH_MAX];			// cue file name
	ssize_t len;						// return value (length or error)
	char buf[BUFF_MAX];					// read data
	off_t offset = 0;					// offset (from the start of the file)
	char *p, *s, *t;					// work
	int n = -1, min, sec, frm, lba;		// work
	char dname[NAME_MAX];				// work directory name
	char fname[NAME_MAX];				// work file name
	long long size;						// work file size

	// ------------------------------------------------------------------------
	if (realpath(toc->path_cue, pathname) == NULL)
		return -my_perror(errno, "error: %s: %s: %s\n", __FUNCTION__, "realpath", toc->path_cue);
	memset(toc, 0, sizeof(struct my_toc));
	strncpy(toc->path_cue, pathname, sizeof(toc->path_cue));
	my_dirname(pathname, dname, sizeof(dname), NULL, 0);
	// ------------------------------------------------------------------------
	if ((fd = my_open(pathname, O_RDONLY, 0)) < 0)
		return fd;
	// ------------------------------------------------------------------------
	while (1) {
		memset(buf, 0, sizeof(buf));
		len = my_pread(fd, buf, sizeof(buf) - 1, offset);
		if (!len)						// file end
			break;
		if (len < 0) {					// read error
			err = len;
			break;
		}
		if ((p = strchr(buf, '\n')) != NULL)
			*(p + 1) = '\0';
		offset += strlen(buf);
		// --------------------------------------------------------------------
		while ((p = strchr(buf, '\r')) || (p = strchr(buf, '\n')))
			*p = '\0';
		// "FILE",bin file name,file type -------------------------------------
		if ((p = strstr(buf, "FILE")) != NULL) {
			if ((s = strchr(p, '"')) != NULL && (t = strchr((s + 1), '"')) != NULL) {
				*t = '\0';
				if ((ret = my_sjis2utf8((s + 1), fname, sizeof(fname))) < 0) {
					err = ret;
					break;
				}
				snprintf(toc->path_bin, sizeof(toc->path_bin), "%s/%s", dname, fname);
				if ((size = my_stat(toc->path_bin)) < 0) {
					err = size;
					break;
				}
				toc->size = size;
				toc->leadout = size / CD_FRAMESIZE_RAW;
			}
			continue;
		}
		// "TRACK",track number (string/numeric-1) ----------------------------
		if ((p = strstr(buf, "TRACK")) != NULL) {
			if ((s = strchr(p, ' ')) != NULL && (t = strchr((s + 1), ' ')) != NULL) {
				*t = '\0';
				n++;
				if (n >= 0 && n < TRACK_MAX) {
					if (!toc->tochdr.cdth_trk0)
						toc->tochdr.cdth_trk0 = strtol((s + 1), NULL, 10);
					toc->tochdr.cdth_trk1 = strtol((s + 1), NULL, 10);
				}
			}
			continue;
		}
		// "INDEX",index number,time and frame(msf) ---------------------------
		if ((p = strstr(buf, "INDEX")) != NULL) {
			if ((s = strchr(p, ' ')) != NULL && (t = strchr((s + 1), ' ')) != NULL) {
				if (n >= 0 && n < TRACK_MAX) {
					if ((lba = my_msf2frame((t + 1), &min, &sec, &frm)) < 0) {
						err = lba;
						break;
					}
					toc->tocentry[n].cdte_track = toc->tochdr.cdth_trk1;
					toc->tocentry[n].cdte_adr = 1;
					toc->tocentry[n].cdte_ctrl = 0;
					toc->tocentry[n].cdte_format = CDROM_MSF;
					if (toc->tocentry[n].cdte_format == CDROM_MSF) {
						toc->tocentry[n].cdte_addr.msf.minute = min;
						toc->tocentry[n].cdte_addr.msf.second = sec;
						toc->tocentry[n].cdte_addr.msf.frame = frm;
					} else {
						toc->tocentry[n].cdte_addr.lba = lba;
					}
					toc->tocentry[n].cdte_datamode = (toc->tocentry[n].cdte_ctrl & 0x04) ? 1 : 0;
				}
			}
			continue;
		}
	}
	// ------------------------------------------------------------------------
	if ((ret = my_close(fd)) < 0)
		err = ret;
	// ------------------------------------------------------------------------
	return err;
}
#endif							// MODULE

// ============================================================================
char *my_msg_ioctl_cmd(unsigned id)
{
	int i, n;
	char *msg = "unknown";
	static struct my_msg_list my_msg_list[] = {
		{CDROMPAUSE							, "Pause Audio Operation"																		},	// 0x5301
		{CDROMRESUME						, "Resume paused Audio Operation"																},	// 0x5302
		{CDROMPLAYMSF						, "Play Audio MSF (struct cdrom_msf)"															},	// 0x5303
		{CDROMPLAYTRKIND					, "Play Audio Track/index (struct cdrom_ti)"													},	// 0x5304
		{CDROMREADTOCHDR					, "Read TOC header (struct cdrom_tochdr)"														},	// 0x5305
		{CDROMREADTOCENTRY					, "Read TOC entry (struct cdrom_tocentry)"														},	// 0x5306
		{CDROMSTOP							, "Stop the cdrom drive"																		},	// 0x5307
		{CDROMSTART							, "Start the cdrom drive"																		},	// 0x5308
		{CDROMEJECT							, "Ejects the cdrom media"																		},	// 0x5309
		{CDROMVOLCTRL						, "Control output volume (struct cdrom_volctrl)"												},	// 0x530a
		{CDROMSUBCHNL						, "Read subchannel data (struct cdrom_subchnl)"													},	// 0x530b
		{CDROMREADMODE2						, "Read CDROM mode 2 data (2336 Bytes) (struct cdrom_read)"										},	// 0x530c
		{CDROMREADMODE1						, "Read CDROM mode 1 data (2048 Bytes)(struct cdrom_read)"										},	// 0x530d
		{CDROMREADAUDIO						, "(struct cdrom_read_audio)"																	},	// 0x530e
		{CDROMEJECT_SW						, "enable(1)/disable(0) auto-ejecting"															},	// 0x530f
		{CDROMMULTISESSION					, "Obtain the start-of-last-session address of multi session disks (struct cdrom_multisession)"	},	// 0x5310
		{CDROM_GET_MCN						, "Obtain the Universal Product Code (struct cdrom_mcn)"										},	// 0x5311
		{CDROMRESET							, "hard-reset the drive"																		},	// 0x5312
		{CDROMVOLREAD						, "Get the drive's volume setting (struct cdrom_volctrl)"										},	// 0x5313
		{CDROMREADRAW						, "read data in raw mode (2352 Bytes)(struct cdrom_read)"										},	// 0x5314
		{CDROMREADCOOKED					, "read data in cooked mode"																	},	// 0x5315
		{CDROMSEEK							, "seek msf address"																			},	// 0x5316
		{CDROMPLAYBLK						, "(struct cdrom_blk)"																			},	// 0x5317
		{CDROMREADALL						, "read all 2646 bytes"																			},	// 0x5318
		{CDROMGETSPINDOWN					, "get spindown"																				},	// 0x531d
		{CDROMSETSPINDOWN					, "set spindown"																				},	// 0x531e
		{CDROMCLOSETRAY						, "pendant of CDROMEJECT"																		},	// 0x5319
		{CDROM_SET_OPTIONS					, "Set behavior options"																		},	// 0x5320
		{CDROM_CLEAR_OPTIONS				, "Clear behavior options"																		},	// 0x5321
		{CDROM_SELECT_SPEED					, "Set the CD-ROM speed"																		},	// 0x5322
		{CDROM_SELECT_DISC					, "Select disc (for juke-boxes)"																},	// 0x5323
		{CDROM_MEDIA_CHANGED				, "Check is media changed "																		},	// 0x5325
		{CDROM_DRIVE_STATUS					, "Get tray position, etc."																		},	// 0x5326
		{CDROM_DISC_STATUS					, "Get disc type, etc."																			},	// 0x5327
		{CDROM_CHANGER_NSLOTS				, "Get number of slots"																			},	// 0x5328
		{CDROM_LOCKDOOR						, "lock or unlock door"																			},	// 0x5329
		{CDROM_DEBUG						, "Turn debug messages on/off"																	},	// 0x5330
		{CDROM_GET_CAPABILITY				, "get capabilities"																			},	// 0x5331
		{CDROMAUDIOBUFSIZ					, "set the audio buffer size or Used to obtain PUN and LUN info"								},	// 0x5382
		{DVD_READ_STRUCT					, "Read structure"																				},	// 0x5390
		{DVD_WRITE_STRUCT					, "Write structure"																				},	// 0x5391
		{DVD_AUTH							, "Authentication"																				},	// 0x5392
		{CDROM_SEND_PACKET					, "send a packet to the drive"																	},	// 0x5393
		{CDROM_NEXT_WRITABLE				, "get next writable block"																		},	// 0x5394
		{CDROM_LAST_WRITTEN					, "get last block written on disc"																},	// 0x5395
		{SG_EMULATED_HOST					, "SG_EMULATED_HOST"																			},	// 0x2203
		{SG_SET_TRANSFORM					, "SG_SET_TRANSFORM"																			},	// 0x2204
		{SG_GET_TRANSFORM					, "SG_GET_TRANSFORM"																			},	// 0x2205
		{SG_SET_RESERVED_SIZE				, "SG_SET_RESERVED_SIZE"																		},	// 0x2275
		{SG_GET_RESERVED_SIZE				, "SG_GET_RESERVED_SIZE"																		},	// 0x2272
		{SG_GET_SCSI_ID						, "SG_GET_SCSI_ID"																				},	// 0x2276
		{SG_SET_FORCE_LOW_DMA				, "SG_SET_FORCE_LOW_DMA"																		},	// 0x2279
		{SG_GET_LOW_DMA						, "SG_GET_LOW_DMA"																				},	// 0x227a
		{SG_SET_FORCE_PACK_ID				, "SG_SET_FORCE_PACK_ID"																		},	// 0x227b
		{SG_GET_PACK_ID						, "SG_GET_PACK_ID"																				},	// 0x227c
		{SG_GET_NUM_WAITING					, "SG_GET_NUM_WAITING"																			},	// 0x227d
		{SG_GET_SG_TABLESIZE				, "SG_GET_SG_TABLESIZE"																			},	// 0x227F
		{SG_GET_VERSION_NUM					, "SG_GET_VERSION_NUM"																			},	// 0x2282
		{SG_SCSI_RESET						, "SG_SCSI_RESET"																				},	// 0x2284
		{SG_IO								, "SG_IO"																						},	// 0x2285
		{SG_GET_REQUEST_TABLE				, "SG_GET_REQUEST_TABLE"																		},	// 0x2286
		{SG_SET_KEEP_ORPHAN					, "SG_SET_KEEP_ORPHAN"																			},	// 0x2287
		{SG_GET_KEEP_ORPHAN					, "SG_GET_KEEP_ORPHAN"																			},	// 0x2288
		{SG_GET_ACCESS_COUNT				, "SG_GET_ACCESS_COUNT"																			},	// 0x2289
//		{SCSI_IOCTL_GET_IDLUN				, "Used to obtain PUN and LUN info"																},	// 0x5382: Conflicts with CDROMAUDIOBUFSIZ
		{SCSI_IOCTL_PROBE_HOST				, "Used to obtain the host number of a device"													},	// 0x5383
		{SCSI_IOCTL_GET_BUS_NUMBER			, "Used to obtain the bus number for a device"													},	// 0x5386
		{SCSI_IOCTL_GET_PCI					, "Used to obtain the PCI location of a device"													},	// 0x5387
	};

	n = sizeof(my_msg_list) / sizeof(struct my_msg_list);
	for (i = 0; i < n; i++) {
		if (my_msg_list[i].id == id) {
			msg = my_msg_list[i].msg;
			break;
		}
	}
	return msg;
}

// ============================================================================
char *my_msg_packet_cmd(unsigned id)
{
	int i, n;
	char *msg = "unknown";
	static struct my_msg_list my_msg_list[] = {
		{GPCMD_TEST_UNIT_READY				, "Test Unit Ready"					},	// 0x00
		{GPCMD_REQUEST_SENSE				, "Request Sense"					},	// 0x03
		{GPCMD_FORMAT_UNIT					, "Format Unit"						},	// 0x04
		{GPCMD_INQUIRY						, "Inquiry"							},	// 0x12
		{GPCMD_START_STOP_UNIT				, "Start/Stop Unit"					},	// 0x1b
		{GPCMD_PREVENT_ALLOW_MEDIUM_REMOVAL	, "Prevent/Allow Medium Removal"	},	// 0x1e
		{GPCMD_READ_FORMAT_CAPACITIES		, "Read Format Capacities"			},	// 0x23
		{GPCMD_READ_CDVD_CAPACITY			, "Read Cd/Dvd Capacity"			},	// 0x25
		{GPCMD_READ_10						, "Read 10"							},	// 0x28
		{GPCMD_WRITE_10						, "Write 10"						},	// 0x2a
		{GPCMD_SEEK							, "Seek"							},	// 0x2b
		{GPCMD_WRITE_AND_VERIFY_10			, "Write and Verify 10"				},	// 0x2e
		{GPCMD_VERIFY_10					, "Verify 10"						},	// 0x2f
		{GPCMD_FLUSH_CACHE					, "Flush Cache"						},	// 0x35
		{GPCMD_WRITE_BUFFER					, "GPCMD_WRITE_BUFFER"				},	// 0x3b
		{GPCMD_READ_BUFFER					, "GPCMD_READ_BUFFER"				},	// 0x3c
		{GPCMD_READ_SUBCHANNEL				, "Read Subchannel"					},	// 0x42
		{GPCMD_READ_TOC_PMA_ATIP			, "Read Table of Contents"			},	// 0x43
		{GPCMD_READ_HEADER					, "Read Header"						},	// 0x44
		{GPCMD_PLAY_AUDIO_10				, "Play Audio 10"					},	// 0x45
		{GPCMD_GET_CONFIGURATION			, "Get Configuration"				},	// 0x46
		{GPCMD_PLAY_AUDIO_MSF				, "Play Audio MSF"					},	// 0x47
		{GPCMD_PLAY_AUDIO_TI				, "Play Audio TrackIndex"			},	// 0x48
		{GPCMD_GET_EVENT_STATUS_NOTIFICATION, "Get Event Status Notification"	},	// 0x4a
		{GPCMD_PAUSE_RESUME					, "Pause/Resume"					},	// 0x4b
		{GPCMD_STOP_PLAY_SCAN				, "Stop Play/Scan"					},	// 0x4e
		{GPCMD_READ_DISC_INFO				, "Read Disc Info"					},	// 0x51
		{GPCMD_READ_TRACK_RZONE_INFO		, "Read Track Rzone Info"			},	// 0x52
		{GPCMD_RESERVE_RZONE_TRACK			, "Reserve Rzone Track"				},	// 0x53
		{GPCMD_SEND_OPC						, "Send OPC"						},	// 0x54
		{GPCMD_MODE_SELECT_10				, "Mode Select 10"					},	// 0x55
		{GPCMD_REPAIR_RZONE_TRACK			, "Repair Rzone Track"				},	// 0x58
		{GPCMD_MODE_SENSE_10				, "Mode Sense 10"					},	// 0x5a
		{GPCMD_CLOSE_TRACK					, "Close Track"						},	// 0x5b
		{GPCMD_READ_BUFFER_CAPACITY			, "GPCMD_READ_BUFFER_CAPACITY"		},	// 0x5c
		{GPCMD_SEND_CUE_SHEET				, "GPCMD_SEND_CUE_SHEET"			},	// 0x5d
		{GPCMD_BLANK						, "Blank"							},	// 0xa1
		{GPCMD_SEND_EVENT					, "Send Event"						},	// 0xa2
		{GPCMD_SEND_KEY						, "Send Key"						},	// 0xa3
		{GPCMD_REPORT_KEY					, "Report Key"						},	// 0xa4
		{GPCMD_LOAD_UNLOAD					, "Load/Unload"						},	// 0xa6
		{GPCMD_SET_READ_AHEAD				, "Set Read-ahead"					},	// 0xa7
		{GPCMD_READ_12						, "Read 12"							},	// 0xa8
		{GPCMD_WRITE_12						, "GPCMD_WRITE_12"					},	// 0xaa
		{GPCMD_GET_PERFORMANCE				, "Get Performance"					},	// 0xac
		{GPCMD_READ_DVD_STRUCTURE			, "Read DVD Structure"				},	// 0xad
		{GPCMD_SET_STREAMING				, "Set Streaming"					},	// 0xb6
		{GPCMD_READ_CD_MSF					, "Read CD MSF"						},	// 0xb9
		{GPCMD_SCAN							, "Scan"							},	// 0xba
		{GPCMD_SET_SPEED					, "Set Speed"						},	// 0xbb
		{GPCMD_PLAY_CD						, "Play CD"							},	// 0xbc
		{GPCMD_MECHANISM_STATUS				, "Mechanism Status"				},	// 0xbd
		{GPCMD_READ_CD						, "Read CD"							},	// 0xbe
		{GPCMD_SEND_DVD_STRUCTURE			, "Send DVD Structure"				},	// 0xbf
		{GPCMD_GET_MEDIA_STATUS				, "GPCMD_GET_MEDIA_STATUS"			},	// 0xda
	};

	n = sizeof(my_msg_list) / sizeof(struct my_msg_list);
	for (i = 0; i < n; i++) {
		if (my_msg_list[i].id == id) {
			msg = my_msg_list[i].msg;
			break;
		}
	}
	return msg;
}

// *** EOF ********************************************************************
