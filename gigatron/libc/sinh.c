#include <stdio.h>
#include <math.h>
#include <errno.h>
#include <gigatron/libc.h>

static double ln2 = 0.6931471805599453;

double sinh(double x)
{
	register char sgn = 0;
	if (x < _fzero) {
		x = -x;
		sgn++;
	}
	if (x < 16.0) {
		x = exp(x);
		x = ldexp(x - _fone / x, -1);
	} else
		x = exp(x - ln2);
	if (sgn)
		x = -x;
	return x;
}

double cosh(double x)
{
	if (x < _fzero)
		x = -x;
	if (x < 16.0) {
		x = exp(x);
		x = ldexp(x + _fone / x, -1);
	} else
		x = exp(x - ln2);
	return x;
}

double tanh(double x)
{
	register char sgn = 0;
	if (x < _fzero) {
		x = -x;
		sgn++;
	}
	if (x < 16.0) {
		x = exp(-ldexp(x, 1));
		x = (_fone - x) / (_fone + x);
	} else
		x = _fone;
	if (sgn)
		x = -x;
	return x;
}

