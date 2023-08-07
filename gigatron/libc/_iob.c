
#include <gigatron/pragma.h>
#define _IOB_DEFINED
#include "_stdio.h"


/* Handles additional IOBs besides stdin/stdout/stderr */

struct _iobuf _iob[IOBSIZE];

extern __weak struct _iobuf _iob0, _iob1, _iob2;

FILE *_sfindiob(void)
{
	register FILE *fp;
	for (fp = _iob; fp != _iob + IOBSIZE; fp++)
		if (! fp->_flag)
			return fp;
	return 0;
}

int _sclose(FILE *fp)
{
	register int (*fptr)(FILE*,int);
	if (fp && fp->_flag)
		if (fptr = fp->_v->flush)
			return fptr(fp, 1);
	return 0;
}

void _swalk(register int (*fptr)(FILE*))
{
	register FILE *fp = _iob + IOBSIZE;
	do {
		fptr(--fp);
	} while (fp != _iob);
	if (&_iob2)
		fptr(&_iob2);
	if (&_iob1)
		fptr(&_iob1);
	if (&_iob0)
		fptr(&_iob0);
}

static void _fcloseall(void)
{
	_swalk(_sclose);
}


DECLARE_FINI_FUNCTION(_fcloseall);
