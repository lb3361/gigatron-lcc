#include <string.h>
#include <stdio.h>
#include <gigatron/console.h>

#define _CONS_STDIO
#include "_stdio.h"


struct _sbuf_linebuf { 
	int size;
	char xtra[2];
	char data[CONS_LINEBUF_SIZE];
} _cons_linebuf = { CONS_LINEBUF_SIZE };

static int cons_write(register int fd, register void *buf, register size_t cnt)
{
	register char *b = buf;
	register int n = console_print(b, cnt);
	if (n > 0)
		return n;
	return 1;
}

static int cons_read(int fd, void *buf, size_t cnt)
{
	*(char*)buf = (char)console_waitkey();
	return 1;
}

static int cons_filbuf(register FILE *fp)
{
	if (fp->_flag & _IOFBF) {
		register char *buf = _cons_linebuf.data;
		fp->_cnt = console_readline(buf, CONS_LINEBUF_SIZE) - 1;
		fp->_ptr = (unsigned char*)(buf + 1);
		return buf[0];
	} else {
		return console_waitkey();
	}
}

struct _svec _cons_svec = { 0, cons_write, cons_filbuf, cons_read, 0, 0 };
