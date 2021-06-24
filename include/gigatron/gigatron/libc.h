#ifndef __GIGATRON_LIBC
#define __GIGATRON_LIBC

#include <stdlib.h>
#include <stdio.h>

/* ==== Nonstandard functions defined in libc ==== */


/* ---- Program startup and exit ---- */

/* Exits the program without running the finalization functions like exit().
   This just calls _exitm() without message. */
extern void _exit(int retcode);

/* Exits with a return code_and an optional message. 
   The libc version of _exitm does the following:
   - restore vSP to the value it had in `_start`.
   - calls the function pointer `_exitm_msgfunc` if nonzero
   - flashes a pixel on the first screen line at a position
     indicative of the return code. */
extern void _exitm(int ret, const char *msg);
extern void (*_exitm_msgfunc)(int ret, const char *msg);

/* Exits after receiving an unrecoverable signal.
   Just calls _exitm() with retcode 20 and an appropriate message. */
extern void _exits(register int signo, register int fpeinfo);

/* Arrange for initialization function func() to be called before main(). 
   Only one of those can exist per c file. */
#define DECLARE_INIT_FUNCTION(func) \
   static struct { void(*f)(void); void *next; \
   } __glink_magic_init = { func, 0 }

/* Arrange for finalization function func() to be called when main() returns. 
   Only one of these can exist per c file. */
#define DECLARE_FINI_FUNCTION(func) \
   static struct { void(*f)(void); void *next; \
   } __glink_magic_fini = { func, 0 }


/* ----- Raising signals ----- */

/* The following vector changes what raise() does
   without requiring all the context saving that
   is necessary for running a full signal handler. */
extern void *_raise_disposition;

/* Legal values for raise disposition */
#define RAISE_EXITS ((void*)0)
#define RAISE_EMITS_SIGNAL ((void*)&_raise_emits_signal)
#define RAISE_SETS_CODE ((void*)&_raise_sets_code)

/* Support for the above. Do not call. */
extern const char _raise_emits_signal;
extern const char _raise_sets_code;

/* Setting _raise_disposition to RAISE_SETS_CODE
   simply writes the signal code into this variable.
   Low byte is the signal code, high byte is the fp code. */
extern int _raise_code;

/* This is the vIRQ handler than emits SIGIRQ. Do not call. */
extern void _virq_handler(void);


/* ---- Numerics ---- */

/* Raise a SIGFPE exception and return defval if the exception is ignored.
   If a signal handler for SIGFPE has been setup, these functions
   return what the signal handler returns. */
extern double _fexception(double defval);
extern double _foverflow(double defval);

/* Multiplies x by 10^n. */
extern double _ldexp10(double x, int n);

/* Returns a double y and an exponent exp such that x = y * 10^exp,
   with y as large as possible (almost) with an exact integer part. */
extern double _frexp10(double x, int *pexp);

/* Like the C99 function remquo but with fmod-style remainder. */
extern double _fmodquo(double x, double y, int *quo);

/* Evaluate polynomials */
extern double _polevl(double x, double *coeff, int n);
extern double _p1evl(double x, double *coeff, int n);


/* ---- Stdio ---- */

struct _sbuf {
	int size;
	char xtra[2];
	char data[2];
};

struct _svec {
	int  (*flsbuf)(int c, FILE *fp);
	int  (*write)(FILE *fp, const void *buf, size_t cnt);
	int  (*filbuf)(FILE *fp);
	int  (*read)(FILE *fp, void *buf, size_t cnt);
	long (*lseek)(FILE *fp, long off, int whence);
	int  (*close)(FILE *fp);
};

/* This function is called before main() to initialize the _iob[]. 
   The default version hooks the console to stdin/stdout/stderr. */
extern void _iob_setup(void);


/* ---- Misc ---- */

/* Calls srand(int) using the gigatron entropy generator */
extern void _srand(void);

/* Scans memory region [s,s+n) and return a pointer to the first byte 
   equal to either c0 or c1. Return zero if not found. 
   This is fast when there is a SYS call. */
extern void *_memchr2(const void *s, char c0, char c1, size_t n);

/* Copy a block of memory [src,src+n) to [dst,dst+n) across memory banks.
   The destination bank is given by bits 6 and 7 of argument banks,
   and the source bank is given by bits 5 and 4.
   Returns zero when no expansion. */
extern void *_memcpyext(char banks, void *dst, const void* src, size_t n);


#endif
