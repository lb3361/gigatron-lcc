#include <signal.h>

extern void _exits(int, int);

static sig_handler_t sigvec[8];

extern void _sigcall0();
extern void _sigvirq0();
extern void (*_raiseptr)();
extern void (*vIRQ_v5)();

sig_handler_t signal(int signo, sig_handler_t h)
{
	register sig_handler_t old;
	/* validate arguments */
	if ((signo & ~7u) || (h == SIG_ERR))
		return SIG_ERR;
	/* signal table */
	old = sigvec[signo];
	sigvec[signo] = h;
	/* activate */
	_raiseptr = _sigcall0;
	if (signo == SIGVIRQ)
		vIRQ_v5 = (~1u & (unsigned)h) ? _sigvirq0 : 0;
	return old;
}

int _sigcall(int signo, int fpeinfo)
{
	typedef int (*handler)(int,int);
	handler *vec = (handler*)sigvec;
	handler h;
	
	signo &= 7;
	h = vec[signo];
	/* Handle SIG_IGN for recoverable signals */
	if ((h == (handler)SIG_IGN) && (signo & 4))
		return 0;
	/* Call signal handler */
	if (~1u & (unsigned)h) {
		vec[signo] = (handler)SIG_DFL;
		if (signo & 4)
			return h(signo, fpeinfo);
		else
			h(signo, fpeinfo);
	}
	_exits(signo, fpeinfo);
	return -1;
}

