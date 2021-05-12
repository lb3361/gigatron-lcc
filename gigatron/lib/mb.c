#include <stdlib.h>

/* We assume LATIN1 encoding on the Gigatron */

int mblen(const char *s, size_t n)
{
	if (s == 0 || *s == 0)
		return 0;
	if (n <= 0)
		return -1;
	return 1;
}

int mbtowc(wchar_t *pwc, const char *s, size_t n)
{
	if (n <= 0)
		return -1;
	if (s == 0 || *s == 0)
		return 0;
	if (pwc)
		*pwc = *s;
	return 1;
}

int wctomb(char *s, wchar_t wc)
{
	if (s == 0)
		return 0;
	if (wc & 0xff00)
		return -1;
	*s = (char)wc;
	return 1;
}


size_t mbstowcs(wchar_t *d, const char *s, size_t n)
{
	size_t r = 0;
	if (s != 0) {
		while (*s && r < n) {
			if (d) { *d++ = *s; }
			r += 1, s += 1;
		}
	}
	return r;
}

size_t wcstombs(char *d, const wchar_t *s, size_t n)
{
	size_t r = 0;
	if (s != 0) {
		while (*s && r < n) {
			if (*s & 0xff00) { return (size_t)-1; }
			if (d) { *d++ = *s; }
			r += 1, s += 1;
		}
	}
	return r;
}

