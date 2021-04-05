#include "common.h"


#define a A(0)
#define d A(2)
#define q A(4)
#define c A(6)
#define s A(7)


/* The following two routines assume that a and d are unsigned in range 0x0000-0x7fff
   Quotient q and shift count c are to be initialized to zero */

void _div_worker()
{
	register sword t1,t2;
 loop1:
	t1 = d.i << 1;
	t2 = a.i - d.i;
	if (t1 >= 0 && t2 >= 0) {
		d.i = t1;
		c.b += 1;
		goto loop1;
	}
	SR.u = c.b;
 loop2:
	t2 = a.i - d.i;
	if (t2 >= 0) {
		a.u = t2;
		q.b += 1;
	}
	if (c.b > 0) {
		c.b -= 1;
		a.u <<= 1;
		q.u <<= 1;
		goto loop2;
	}
}
	


word _divu()
{
	a.u = AC.u;
	d.u = R8.u;
	c.b = 0;
	q.u = 0;
	if (d.i == 0)
		return 0;
	if (d.i < 0) {  /* if d.u >= 0x8000u, then q=0 or 1. */
		if ((a.i < 0) && (sword)(a.i - d.i) >= 0) {
			a.i -= d.i;
			return 1;
		} else
			return 0;
	}
	if (a.i < 0) { 
		while ( (sword)(d.i << 1) >= 0 ) {
			d.i <<= 1;
			c.b += 1;
		}
		do {
			a.u = a.u - d.u;
			q.b += 1;
		} while (a.i < 0);
	}
	_div_worker();
	return q.u;
}

word _modu()
{
	SR.u = 0;
	_divu();
	return a.u >> SR.u;
}
	
sword _divs()
{
	a.i = AC.u;
	d.i = R8.u;
	s.b = 0;
	c.b = 0;
	q.u = 0;
	if (d.i == 0) {
		return 0; /* division by zero */
	} else if (d.i < 0) {
		d.i = -d.i;
		s.b ++;
	}
	if (a.i < 0) {
		a.i = -a.i;
		s.b ++;
	}
	_div_worker();
	if (s.b & 1)
		return -q.i;
	else
		return q.i;
}

sword _mods()
{
	SR.u = 0;
	_divs();
	a.u = a.u >> SR.u;
	if (AC.i < 0)
		return -a.i;
	else
		return +a.i;
}


#undef a
#undef d
#undef q
#undef c
#undef s

#ifdef TEST

void chk_divu(word a, word b)
{
	if (b != 0) {
		AC.u = a;
		R8.u = b;
		CHK(_divu() == (word)(a/b) );
		CHK(_modu() == (word)(a%b) );
	}
	
}

void chk_divs(sword a, sword b)
{
	if (b != 0) {
		AC.i = a;
		R8.i = b;
		CHK((sword)_divs() == (sword)(a/b) );
		CHK((sword)_mods() == (sword)(a%b) );
	}
}

int main()
{
	int i;
	for (i=0; i<1000000; i++)
		chk_divu((word)rand(), (word)rand());
	for (i=0; i<1000000; i++)
		chk_divs((word)rand(), (word)rand());
}
#endif
