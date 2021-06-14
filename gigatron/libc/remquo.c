#include <gigatron/libc.h>
#include <math.h>

double remquo(double x, double y, int *pquo)
{
	/* All positive below */
	double r = _fmodquo(fabs(x), y, pquo);
	register int quo = *pquo;
	/* Rounding adjustement with even rule */
	double mr = fabs(y) - r;
	if (mr < r || (mr == r && (quo & 1))) {
		quo += 1;
		r = -mr;
	}
	/* Sign adjustments */
	if (x < 0) {
		r = -r;
		if (y > 0)
			quo = -quo;
	} else {
		if (y < 0)
			quo = -quo;
	}
	*pquo = quo;
	return r;
}
