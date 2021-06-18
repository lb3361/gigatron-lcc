#include "_stdio.h"
#include <errno.h>

int fclose(FILE *fp)
{
	if (fp->_flag) {
		register int r = _fclose(fp);
#if WITH_MALLOC
		if (fp->_flag & _IOMYBUF)
			free(fp->_base);
#endif
		_sfreeiob(fp);
		return r;
	}
	errno = EINVAL;
	return -1;
}
