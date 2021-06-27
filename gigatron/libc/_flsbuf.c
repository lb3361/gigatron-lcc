#include "_stdio.h"
#include <errno.h>

/* This is the generic version of fp->_v->filbuf.
   It is similar to cons_flsbuf but:
   - can use arbitrary buffer or arbitrary size.
   - can allocate a buffer when none is provided.
   - checks for errors and end-of-file condition. */

int _default_flsbuf(register int c, register FILE *fp)
{
	register int flag = fp->_flag;
	register int cnt = 0;
	register int n = 0;
	register char *buf;
	
	/* Ensure buffer */
	if ((flag & _IOFBF) && !fp->_base) {
#if WITH_MALLOC
		struct _sbuf *sb = malloc(BUFSIZ);
		if ((fp->_base = sb)) {
			sb->size = BUFSIZ - sizeof(sb) + 2;
			flag = (flag | _IOMYBUF);
		} else
#endif
			flag = (flag & ~_IOLBF) | _IONBF;
		fp->_flag = flag;
	}
	/* Determine buffer */
	if (flag & _IOFBF) {
		cnt = fp->_base->size - 1;
		buf = fp->_base->data;
		if (fp->_ptr)
			n = fp->_ptr - buf;
	} else 
		buf = fp->_buf;
	/* Prepare buffer for future putc */ 
	fp->_ptr = buf;
	fp->_cnt = cnt;
	/* Write current buffer + c */
	if (c >= 0)
		buf[n++] = (char) c;
	while (n > 0) {
		if ((cnt = fp->_v->write(fp, buf, n)) <= 0)
			return _serror(fp, EIO);
		buf += cnt;
		n -= cnt;
	}
	if (c < 0)
		return 0;
	return c;
}
