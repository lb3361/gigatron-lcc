#ifndef _STDIO_INTERNAL
#define _STDIO_INTERNAL

#include <stdio.h>
#include <errno.h>
#include <gigatron/libc.h>

#define _IOB_NUM 5
extern FILE *_sfindiob(void);
extern void _sfreeiob(FILE *fp);
extern int _serror(FILE*, int);
extern int _swalk(int(*f)(FILE*));

#define CONS_BUFSIZE 80
extern struct _svec _cons_svec;

#endif
