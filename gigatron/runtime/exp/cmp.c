#include <stdio.h>
#include <stdlib.h>

typedef signed short   sword;
typedef unsigned short uword;
typedef signed char    sbyte;
typedef unsigned char  ubyte;


int cmp(int a, int b)
{
	return (a<b)?-1:(a==b)?0:1;
}

sword cmpis(sword a, ubyte b)
{
	if (a >= 0)
		a = a - b;
	return a;
}

sword cmpiu(sword a, ubyte b)
{
	if (a < 0)
		a = 0x100;
	a = a - b;
	return a;
}


sword cmpws(sword a, sword b)
{
	if ((a ^ b) & 0x8000)
		a = a | 1;
	else
		a = a - b;
	return a;
}

sword cmpwu(sword a, sword b)
{
	if ((a ^ b) & 0x8000)
		a = b | 1;
	else
		a = a - b;
	return a;
}

void cmphs(sbyte *a, sbyte h)
{
	if ((sbyte)(h ^ a[1]) < 0) {
		if (a[1] < 0)
			a[1] = -1 + h;
		else
			a[1] = +1 + h;
	}
}

sword cmphu(sbyte *a, sbyte h)
{
	if ((sbyte)(h ^ a[1]) < 0) {
		if (a[1] < 0)
			a[1] = +1 + h;
		else
			a[1] = -1 + h;
	}
}

sword cmpis2(sword a, ubyte b)
{
	cmphs((sbyte*)&a, 0);
	a = a - b;
	return a;
}

sword cmpiu2(sword a, ubyte b)
{
	cmphu((sbyte*)&a, 0);
	a = a - b;
	return a;
}

sword cmpws2(sword a, sword b)
{
	cmphs((sbyte*)&a, (sbyte)(b>>8));
	a = a - b;
	return a;
}

sword cmpwu2(sword a, sword b)
{
	cmphu((sbyte*)&a, (sbyte)(b>>8));
	a = a - b;
	return a;
}

void main()
{
	int i,j;
	for (i=0; i<65536; i++) {
		printf("\r        \r  0x%04x\r", i); fflush(stdout);
		for (j=0; j<65536; j++) {
#define DO(f,t1,t2) \
     if (cmp((t1)i,(t2)j) != cmp(f((t1)i,(t2)j),0)) \
	   printf("fail: %s(0x%04x,0x%04x)\n", #f, (uword)(t1)i, (uword)(t2)j);
			DO(cmpis,sword,ubyte);
			DO(cmpiu,uword,ubyte);
			DO(cmpws,sword,sword);
			DO(cmpwu,uword,uword);
			DO(cmpis2,sword,ubyte);
			DO(cmpiu2,uword,ubyte);
			DO(cmpws2,sword,sword);
			DO(cmpwu2,uword,uword);
		}
	}
}

