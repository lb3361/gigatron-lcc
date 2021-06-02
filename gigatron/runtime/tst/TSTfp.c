#include <stdio.h>



int main()
{
	int i;
	int d; unsigned int ud;
	long l; unsigned long ul;

	printf("----------- fcvu\n");
	for (i=1, ud = 1; i!=12; i++,ud*=17)
		printf("%u -> %f\n", ud, (double)ud);
	for (i=1, ul = 1; i!=12; i++,ul*=13)
		printf("%lu -> %f\n", ul, (double)ul);

	printf("----------- fcvi\n");
	d = 0;
	printf("%u -> %f\n", d, (float)d);
	for (i=1, d = 1; i!=12; i++,d*=-13)
		printf("%d -> %f\n", d, (double)d);
	for (i=1, l = 1; i!=12; i++,l*=-17)
		printf("%ld -> %f\n", l, (double)l);
	
	


	return 0;
}
