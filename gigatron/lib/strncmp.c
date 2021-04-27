
#include <string.h>

int
strncmp(const char *s1, const char *s2, size_t n)
{
	for(;;) {
		if (n == 0)
			return 0;
		if (*s1 == 0 || *s1 != *s2)
			break;
		s1++;
		s2++;
		n--;
	}
	if (*(const unsigned char*)s1 > *(const unsigned char*)s2)
		return +1;
	else if (*(const unsigned char*)s1 < *(const unsigned char*)s2)
		return -1;
	return 0;
}
