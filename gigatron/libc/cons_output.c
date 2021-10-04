#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/libc.h>
#include <gigatron/sys.h>

struct console_state_s console_state = { CONSOLE_DEFAULT_FGBG };

static char *cons_addr(void)
{
	for(;;) {
		register int cx, cy, nl;
		register char *addr;
		if ((addr = _console_addr(cx = console_state.cx, cy = console_state.cy)))
			return addr;
		if (cx < 0)
			cx = 0;
		if (console_info.ncolumns - cx <= 0) {
			cx = 0;
			cy += 1;
		}
		console_state.cx = cx;
		if (cy < 0)
			cy = 0;
		if ((nl = console_info.nlines) - nl <= 0) {
			console_scroll(0, nl, 1);
			console_clear_line(cy = nl - 1);
		}
		console_state.cy = cy;
	}
}

static void cons_bell(void)
{
	static struct channel_s bell = {0,1,77,21};
	int i;
	for (i = channelMask_v4 & 3; i >= 0; i--)
		channel(i+1) = bell;
	soundTimer = 4;
}


static void cons_control(register int c)
{
	switch(c) {
	case '\a':
		cons_bell();
		break;
	case '\b': /* backspace */
		if (console_state.cx > 0)
			console_state.cx -= 1;
		else if (console_state.cy > 0) {
			console_state.cx = console_info.ncolumns-1;
			console_state.cy -= 1;
		}
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
}

int console_print(const char *ss, register int len)
{
	register int n;
	register const char *s = ss;
	while (len > 0 && *s) {
		if (n = _console_printchars(console_state.fgbg, cons_addr(), s, len))
			console_state.cx += n;
		else {
			cons_control(*s);
			n = 1;
		}
		s += n;
		len -= n;
	}
	return s - ss;
}

DECLARE_INIT_FUNCTION(_console_setup);
