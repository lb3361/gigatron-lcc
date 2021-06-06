#ifndef __GIGATRON_MATH
#define __GIGATRON_MATH

/* ==== Nonstandard functions defined in libm ==== */

/* Raise a SIGFPE exception and return defval if the exception is ignored.
   If a signal handler for SIGFPE has been setup, these functions
   return what the signal handler returns. */

extern double _fexcept(double defval);
extern double _foverflow(double defval);


#endif
