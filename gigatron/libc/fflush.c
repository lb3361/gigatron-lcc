#include "_stdio.h"

int fflush(register FILE *fp)
{
	register int flag;
	if (! fp)
		return _fwalk(fflush);
	flag = fp->_flag;
	if ((flag & (_IOFBF|_IOWRIT)) == (_IOFBF|_IOWRIT))
		_flsbuf(EOF, fp);
	else
		fp->_cnt = 0;
	return _fcheck(fp);
}
