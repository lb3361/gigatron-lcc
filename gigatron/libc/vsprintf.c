#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "_doprint.h"

static int _sprintf_writall(register const char *buf, register size_t sz, register FILE *fp)
{
	register char *b;
	if ((b = fp->_x)) {
		memcpy(b, buf, sz);
		b += sz;
		*b = 0;
		fp->_x = b;
	}
	return sz;
}

static struct _iobuf _sprintf_iobuf;

int vsprintf(register char *s, register const char *fmt, register va_list ap)
{
	_sprintf_iobuf._x = s;
	_doprint_dst.fp = &_sprintf_iobuf;
	_doprint_dst.writall = (writall_t)_sprintf_writall;
	return _doprint(fmt, ap);
}

/* A sprintf relay is defined in _printf.s */
