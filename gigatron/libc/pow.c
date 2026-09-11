#include <gigatron/libc.h>
#include <errno.h>
#include <math.h>


static double _ipow(double x, unsigned long i)
{
	register double r = _fone;
	while (i) {
		if ((unsigned int)i & 1)
			r *= x;
		x *= x;
		i >>= 1;
	}
	return r;
}

double pow(double x, double y)
{
	double ye;
	if (y <= _fzero) {
		if (y == _fzero)
			return _fone;
		y = -y;
		x = _fone / x;
	}
	if (x == _fzero)
		return _fzero;
	if (modf(y, &ye) == _fzero)
		return _ipow(x, (unsigned long)ye);
	if (x < _fzero) {
		errno = EDOM;
		return _fexception(_fzero);
	} else {
		return exp(y * log(x));
	}
}
