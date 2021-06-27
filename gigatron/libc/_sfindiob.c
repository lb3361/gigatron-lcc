#include "_stdio.h"
#include "errno.h"

FILE *_sfindiob(void)
{
	register FILE *f = _iob;
	register struct _more_iobuf **pnext = &_more_iob;
	for(;;) {
		register int i;
		for (i = 0; i != _IOB_NUM; i++, f++)
			if  (! f->_flag)
				return f;
#if WITH_MALLOC
		if (! *pnext)
			*pnext = calloc(1, sizeof(struct _more_iob));
#endif
		if (! *pnext)
			break;
		f = (*pnext)->_iob;
		pnext = &(*pnext)->next;
	}
	errno = ENFILE;
	return 0;
}

void  _sfreeiob(FILE *fp)
{
#if WITH_MALLOC
	if ((fp->_flag & _IOMYBUF) && fp->_base)
		free(fp->_base);
#endif
	fp->_flag = 0;
}

