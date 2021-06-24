#include "_stdio.h"

int _swalk(int(*func)(FILE*))
{
	register int i;
	register int r = 0;
	FILE *f = _iob;
	
	for (i = 0; i != _IOB_NUM; i++, f++)
		if  (f->_flag && (*func)(f) < 0)
			r = -1;
#if WITH_MALLOC
	{
		register struct more_iobuf *m;
		for (m = _more_iob; m; m = m->next)
			if (m->_iob->_flag && (*func)(m->_iob) < 0)
				r = -1;
	}
#endif
	return r;
}

