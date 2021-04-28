
#include <string.h>

void *memset(void *d, int c, size_t n)
{
	register unsigned s = (unsigned)d;
	unsigned e = s + n;
	if (s & 1) {
		*(char*)s = c;
		s += 1;
	}
	if (e & 1) {
		e -= 1;
		*(char*)e = c;
	}
	c = c & 0xff;
	c = (c << 8) | c;
	while (s != e) {
		*(unsigned*)s = c;
		s += 2;
	}
	return d;
}
