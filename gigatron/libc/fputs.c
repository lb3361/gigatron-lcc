#include <string.h>
#include "_stdio.h"

int _fputm(register const char *buf, register size_t sz, register FILE *fp)
{
	if (sz <= fp->_cnt) {
		memcpy(fp->_ptr, buf, sz);
		fp->_ptr += sz;
		fp->_cnt -= sz;
		if ((fp->_flag & _IOLBF) == _IOLBF)
			if (memchr(buf, '\n', sz))
				_fflush(fp);
		return sz;
	} else {
		_fflush(fp);
		return fp->_v->write(fp->_file, buf, sz);
	}
}

int fputs(register const char *s, register FILE *fp)
{
	_fputm(s, strlen(s), fp);
	return _fcheck(fp);
}

