#include <stdarg.h>
#include <stdlib.h>
#include <gigatron/console.h>

#include "_doprint.h"


/* defined in cons_asm.s */
extern void _console_writall(void *unused, const char *s, unsigned int len);

int vcprintf(const char *fmt, register __va_list ap)
{
	doprint_t ddobj;
	register doprint_t *dp = &ddobj;
	dp->cnt = 0;
	dp->f = _console_writall;
	return _doprint(&ddobj, fmt, ap);
}

/* A cprintf relay is defined in _printf.s */
