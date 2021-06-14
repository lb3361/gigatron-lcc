
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <errno.h>
#include <math.h>
#include <gigatron/libc.h>

double _frexp10(double x, int *pn)
{
	int exp2;
	register int exp10;
	double y;
	frexp(x, &exp2);
	exp10 = (double)exp2 * 0.3; /* ballpark estimate */
	y = _ldexp10(fabs(x), -exp10);
	while (y >= 1.0) {
		y = y * 0.1;
		exp10 += 1;
	}
	while (y < 0.1) {
		y = y * 10;
		exp10 -= 1;
	}
	*pn = exp10;
	return copysign(y, x);
}


