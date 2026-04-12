#include <string.h>
#include <gigatron/libc.h>

char *
strcat(register char *dst, register const char *src)
{
	strcpy((char*)__memchr2(dst, 0, 0xffffu), src);
	return dst;
}
