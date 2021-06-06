#include <math.h>
#include <gigatron/math.h>

double sqrt(register double x)
{
	int exp = 0;

	if (x <= 0) {
		if (x < 0)
			return _fexception(-1.0);
		return 0.0;
	} else {
		register double u,v;
		u = frexp(x, &exp);
		u = ldexp(u, exp/2);
		do {
			v = u;
			u = ( v + x / v ) / 2.0;
		} while (u != v);
		return u;
	}
}
