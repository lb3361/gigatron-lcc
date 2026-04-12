#include <string.h>
#include <gigatron/libc.h>

char *
strncpy(register char *dst, register const char *src, size_t n)
{
	register int l = strlen(src);
	if (l > n)
		l = n;
	memcpy(dst, src, l);
	if (l < n)
		memset(dst+l, 0, n-l);
	return dst;
}
