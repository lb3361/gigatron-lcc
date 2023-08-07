#ifndef __GIGATRON_PRINTF
#define __GIGATRON_PRINTF

#if !defined(_SIZE_T) && !defined(_SIZE_T_) && !defined(_SIZE_T_DEFINED)
#define _SIZE_T
#define _SIZE_T_
#define _SIZE_T_DEFINED
typedef unsigned int size_t;
#endif

#if !defined(_VA_LIST) && !defined(_VA_LIST_DEFINED)
#define _VA_LIST
#define _VA_LIST_DEFINED
typedef char *__va_list;
#endif

/* ========================================
   PRINTF-LIKE FUNCTIONS FROM STDIO.H
   ======================================== */

/* Must exactly match the stdio declarations */

extern int printf(const char *, ...);
extern int sprintf(char *, const char *, ...);
extern int vprintf(const char *, __va_list);
extern int vsprintf(char *, const char *, __va_list);

/* extern int fprintf(FILE *, const char *, ...); */
/* extern int vfprintf(FILE *, const char *, __va_list); */


/* ========================================
   PRINTF-LIKE FUNCTIONS FOR THE CONSOLE 
   ======================================== 

   These functions are similar to the stdio printf functions but they
   bypass stdio and hit directly the console. The cprintf function
   still import the relatively heavy printf machinery but not the
   stdio machinery. The midcprintf and mincprintf functions are
   considerably smaller but with limited capabilities. */


/* Print formatted text at the cursor position */
extern int cprintf(const char *fmt, ...);

/* Print formatted text like cprintf except that it is called
   with a va_list instead of a variable number of arguments. */
extern int vcprintf(const char *fmt, __va_list ap);

/* Alternate cprintf functions with less capabilities.
   Function mincprintf only understands %d and %s without
   qualifications.  Function midcprintf also understands %c, %i, %u,
   %o, %x with numeric field sizes.  None of these functions handles
   longs or floating point numbers. */
extern int mincprintf(const char *fmt, ...);
extern int midcprintf(const char *fmt, ...);



/* ========================================
   PRINTF CAPABILITY SELECTION
   ======================================== */

typedef struct doprint_s doprint_t;

/* Function pointer _doprint selects the low level formatting routine
   used by all the printf-like functions (except mincprintf and
   midcprintf). The default value is _doprint_c89. */
extern int (* const _doprint)(doprint_t*, const char*, __va_list);

/* The _doprint_c89 formatting routine complies with the ANSI C89
   specification which is unfortunately complex. This formatting
   functions requires 2KB bytes of code, plus additional code
   to support longs and doubles which is only linked if longs
   or doubles are used elsewhere in the program. */
extern int  _doprint_c89(doprint_t*, const char*, __va_list);

/* The _doprint_simple formatting routine only provides support for
   conversion characters %c, %s, %d, %i, %u, %x, %o with optional
   field length. No attempt is made to support longs and doubles.
   This formatting functions requires about 750 bytes of code.
   The same code is used directly by function midcprinf. */
extern int  _doprint_simple(doprint_t*, const char*, __va_list);

/* Macro PRINTF_C89 and PRINTF_SIMPLE can be used to select the
   low-level formatting routine used by the printf-like
   routines. These macro merely define and initialize the _doprint
   function pointer.
   Example:
     #include <conio.h>
     PRINTF_SIMPLE;
     int main() { ...
   Compile with option
     --option=PRINTF_SIMPLE
   has the same effect with a lower priority. 
*/
#define PRINTF_C89 \
  int (*const _doprint)(doprint_t*,const char*,__va_list) = _doprint_c89
#define PRINTF_SIMPLE \
  int (*const _doprint)(doprint_t*,const char*,__va_list) = _doprint_simple

#endif
