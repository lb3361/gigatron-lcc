#include <string.h>
#include <gigatron/libc.h>

size_t
strspn(register const char *s0, register const char *set)
{
	register int c;
	register const char *s = s0;
	while ((c = *s0) && *(char*)__memchr2(set, (char)c, 255))
		s0 += 1;
	return s0 - s;
}

size_t
strcspn(register const char *s0, register const char *set)
{
	register int c;
	register const char *s = s0;
	while ((c = *s0) && !*(char*)__memchr2(set, (char)c, 255))
		s0 += 1;
	return s0 - s;
}
