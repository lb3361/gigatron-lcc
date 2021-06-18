#include <string.h>
#include <stdio.h>
#include <gigatron/console.h>

#define _CONS_STDIO
#include "_stdio.h"


struct _cbuf { 
	int size;
	char xtra[2];
	char data[CONS_BUFSIZE];
};

struct _cbuf _cons_ibuf = { CONS_BUFSIZE };
struct _cbuf _cons_obuf = { CONS_BUFSIZE };

static int cons_write(register int fd, register const void *buf, register size_t cnt)
{
	register int written = 0;
	while (written != cnt) {
		register int n;
		if (! (n = console_print((char*)buf + written, cnt - written)))
			n = 1;
		written += n;
	}
	return written;
}

static int cons_flsbuf(register int c, register FILE *fp)
{
	register char *buf = _cons_obuf.data;
	register int cnt = 0;
	register int n = 0;
	if (fp->_flag & _IOFBF) {
		cnt = CONS_BUFSIZE - 1;
		if (fp->_ptr)
			n = fp->_ptr - buf;
	}
	fp->_ptr = buf;
	fp->_cnt = cnt;
	if (c >= 0)
		buf[n++] = (char) c;
	cons_write(fp->_file, buf, n);
	return c;
}

static int cons_read(int fd, register void *buf, size_t cnt)
{
	*(char*)buf = (char)console_waitkey();
	return 1;
}

static int cons_filbuf(register FILE *fp)
{
	register int n;
	register char *buf = _cons_ibuf.data;
	if (stdout->_v == &_cons_svec)
		_fflush(stdout);
	if (fp->_flag & _IOFBF)
		n = console_readline(buf, CONS_BUFSIZE);
	else
		n = cons_read(0, buf, 1);
	fp->_cnt = n - 1;
	fp->_ptr = buf + 1;
	return buf[0];
}

struct _svec _cons_svec = { cons_flsbuf, cons_write, cons_filbuf, cons_read, 0, 0 };
