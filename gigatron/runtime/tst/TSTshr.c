#include <stdio.h>


#ifdef __GNUC__
typedef unsigned short word;
typedef short sword;
#else
typedef unsigned int word;
typedef int sword;
#endif

int main()
{
	unsigned int i;
	int j;

	for (i=0; i<0x8000u; i=(i+i)^0x45) {
		printf("\n");
		for (j=0; j<16; j++) {
			printf("%04x >> %04x = %04x\t", i, j, (word)(i >> j));
			printf("%04x >> %04x = %04x\t", i, j, (word)((sword)i >> j));
			printf("%04x >> %04x = %04x\n", (word)(-(sword)i), j, (word)((-(sword)i) >> j));
		}
	}
	return 0;
}
