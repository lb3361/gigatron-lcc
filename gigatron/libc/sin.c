#include <stdio.h>
#include <math.h>
#include <errno.h>
#include <gigatron/libc.h>

/* From _trig.c */
extern double __pi_over_4;
extern double __k_sin_over_x(double x);
extern double __k_cos(double x);


double sin(double x)
{
	int tmp;
	register int quo, qs;
	qs = 0;
	if (x < 0)
		qs = 4;
	x = _fmodquo(fabs(x), __pi_over_4, &tmp);
	if ((quo = tmp) & 1)
		x = __pi_over_4 - x;
	if ((quo + 1) & 2)
		x = __k_cos(x);
	else
		x = __k_sin_over_x(x) * x;
	if ((quo ^ qs) & 4)
		x = -x;
	return x;
}
