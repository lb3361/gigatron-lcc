#include <stdio.h>
#include <stdarg.h>

int printf(const char *fmt, ...)
{
	register int r;
	va_list ap;
	va_start(ap, fmt);
	r = vfprintf(stdout, fmt, ap);
	va_end(ap);
	return r;
}
