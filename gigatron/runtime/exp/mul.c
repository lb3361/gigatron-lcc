#include <assert.h>

typedef unsigned short word;

#define NELEMS(a) (sizeof(a)/sizeof(a[0]))

#ifdef TEST
word uVecs[] = { 0x0000, 0x0234, 0xa234, 0xffff };
int  iVecs[] = { 0x0000, 0x0234, 0xa234, 0xffff };
#endif


#ifdef TEST
word Ra;
word Rb;
word Rc;
word Rd;
#else
#define Ra  (*(word*)0xA0)
#define Rb  (*(word*)0xB0)
#define Rc  (*(word*)0xC0)
#define Rd  (*(word*)0xD0)
#endif

void _mul16()
{
	Rc = 0;
	Rd = 1;
	do {
		if (Rb & Rd)
			Rc += Ra;
		Ra <<= 1;
		Rd <<= 1;
	} while((-(short)Rd) & Rb);
}

word mul16(word a, word b)
{
	Ra = a;
	Rb = b;
	_mul16();
	return Rc;
}

#ifdef TEST
void main()
{
	int i, j;
	for (i=0; i<NELEMS(uVecs); i++)
		for (j=0; j<NELEMS(uVecs); j++)
			assert( mul16(uVecs[i],uVecs[j]) == (word)(uVecs[i]*uVecs[j]) );
	for (i=0; i<NELEMS(iVecs); i++)
		for (j=0; j<NELEMS(iVecs); j++)
			assert( (short)mul16(iVecs[i],iVecs[j]) == (short)(iVecs[i]*iVecs[j]) );
}
#endif
