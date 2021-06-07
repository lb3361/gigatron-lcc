#ifndef __GIGATRON_LIBC
#define __GIGATRON_LIBC

/* ==== Nonstandard functions defined in libc ==== */


/* ---- Program startup and exit ---- */

/* Exits the program without running the finalization functions like exit().
   This just calls _exitm() without message. */
extern void _exit(int retcode);

/* Exits with a return code_and an optional message. */
extern void _exitm(int ret, const char *msg);

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


/* ---- Misc ---- */

/* Calls srand(int) using the gigatron entropy generator */
extern void _srand(void);

/* Scans memory region [s,s+n) and return a pointer to the first byte 
   equal to either c0 or c1. Return zero if not found. 
   This is fast when there is a SYS call. */
extern void *_memchr2(void *s, char c0, char c1, size_t n);

/* Copy a block of memory [src,src+n) from the current address space
   into block [dst,dst+n) in the address space one gets when the bits
   6 and 7 of go into the ram expansion control register.  This is
   slow without SYS_CopyMemoryExt. Returns zero when no expansion. */
extern void *_memcpyext(char bank, void *dst, const void* src, size_t n);

/* Same as _strtod() but raises SIGFPE on overflow.
   Function strtod() call this after setting the SIGFPE handler. */
extern double _strtod(const char *nptr, char **endptr);





#endif
