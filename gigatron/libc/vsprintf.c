#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "_doprint.h"

static int _sprintf_writall(register const char *buf, register size_t sz, FILE *fp)
{
	register char **bb = (char**)&(_doprintdst->fp);
	if (*bb) {
		memcpy(*bb, buf, sz);
		*bb += sz;
		**bb = 0;
	}
	return sz;
}

int vsprintf(register char *s, register const char *fmt, register va_list ap)
{
	register struct _doprint_dst_s *sav = _doprintdst;
	register int c;
	struct _doprint_dst_s dd;
	_doprintdst = &dd;
	dd.writall = (writall_t)_sprintf_writall;
	dd.fp = (FILE*)s;
	c = _doprint(fmt, ap);
	_doprintdst = sav;
	return c;
}

/* A sprintf relay is defined in _printf.s */
