#ifndef _DOPRINT_INTERNAL
#define _DOPRINT_INTERNAL

#include <gigatron/libc.h>
#include <gigatron/printf.h>

#include "_stdlib.h"

#define DPR_LEFTJ   1
#define DPR_ZEROJ   2
#define DPR_SGN     4
#define DPR_SPC     8
#define DPR_ALT    16
#define DPR_LONG   32
#define DPR_WIDTH  64
#define DPR_PREC  128

struct doprint_s {
	int cnt;
	void *closure;
	void (*f)(void*, const char*, size_t);
};

extern void _doprint_putc(doprint_t*, int, size_t);
extern void _doprint_puts(doprint_t*, const char*, size_t);

typedef struct doprintspec_s {
	char flags;
	char conv;
	int width;
	int prec;
} doprintspec_t;

extern void _doprint_num(doprint_t*, doprintspec_t*, int, char*);
extern void _doprint_double(doprint_t*, doprintspec_t*, __va_list*);
extern void _doprint_long(doprint_t*, doprintspec_t*, int, __va_list*);

#endif
