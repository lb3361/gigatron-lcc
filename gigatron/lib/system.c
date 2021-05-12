#include <stdlib.h>
#include <errno.h>

int errno;

int system(const char *)
{
	// Override in a map.
	errno = ENOTIMPL;
	return -1;
}
