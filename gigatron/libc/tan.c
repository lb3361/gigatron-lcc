#include <stdio.h>
#include <math.h>
#include <errno.h>
#include <gigatron/libc.h>

/* From _trig.c */
extern double __pi_over_4;
extern double __k_sin_over_x(double x);
extern double __k_cos(double x);


double tan(double x)
{
	int tmp;
	register int quo, qs;
	double s, c;
	qs = 0;
	if (x < 0)
		qs = 4;
	x = _fmodquo(fabs(x), __pi_over_4, &tmp);
	if ((quo = tmp) & 1)
		x = __pi_over_4 - x;
	s = __k_sin_over_x(x) * x;
	c = __k_cos(x);
	if ((quo + 1) & 2)
		x = c / s;
	else
		x = s / c;
	if (quo & 2)
		x = -x;
	return x;
}
