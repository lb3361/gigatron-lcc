#include <math.h>
#include <errno.h>
#include <gigatron/libc.h>


static double sqrt2 = 1.41421356237309504880;

double sqrt(double x)
{
	if (x <= 0) {
		if (x == 0)
			return 0.0;
		errno = EDOM;
		return _fexception(-1.0);
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
			x = (x + w / x) * 0.5;
		return x;
	}
}

