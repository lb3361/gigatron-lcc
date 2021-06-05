#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <signal.h>

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
		return 123456789.0;
	*(unsigned char*)&x = i;
	return x;
}

double sigfpe(int signo, int fpeinfo)
{
	printf("[SIGFPE %d %d] ", signo, fpeinfo);
	signal(SIGFPE, (sig_handler_t)sigfpe);
	return 123456789.0;
}

#else /* not __gigatron */

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
		return 123456789.0;
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

#ifdef __gigatron__
	signal(SIGFPE, (sig_handler_t)sigfpe);
#endif

	printf("----------- fcvu/ftou\n");
	for (i=1, ud = 1; i!=12; i++, ud *= 17) {
		x = (double)ud;
		printf("%u -> %f -> %u\n", ud, x, (unsigned word)x);
	}
	for (i=1, ul = 1; i!=12; i++, ul *= 13) {
		x = (double)ul;
		printf("%lu -> %f -> %lu\n", (long)ul, x, (long)(unsigned dword)x);
	}

	printf("----------- fcvi/ftoi\n");
	d = 0;
	printf("%u -> %f\n", d, (float)d);
	for (i=1, d = 1; i!=12; i++, d *= -13) {
		x = (double)d;
		printf("%d -> %f -> %d\n", d, x, (word)x);
	}
	for (i=1, l = 1; i!=12; i++, l *= -17) {
		x = (double)l;
		printf("%ld -> %f -> %ld\n", (long)l, x, (long)(dword)x);
	}
	
	printf("------------ fadd/fsub\n");
	x = 0;
	for (i=0; i<100; i++) {
		y = drand();
		printf("a=%.8g b=%.8g ", x, y);
		printf("a+b=%.8g a-b=%.8g\n", c(x+y), c(x-y));
		x = y;
	}

	printf("------------ fcmp\n");
	x = 0;
	for (i=0; i<100; i++) {
		if (i % 12)
			y = drand();
		printf("%.8g > %.8g = %d\n", x, y, (x > y));
		printf("%.8g >= %.8g = %d\n", x, y, (x >= y));
		printf("%.8g != %.8g = %d\n", x, y, (x != y));
		x = y;
	}

	printf("------------ fmul\n");
	x = 0;
	for (i=0; i<100; i++) {
		y = drand();
		printf("%.8g * %.8g = ", x, y);
		printf("%.8g\n", c(x * y));
		x = y;
	}
	signal(SIGFPE, SIG_DFL);


	printf("------------ fdiv\n");
	x = 0;
	for (i=0; i<100; i++) {
		y = drand();
		printf("%.8g / %.8g = ", x, y);
		printf("%.8g\n", c(x / y));
		x = y;
	}

	return 0;
}
