#include "_stdio.h"

int fflush(register FILE *fp)
{
	register int r = 0;
	register int f;
	if (! fp)
		return _swalk(fflush);
	if ((fp->_flag & (_IOFBF|_IOWRIT)) == (_IOFBF|_IOWRIT))
		_flsbuf(EOF, fp);
	else if (fp->_flag & _IOREAD)
		fp->_cnt = 0;
	if (fp->_flag & _IOERR)
		return -1;
	return 0;
}
