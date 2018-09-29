// ----------------------------------------------------------------------------
// my library debug program
//  gcc -Wall t_cdrom.c my_cdrom.c my_file.c my_string.c -o t_cdrom
//  ./t_cdrom *.cue -d
// ----------------------------------------------------------------------------
#include "my_common.h"
#include <stdint.h>						// uint16_t,uint32_t,uint64_t,...
#include <stdio.h>						// FILE,fopen,fclose,...
#include <stdlib.h>						// strtoul
#include <string.h>						// memset,strncpy,strlen,strchr,strstr
#include <sys/stat.h>					// stat
#include <linux/cdrom.h>				// CD_FRAMES,CD_SECS,...
#include <linux/limits.h>				// PATH_MAX
#include <iconv.h>						// iconv_t,iconv
#include <unistd.h>						// getopt
// ----------------------------------------------------------------------------
void dbg_print(const cuedata_t * cuedata)
{
	int i;
	int lba, m, s, f;

	printf("cue file name: [%s]\n", cuedata->fname_cue);
	printf("bin file name: [%s]\n", cuedata->fname_bin);
	printf("bin file size: [%lu]\n", cuedata->fsize_bin);
	printf("frame size   : [%d]\n", cuedata->frame_len);
	printf("start track  : [%02d]\n", cuedata->trk0);
	printf("end track    : [%02d]\n", cuedata->trk1);
	printf("flag         : [%d]\n", cuedata->flg);
	printf("|TRK|IDX| S-TIME | E-TIME | lba0 | lba1 |flg|lbasiz|  TIME  |\n");
	for (i = 0; i < sizeof(cuedata->td) / sizeof(cuedata->td[0]); i++) {
		if (!cuedata->td[i].trk)
			break;
		lba = cuedata->td[i].lba1 - cuedata->td[i].lba0 + 1;
		my_lba2msf(lba, &m, &s, &f);
		printf("|%03d|%03d|%02d:%02d.%02d|%02d:%02d.%02d|%6d|%6d|%3d|%6d|%02d:%02d.%02d|\n",
			   cuedata->td[i].trk, cuedata->td[i].ind,
			   cuedata->td[i].min0, cuedata->td[i].sec0, cuedata->td[i].frm0, cuedata->td[i].min1, cuedata->td[i].sec1, cuedata->td[i].frm1, cuedata->td[i].lba0, cuedata->td[i].lba1, cuedata->td[i].flg, lba, m, s, f);
	}
}

// ----------------------------------------------------------------------------
int main(int argc, char *argv[])
{
	cuedata_t cuedata;					// cue data
	int flg_disp = 0;					// 1: cue data print display
	int flg_wave = 0;					// 1: output to wave data
	int opt;							// option character
	int i;

	while ((opt = getopt(argc, argv, "wd")) != -1) {
		switch (opt) {
		case 'w':
			flg_wave = 1;
			break;
		case 'd':
			flg_disp = 1;
			break;
		case 'h':
		case '?':
			fprintf(stderr, "usage: %s [cue file name]\n", argv[0]);
			return 0;
			break;
		default:
			break;
		}
	}
	if (argc - optind < 1) {
		fprintf(stderr, "usage: %s [cue file name]\n", argv[0]);
		return -1;
	}
	for (i = optind; i < argc; i++) {
		strncpy(cuedata.fname_cue, argv[i], sizeof(cuedata.fname_cue));
		if (my_get_cuedata(&cuedata) < 0)
			return -1;
		if (flg_disp) {
			dbg_print(&cuedata);
			continue;
		}
		if (my_get_bindata(&cuedata, flg_wave) < 0)
			return -1;
	}
	return 0;
}

// ----------------------------------------------------------------------------
