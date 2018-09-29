// ----------------------------------------------------------------------------
// my library debug program
//  gcc -Wall t_copy.c my_file.c my_string.c -o t_copy
//  ./t_copy source taget
// ----------------------------------------------------------------------------
#include "my_common.h"

// ----------------------------------------------------------------------------
int main(int argc, const char *argv[])
{
	char ipath[PATH_MAX], opath[PATH_MAX];

	strncpy(ipath, argv[1], sizeof(ipath));
	strncpy(opath, argv[2], sizeof(opath));

	return my_copy(ipath, opath);
}

// ----------------------------------------------------------------------------
