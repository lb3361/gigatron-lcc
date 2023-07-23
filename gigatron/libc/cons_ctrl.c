#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/libc.h>
#include <gigatron/sys.h>

/* defined in cons_asm.s */
extern char *_console_addr();
extern int _console_special(const char *s, int len);


/* Handle control characters other than BS, CR, LF */
int _console_ctrl(register const char *s, int len)
{
	register char *addr;
	switch (*s) {
	case '\t':  /* TAB */
		console_state.cx = (console_state.cx | 3) + 1;
		break;
	case '\f': /* FF */
		console_clear_screen();
		break;
	case '\v': /* VT */
		if ((addr = _console_addr()))
			_console_clear(addr, console_state.fgbg, 8);
		break;
	case '\a': /* BELL */
		_console_bell(4);
		break;
	default:
		return 0;
	}
	return 1;
}

