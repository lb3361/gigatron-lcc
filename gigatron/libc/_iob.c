#include "_stdio.h"

struct _iobuf _iob[_IOB_NUM] = { 0 };

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

int _fcheck(register FILE *fp)
{
	register int f = fp->_flag;
	if (f == 0 || (f & (_IOERR|_IOEOF)))
		return EOF;
	return 0;
}

void _fflush(register FILE *fp)
{
	register int flag;
	flag = fp->_flag;
	if ((flag & (_IOFBF|_IOWRIT)) == (_IOFBF|_IOWRIT))
		_flsbuf(EOF, fp);
	else
		fp->_cnt = 0;
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

FILE *_sfindiob(void)
{
	int i;
	FILE *f = _iob;
	for (i = 0; i != _IOB_NUM; i++, f++)
		if (! f->_flag)
			return f;
#if WITH_MALLOC
	/* Allocate a struct _iobuf outside _iob: not implemented */
#endif
	return 0;
}

void  _sfreeiob(FILE *fp)
{
	fp->_flag = 0;
#if WITH_MALLOC
	/* Free struct _iobuf outside _iob: not implemented */
#endif
}

int _swalk(int(*func)(FILE*))
{
	register int i;
	register int r = 0;
	FILE *f = _iob;
	for (i = 0; i != _IOB_NUM; i++, f++)
		if  (f->_flag && (*func)(f) < 0)
			r = -1;
#if WITH_MALLOC
	/* Walk struct _iobuf outside _iob: not implemented */
#endif
	return r;
}

int _fclose(register FILE *fp)
{
	register int r = 0;
	_fflush(fp);
	if (ferror(fp))
		r = -1;
	if (fp->_v->close && (*fp->_v->close)(fp->_file) < 0)
		r = -1;
	return 0;
}

static void _fcloseall(void)
{
	_swalk(_fclose);
}

DECLARE_INIT_FUNCTION(_iob_setup);
DECLARE_FINI_FUNCTION(_fcloseall);

