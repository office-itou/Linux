// ****************************************************************************
// SCSI cdrom (sr) emulation driver
// ****************************************************************************

#ifndef __SREMU_H__
#define __SREMU_H__

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#include <linux/limits.h>				// PATH_MAX,NAME_MAX
#include <linux/cdrom.h>				// struct cdemu_toc,struct cdemu_unit, ...

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#define AUTHOR				"Jun Itou"
#define DESCRIPTION			"SCSI cdrom ("DEVICE_NAME") emulation driver"
#define DEVICE_NAME			"sremu"
enum {									// IOCTL commands
	SR_NO_COMMAND = 0,
	SR_MEDIA_LOAD,
};

// ============================================================================
#define GETMSB(n)			(((n) >> 8) & 0xff)
#define GETLSB(n)			((n) & 0xff)

#ifndef _G_BUFSIZ
#define _G_BUFSIZ			8192
#endif

#ifndef _IO_BUFSIZ
#define _IO_BUFSIZ			_G_BUFSIZ
#endif

#ifndef BUFSIZ
#define BUFSIZ				_IO_BUFSIZ
#endif

#if BUFSIZ > PATH_MAX
#define BUFF_MAX			BUFSIZ
#else
#define BUFF_MAX			PATH_MAX
#endif

// ============================================================================
#define TRACK_MAX			99
struct sr_toc {
	int initial;						// initial flag
	char path_cue[PATH_MAX];			// cue file name
	char path_bin[PATH_MAX];			// bin file name
	int leadout;						// last frame number (set track = CDROM_LEADOUT)
	struct cdrom_tochdr tochdr;
	struct cdrom_tocentry tocentry[TRACK_MAX];
};

// ============================================================================
static const struct {
	unsigned short packet_command;
	char *const text;
} packet_command_texts[] = {
	{GPCMD_TEST_UNIT_READY              , "Test Unit Ready"              }, // 0x00
	{GPCMD_REQUEST_SENSE                , "Request Sense"                }, // 0x03
	{GPCMD_FORMAT_UNIT                  , "Format Unit"                  }, // 0x04
	{GPCMD_INQUIRY                      , "Inquiry"                      }, // 0x12
	{GPCMD_START_STOP_UNIT              , "Start/Stop Unit"              }, // 0x1b
	{GPCMD_PREVENT_ALLOW_MEDIUM_REMOVAL , "Prevent/Allow Medium Removal" }, // 0x1e
	{GPCMD_READ_FORMAT_CAPACITIES       , "Read Format Capacities"       }, // 0x23
	{GPCMD_READ_CDVD_CAPACITY           , "Read Cd/Dvd Capacity"         }, // 0x25
	{GPCMD_READ_10                      , "Read 10"                      }, // 0x28
	{GPCMD_WRITE_10                     , "Write 10"                     }, // 0x2a
	{GPCMD_SEEK                         , "Seek"                         }, // 0x2b
	{GPCMD_WRITE_AND_VERIFY_10          , "Write and Verify 10"          }, // 0x2e
	{GPCMD_VERIFY_10                    , "Verify 10"                    }, // 0x2f
	{GPCMD_FLUSH_CACHE                  , "Flush Cache"                  }, // 0x35
	{GPCMD_WRITE_BUFFER                 , "GPCMD_READ_BUFFER"            },	// 0x3b
	{GPCMD_READ_BUFFER                  , "GPCMD_READ_SUBCHANNEL"        },	// 0x3c
	{GPCMD_READ_SUBCHANNEL              , "Read Subchannel"              }, // 0x42
	{GPCMD_READ_TOC_PMA_ATIP            , "Read Table of Contents"       }, // 0x43
	{GPCMD_READ_HEADER                  , "Read Header"                  }, // 0x44
	{GPCMD_PLAY_AUDIO_10                , "Play Audio 10"                }, // 0x45
	{GPCMD_GET_CONFIGURATION            , "Get Configuration"            }, // 0x46
	{GPCMD_PLAY_AUDIO_MSF               , "Play Audio MSF"               }, // 0x47
	{GPCMD_PLAYAUDIO_TI                 , "Play Audio TrackIndex"        }, // 0x48
	{GPCMD_GET_EVENT_STATUS_NOTIFICATION, "Get Event Status Notification"}, // 0x4a
	{GPCMD_PAUSE_RESUME                 , "Pause/Resume"                 }, // 0x4b
	{GPCMD_STOP_PLAY_SCAN               , "Stop Play/Scan"               }, // 0x4e
	{GPCMD_READ_DISC_INFO               , "Read Disc Info"               }, // 0x51
	{GPCMD_READ_TRACK_RZONE_INFO        , "Read Track Rzone Info"        }, // 0x52
	{GPCMD_RESERVE_RZONE_TRACK          , "Reserve Rzone Track"          }, // 0x53
	{GPCMD_SEND_OPC                     , "Send OPC"                     }, // 0x54
	{GPCMD_MODE_SELECT_10               , "Mode Select 10"               }, // 0x55
	{GPCMD_REPAIR_RZONE_TRACK           , "Repair Rzone Track"           }, // 0x58
	{GPCMD_MODE_SENSE_10                , "Mode Sense 10"                }, // 0x5a
	{GPCMD_CLOSE_TRACK                  , "Close Track"                  }, // 0x5b
	{GPCMD_READ_BUFFER_CAPACITY         , "GPCMD_READ_BUFFER_CAPACITY"   },	// 0x5c
	{GPCMD_SEND_CUE_SHEET               , "GPCMD_SEND_CUE_SHEET"         },	// 0x5d
	{GPCMD_BLANK                        , "Blank"                        }, // 0xa1
	{GPCMD_SEND_EVENT                   , "Send Event"                   }, // 0xa2
	{GPCMD_SEND_KEY                     , "Send Key"                     }, // 0xa3
	{GPCMD_REPORT_KEY                   , "Report Key"                   }, // 0xa4
	{GPCMD_LOAD_UNLOAD                  , "Load/Unload"                  }, // 0xa6
	{GPCMD_SET_READ_AHEAD               , "Set Read-ahead"               }, // 0xa7
	{GPCMD_READ_12                      , "Read 12"                      }, // 0xa8
	{GPCMD_WRITE_12                     , "GPCMD_WRITE_12"               },	// 0xaa
	{GPCMD_GET_PERFORMANCE              , "Get Performance"              }, // 0xac
	{GPCMD_READ_DVD_STRUCTURE           , "Read DVD Structure"           }, // 0xad
	{GPCMD_SET_STREAMING                , "Set Streaming"                }, // 0xb6
	{GPCMD_READ_CD_MSF                  , "Read CD MSF"                  }, // 0xb9
	{GPCMD_SCAN                         , "Scan"                         }, // 0xba
	{GPCMD_SET_SPEED                    , "Set Speed"                    }, // 0xbb
	{GPCMD_PLAY_CD                      , "Play CD"                      }, // 0xbc
	{GPCMD_MECHANISM_STATUS             , "Mechanism Status"             }, // 0xbd
	{GPCMD_READ_CD                      , "Read CD"                      }, // 0xbe
	{GPCMD_SEND_DVD_STRUCTURE           , "Send DVD Structure"           }, // 0xbf
	{GPCMD_GET_MEDIA_STATUS             , "GPCMD_GET_MEDIA_STATUS"       },	// 0xda
};

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
extern void sr_lba2msf(int lba, int *m, int *s, int *f);
extern int sr_msf2lba(int m, int s, int f);

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#ifdef __KERNEL__
#endif							// __KERNEL__
// ============================================================================
#endif							// __SREMU_H__

// *** EOF ********************************************************************
