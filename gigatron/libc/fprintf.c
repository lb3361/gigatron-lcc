#include <stdio.h>
#include <stdarg.h>

int fprintf(FILE *fp, const char *fmt, ...)
{
	register int r;
	va_list ap;
	va_start(ap, fmt);
	r = vfprintf(fp, fmt, ap);
	va_end(ap);
	return r;
}
