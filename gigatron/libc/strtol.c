#include <limits.h>
#include <ctype.h>
#include <errno.h>
#include <stdlib.h>
#include "_stdio.h"


#define FLG_MINUS 1
#define FLG_PLUS  2
#define FLG_0X    4
#define FLG_DIGIT 8
#define FLG_OVF   128

int _strtol_push(strtol_t *d, const char *p)
{
	/* p[0] : current char
           p[1] : lookahead char */
	register int f = d->flags;
	register int base = d->base;
	register int fchk = 0;
	register int v = 0;
	register int c = p[0];
	unsigned long x;

	if (f == 0) {
		if (c == '-')
			fchk = FLG_MINUS;
		if (c == '+')
			fchk = FLG_PLUS;
	}
	if (fchk) {
		base = 10;
		c = p[1];
	} else if (base == 0) {
		if (f & FLG_0X) {
			fchk = f;
			d->base = base = 16;
			c = p[1];
		} else if (c != '0')
			d->base = base = 10;
		else if ((p[1] | 0x20) == 'x')
			return (d->flags = (f | FLG_0X | FLG_DIGIT));
		else
			d->base = base = 8;
	}
	if ((v = c - '0') > 9)
		if ((v = (c | 0x20) - 'a') >= 0)
			v = v + 10;
	if (v < 0 || v >= base)
		return 0;
	if (fchk)
		return d->flags = fchk;
	x = d->x;
	if (x >= 0x00ffffff) {
		unsigned long y = (x >> 16) * base;
		x = (unsigned int)x * (unsigned long)base + v;
		y = y + (x >> 16);
		if (y != (y & 0xffff)) {
			f |= FLG_OVF;
			d->x = ULONG_MAX;
		} else
			d->x = (unsigned int)x + (y << 16);
	} else
		d->x = base * x + v;
	return d->flags = (f | FLG_DIGIT);
}

int _strtol_decode_u(strtol_t *d, unsigned long *px)
{
	if (d->flags & FLG_DIGIT) {
		*px = d->x;
		if (d->flags & FLG_OVF) {
			errno = ERANGE;
		} else if (d->flags & FLG_MINUS)
			*px = (unsigned long) - (long)(d->x);
		return 1;
	}
	*px = 0;
	return 0;
}

int _strtol_decode_s(strtol_t *d, long *px)
{
	if (d->flags & FLG_DIGIT) {
		static unsigned long lmin = (unsigned long)LONG_MIN;
		static unsigned long lmax = LONG_MAX;
		register unsigned long *lm = &lmax;
		register unsigned long *pdx = &d->x;
		if (d->flags & FLG_MINUS)
			lm = &lmin;
		if ((d->flags & FLG_OVF) || (*pdx > *lm)) {
			errno = ERANGE;
			*px = *(long*)lm;
		} else if (d->flags & FLG_MINUS)
			*px = -*(long*)pdx;
		else
			*px = *(long*)pdx;
		return 1;
	}
	*px = 0;
	return 0;
}

static const char *worker(register strtol_t *d, register const char *p, register int base)
{
	d->x = 0;
	d->flags = 0;
	d->base = base;
	while (isspace(p[0]))
		p += 1;
	while (_strtol_push(d, p))
		p += 1;
	return p;
}

unsigned long int strtoul(const char *nptr, char **endptr, register int base)
{
	strtol_t dd;
	register strtol_t *d = &dd;
	register const char *p = worker(d, nptr, base);
	unsigned long x;
	if (! _strtol_decode_u(d, &x))
		p = nptr;
	if (endptr)
		*endptr = (char*)p;
	return x;
}

long int strtol(const char *nptr, char **endptr, register int base)
{
	strtol_t dd;
	register strtol_t *d = &dd;
	register const char *p = worker(d, nptr, base);
	long x;
	if (! _strtol_decode_s(d, &x))
		p = nptr;
	if (endptr)
		*endptr = (char*)p;
	return x;
}


