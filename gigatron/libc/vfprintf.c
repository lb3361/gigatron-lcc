#include <stdarg.h>
#include <stdlib.h>

#include "_stdio.h"
#include "_doprint.h"

int vfprintf(register FILE *fp, register const char *fmt, register __va_list ap)
{
	register struct _doprint_dst_s *sav = _doprintdst;
	register int c = EOF;
	struct _doprint_dst_s dd;
	_doprintdst = &dd;
	dd.fp = fp;
	if ((dd.writall = _schkwrite(fp))) {
		c = _doprint(fmt, ap);
		if (ferror(fp))
			c = EOF;
	}
	_doprintdst = sav;
	return c;
}

/* A fprintf relay is defined in _printf.s */
