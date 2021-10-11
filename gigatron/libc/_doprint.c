#include "_stdio.h"
#include <stdarg.h>
#include <ctype.h>
#include <string.h>
#include <errno.h>


void _doprint_putc(doprint_t *dp, int c, size_t cnt)
{
	dp->cnt += cnt;
	while (cnt) {
		fputc(c, dp->fp);
		cnt -= 1;
	}
}

void _doprint_puts(register doprint_t *dp, register const char *s, register size_t cnt)
{
	register const char *e;
	if (e = memchr(s, 0, cnt))
		cnt = e - s;
	dp->cnt += cnt;
	_fwrite(dp->fp, s, cnt);
}


static const char *parsespec(const char *s, doprintspec_t *spec, va_list *ap)
{
	static char fl[] = " + #0 - ";
	static char fv[] = { DPR_SPC, DPR_SGN, 0, DPR_ALT, DPR_ZEROJ, 0, DPR_LEFTJ, 0 };
	register int f = spec->flags;
	register int c;
	register int *np;
	register int nf;

	c = *++s;
	/* Flags */
	for(;;) {
		nf = (c ^ (c >> 2)) & 0x7; /* perfect hash */
		if (fl[nf] != c)
			break;
		f |= fv[nf];
		c = *++s;
	}
	/* Width and precision */
	nf = DPR_WIDTH;
	np = &spec->width;
 num:	if (c == '*') {
		f |= nf;
		*np = va_arg(*ap, int);
		c = *++s;
	} else {
		while (_isdigit(c)) {
			f |= nf;
			*np = *np * 10 + c - '0';
			c = *++s;
		}
	}
	if (nf == DPR_WIDTH) {
		if (*np < 0) {
			f |= DPR_LEFTJ;
			*np = - *np;
		}
		if (c == '.') {
			c = *++s;
			nf = DPR_PREC;
			np = &spec->prec;
			goto num;
		}
	}
	/* Size modifier */
	for(;;) {
		if (c == 'l')
			f |= DPR_LONG;
		if (c != 'h')
			break;
		c = *++s;
	}
	spec->flags = f;
	return s;
}

static void do_str(doprint_t *dd, doprintspec_t *spec, const char *s, size_t l)
{
	register const char *p;
	register int f = spec->flags;
	register int b = 0;
	if (l == 0) {
		l = 0xffffu;
		if (f & DPR_PREC)
			l = spec->prec;
	}
	if (p = memchr(s, 0, l))
		l = p - s;
	if (f & DPR_WIDTH)
		b = spec->width - l;
	if (b > 0 && !(f & DPR_LEFTJ))
		_doprint_putc(dd, ' ', b);
	_doprint_puts(dd, s, l);
	if (b > 0 && (f & DPR_LEFTJ))
		_doprint_putc(dd, ' ', b);
}


static void upcase(char *s)
{
	register int c;
	while (c = *s) {
		if (_islower(c))
			*s = c ^ 0x20;
		s += 1;
	}
}

void _doprint_num(register doprint_t *dd,  register doprintspec_t *spec,
		  register int b, register char *s)
{
	register int l, z;
	register int f = spec->flags;
	register char *p = "";

	if (*s == '-') {
		p = "-";
		s += 1;
	} else if ((b & 1) && (f & DPR_SGN)) {
		p = "+";
	}
	if (*s == '0') {
		if (f & DPR_PREC)
			s += 1;
	} else if (f & DPR_ALT) {
		if (b == 8) {
			p = "0";
			spec->prec -= 1;
		} else if (b == 16)
			p = "0x";
	}
	b = strlen(p);
	l = strlen(s) + b;
	z = 0;
	if (f & DPR_PREC) {
		if ((z = spec->prec - l - b) < 0)
			z = 0;
	} else if (f & DPR_ZEROJ) {
		if ((z = spec->width - l) < 0)
			z = 0;
	}
	l = l + z;
	b = spec->width - l;
	if (_isupper(spec->conv)) {
		upcase(s);
		if (p[1]=='x')
			p = "0X";
	}
	if (b > 0 && !(f & DPR_LEFTJ))
		_doprint_putc(dd, ' ', b);
	if (p[0])
		_doprint_puts(dd, p, 4);
	if (z > 0)
		_doprint_putc(dd, '0', z);
	_doprint_puts(dd, s, l);
	if (b > 0 && (f & DPR_LEFTJ))
		_doprint_putc(dd, ' ', b);
}

static void do_int(register doprint_t *dd,  register doprintspec_t *spec, register int b, register unsigned int x)
{
	char buffer[8];
	register char *s;
	register int f = spec->flags;
	if (b == 11) {
		s = itoa(x, buffer, 10);
	} else
		s = utoa(x, buffer, b);
	_doprint_num(dd, spec, b, s);
}


static int _doprint_conv_info(int c)
{
	/* return n such that:
           -  n == 0 for incorrect conversion letter
	   -  n == 129 for float conversions
           -  n == 32, 64, 96 for c/s/n conversions
	   -  n & 0x1e is the radix for int conversions
           -  n & 0x01 is nonzero when the format is signed
	*/
	static char convl[] = "EGxounsFegcipdXf";
	static char displ[] = {/* EGxo */ 129, 129,  16,   8,
			       /* unsF */  10,  96,  64, 129,
			       /* egci */ 129, 129,  32,  11,
			       /* pdXf */  16,  11,  16, 129 };
	register int i = c;
	/* perfect hash */
	if (i & 1) i += 58;
	if ((i ^ 199) - 187 > 0) i -= 187;
	i = (i ^ (i >> 2)) & 0xf;
	if (convl[i] == c)
		return displ[i];
	return 0;
}


int vfprintf(register FILE *fp, register const char *fmt, __va_list ap)
{
	doprint_t ddobj;
	doprintspec_t spobj;
	register doprint_t *dd = &ddobj;
	register doprintspec_t *spec = &spobj;
	register int c;
	register unsigned int i;
	register const char *s;
	char tmp;
	/* prep */
	dd->fp = fp;
	dd->cnt = 0;
	if ((c = _schkwrite(fp)))
		return _serror(fp, c);
	/* loop */
	for(; *fmt; fmt = s) {
		s = fmt;
		while((c = *s) && c != '%')
			s += 1;
		if (s != fmt) {
		pfmt:   _doprint_puts(dd, fmt, s-fmt);
			continue;
		}
		if (s[1] == '%') {
			s += 1;
			fmt += 1;
			goto pfmt;
		}
		memset(spec, 0, sizeof(*spec));
		s = parsespec(s, spec, &ap);
		if (! (c = _doprint_conv_info(*s++)))
			goto pfmt;
		if ((spec->flags & DPR_LONG) && (c & 0x1e)) {
			_doprint_long(dd, spec, c, &ap);
		} else if (c == 129) {
			_doprint_double(dd, spec, &ap);
		} else {
			i = va_arg(ap, unsigned int);
			if (c == 32) {
				tmp = (char)i;
				do_str(dd, spec, (const char*)&tmp, 1);
			} else if (c == 64) {
				do_str(dd, spec, (const char*)i, 0);
			} else if (c == 96) {
				*(int*)i = dd->cnt;
			} else {
				do_int(dd, spec, c, i);
			}
		}
	}
	if (ferror(dd->fp))
		return EOF;
	return dd->cnt;
}

