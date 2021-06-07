#include <math.h>
#include <gigatron/math.h>


static double sqrt1(register double x, register double u)
{
	register double v;
	do {
		v = u;
		u = ( v + x / v ) * 0.5;
	} while (u != v);
	return u;
}

double sqrt(register double x)
{
	if (x > 0) {
		int exp = 0;
		register double u = frexp(x, &exp);
		return sqrt1(x, ldexp(u, exp/2));
	}
	if (x < 0) {
		return _fexception(-1.0);
	}
	return 0.0;
}
