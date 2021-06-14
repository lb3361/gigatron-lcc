#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <errno.h>
#include <math.h>
#include <gigatron/libc.h>

/* This code is much simpler than a numerically correct strtod. In
   particular it is going to overflow/underflow up to one bit below
   FLT_MAX or above FLT_MIN. */

static int _exponent(register const char **sp)
{
	register const char *s = *sp;
	register int exp = 0;
	register int c = *s;
	char neg = 0;

	if (c == 'e' || c == 'E') {
		c = *++s;
		if (c == '+' || (c == '-' && (neg = 1)))
			c = *++s;
		if (c >= '0' && c <= '9') {
			while (c >= '0' && c <= '9') {
				if (exp < 1000)
					exp = _ldexp10(exp,1) + c - '0';
				c = *++s;
			}
			*sp = s;
			if (neg)
				return -exp;
			else
				return exp;
		}
	}
	return 0;
}

static double _mantissa(register const char **sp, int *pe)
{
	register const char *s = *sp;
	register int c = *s;
	register int e = 0;
	int d = 0;
	double x = 0.0;
	
	/* leading zeroes */
	for(;; c = *++s) {
		if (c == '.' && !d)
			d = 1;
		else if (c == '0')
			e -= d;
		else
			break;
	}
	/* mantissa */
	for(;; c = *++s) {
		if (c == '.' && !d)
			d = 1;
		else if (c >= '0' && c <= '9') {
			if (x < 1e16) {
				e -= d;
				x = x * 10 + (double)(c - '0');
			} else if (! d) 
				e += 1;
		} else
			break;
	}
	/* return */
	*pe = e;
	*sp = s;
	return x;
}

double strtod(const char *nptr, char **endptr)
{
	register double x;
	register const char *s = nptr;
	register int c = *s;
	int  exp = 0;
	char neg = 0;

	/* suppress raise to capture sigfpe */
	void *saved_raise_disposition = _raise_disposition;
	_raise_code = 0;
	_raise_disposition = RAISE_SETS_CODE;
	/* skip space */
	while (isspace(c))
		c = *++s;
	if ((c == '+') || ((c == '-') && (neg = 1)))
		c = *++s;
	/* parse number */
	if (isdigit(c) || ((c == '.') && isdigit(s[1]))) {
		nptr = s;
		x = _mantissa(&nptr, &exp);
		exp += _exponent(&nptr);
	} else {
		x = 0.0;
	}
	/* finalize */
	x = _ldexp10(x, exp);
	/* check for error */
	_raise_disposition = saved_raise_disposition;
	if (_raise_code) {
		x = HUGE_VAL;
		errno = ERANGE;
	}
	/* return */
	if (neg)
		x = -x;
	if (endptr)
		*endptr = (char*)nptr;
	return x;
}

double atof(register const char *s)
{
	return strtod(s, NULL);
}


#if TEST
int main(int argc, char **argv)
{
	int i;
	for (i=1; i<argc; i++)
		{
			char *endptr = 0;
			double x = _strtod(argv[i], &endptr);
			printf("\t[%s] : %.8g : [%s]\n\n", argv[i], x, endptr);
		}
	return 0;
}
#endif


