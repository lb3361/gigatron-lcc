#include <stdio.h>
#include <math.h>
#include <errno.h>
#include <gigatron/libc.h>

double atan2(double y, double x)
{
	register char nx = 0;
	register char ny = 0;
	if (x < _fzero)
		{ nx++; x = -x; }
	if (y < _fzero)
		{ ny++; y = -y; }
	if (x != _fzero && x >= y)
		x = atan(y / x);
	else if (y != _fzero)
		x = _pi_over_2 - atan(x / y);
	if (nx)
		x = _pi - x;
	if (ny)
		x = -x;
	return x;
}
