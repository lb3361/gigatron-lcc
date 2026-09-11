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
		int e;
		register double z = frexp(x, &e);
		register char i;
		if (! (e & 1))
			z *= _fhalf;
		z += _fhalf;
		z = ldexp(z, (e >> 1));
		for (i=(char)-3; i; i++)
			z = (z + x / z) * _fhalf;
		return z;
	}
}

