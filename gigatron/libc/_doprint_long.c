#include <stdarg.h>
#include <ctype.h>
#include <string.h>
#include <errno.h>

#include "_doprint.h"

/* See _support.s for the actual _doprint_long
   and the machinery that only links this when
   long integers are used in the program. */

void _doprint_long_imp(doprintspec_t *spec, int b, __va_list *ap)
{
	char buffer[16];
	register char *s;
	register unsigned long x = va_arg(*ap, unsigned long);
	if (b == 11) {
		s = ltoa(x, buffer, 10);
	} else
		s = ultoa(x, buffer, b);
	_doprint_num(spec, b, s);
}
