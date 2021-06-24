#include "_stdio.h"

#if WITH_MALLOC

struct more_iobuf *_more_iob = 0;

static FILE *_sfindmoreiob(void)
{
	int i;
	struct more_iobuf *m;
	for (m = _more_iob; m; m = m->next)
		if (m->_iob->_flag == 0)
			return m->_iob;
	if (! (m = malloc(sizeof(struct more_iobuf))))
		return 0;
	m->next = _more_iob;
	_more_iob = m;
	return m->_iob;
}

#endif

FILE *_sfindiob(void)
{
	int i;
	FILE *f = _iob;
	for (i = 0; i != _IOB_NUM; i++, f++)
		if (! f->_flag)
			return f;
#if WITH_MALLOC
	return _sfindmoreiob();
#else
	return 0;
#endif
}

void  _sfreeiob(FILE *fp)
{
#if WITH_MALLOC
	if ((fp->_flag & _IOMYBUF) && fp->_base)
		free(fp->_base);
#endif
	fp->_flag = 0;
}

