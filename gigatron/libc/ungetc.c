#include "_stdio.h"
#include <errno.h>

extern int ungetc( int c, FILE *fp)
{
	if (c < 0) {
		return EOF;
	} else if (fp->_cnt <= 0) {
		fp->_ptr = fp->_buf + sizeof(fp->_buf) - 1;
		fp->_cnt = 1;
		return c;
	} else if ((fp->_base && fp->_ptr > fp->_base->xtra &&
		    fp->_ptr < fp->_base->data + fp->_base->size ) ||
		   (fp->_ptr > fp->_buf &&
		    fp->_ptr < fp->_buf + sizeof(fp->_buf) ) ) {
		fp->_ptr -= 1;
		fp->_cnt += 1;
		fp->_ptr[0] = c;
		return c;
	}
	return EOF;
}
