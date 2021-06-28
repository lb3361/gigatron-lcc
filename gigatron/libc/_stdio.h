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
extern void _fflush(FILE*);
extern size_t _fwrite(FILE*, const char*, size_t);
extern size_t _fread(FILE*, char*, size_t);
extern FILE *_sfindiob(void);
extern void _sfreeiob(FILE *fp);
extern void _swalk(int(*f)(FILE*));

/* Weak references '__glink_weak_xxxx' do not cause anything to be imported. 
   They resolve to 'xxxx' if it is defined and zero otherwise. */
extern void *__glink_weak_malloc(size_t);
extern void __glink_weak_free(void*);
extern void __glink_weak__doprint_float();
extern void __glink_weak__doscan_float();
extern void __glink_weak__doprint_long();
extern void __glink_weak__doscan_long();

/* printf and scanf support */
extern int _doprint(FILE*, const char*, __va_list);
extern int _doscan(FILE*, const char*, __va_list);
extern int _doprint_float();
extern int _doscan_float();
extern int _doprint_long();
extern int _doscan_long();

/* Console definitions */
#define CONS_BUFSIZE 80
extern struct _svec _cons_svec;

#endif
