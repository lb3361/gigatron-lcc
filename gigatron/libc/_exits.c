#include <signal.h>

extern void _exitm(int, const char*);

void _exits(register int signo, register int fpeinfo)
{
	_exitm(20, (signo == SIGABRT) ? "Abort"
	       :   (signo != SIGFPE) ? 0
	       :   (fpeinfo == 1) ? "Division by zero"
	       :   (fpeinfo == 2) ? "Floating point overflow"
	       :   "Floating point exception" );
}
