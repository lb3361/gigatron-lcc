#include <stdio.h>
#include <stdlib.h>

long atol(const char *s)
{
	return strtol(s, NULL, 0);
}

int  atoi(const char *s)
{
	return (int)strtol(s, NULL, 0);
}
