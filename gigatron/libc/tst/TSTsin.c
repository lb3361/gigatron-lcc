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
	printf("x=%+5.1f sin=%+11.8f %s %s cos=%+11.8f",
	       x, s, mercury(s), mercury(c), c );
	printf(" tan=%+.8g\n", tan(x));
}

#ifdef __gigatron
extern double _pi, _pi_over_4;
#else
double _pi = M_PI, _pi_over_4 = M_PI_4;
#endif

int main()
{
	int i;
#ifdef __gigatron__
	signal(SIGFPE, (sig_handler_t)handler);
#endif
	for (i = -50; i <= 50; i+=2)
		go(i * 0.1);
	printf("\n");
	for (i = 0; i != 8; i++)
		go (_pi_over_4 * i);
	return 0;
}
