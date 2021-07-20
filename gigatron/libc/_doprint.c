#include "_stdio.h"
#include <stdarg.h>
#include <ctype.h>
#include <string.h>
#include <errno.h>


void _doprint_putc(doprint_t *dp, int c, size_t cnt)
{
	while (cnt) {
		fputc(c, dp->fp);
		cnt -= 1;
	}
	dp->cnt += cnt;
}

void _doprint_puts(register doprint_t *dp, register const char *s, register size_t cnt)
{
	register const char *e;
	if (e = memchr(s, 0, cnt))
		cnt = e - s;
	_fwrite(dp->fp, s, cnt);
	dp->cnt += cnt;
}


static int pushspec(int c, doprintspec_t *spec, va_list ap)
{
	static char fl[] = "-0+ #lLh";
	static char fv[] = { DPR_LEFTJ, DPR_ZEROJ, DPR_SGN, DPR_SPC, DPR_ALT, DPR_LONG, DPR_LONG, 0 };
	register int f = spec->flags;
	register int state = spec->conv;
	register int *np;
	register int nf;

	if (state == 0) {
		nf = 0;
		/* This also accepts lenght letters (lLh) 
		   in the flag section but that saves code */
	flg: 	for (; nf != sizeof(fl); nf++)
			if (c == fl[nf]) {
				f |= fv[nf];
				goto ok;
			}
		state += 1;
	}
	if (state == 1) {
		np = &spec->width;
		nf = DPR_WIDTH;
	num:	if (_isdigit(c)) {
			f |= nf;
			*np = *np * 10 + c - '0';
			goto ok;
		} else if (c == '*') {
			*np = va_arg(ap, int);
			if (state == 1) {
				f |= nf;
				if (*np < 0) {
					f |= DPR_LEFTJ; /* so ugly but ansi */
					*np = -*np;
				}
			} else {
				if (*np >= 0)
					f |= nf;
			}
			state += 1;
			goto ok;
		}
		state += 1;
	}
	if (state == 2) {
		if (c == '.') {
			state = 3;
			goto ok;
		}
		state = 4;
	}
	if (state == 3) {
		np = &spec->prec;
		nf = DPR_PREC;
		goto num;
	}
	if (state == 4) {
		nf = 5;
		goto flg;
	}
	if (state == 5) {
	done:	spec->flags = f;
		spec->conv = c;
		return 0;
	} else {
	ok:     spec->flags = f;
		spec->conv = state;
		return 1;
	}
}

void _doprint_str(doprint_t *dd, doprintspec_t *spec, const char *s, int len)
{
}

void _doprint_int(doprint_t *dd,  doprintspec_t *spec, unsigned int x)
{
}

int _doprint(register FILE *fp, register const char *fmt, __va_list ap)
{
	doprint_t ddobj;
	doprintspec_t spobj;
	register doprint_t *dd = &ddobj;
	register doprintspec_t *spec = &spobj;
	register int c;
	register unsigned int i;
	register const char *s;
	int tmp;
	static char displ[] = "--cdeee-d----nd---s-d-d---";
	/*                    "abcdefghijklmnopqrstuvwxyz" */
	dd->fp = fp;
	dd->cnt = 0;
	/* loop */
	for(; *fmt; fmt = s) {
		s = fmt;
		while((c = *s) && c != '%')
			s += 1;
		if (s != fmt) {
		pfmt:   _doprint_puts(dd, fmt, s-fmt);
			continue;
		}
		c = *++s;
		if (c == '%') {
			s += 1;
			fmt += 1;
			goto pfmt;
		}
		memset(spec, 0, sizeof(*spec));
		while (pushspec(c, spec, ap))
			c = *++s;
		s += 1;
		c = c | 0x20;
		if (! _islower(c))
			goto pfmt;
		if ((c = displ[c-'a']) == '-')
			goto pfmt;
		if ((c == 'd') && (spec->flags && DPR_LONG)) {
			_doprint_long(dd, spec, va_arg(ap, unsigned long));
		} else if (c == 'e') {
			_doprint_double(dd, spec, va_arg(ap, double));
		} else {
			i = va_arg(ap, unsigned int);
			if (c == 'd') {
				_doprint_int(dd, spec, i);
			} else if (c == 'c') {
				tmp = (char)i;
				_doprint_str(dd, spec, (const char*)&tmp, 1);
			} else if (c == 's') {
				_doprint_str(dd, spec, (const char*)i, -1);
			} else if (c == 'n') {
				*(int*)i = dd->cnt;
			}
		}
	}
	if (ferror(dd->fp))
		return EOF;
	return dd->cnt;
}

