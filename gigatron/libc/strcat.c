#include <string.h>
#include <gigatron/libc.h>

char *
strcat(register char *dst, register const char *src)
{
	strcpy((char*)_strend(dst), src);
	return dst;
}
