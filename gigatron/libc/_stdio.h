#ifndef _STDIO_INTERNAL
#define _STDIO_INTERNAL

#include <stdio.h>
#include <errno.h>
#include <gigatron/libc.h>

#define _IOB_NUM 5

extern int _fcheck(FILE*);
extern void _fflush(FILE*);

extern int   _serror(FILE*, int);

extern FILE *_sfindiob(void);
extern void  _sfreeiob(FILE *fp);

#define CONS_BUFSIZE 80
extern struct _svec _cons_svec;

#endif
