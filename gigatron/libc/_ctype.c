#include <ctype.h>

/* Split the ctype array in pieces smaller than 96 bytes */

static unsigned char _ctype1[] = {
      	__C,	__C,	__C,	__C,	__C,	__C,	__C,	__C, /*00*/
	__C,	__C|__S,__C|__S,__C|__S,__C|__S,__C|__S,__C,	__C,
	__C,	__C,	__C,	__C,	__C,	__C,	__C,	__C, /*10*/
	__C,	__C,	__C,	__C,	__C,	__C,	__C,	__C,
	__S|__B,__P,	__P,	__P,	__P,	__P,	__P,	__P, /*20*/
	__P,	__P,	__P,	__P,	__P,	__P,	__P,	__P,
	__N,	__N,	__N,	__N,	__N,	__N,	__N,	__N, /*30*/
	__N,	__N,	__P,	__P,	__P,	__P,	__P,	__P
};

static unsigned char _ctype2[] = {
	__P,	__U|__X,__U|__X,__U|__X,__U|__X,__U|__X,__U|__X,__U, /*40*/
	__U,	__U,	__U,	__U,	__U,	__U,	__U,	__U,
	__U,	__U,	__U,	__U,	__U,	__U,	__U,	__U, /*50*/
	__U,	__U,	__U,	__P,	__P,	__P,	__P,	__P,
	__P,	__L|__X,__L|__X,__L|__X,__L|__X,__L|__X,__L|__X,__L, /*60*/
	__L,	__L,	__L,	__L,	__L,	__L,	__L,	__L,
	__L,	__L,	__L,	__L,	__L,	__L,	__L,	__L, /*70*/
	__L,	__L,	__L,	__P,	__P,	__P,	__P,	__C,
	__P,    __P,    __P,    __P   /* Gigatron arrow characters */
};


unsigned char _ctype(register unsigned int c)
{
	if (c < 64)
		return _ctype1[c];
	else if (c < 132)
		return _ctype2[c - 64];
	return 0;
}
