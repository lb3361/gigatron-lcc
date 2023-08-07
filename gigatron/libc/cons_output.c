#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/libc.h>
#include <gigatron/sys.h>

/* defined in cons_asm.s */
extern char *_console_addr();
extern int _console_special(const char *s, int len);

/* console state */
__near struct console_state_s console_state = { CONSOLE_DEFAULT_FGBG, 0, 0, 1, 1 };

/* print */
int console_print(register const char *s, register int len)
{
	register int nc = 0;
	while (len > 0 && *s) {
		register int n;
		register char *addr;
		if ((addr = _console_addr()) &&
		    (n = _console_printchars(console_state.fgbg, addr, s, len)) > 0 )
			console_state.cx += n;
		else if ((n = _console_special(s, len)) <= 0)
			n = 1;
		nc += n;
		s += n;
		len -= n;
	}
	return nc;
}

/* cause setup code to be called */
DECLARE_INIT_FUNCTION(_console_setup);

