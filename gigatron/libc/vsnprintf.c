#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "_doprint.h"

struct _doprint_dst_ext_s {
	struct _doprint_dst_s dd;
	char *e;
};

static int _sprintf_writall(register const char *buf, register size_t sz, FILE *fp)
{
	register char **bb = (char**)&(_doprintdst->fp);
	register char *b;
	if ((b = *bb)) {
		register size_t rsz = (size_t)(bb[1]-b);
		if (rsz > sz)
			rsz = sz;
		memcpy(b, buf, rsz);
		*bb += rsz;
		**bb = 0;
	}
	return sz;
}

int vsnprintf(register char *s, size_t n, register const char *fmt, register va_list ap)
{
	register struct _doprint_dst_s *sav = _doprintdst;
	register int c;
	struct _doprint_dst_ext_s de;
	_doprintdst = &de.dd;
	if (n == 0) { s = 0; }
	de.dd.writall = (writall_t)_sprintf_writall;
	de.dd.fp = (FILE*)s;
	de.e = s + n - 1;
	c = _doprint(fmt,ap);
	_doprintdst = sav;
	return c;
}

/* A snprintf relay is defined in _printf.s */
