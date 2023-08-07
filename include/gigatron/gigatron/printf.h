#ifndef __GIGATRON_PRINTF
#define __GIGATRON_PRINTF

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
   mincprintf only understands %d and %s without qualifications.
   midcprintf also understands %u, %x, and numeric field sizes.
   None of these functions handles longs or floating point numbers. */

extern int mincprintf(const char *fmt, ...);
extern int midcprintf(const char *fmt, ...);



/* ========================================
   PRINTF CAPABILITY SELECTION [TODO]
   ======================================== */



#endif
