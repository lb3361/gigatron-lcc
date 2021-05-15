#include <string.h>

char *
strchr(const char *p, int ch)
{
	for(; *p; p++)
		if (*p == ch)
			return (char*)p;
	return 0;
}
