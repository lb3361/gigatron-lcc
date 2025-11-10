#include <stdio.h>
#include <stdarg.h>

#include "_stdio.h"
#include "_doprint.h"

int vprintf(register const char *fmt, register __va_list ap)
{
	register struct _doprint_dst_s *sav = _doprintdst;
	register int c = EOF;
	struct _doprint_dst_s dd;
	_doprintdst = &dd;
	dd.fp = stdout;
	if ((dd.writall = _schkwrite(stdout)))
		c = _doprint(fmt, ap);
	_doprintdst = sav;
	return c;
}

/* A printf relay is defined in _printf.s */
