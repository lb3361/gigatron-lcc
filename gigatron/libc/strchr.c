#include <string.h>

extern const void* _memchr2(const void*, char, char, size_t);

char *
strchr(register const char *p, register int ch)
{
	const char *q = _memchr2(p, ch, 0, 0xffffu);
	if (q && *q)
		return (char*)q;
	return 0;
}

