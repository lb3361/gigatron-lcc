#include <math.h>
#include <errno.h>
#include <gigatron/libc.h>

double sqrt(double x)
{
	if (x <= _fzero) {
		if (x == _fzero)
			return _fzero;
		errno = EDOM;
		return _fexception(_fminus);
	} else {
		register int i;
		int e;
		double w = x;
		double z = frexp(x, &e);
		x = 4.173075996388649989089E-1 + 5.9016206709064458299663E-1 * z;
		if (e & 1)
			x = x * 1.41421356237309504880;
		x = ldexp(x, (e >> 1));
		for (i=0; i!=3; i++)
			x = (x + w / x) * _fhalf;
		return x;
	}
}

