#include <stdlib.h>
#include <time.h>
#include <gigatron/libc.h>

time_t time(time_t *tloc)
{
	register time_t t = _lzero;
	if (tloc)
		*tloc = t;
	return t;
}
