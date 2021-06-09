#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <errno.h>
#include <math.h>
#include <gigatron/libc.h>

int _exponent(register const char **sp)
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
					exp = exp * 10 + c - '0';
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

double _mantissa(register const char **sp, int *pe)
{
	register const char *s = *sp;
	register int c = *s;
	register double x = 0.0;
	register double p = 1.0;
	int e = 0;
	int d = 0;

	/* leading zeroes */
	for(;; c = *++s) {
		if (c == '.')
			d = 1;
		else if (c == '0' && d)
			e -= 1;
		else if (c != '0')
			break;
	}
	/* mantissa */
	for(;; c = *++s) {
		if (c == '.' && !d)
			d = 1;
		else if (c >= '0' && c <= '9') {
			if (! d)
				e += 1;
			p = p * 0.1;
			x = x + (double)(c - '0') * p;
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
	while (exp > 0) {
		x = x * 10;
		exp -= 1;
	}
	while (exp < 0) {
		x = x * 0.1;
		exp += 1;
	}
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


