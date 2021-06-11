#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/libc.h>
#include <gigatron/sys.h>

static void console_exitm_msgfunc(int retcode, const char *s)
{
	if (s) {
		console_state.fgbg = 3;
		console_state.cx = 0;
		console_state.cy = console_info.nlines;
		console_print(s, console_info.ncolumns);
	}
}

void _console_setup(void)
{
	console_clear_screen();
	_exitm_msgfunc = console_exitm_msgfunc;
}
