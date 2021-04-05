#include "common.h"



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

void chk_mul(word a, word b)
{
	AC.u = a;
	R8.u = b;
	_mul16();
	CHK(AC.u == (word)(a * b));
}

int main()
{
	int i;
	for (i=0; i<1000000; i++)
		chk_mul((word)rand(), (word)rand());
	return 0;
}

#endif
