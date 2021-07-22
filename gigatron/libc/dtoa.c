#include <stdio.h>
#include <math.h>
#include <float.h>
#include <stdlib.h>
#include <string.h>
#include <gigatron/libc.h>

// #define DEBUG(x) printf x
#define DEBUG(x)

static const double p9 = 1e9;
static const double p8 = 1e8;

char *dtoa(double x, char *buf, register char fmt, register int prec)
{
	int tmp;
	double y;
	register int exp;
	register int per;
	register int skip = 0;
	register char *q = buf;
	/* Prevent allocating a register for x or y */
	(void) &x;
	(void) &y;
	/* Decode */
	if (x < 0)
		*q++ = '-';
	if (x == 0) {
		y = 1;
		exp = tmp = 0;
	} else {
		x = _frexp10(fabs(x), &tmp);
		DEBUG(("| frexp -> %.2f %d\n", x, tmp));
		if (x < (y = p9)) {
			y = p8;
			exp = tmp + 8;
			tmp = 8;
		} else {
			exp = tmp + 9;
			tmp = 9;
		}
	}
	/* Position period */
	per = 1;
	if (fmt == 'g' && prec > 1)
		prec -= 1;
	if (fmt == 'f' || fmt != 'e' && exp >= -4 && exp < prec) {
		if ((per = per + exp) <= 0) {
			skip = 1 - per;
			per = 1;
		}
		exp = 0;
	}
	/* Round */
	x += _ldexp10(5, tmp - per - prec);
	DEBUG(("|  rounded %.2f %.8g\n", x, y));
	DEBUG(("|  exp=%d per=%d skip=%d tmp=%d prec=%d\n", exp, per, skip, tmp, prec));
	/* Extract digits */
	while (per > 0 || prec > 0) {
		if (skip > 0) {
			skip -= 1;
			tmp = 0;
		} else {
			DEBUG(("|  extract %.8g %.8g -> ", x, y));
			x = _fmodquo(x, y, &tmp);
			if (tmp >= 10) {
				DEBUG((" (carry while rounding!) "));
				tmp = 1;
				exp += 1;
			} else 
				x = _ldexp10(x, 1);
			DEBUG((" %.8g %.8g %d\n", x, y, tmp));
		}
		if (per == 0)
			*q++ = '.';
		*q = '0' + tmp;
		q += 1;
		if (--per < 0)
			--prec;
	}
	/* Kill extra zeroes for g style */
	if (fmt == 'g') {
		while (per < 0 && q[-1] == '0') {
			q -= 1;
			per += 1;
		}
		if (q[-1] == '.')
			q -= 1;
	}
	/* Exponent */
	if (exp || fmt == 'e') {
		*q = 'e';
		q += 1;
		if (exp >= 0)
			*q = '+';
		else {
			exp = -exp;
			*q = '-';
		}
		q += 1;
		*q = '0' + exp / 10;
		q += 1;
		*q = '0' + exp % 10;
		q += 1;
	}
	*q = 0;
	return buf;
}

