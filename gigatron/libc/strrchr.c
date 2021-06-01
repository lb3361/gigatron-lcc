#include <string.h>

extern const void* _memchr2(const void*, char, char, size_t);

char *
strrchr(const char *p, register int ch)
{
	register const char *r = 0;
	register const char *q = p;
	while (*q && (q = _memchr2(q, ch, 0, 0xffffu)))
		while (*q && *q == ch)
			r = q++;
	return (char*)r;
}

