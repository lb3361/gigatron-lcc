#include <stdarg.h>
#include <stdlib.h>
#include <gigatron/console.h>

#include "_doprint.h"

int vcprintf(const char *fmt, register __va_list ap)
{
	register struct _doprint_dst_s *sav = _doprintdst;
	register int c;
	struct _doprint_dst_s dd;
	_doprintdst = &dd;
	dd.writall = (writall_t)console_writall;
	c = _doprint(fmt, ap);
	_doprintdst = sav;
	return c;
}

/* A cprintf relay is defined in _printf.s */
