#ifndef _STDIO_INTERNAL
#define _STDIO_INTERNAL

#include <stdio.h>
#include <errno.h>
#include <gigatron/libc.h>

/* -------- iob management ------- */

#define _IOB_NUM 5

extern FILE *_sfindiob(void);
extern void  _sfreeiob(FILE *fp);

extern int  _serror(FILE*, int);
extern void _scheckbuf(FILE*);

/* -------- console io ----------- */

#ifndef _CONS_STDIO
extern struct _svec _cons_svec;
extern struct _sbuf _cons_linebuf;
#endif

#define CONS_LINEBUF_SIZE 80

#endif
