#include "_stdio.h"
#include <errno.h>

int fflush(FILE *fp)
{
	if (! fp) {
		_swalk(fflush);
		return 0;
	}
	if (fp->_flag) {
		_fflush(fp);
		return _fcheck(fp);
	}
	errno = EINVAL;
	return -1;
}
