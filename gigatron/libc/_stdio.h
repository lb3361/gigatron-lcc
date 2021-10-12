#ifndef _STDIO_INTERNAL
#define _STDIO_INTERNAL

#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <gigatron/libc.h>


/* Buffering stuff */

#define _IOB_NUM 5

extern struct _more_iobuf {
	struct _iobuf _iob[_IOB_NUM];
	struct _more_iobuf *next;
} *_more_iob;

extern int _schkwrite(FILE*);
extern int _schkread(FILE*);
extern int _serror(FILE*, int);
extern int _fcheck(FILE*);
extern int _fclose(FILE*);
extern int _fflush(FILE*);
extern size_t _fwrite(FILE*, const char*, size_t);
extern size_t _fread(FILE*, char*, size_t);
extern FILE *_sfindiob(void);
extern void _sfreeiob(FILE *fp);
extern void _swalk(int(*f)(FILE*));


/* Weak references '__glink_weak_xxxx' do not cause anything to be imported. 
   They resolve to 'xxxx' if it is defined and zero otherwise. */
extern void *__glink_weak_malloc(size_t);
extern void __glink_weak_free(void*);


/* String to number conversions */

typedef struct {
	int flags, base;
	unsigned long x;
} strtol_t;

extern int _strtol_push(strtol_t*, int c);
extern int _strtol_decode_u(strtol_t*, unsigned long *px);
extern int _strtol_decode_s(strtol_t*, long *px);

typedef struct {
	int flags;
	int e0, e1;
	double x;
} strtod_t;

extern int _strtod_push(strtod_t*, int c, const char *p);
extern int _strtod_decode(strtod_t*, double *px);


/* Console definitions */

#define CONS_BUFSIZE 80
extern struct _svec _cons_svec;

/* Printf and scanf support. 
   The _do{print|scan}_{float|long} functions forward to their actual
   implementation _do{print|scan}_{float|long}_imp() which may or may 
   not be included in the link depending on whether floats or longs
   are used in the calling program. */

typedef struct {
	int c;
	FILE *fp;
	int cnt;
	int n;
} doscan_t;

extern int _doscan(FILE*, const char*, __va_list);
extern int _doscan_next(doscan_t *);
extern int _doscan_double(doscan_t *, double *);


#endif
