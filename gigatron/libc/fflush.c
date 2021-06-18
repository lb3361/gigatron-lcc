#include "_stdio.h"
#include <errno.h>

int fflush(FILE *fp)
{
	if (! fp)
		return _swalk(fflush);
	if (fp->_flag) {
		_fflush(fp);
		return _fcheck(fp);
	}
	errno = EINVAL;
	return -1;
}
