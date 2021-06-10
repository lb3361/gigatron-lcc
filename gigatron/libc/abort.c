#include <stdlib.h>
#include <signal.h>
#include <gigatron/libc.h>

void abort(void)
{
	raise(SIGABRT);
	_raise_disposition = 0;  /* in case somebody changed it... */
	raise(SIGABRT);
}
