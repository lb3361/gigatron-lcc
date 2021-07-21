#include <stdio.h>
#include <stdarg.h>

int vprintf(const char *fmt, va_list ap)
{
	return vfprintf(stdout, fmt, ap);
}	
