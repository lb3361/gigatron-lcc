#include <string.h>
#include <gigatron/libc.h>

char *
strcpy(register char *dst, register const char *src)
{
	memcpy(dst, src, _strend(src) - src + 1);
	return dst;
}
