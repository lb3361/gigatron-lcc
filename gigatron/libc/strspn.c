#include <string.h>
#include <gigatron/libc.h>


static unsigned char _buf[32];
static unsigned char _mask[8] = { 1,2,4,8,16,32,64,128 };


static void
_doset(const char *set)
{
	register unsigned char *buf = _buf;
	register unsigned char *mask = _mask;
	register unsigned int c = (unsigned char)*set;
	while (c) {
		buf[c&31] |= mask[c>>5];
		c = (unsigned char)*++set;
	}
}

static const char *
_strspn(const char *s)
{
	register unsigned char *buf = _buf;
	register unsigned char *mask = _mask;
	register unsigned int c = (unsigned char)*s;
	while (buf[c&31] & mask[c>>5])
		c = (unsigned char)*++s;
	return s;		
}

size_t
strspn(const char *s, const char *set)
{
	memset(_buf, 0, sizeof(_buf));
	_doset(set);
	return _strspn(s) - s;
}

static const char *
_strcspn(const char *s)
{
	register unsigned char *buf = _buf;
	register unsigned char *mask = _mask;
	register unsigned int c = (unsigned char)*s;
	buf[0] |= mask[0];
	while (!(buf[c&31] & mask[c>>5]))
		c = (unsigned char)*++s;
	return s;		
}

size_t
strcspn(const char *s, const char *set)
{
	memset(_buf, 0, sizeof(_buf));
	_doset(set);
	return _strcspn(s) - s;
}
