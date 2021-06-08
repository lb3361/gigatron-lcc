#include <signal.h>
#include <gigatron/libc.h>

static sig_handler_t sigvec[8];

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
	_raise_disposition = RAISE_EMITS_SIGNAL;
	if (signo == SIGVIRQ)
		_set_virq_handler((~1u & (unsigned)h) ? _virq_handler : 0 );
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

