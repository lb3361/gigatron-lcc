#include "_stdio.h"

int puts(register const char *s)
{
	fputs(s, stdout);
	return fputs("\n", stdout);
}
