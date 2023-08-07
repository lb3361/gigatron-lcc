#include <stdarg.h>
#include <stdlib.h>
#include <gigatron/console.h>

#include "_doprint.h"


/* Defined in doprint.s for size. Just calls console_print. */
extern void _doprint_console(void *closure, const char *buf, size_t sz);

int vcprintf(const char *fmt, __va_list ap)
{
	doprint_t ddobj;
	register doprint_t *dp = &ddobj;
	dp->cnt = 0;
	dp->f = _doprint_console;
	return _doprint(&ddobj, fmt, ap);
}

int cprintf(const char *fmt, ...)
{
	register va_list ap;
	va_start(ap, fmt);
	return vcprintf(fmt, ap);
}
