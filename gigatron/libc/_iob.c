#include "_stdio.h"

struct _iobuf _iob[_IOB_NUM] = { 0 };

DECLARE_INIT_FUNCTION(_iob_setup);

int _fcheck(register FILE *fp)
{
	register int f = fp->_flag;
	if (f == 0 || (f & (_IOERR|_IOEOF)))
		return EOF;
	return 0;
}

int _fwalk(register int(*func)(FILE*))
{
	int i;
	for (i = 0; i != _IOB_NUM; i++)
		if (_iob[i]._flag)
			(*func)(&_iob[i]);
	return 0;
}

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

static int _chk_flsbuf(register FILE *fp)
{
	register int flag = fp->_flag;
	if (flag & (_IOERR|_IOEOF))
		return EOF;
	if (! (flag & _IOWRIT))
		return EPERM;
	if (!fp->_v->flsbuf)
		return ENOTSUP;
	return 0;
}

int _flsbuf(register int c, register FILE *fp)
{
	register int n;
	if ((n = _chk_flsbuf(fp)))
		return _serror(fp, n);
	return fp->_v->flsbuf(c, fp);
}

static int _chk_filbuf(register FILE *fp)
{
	register int flag = fp->_flag;
	if (flag & (_IOERR|_IOEOF))
		return EOF;
	if (! (flag & _IOREAD))
		return EPERM;
	if (!fp->_v->filbuf)
		return ENOTSUP;
	return 0;
}

int _filbuf(register FILE *fp)
{
	register int n;
	register char *buf;
	if ((n = _chk_filbuf(fp)))
		return _serror(fp, n);
	return fp->_v->filbuf(fp);
}
