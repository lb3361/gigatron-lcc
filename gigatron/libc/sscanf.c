#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "_stdio.h"

int sscanf(register const char *str, const char *fmt, ...)
{
	register int r;
	struct _iobuf f;
	FILE *fp = &f;
	va_list ap;
	
	memset(fp, 0, sizeof(f));
	fp->_cnt = strlen(str);
	fp->_ptr = (char*)str;
	fp->_flag = _IOFBF|_IOSTR|_IOREAD|_IOEOF;
	va_start(ap, fmt);
	r = _doscan(fp, fmt, ap);
	va_end(ap);
	return r;
}
