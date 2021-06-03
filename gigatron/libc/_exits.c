#include <signal.h>

extern void _exitm(int, const char*);


static const char *_exitmsg(register int signo, register int fpeinfo)
{
	if (signo == SIGABRT)
		return "Abort";
	else if (signo != SIGFPE)
		return 0;
	else if (fpeinfo == 1)
		return "Division by zero";
	else if (fpeinfo == 2)
		return "Floating point overflow";
	else
		return "Floating point exception";
}

void _exits(register int signo, register int fpeinfo)
{
	_exitm(20, _exitmsg(signo, fpeinfo));
}
