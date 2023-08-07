#include <gigatron/pragma.h>
#include <errno.h>
#define _IOB_DEFINED
#include "_stdio.h"

extern __weak struct _iobuf _iob0, _iob1, _iob2, _iob[];

static int _flush(register FILE *fp)
{
	register int (*fptr)(FILE*,int);
	if (fp && fp->_flag) {
		fp->_flag &= 0xff ^ _IOUNGET;
		if (fptr = fp->_v->flush)
			return fptr(fp, 1);
	}
	return 0;
}

int fflush(register FILE *fp)
{
	if (! fp) {
		_swalk(_flush);
		return 0;
	} else if (! fp->_flag) {
		errno = EINVAL;
		return -1;
	} else {
		return _flush(fp);
	}
}
