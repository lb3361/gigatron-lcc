#include <stdio.h>
#include <math.h>
#include <errno.h>
#include <gigatron/libc.h>

/* From _trig.c */
extern double __pi_over_4;
extern double __k_sin_over_x(double x);
extern double __k_cos(double x);


double cos(double x)
{
	int tmp, quo;
	x = _fmodquo(fabs(x), __pi_over_4, &tmp);
	if ((quo = tmp) & 1)
		x = __pi_over_4 - x;
	if ((quo + 1) & 2)
		x = __k_sin_over_x(x) * x;
	else
		x = __k_cos(x);
	if ((quo + 2) & 4)
		x = -x;
	return x;
}
