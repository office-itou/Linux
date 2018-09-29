// ============================================================================
#include "my_common.h"

// ============================================================================
void dbg_print(const tocdata_t * tocdata)
{
	int i, n;
	int m, s, f, m0, s0, f0, m1, s1, f1;
	int lba, lba0, lba1;

	printf("cue file name: [%s]\n", tocdata->cue);
	printf("bin file name: [%s]\n", tocdata->bin);
	printf("start track  : [%02d]\n", tocdata->first);
	printf("end track    : [%02d]\n", tocdata->last);
	printf("last frame   : [%d]\n", tocdata->leadout);
	printf("|TRK| S-TIME | E-TIME | lba0 | lba1 |lbasiz|  TIME  |\n");
	for (i = 0, n = tocdata->first; n <= tocdata->last; i++, n++) {
		lba0 = tocdata->entry[i];
		if (n < tocdata->last)
			lba1 = tocdata->entry[i + 1] - 1;
		else
			lba1 = tocdata->leadout;
		lba = lba1 - lba0 + 1;
		my_lba2msf(lba0, &m0, &s0, &f0);
		my_lba2msf(lba1, &m1, &s1, &f1);
		my_lba2msf(lba, &m, &s, &f);
		printf("|%03d|%02d:%02d.%02d|%02d:%02d.%02d|%6d|%6d|%6d|%02d:%02d.%02d|\n", n, m0, s0, f0, m1, s1, f1, lba0, lba1, lba, m, s, f);
	}
}

// ----------------------------------------------------------------------------
int main(int argc, char *argv[])
{
	tocdata_t tocdata;					// toc data
	int flg_disp = 0;					// 1: cue data print display
	int flg_wave = 0;					// 1: output to wave data
	int opt;							// option character
	int i;

	while ((opt = getopt(argc, argv, "wd")) != -1) {
		switch (opt) {
		case 'w':
			flg_disp = 0;
			flg_wave = 1;
			break;
		case 'd':
			flg_disp = 1;
			flg_wave = 0;
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
		strncpy(tocdata.cue, argv[i], sizeof(tocdata.cue));
		if (my_read_toc(&tocdata) < 0)
			return -1;
		if (flg_disp) {
			dbg_print(&tocdata);
			continue;
		}
		if (flg_wave) {
			continue;
		}
//      if (my_get_bindata(&tocdata, flg_wave) < 0)
//          return -1;
	}
	return 0;
}

// ============================================================================
