#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <errno.h>
#include <math.h>
#include <string.h>
#include "_stdio.h"

/* This code is much simpler than a numerically correct strtod 
   but gets the exact numbers right. */

#define ST_SIGN    0
#define ST_MANT    1
#define ST_ESGN    2
#define ST_EXPN    3
#define FLG_NEGEXP 8
#define FLG_DIGIT  16
#define FLG_PERIOD 32
#define FLG_NEG    64
#define FLG_OVF    128

int _strtod_push(strtod_t *d, const char *p)
{
	/* p[0]    : current char
           p[1..2] : lookahead chars */
	register int c = p[0];
	register int f = d->flags;
	
	if (f == 0) {
		f = ST_MANT;
		if (c == '-') {
			f |= FLG_NEG;
			goto sign;
		} else if (c == '+') {
		sign:   if ((c = p[1]) == '.')
				c = p[2];
			if (! _isdigit(c))
				goto end;
			goto ret;
		}
	}
	if ((f & 0x7) == ST_MANT) {
		if (c == '.') {
			if (f & FLG_PERIOD)
				goto end;
			f |= FLG_PERIOD;
			if ((f & FLG_DIGIT) || _isdigit(p[1]))
				goto ret;
			goto end;
		} else if (_isdigit(c)) {
			double x = d->x;
			f |= FLG_DIGIT;
			if (x < 1e16) {
				if (f & FLG_PERIOD)
					d->e0 -= 1;
				d->x = x * 10 + (double)(c - '0');
			} else if (! (f & FLG_PERIOD)) 
					d->e0 += 1;
			goto ret;
		} else if ((c | 0x20) == 'e') {
			c = p[1];
			if (c == '+' || c == '-')
				c = p[2];
			if (! _isdigit(c))
				return 0;
			f = f ^ ((f ^ ST_ESGN) & 0x7);
			goto ret;
		} 
		return 0;
	}
	if ((f & 0x7) == ST_ESGN) {
		f = f ^ ((f ^ ST_EXPN) & 0x7);
		if (c == '-') {
			f |= FLG_NEGEXP;
			goto ret;
		} else if (c == '+')
			goto ret;
	}
	if ((f & 0x7) == ST_EXPN) {
		int e1 = d->e1;
		if (_isdigit(c)) {
			if (e1 < 250)
				d->e1 = e1 * 10 + c - '0';
			goto ret;
		}
	}
 end:
	return 0;
 ret:
	return d->flags = f;
}

int _strtod_decode(strtod_t *d, double *px)
{
	double x = d->x;
	register int e = d->e0;
	register int f = d->flags;
	void *saved_raise_disposition = _raise_disposition;

	if (! (f & FLG_DIGIT))
		return 0;
	if (f & FLG_NEGEXP)
		e -= d->e1;
	else
		e += d->e1;
	_raise_code = 0;
	_raise_disposition = RAISE_SETS_CODE;
	x = _ldexp10(x, e);
	if (_raise_code) {
		x = HUGE_VAL;
		errno = ERANGE;
	}
	_raise_disposition = saved_raise_disposition;
	if (f & FLG_NEG)
		x = -x;
	if (px)
		*px = x;
	return 1;
}


double strtod(const char *nptr, char **endptr)
{
	strtod_t dobj;
	double x = 0.0;
	register strtod_t *d = &dobj;
	register const char *p = nptr;

	memset(d, 0, sizeof(dobj));
	while (isspace(p[0]))
		p += 1;
	while (_strtod_push(d, p))
		p += 1;
	if (! _strtod_decode(d, &x))
		p = nptr;
	if (endptr)
		*endptr = (char*) p;
	return x;
}

double atof(register const char *s)
{
	return strtod(s, NULL);
}



