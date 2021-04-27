
#include <string.h>

int
strcmp(const char *s1, const char *s2)
{
	while(*s1 && *s1 == *s2) {
		s1++;
		s2++;
	}
	if (*(const unsigned char*)s1 > *(const unsigned char*)s2)
		return +1;
	else if (*(const unsigned char*)s1 < *(const unsigned char*)s2)
		return -1;
	return 0;
}
