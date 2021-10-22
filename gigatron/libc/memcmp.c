
#include <string.h>

int
memcmp(const void *s1, const void *s2, size_t n)
{
	int r;
	while (n) {
		if ((r = (int)*(const unsigned char*)s1 - (int)*(const unsigned char*)s2))
			return r;
		s1 = (const char*)s1 + 1;
		s2 = (const char*)s2 + 1;
		n--;
	}
	return 0;
}
