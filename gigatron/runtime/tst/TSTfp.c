#include <stdio.h>
#include <math.h>

#ifdef __GNUC__
# define word short
# define dword int
#else
# define word int
# define dword long
#endif

double rand()
{
	static unsigned dword whatever = 0;
	double x;
	int e;

	whatever = whatever * (dword)1664525L + (dword)1013904223L;
	x = (double)whatever;
	if (whatever & 0x200)
		x = -x;
	e = 80 - ((whatever>>16)&0xff);
#ifdef __GNUC__
	x = ldexp(x, e);
	frexp(x, &e);
	if (e <= -128)
		x = 0;
#else
	e = (*(char*)&x) + e;
	if (e > 0)
		(*(char*)&x) = e;
	else
		x = 0;
#endif
	return x;
}



int main()
{
	int i;
	word d; unsigned word ud;
	dword l; unsigned dword ul;
	double x, y;

	printf("----------- fcvu\n");
	for (i=1, ud = 1; i!=12; i++, ud *= 17)
		printf("%u -> %f\n", ud, (double)ud);
	for (i=1, ul = 1; i!=12; i++, ul *= 13)
		printf("%lu -> %f\n", (long)ul, (double)ul);

	printf("----------- fcvi\n");
	d = 0;
	printf("%u -> %f\n", d, (float)d);
	for (i=1, d = 1; i!=12; i++, d *= -13)
		printf("%d -> %f\n", d, (double)d);
	for (i=1, l = 1; i!=12; i++, l *= -17)
		printf("%ld -> %f\n", (long)l, (double)l);
	
	printf("------------ fadd/fsub\n");
	x = 0;
	for (i=0; i<100; i++) {
		y = rand();
		printf("a=%.6e b=%.6e ", x, y);
		printf("a+b=%.6e a-b=%.6e\n", x+y, x-y);
		x = y;
	}

	return 0;
}
