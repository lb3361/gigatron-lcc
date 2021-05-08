#include <stdio.h>

int main()
{
	unsigned int i;
	int j;

	for (i=0; i<0x8000u; i=(i+i)^0x45) {
		printf("\n");
		for (j=-2; j<18; j++) {
			printf("%04x >> %04x = %04x\t", i, j, (unsigned)(i >> j));
			printf("%04x >> %04x = %04x\n", -(int)i, j, (unsigned)((-(int)i) >> j));
		}
	}
	return 0;
}
