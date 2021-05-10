#include <stdio.h>

#ifdef __GNUC__
typedef unsigned short word;
#else
typedef unsigned int word;
#endif


int main()
{
	unsigned int i;
	int j;

	for (i=0; i<0x8000u; i=(i+i)^0x45) {
		printf("\n");
		for (j=0; j<16; j++) // others are undefined
			printf("%04x << %04x = %04x\n", (word)i, (word)j, (word)(i << j));
	}
	return 0;
}
