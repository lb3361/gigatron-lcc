#include <limits.h>
#include <ctype.h>
#include <errno.h>
#include <stdlib.h>
#include <gigatron/libc.h>

#include "_stdlib.h"


#define FLG_MINUS 1
#define FLG_PLUS  2
#define FLG_0X    4
#define FLG_DIGIT 8
#define FLG_OVF   128

int _strtol_push(strtol_t *d, int c)
{
	register int v = 0;
	register int base = d->base;
	register int f = d->flags;

	if (f == 0) {
		if (c == '-') {
			f = FLG_MINUS;
			goto ret;
		} else if (c == '+') {
			f = FLG_PLUS;
			goto ret;
		}
	}
	if (base == 0) {
		if (f & FLG_0X) {
			if ((c | 0x20) == 'x') {
				base = d->base = 16;
				goto ret;
			} else {
				f |= FLG_DIGIT;
				base = d->base = 8;
			}
		} else if (c == '0') {
			f |= FLG_0X;
			goto ret;
		} else
			base = d->base = 10;
	}
	if ((v = c - '0') > 9)
		if ((v = (c | 0x20) - 'a') >= 0)
			v = v + 10;
	if (v < 0 || v - base >= 0)
		return 0;
	f |= FLG_DIGIT;
	/* update d->x caring for overflows */
	register unsigned long *xp = & d->x;
	register char *xphi = (char*)xp + 3;
	register int xhi = *xphi;
	*xphi = 0;
	*xp = *xp * base + v;
	xhi = xhi * base + *xphi;
	*xphi = (char)xhi;
	if  (xhi != (char)xhi) {
		f |= FLG_OVF;
		*xp = ULONG_MAX;
	}		
 ret:
	return d->flags = f;
}

int _strtol_decode_u(strtol_t *d, unsigned long *px)
{
	if (! (d->flags & FLG_DIGIT))
		return 0;
	if (d->flags & FLG_OVF)
		errno = ERANGE;
	else if (d->flags & FLG_MINUS)
		d->x = (unsigned long)(-(long)(d->x));
	if (px)
		*px = d->x;
	return 1;
}

int _strtol_decode_s(strtol_t *d, long *px)
{
	static unsigned long lmin = (unsigned long)LONG_MIN;
	static unsigned long lmax = LONG_MAX;
	register unsigned long *lm = &lmax;
	register unsigned long *pdx = &d->x;
	if (! (d->flags & FLG_DIGIT))
		return 0;
	if (d->flags & FLG_MINUS)
		lm = &lmin;
	if ((d->flags & FLG_OVF) || (*pdx > *lm)) {
		errno = ERANGE;
		*pdx = *lm;
	} else if (d->flags & FLG_MINUS) 
		*pdx = (unsigned long)(-(long)*pdx);
	if (px)
		*px = (long)*pdx;
	return 1;
}

static const char *worker(register strtol_t *d, register const char *p, register int base)
{
	d->x = _lzero;
	d->flags = 0;
	d->base = base;
	while (isspace(p[0]))
		p += 1;
	while (_strtol_push(d, p[0]))
		p += 1;
	return p;
}

unsigned long int strtoul(const char *nptr, char **endptr, register int base)
{
	strtol_t dd;
	register strtol_t *d = &dd;
	register const char *p = worker(d, nptr, base);
	unsigned long x = _lzero;
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
	long x = 0;
	if (! _strtol_decode_s(d, &x))
		p = nptr;
	if (endptr)
		*endptr = (char*)p;
	return x;
}


