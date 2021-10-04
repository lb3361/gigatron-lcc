#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/libc.h>
#include <gigatron/sys.h>


static void echo(int ch)
{
	char c = '?';
	if (ch == '\n' || (ch >= ' ' && 0x83 - ch > 0))
		c = ch;
	console_print(&c, 1);
}

int console_readline(char *buffer, int bufsiz)
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
		} else if (s < e || ch == '\n') {
			echo(ch);
			*s++ = ch;
			*s = 0;
			continue;
		}
		console_print("\a", 1);
	}
	return s - buffer;
}
