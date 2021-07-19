#include <stdarg.h>
#include <stdlib.h>
#include "_stdio.h"

int fscanf(register FILE *fp, const char *fmt, ...)
{
	register int r;
	va_list ap;
	va_start(ap, fmt);
	r = _doscan(fp, fmt, ap);
	va_end(ap);
	return r;
}

int scanf(const char *fmt, ...)
{
	register int r;
	va_list ap;
	va_start(ap, fmt);
	r = _doscan(stdin, fmt, ap);
	va_end(ap);
	return r;
}
