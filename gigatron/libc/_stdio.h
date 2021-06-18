#ifndef _STDIO_INTERNAL
#define _STDIO_INTERNAL

#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <gigatron/libc.h>

#define _WITH_MALLOC 0

#define _IOB_NUM 5

extern int _fcheck(FILE*);
extern int _fclose(FILE*);
extern void _fflush(FILE*);

extern int   _serror(FILE*, int);

extern FILE *_sfindiob(void);
extern void  _sfreeiob(FILE *fp);
extern int   _swalk(int(*f)(FILE*));

#define CONS_BUFSIZE 80
extern struct _svec _cons_svec;

#endif
