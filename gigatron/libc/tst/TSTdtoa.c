
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <gigatron/libc.h>

char buffer[64];

//#define REF " (%."
#define REF " (%%."

#define TSTE(x,p) \
	printf("dtoa(" #x ",buffer,'e',%d) -> [%s]" REF #p "e)\n", \
	       p, dtoa(x, buffer, 'e', p), (double)x);
#define TSTF(x,p) \
	printf("dtoa(" #x ",buffer,'f',%d) -> [%s]" REF #p "f)\n", \
	       p, dtoa(x, buffer, 'f', p), (double)x);
#define TSTG(x,p) \
	printf("dtoa(" #x ",buffer,'g',%d) -> [%s]" REF #p "g)\n", \
	       p, dtoa(x, buffer, 'g', p), (double)x);
#define TSTGCVT(x,p) \
	printf("gvct(" #x ", %d, buffer)   -> [%s]" REF #p "g)\n", \
	       p, gcvt(x, p, buffer), (double)x);

#define TST(x,p)  \
	printf("----\n"); \
	TSTE(x,p); TSTF(x,p); TSTG(x,p); TSTGCVT(x, p)

double pi = 3.141592653589793;

double ulong_max = (double)(0xfffffffful);

int main()
{
	TST(0,6);
	TST(1,4);
	TST(-37.2,4);
	TST(pi,4);
	TST(pi,12);
	TST(pi*1e6,3);
	TST(pi*1e-6,3);
	TST(ulong_max,2);
	TST(1e-12,8);
	TST(1e-38,8);	
	TST(1e+38,8);
	return 0;
}
