#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/libc.h>
#include <gigatron/sys.h>

struct console_state_s console_state = { CONSOLE_DEFAULT_FGBG };

void console_printxy(register int x, register int y, register const char *s, register int len)
{
	register char *addr = _console_addr(x,y);
	if (addr)
		_console_printchars(console_state.fgbg, addr, s, len);
}

static void cons_vfix(void)
{
	register int nl = console_info.nlines;
	if (console_state.cy >= nl) {
		console_scroll(0, nl, 1);
		console_clear_line(console_state.cy = nl - 1);
	}
}

static void cons_hfix(void)
{
	register int cx = console_state.cx;
	register int cy;
	if (cx < 0) {
		console_state.cx = 0;
	} else if (cx - console_info.ncolumns >= 0) {
		console_state.cx = 0;
		console_state.cy += 1;
	}
}

static void cons_fix(register int cx, register int cy)
{
	if (cx < 0 || cx - console_info.ncolumns >= 0)
		cons_hfix();
	if (cy != console_state.cy /* changed by hfix */
	    || cy < 0 || cy - console_info.nlines >= 0)
		cons_vfix();
}

static char *cons_addr(void)
{
	for(;;) {
		register int cx = console_state.cx;
		register int cy = console_state.cy;
		register char *addr = _console_addr(cx, cy);
		if (addr)
			return addr;
		cons_fix(cx, cy);
	}
}

static int cons_control(register int c)
{
	switch(c) {
	case '\a': /* bell (todo) */
		break;
	case '\b': /* backspace */
		if (console_state.cx > 0)
			console_state.cx -= 1;
		break;
	case '\t':  /* tab */
		console_state.cx = (console_state.cx | 3) + 1;
		break;
	case '\n': /* lf */
		console_state.cy += 1;
	case '\r': /* cr */
		console_state.cx = 0;
		break;
	case '\f':
		console_clear_screen();
		break;
	default:
		if (console_state.controlf)
			console_state.controlf(c);
		break;
	}
	return 1;
}

static int cons_print(register const char *s, register int len)
{
	register int n = _console_printchars(console_state.fgbg, cons_addr(), s, len);
	console_state.cx += n;
	return n;
}

void console_print(register const char *s, register int len)
{
	register int c, n;
	while (len > 0 && (c = *s)) {
		if (! (n = cons_print(s, len)))
			n = cons_control(*s);
		s += n;
		len -= n;
	}
}

DECLARE_INIT_FUNCTION(_console_setup);
