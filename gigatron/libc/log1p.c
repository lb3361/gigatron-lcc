#include <gigatron/libc.h>
#include <errno.h>
#include <math.h>


/* Using the Cephes method which is an overkill. */

static double P[] = {
		     1.01875663804580931796E-4,
		     4.97494994976747001425E-1,
		     4.70579119878881725854E0,
		     1.44989225341610930846E1,
		     1.79368678507819816313E1,
		     7.70838733755885391666E0,
};
static double Q[] = {
		     /* one */
		     1.12873587189167450590E1,
		     4.52279145837532221105E1,
		     8.29875266912776603211E1,
		     7.11544750618563894466E1,
		     2.31251620126765340583E1,
};

double log1p(register double x)
{
	register double z, y;
	if (x <= 0.25 || x >= 4)
		return log(1.0 + x);
	z = x * x;
	y = x * ( z * _polevl( x, P, 5 ) / _p1evl( x, Q, 5 ) );
	return x - 0.5 * z + y;
}
