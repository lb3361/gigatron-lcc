#include <stdarg.h>
#include <stdlib.h>
#include <gigatron/console.h>

#include "_doprint.h"

int midcprintf(const char *fmt, ...)
{
	register struct _doprint_dst_s *sav = _doprintdst;
	register int c;
	struct _doprint_dst_s dd;
	register va_list ap;
	va_start(ap, fmt);
	_doprintdst = &dd;
	dd.writall = (writall_t)console_writall;
	c = _doprint_simple(fmt, ap);
	_doprintdst = sav;
	return c;
}
