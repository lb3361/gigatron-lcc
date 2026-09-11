
#include <string.h>

typedef const unsigned char *ptr;

int
memcmp(const void *s1, const void *s2, size_t n)
{
	register int d;
	while ((d = n) && !(d = *(ptr)s1 - *(ptr)s2)) {
		s1 = (ptr)s1 + 1;
		s2 = (ptr)s2 + 1;
		n--;
	}		
	return d;
}
