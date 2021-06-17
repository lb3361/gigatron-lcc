#include "_stdio.h"

static int _chk_filbuf(register FILE *fp)
{
	register int flag = fp->_flag;
	fp->_cnt = 0;
	fp->_ptr = 0;
	if (flag & (_IOERR|_IOEOF))
		return EOF;
	if (! (flag & _IOREAD))
		return EPERM;
	if (!fp->_v->filbuf && !fp->_v->read)
		return ENOTSUP;
	return 0;
}


int _filbuf(register FILE *fp)
{
	register int n;
	register char *buf;

	if ((n =  chk_filbuf(fp)))
		return _serror(fp, n);
	_scheckbuf(fp);
	if (fp->_v->filbuf)
		return fp->_v->filbuf(fp);

	if (fp->_flag & _IOFBF) {
		buf = fp->_base->data;
		n = fp->_base->size;
	} else {
		buf = fp->_buf;
		n = 1;
	}
	if ((n = fp->_v->read(fp->_file, buf, n)) <= 0)
		return _serror(fp, (n) ? EIO : EOF);
	fp->_cnt = n - 1;
	fp->_ptr = (unsigned char*)(buf + 1);
	return buf[0];
}


