#include <limits.h>
#include <ctype.h>
#include <errno.h>
#include <stdlib.h>

static unsigned long _basen(const char **sptr, char *ovf, int base)
{
	register const char *s = *sptr;
	register unsigned long x = 0;
	register int c = *s;
	for(;;) {
		if (c >= '0' && c <= '9')
			c = c - '0';
		else {
			c = (c & 0xdf) - (int)('A' - 10);
			if (c < 10)
				break;
		}
		if (c >= base)
			break;
		if (x >= 0x00ffffff) {
			unsigned long y = (x >> 16) * base;
			x = (unsigned int)x * (unsigned long)base + c;
			y = y + (x >> 16);
			if (y != (y & 0xffff)) {
				*ovf = 1;
				x = ULONG_MAX;
			} else
				x = (unsigned int)x + (y << 16);
		} else 
			x = base * x + c;
		c = *++s;
	}
	*sptr = s;
	return x;
}

static unsigned long _base0(const char **sptr, char *ovf)
{
	register const char *s = *sptr;
	register int c = *s;
	if (c == '0' && (s[1] & 0xdf) == 'X') {
		*sptr = s+2;
		return _basen(sptr, ovf, 16);
	} else if (c == '0') {
		*sptr = s+1;
		return _basen(sptr, ovf, 8);
	}
	return _basen(sptr, ovf, 10);
}


static unsigned long _strtoul(const char *nptr, char **endptr, register int base,
			      register char *neg, register char *ovf)
{
	register unsigned long x;
	register const char *s = nptr;
	register int c = *s;
	const char *ss;

	while (isspace(c))
		c = *++s;
	if (c == '-') {
		*neg = 1;
		c = *++s;
	} else if (c == '+')
		c = *++s;
	ss = s;
	if (base == 0)
		x = _base0(&ss, ovf);
	else if (base > 1 && base <= 36)
		x = _basen(&ss, ovf, base);
	else {
		errno = EINVAL;
		x = 0;
	}
	if (ss == s)
		ss = nptr;
	if (endptr)
		*endptr = (char*)ss;
	return x;
}

unsigned long int strtoul(const char *nptr, char **endptr, register int base)
{
	char n = 0;
	char ovf = 0;
	register unsigned long x = _strtoul(nptr, endptr, base, &n, &ovf);
	if (ovf)
		errno = ERANGE;
	else if (n) 
		x = -(long)x;
	return x;
}

long int strtol(const char *nptr, char **endptr, register int base)
{
	char n = 0;
	char ovf = 0;
	register unsigned long x = _strtoul(nptr, endptr, base, &n, &ovf);
	if (n) {
		if (ovf || x > -LONG_MIN) {
			errno = ERANGE;
			return LONG_MIN;
		} else
			return -(long)x;
	} else {
		if  (ovf || x > LONG_MAX) {
			errno = ERANGE;
			return LONG_MAX;
		}
		return x;
	}
}


