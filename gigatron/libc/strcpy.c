#include <string.h>
#include <gigatron/libc.h>

char *
strcpy(register char *dst, register const char *src)
{
	memcpy(dst, src, (const char*)__memchr2(src, 0, 0xffffu) - src + 1);
	return dst;
}
