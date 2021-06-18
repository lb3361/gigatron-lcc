#include <string.h>
#include "_stdio.h"

int _fputm(register const char *buf, register size_t sz, register FILE *fp)
{
	/* must do better here */
	register char c;
	register int written = 0;
	while (written != sz && fp->_cnt > 0) {
		c = *buf;
		putc(c, fp);
		buf++;
		written++;
		if (c == '\n' && (fp->_flag & _IOLBF) == _IOLBF)
			break;
	}
	fflush(fp);
	if (written != sz)
		written += fp->_v->write(fp->_file, buf, sz - written);
	return written;
}

int fputs(register const char *s, register FILE *fp)
{
	_fputm(s, strlen(s), fp);
	return _fcheck(fp);
}

