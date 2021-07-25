#include <stdio.h>
#include <math.h>
#include <float.h>
#include <stdlib.h>
#include <string.h>
#include <gigatron/libc.h>

/* Helpers defined in itoa.s */
extern int _utwoa(int);
extern char *_uftoa(double,char*);

#if 0
# define DBG(x) printf x
#else
# define DBG(x)
#endif

/* This file contains two implementations of dtoa
   Which one offers the best compromise of code size
   and accuracy is an open question... */

#if 1

static const double halfm = (2.0 - DBL_EPSILON) / 4.0;
static const double billion = 1e9;

char *dtoa(double x, char *buf, register char fmt, register int prec)
{
	int tmp;
	char lbuf[16];
	register int exp, nd, per;
	register char *q = buf;
	register char *s;
	(void) &x;

	if (x < _fzero) {
		*q = '-';
		q++;
	}
	/* Decode */
	x = _frexp10(fabs(x), &tmp) + halfm;
	nd = 9;
	if (x >= billion)
		nd = 10;
	else if (x < _fone)
		nd = 1;
	DBG(("| frexp -> %.2f exp=%d nd=%d\n", x, tmp, nd));
	/* Position period */
	per = 1;
	exp = tmp + nd - per;
	if (fmt == 'g' && prec - 1 > 0)
		prec -= 1;
	if (fmt == 'f' || fmt != 'e' && exp +4 >= 0 && exp - prec <= 0) {
		if ((per = per + exp) <= 0 && (fmt != 'f'))
			prec = prec - per + 1;
		exp = 0;
	}
	DBG(("| exp=%d per=%d prec=%d nd=%d\n", exp, per, prec, nd));
	/* Truncate */
	if (per + prec - nd < 0) {
		x = _ldexp10(x, per + prec - nd) + halfm;
		nd = per + prec;
		DBG(("| trunc: nd=%d\n", nd));
	}
	/* Extract digits */
	//s = ultoa((long)x, lbuf, 10);
	s = _uftoa(x, lbuf);
	DBG(("| digits=[%s]\n", s));
	if (s[nd] != 0) {
		/* Carry propagation during rounding got us an extra digit */
		if (fmt == 'e' || fmt != 'f' && per != 1) {
			lbuf[nd] = 0;
			exp += 1;
		} else
			per += 1;
		DBG(("| carry adjustment: digits=[%s] exp=%d per=%d\n", s, exp, per));
	}
	/* Output digits */
	if ((nd = 1 - per) < 0)
		nd = 0;
	per = per + nd;
	DBG(("| skip=%d per=%d\n", nd, per));
	while (per > 0 || prec > 0) {
		if (per == 0) {
			*q = '.';
			q += 1;
		}
		if ((per = per - 1) < 0)
			prec = prec - 1;
		if (nd <= 0 && *s) {
			*q = *s;
			s += 1;
		} else
			*q = '0';
		q += 1;
		nd -= 1;
	}
	/* Remove zeroes for g style */
	if (fmt == 'g' && per < 0) {
		do {
			q -= 1;
		} while (*q == '0');
		if (*q != '.')
			q += 1;
	}
	/* Output exponent */
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
		exp = _utwoa(exp);
		*q = (exp >> 8);
		q += 1;
		*q = exp;
		q += 1;
	}
	*q = 0;
	return buf;
}

#else

static const double p9 = 1e9;
static const double p8 = 1e8;
static const double fivem = ((2.0 - DBL_EPSILON) / 4.0) * 10.0;

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
		DBG(("| frexp -> %.2f %d\n", x, tmp));
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
	if (fmt == 'f' || fmt != 'e' && exp >= -4 && exp <= prec) {
		if ((per = per + exp) <= 0) {
			skip = 1 - per;
			per = 1;
		}
		exp = 0;
	}
	/* Round */
	x = _ldexp10(fivem, tmp - per - prec) + x;
	DBG(("|  rounded %.2f %.8g\n", x, y));
	DBG(("|  exp=%d per=%d skip=%d tmp=%d prec=%d\n", exp, per, skip, tmp, prec));
	/* Extract digits */
	while (per > 0 || prec > 0) {
		if (skip > 0) {
			skip -= 1;
			tmp = 0;
		} else {
			DBG(("|  extract %.8g %.8g -> ", x, y));
			x = _fmodquo(x, y, &tmp);
			if (tmp >= 10) {
				DBG((" (carry while rounding!) "));
				tmp = 1;
				exp += 1;
			} else 
				x = _ldexp10(x, 1);
			DBG((" %.8g %.8g %d\n", x, y, tmp));
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
		exp = _utwoa(exp);
		*q = (exp >> 8);
		q += 1;
		*q = exp;
		q += 1;
	}
	*q = 0;
	return buf;
}

#endif
