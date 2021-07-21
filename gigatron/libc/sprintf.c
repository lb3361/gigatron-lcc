#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "_stdio.h"

static int str_flsbuf(register int c, register FILE *fp)
{
	printf("flsbuf: [%c] %d\n", c, c);
	fp->_cnt = 0;
	return c;
}

static int str_write(FILE *fp, const void *buf, size_t sz)
{
	return sz;
}

static struct _svec v = { str_flsbuf, str_write, 0, 0, 0, 0 };

int vsprintf(char *s, const char *fmt, va_list ap)
{
	int r;
	struct _iobuf f;
	FILE *fp = &f;

	memset(fp, 0, sizeof(f));
	if (fp->_ptr = s)
		fp->_cnt = 0x7fff;
	fp->_flag = _IOFBF|_IOSTR|_IOWRIT;
	fp->_v = &v;
	r = vfprintf(fp, fmt, ap);
	if (fp->_cnt >= 0)
		*fp->_ptr++ = 0;
	return r;
}

int sprintf(char *s, const char *fmt, ...)
{
	register int r;
	va_list ap;
	va_start(ap, fmt);
	r = vsprintf(s, fmt, ap);
	va_end(ap);
	return r;
}
