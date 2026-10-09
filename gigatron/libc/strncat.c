#include <string.h>
#include <gigatron/libc.h>

char *
strncat(register char *dst, register const char *src, register size_t n)
{
	register char *e;
	register int l = strlen(src);
	if (l > n)
		l = n;
	memcpy(e = _strend(dst), src, l);
	e[l] = 0;
	return dst;
}
