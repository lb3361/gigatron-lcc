#include <limits.h>
#include <ctype.h>
#include <errno.h>
#include <stdlib.h>
#include <signal.h>
#include <float.h>
#include <math.h>

static char _ovf;

void _sigfpe(int sig)
{
	_ovf = 1;
	errno = ERANGE;
	signal(SIGFPE, _sigfpe);
}

extern double _strtod(const char *nptr, char **endptr);

double strtod(const char *nptr, char **endptr)
{
	sig_handler_t saved = signal(SIGFPE, _sigfpe);
	register double x = _strtod(nptr, endptr);
	signal(SIGFPE, saved);
	if (_ovf && x < 0)
		return -HUGE_VAL;
	else if (_ovf)
		return HUGE_VAL;
	return x;
}


