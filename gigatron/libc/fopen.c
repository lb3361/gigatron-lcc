#include "_stdio.h"
#include <errno.h>

FILE *fopen(const char *fname, const char *mode)
{
	errno = ENOTSUP;
	return 0;
}

FILE *freopen(const char *fname, const char *mode, FILE *fp)
{
	errno = ENOTSUP;
	return 0;
}

