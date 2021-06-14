
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <errno.h>
#include <math.h>
#include <gigatron/libc.h>


static double pp10[] = {1e32,1e16,1e8,1e4,1e2,1e1};
static double np10[] = {1e-32,1e-16,1e-8,1e-4,1e-2,1e-1};


/* Warning: when one approaches MAX_FLOAT or MIN_FLOAT, this code is
   going to overflow or underflow up to one bit earlier than it should
   because the multiplication threshold the exponent before
   normalizing. */

static double _ldexp10sub(double x, int n, double *pp)
{
	register int i;
	for (; n > 32; n -= 32)
		x *= pp[0];
	for (i=0; i != 6; i += 1, n <<= 1)
		if (n & 32)
			x *= pp[i];
	return x;
}

double _ldexp10(double x, int n)
{
	if (n > 0) {
		x = _ldexp10sub(x, n, pp10);
	} else if (n < 0) {
		x = _ldexp10sub(x, -n, np10);
	}
	return x;
}


