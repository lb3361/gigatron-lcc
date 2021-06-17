#include "_stdio.h"

static int chk_flsbuf(register FILE *fp)
{
	register int flag = fp->_flag;
	fp->_cnt = 0;
	fp->_ptr = 0;
	if (flag & (_IOERR|_IOEOF))
		return EOF;
	if (! (flag & _IOWRIT))
		return EPERM;
	if (!fp->_v->flsbuf && !fp->_v->write)
		return ENOTSUP;
	return 0;
}

int _flsbuf(unsigned c, FILE *fp)
{
	register char *buf;
	register int n, m;

	if ((n = chk_flsbuf(fp)))
		return _serror(fp, n);
	_scheckbuf(fp);
	if (fp->_v->flsbuf)
		return fp->_v->flsbuf(c, fp);

	if (fp->_flag & _IOFBF) {
		buf = fp->_base->data;
		n = (char*)fp->_ptr - buf;
		buf[n++] = (char) c;
		fp->_cnt = fp->_base->size - 1;
		fp->_ptr = (unsigned char*)buf;
	} else {
		n = 1;
		buf = (char*)(fp->_buf);
		buf[0] = (char)c;
	}
	while (n > 0) {
		if ((m = fp->_v->write(fp->_file, buf, n)) <= 0)
			return _serror(fp, EIO);
		buf += m;
		n -= m;
	}
	return (int)c;
}

