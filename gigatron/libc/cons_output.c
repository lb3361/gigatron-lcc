#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/libc.h>
#include <gigatron/sys.h>


struct console_state_s console_state =
	{ CONSOLE_DEFAULT_FGBG,
	  0, 0, 0, 0,
	  0, 0, 0 };

void console_printxy(register int x, register int y, register const char *s, register int len)
{
	register char *addr = _console_addr(x,y);
	if (addr)
		_console_printchars(console_state.fgbg, addr, s, len);
}

static void cons_bell(void)
{
	// todo
}

static void cons_bs(void)
{
	if (console_state.cx > 0)
		console_state.cx -= 1;
}

static void cons_tab(void)
{
	console_state.cx = (console_state.cx | 7) + 1;
}

static void cons_lf(void)
{
	console_state.cx = 0;
	console_state.cy += 1;
}

static void cons_ff(void)
{
	console_clear_screen();
}

static void cons_home(void)
{
	console_state.botm = console_state.topm = 0;
	console_state.cx = console_state.cy = 0;
}

static void cons_cr(void)
{
	console_state.cx = 0;
}

static void (*ctrlf[16])(void) =
	{ 0,0,0,0,0,0,0,cons_bell,
	  cons_bs,cons_tab,cons_lf,0,cons_ff,cons_cr,0,0 };

static int cons_control(register int c)
{
	register void (*f)(int) = (void(*)(int))ctrlf[c & 0xf];
	if (f == 0 || c != (c & 0xf))
		f = console_state.controlf;
	if (f != 0)
		f(c);
	return 1;
}

static int cons_boty(void)
{
	register int nl = console_info.nlines;
	register int boty = nl - console_state.botm;
	if (boty <= 0)
		boty = 1;
	if (boty - nl > 0)
		boty = nl;
	return boty;
}

static void cons_vfix(void)
{
	int boty = cons_boty();
	if (console_state.cy >= boty) {
		console_scroll(console_state.topm, boty, 1);
		console_clear_line(console_state.cy = boty-1);
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

static int cons_capture(const char *s)
{
	void (*f)(int) = console_state.capturef;
	if (! f) return 0;
	console_state.capturef = 0;
	f(*s);
	return 1;
}

static int cons_print(register const char *s, register int len)
{
	register int n = _console_printchars(console_state.fgbg, cons_addr(), s, len);
	console_state.cx += n;
	if (n == 0)
		n = cons_control(*s);
	return n;
}

void console_print(register const char *s, register int len)
{
	while (len > 0 && *s) {
		register int n = 1;
		if (! cons_capture(s))
			n = cons_print(s, len);
		s += n;
		len -= n;
	}
}

static void console_exitm_msgfunc(int retcode, const char *s)
{
	if (s) {
		cons_home();
		console_state.fgbg = 3;
		console_state.cy = console_info.nlines;
		console_print(s, console_info.ncolumns);
	}
}

void console_init(void)
{
	_console_setup();
	_exitm_msgfunc = console_exitm_msgfunc;
}
