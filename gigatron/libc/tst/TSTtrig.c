#include <stdio.h>
#include <signal.h>
#include <math.h>

const char *mercury(double x)
{
	static char* m[] = {
		"*****|     ",
		" ****|     ",
		"  ***|     ",
		"   **|     ",
		"    *|     ",
		"     |     ", 
		"     |*    ",
		"     |**   ",
		"     |***  ",
		"     |**** ",
		"     |*****",
		"     |*****"  };
	if (x <= -1.0)
		x = -1.0;
	else if (x >= 1.0)
		x = 1.0;
	return m[ (int)((x + 1.0) * 5.5) ];
}

#ifdef __gigatron__
double handler(int signo)
{
	printf(" [SIGFPE] ");
	signal(SIGFPE, (sig_handler_t)handler);
	return HUGE_VAL;
}
#endif

void go(double x)
{
	double s = sin(x);
	double c = cos(x);
	printf("x=%+5.1f sin=%+11.9f %s %s cos=%+11.9f",
	       x, s, mercury(s), mercury(c), c );
	printf(" tan=%+.8g\n", tan(x));
}

double pi = 3.14159265359;

int main()
{
	double x;
	int i;
#ifdef __gigatron__
	signal(SIGFPE, (sig_handler_t)handler);
#endif
	for (x = -5; x <= +5; x += 0.1)
		go(x);
	printf("\n");
	for (i = 0; i != 8; i++)
		go (pi * (i / 4.0));
	return 0;
}
