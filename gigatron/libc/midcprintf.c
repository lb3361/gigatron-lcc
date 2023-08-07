#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/libc.h>
#include <ctype.h>
#include <conio.h>


#define FLG_ZPAD 1
#define FLG_RPAD 2

void midcprintf(const char *fmt, ...)
{
	register va_list ap;
	register const char *f = fmt;
	register const char *s;
	register int l, c, pad;
	register char style;
	char buf8[8];

	va_start(ap, fmt);
	while(*f) {
		s = f;
		style = ' ';
		pad = 0;
		if (*f != '%') {
			while (*f && *f != '%')
				f++;
			l = f - s;
		} else {
			c = *++f;
			l = 32767;
			if (c == '-' || c == '0') {
				style = c;
				c = *++f;
			}
			while(isdigit(c)) {
				pad = pad * 10 + c - 0x30;
				c = *++f;
			}
			f += 1;
			switch(c) {
			case 's':
				s = va_arg(ap, char*);
				pad -= strlen(s);
				break;
			case 'c':
				buf8[0] = va_arg(ap,char);
				s = buf8;
				l = 1;
				break;
			case 'd':
				s = itoa(va_arg(ap, int), buf8, 10);
				if (style == '0' && *s == '-') {
					putch(*s);
					pad -= 1;
					s += 1;
				}
				goto xint;
			case 'u':
				c = 10;
				goto uint;
			case 'x':
				c = 16;
			uint:   s = utoa(va_arg(ap, unsigned int), buf8, c);
			xint:	pad -= buf8 + 7 - s;
				break;
			default:
				f = s + 1;
			case '%':
				pad = 0;
				l = 1;
				break;
			}
		}
		if (style != '-')
			while (--pad >= 0)
				putch(style);
		console_print(s, l);
		while (--pad >= 0)
			console_print(" ", 1);
	}
}
