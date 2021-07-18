#ifndef _STDIO_INTERNAL
#define _STDIO_INTERNAL

#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <gigatron/libc.h>

#define _IOB_NUM 5

extern struct _more_iobuf *_more_iob;

struct _more_iobuf {
	struct _iobuf _iob[_IOB_NUM];
	struct _more_iobuf *next;
};

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

extern int _strtol_push1(strtol_t*, int, int);
extern int _strtol_decode_u(strtol_t*, unsigned long *px);
extern int _strtol_decode_s(strtol_t*, long *px);



/* Printf and scanf support. 
   The _do{print|scan}_{float|long} functions forward to their actual
   implementation _do{print|scan}_{float|long}_imp() which may or may 
   not be included in the link depending on whether floats or longs
   are used in the calling program. */


typedef struct doscan_s {
	int c;
	FILE *fp;
	int cnt;
	int n;
} doscan_t;

extern int _doscan(FILE*, const char*, __va_list);
extern int _doscan_next(doscan_t *);
extern void _doscan_double(doscan_t *, double *);


extern int _doprint(FILE*, const char*, __va_list);
extern int _doprint_double();
extern int _doprint_long();

/* Console definitions */
#define CONS_BUFSIZE 80
extern struct _svec _cons_svec;

#endif
