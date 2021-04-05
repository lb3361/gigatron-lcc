#if TEST
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#endif

typedef unsigned short word;
typedef signed short sword;
typedef unsigned char byte;
typedef signed char sbyte;

typedef struct {
	byte  e;
	sbyte x;
	word  lo;
	sword hi;
} freg_t;

typedef union {
	byte e;
	byte xb[5];
} fmem_t;

typedef union {
	byte   b;
	sbyte  s;
	word   u;
	sword  i;
	byte   xb[6];
	sbyte  sb[6];
	word   xu[3];
	sword  xi[3];
	freg_t f;
} union_t;

#if TEST
word regbase[32];
byte sysargbase[8];
#else
# define regbase ((byte*)0x80)
# define sysargbase ((byte*)0x24)
#endif

#define R(i) (*(union_t*)(regbase+2*i))
#define A(i) (*(union_t*)(sysargbase+i))

#define AC   R(0)
#define SR   R(1)
#define FAC  F(2)
#define LAC  L(3)
#define FARG F(5)
#define LARG L(6)
#define R8   R(8)
#define R12  R(12)

#ifdef TEST
# define CHK(x) if (!(x)) exit(1);
#endif
