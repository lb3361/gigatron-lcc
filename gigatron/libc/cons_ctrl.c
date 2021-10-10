#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/libc.h>
#include <gigatron/sys.h>


static struct channel_s bell = {0,1,77,21};

int _console_ctrl(register int c)
{
	switch(c) {
	case '\a':
		for (c = channelMask_v4 & 3; c >= 0; c--)
			channel(c+1) = bell;
		soundTimer = 4;
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
	case '\v':
		console_clear_to_eol();
	default:
		return 0;
	}
	return 1;
}

