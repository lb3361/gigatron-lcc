#include <stdlib.h>

void abort(void)
{
	extern int _exitm(int,const char*);
	_exitm(10, "Abort");
}
