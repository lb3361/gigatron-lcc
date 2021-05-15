#ifndef __SIGNAL
#define __SIGNAL

typedef int sig_atomic_t;

#define SIG_DFL ((void (*)(int))0)
#define SIG_ERR ((void (*)(int))-1)
#define SIG_IGN ((void (*)(int))1)

#define SIGABRT	6
#define SIGFPE	8
#define SIGILL	4
#define SIGINT	2
#define SIGSEGV	11
#define SIGTERM	15

#define FPE_INTDIV      1       /* integer divide by zero */
/* #define FPE_INTOVF      2       /* integer overflow */
#define FPE_FLTDIV      3       /* floating point divide by zero */
#define FPE_FLTOVF      4       /* floating point overflow */
/* #define FPE_FLTUND      5       /* floating point underflow */
/* #define FPE_FLTRES      6       /* floating point inexact result */
/* #define FPE_FLTINV      7       /* floating point invalid operation */

typedef void(*sig_handler_t)(int);

sig_handler_t signal(int, sig_handler_t);

int raise(int);

#endif /* __SIGNAL */
