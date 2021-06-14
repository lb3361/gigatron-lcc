#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <gigatron/console.h>
#include <gigatron/libc.h>
#include <gigatron/sys.h>


int console_getkey(void)
{
	static char last = 0xff;
	register char ch = serialRaw;
	if (last != ch) {
		last = ch;
		if (ch != 255)
			return ch;
	}
	return -1;
}

static void update_cursor(int on)
{
	console_print(on ? "\x7f\b" : "\x20\b", 2);
}

int console_waitkey()
{
	register int btn;
	register int ofc = frameCount & 0xff;
	for(;;) {
		if ((btn = console_getkey()) >= 0)
			break;
		if ((frameCount ^ ofc) & 0xf0) {
			update_cursor(ofc & 0x10);
			ofc = frameCount;
		}
	}
	update_cursor(0);
	return btn;
}

static void echo(int ch)
{
	char c = '?';
	if (ch == '\n' || isprint(ch))
		c = ch;
	console_print(&c, 1);
}

void console_readline(char *buffer, int bufsiz)
{
	register char *s = buffer;
	register char *e = buffer + bufsiz - 3;
	register int ch = 0;
	for(;ch != '\n';) {
		ch = console_waitkey();
		if (ch == '\b' || ch == 0xfd || ch == 0x7f) {
			if (s > buffer) {
				console_print("\b \b", 3);
				*--s = 0;
				continue;
			}
		} else if (ch == 0x3) {
			while (s > buffer) {
				console_print("\b \b", 3);
				*--s = 0;
			}
			continue;
		} else if (s < e || ch == '\n') {
			echo(ch);
			*s++ = ch;
			*s = 0;
			continue;
		}
		console_print("\a", 1);
	}
}
