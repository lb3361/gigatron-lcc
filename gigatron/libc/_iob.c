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

FILE *_sfindiob(void)
{
	int i;
	for (i = 0; i != _IOB_NUM; i++)
		if (_iob[i]._flag == 0)
			return &_iob[i];
	errno = ENFILE;
	return 0;
}

void _sfreeiob(FILE *fp)
{
	fp->_flag = 0;
}

int _swalk(register int(*f)(FILE*))
{
	register int i;
	for (i = 0; i != _IOB_NUM; i++)
		if (_iob[i]._flag)
			(*f)(&_iob[i]);
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
