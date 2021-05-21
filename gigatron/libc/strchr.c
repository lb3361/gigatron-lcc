#include <string.h>

extern const void* _memscan(const void*, int, size_t);

char *
strchr(register const char *p, register int ch)
{
	const char *q = _memscan(p, ch, 0xffffu);
	if (q && *q)
		return (char*)q;
	return 0;
}

