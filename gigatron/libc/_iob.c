#include "_stdio.h"

struct _iobuf _iob[_IOB_NUM] = { 0 };

DECLARE_INIT_FUNCTION(_iob_setup);

int _serror(FILE *fp, int errn)
{
	if (errn > 0) {
		errno = errn;
		fp->_flag |= _IOERR;
	} else if (errn < 0)
		fp->_flag |= _IOEOF;
	if (errn) {
		fp->_cnt = 0;
		fp->_ptr = 0;
		return EOF;
	} else
		return 0;
}

void _scheckbuf(FILE *fp)
{
	/* TODO: allocate a buffer and move elsewhere */
	if ((fp->_flag & _IOFBF) && ! fp->_base)
		fp->_flag &= ~_IOFBF;
}
