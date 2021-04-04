#include "common.h"


#ifdef TEST
#endif




void _mul16()
{
#define a A(0)
#define b A(2)
#define m A(4)
#define r A(6)
	a.u = R8.u;
	b.u = AC.u;
	m.u = 1;
	r.u = 0;
	do {
		if (b.u & m.u)
			r.u += A(0).u;
		a.u <<= 1;
		m.u <<= 1;
	} while(b.u & -m.i);
	AC.u = r.u;
#undef a
#undef b
#undef m
#undef r
}


#ifdef TEST
#define NELEMS(x) (sizeof(x)/sizeof((x)[0]))
word uVecs[] = { 0x0000, 0x0234, 0xa234, 0xffff };
int  iVecs[] = { 0x0000, 0x0234, 0xa234, 0xffff };

word mul16(word a, word b)
{
	AC.u = a;
	R8.u = b;
	_mul16();
	return AC.u;
}

int main()
{
	int i, j;
	for (i=0; i<NELEMS(uVecs); i++)
		for (j=0; j<NELEMS(uVecs); j++)
			assert( mul16(uVecs[i],uVecs[j]) == (word)(uVecs[i]*uVecs[j]) );
	for (i=0; i<NELEMS(iVecs); i++)
		for (j=0; j<NELEMS(iVecs); j++)
			assert( (short)mul16(iVecs[i],iVecs[j]) == (short)(iVecs[i]*iVecs[j]) );
	return 0;
}
#endif
