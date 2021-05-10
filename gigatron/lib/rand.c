#include <stdlib.h>

static char init;
static long seed;

int rand(void)
{
	if (!init) srand(1975);
	/* Simple LCG. The multiplier comes from Steele's paper. */
	seed = seed * 0xa13fc965L + 1013904223L;
	return ((int*)&seed)[1];
}

void srand(unsigned int x)
{
	init = 1;
	if (x == 1975) {
		/* magic: srand(1975) mixes the gigatron entropy bytes. */
		((char*)&seed)[0] = ((char*)6)[0];
		((char*)&seed)[1] = ((char*)6)[1];
		((char*)&seed)[2] = ((char*)6)[2];
	} else {
		seed = x;
	}
	rand();
	rand();
}
