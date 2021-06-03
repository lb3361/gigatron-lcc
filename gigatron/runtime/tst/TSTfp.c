#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#ifdef __gigatron__
# define word int
# define dword long
# define c(x) x
#else
# define word short
# define dword int
#endif


#ifdef __gigatron__
/* quick ldexp to avoid -lm in test file */
double ldexp(double x, int i)
{
	i = i + *(unsigned char*)&x;
	if (i <= 0)
		return 0;
	if (i > 255)
		abort();
	*(unsigned char*)&x = i;
	return x;
}
#endif


#ifndef __gigatron__
/* cut ieee double to gigatron precision.
   note that there are still carry effects. */
double c(double x)
{
	int exponent;
	double y = copysign(1.0, x);
	long mantissa = (long)floor(ldexp(frexp(fabs(x), &exponent), 32));
	if (exponent <= -128)
		return 0;
	if (exponent > 127)
		abort();
	y *= ldexp((double)mantissa, exponent-32);
	//printf("((%e -> e=%d m=%lx -> %e))\n", x, exponent, mantissa, y);
	return y;
}
#endif


double drand()
{
	static unsigned dword whatever = 0;
	double x;
	int e;

	whatever = whatever * (dword)1664525L + (dword)1013904223L;
	x = (double)whatever;
	if (whatever & 0x200)
		x = -x;
	e = 40 - ((whatever>>16)&0x7f);
	return c(ldexp(x, e));
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
		y = drand();
		printf("a=%+.6e b=%+.6e ", x, y);
		printf("a+b=%+.6e a-b=%+.6e\n", c(x+y), c(x-y));
		x = y;
	}

	return 0;
}
