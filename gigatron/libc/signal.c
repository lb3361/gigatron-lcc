#include <signal.h>

extern void _exits(int, int);
extern void _sigcall0();

static sig_handler_t sigvec[8];
void (*_sigptr)();

sig_handler_t signal(int signo, sig_handler_t h)
{
	sig_handler_t old;
	if ((signo & ~7u) || (h == SIG_ERR))
		return SIG_ERR;
	_sigptr = _sigcall0;
	old = sigvec[signo];
	sigvec[signo] = h;
	return old;
}

int _sigcall(int signo, int fpeinfo)
{
	typedef int (*handler)(int,int);
	handler *vec = (handler*)sigvec;
	handler h;

	signo &= 7;
	h = vec[signo];
	if (h == (handler)SIG_IGN)
		if (signo & 4)
			return 0;
	vec[signo] = (handler)SIG_DFL;
	if (h != (handler)SIG_DFL) {
		if (signo & 4)
			return h(signo, fpeinfo);
		else
			h(signo, fpeinfo);
	}
	_exits(signo, fpeinfo);
	return -1;
}

