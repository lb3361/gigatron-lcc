#include <stdio.h>
#include <stdlib.h>
#include <string.h>


extern _tstncopy(void *dst, void *src, int n);

#define mem ((char*)0x9000)

#define tst(d,s,n) do {	int i;                       \
	  for (i=0; i!=1024; i++)                     \
	    mem[i]=i+((i>>2)&0xff);	             \
	  _tstncopy(mem+d,mem+s,n);                  \
	  if (memcmp(mem+d,mem+s,n))                 \
	    printf(" tst(%d,%d,%d) FAIL\n",d,s,n);   \
	  else                                       \
	    printf(" tst(%d,%d,%d) pass\n",d,s,n);   \
	} while(0) 
			  


void dotst(int n)
{
	printf("Blocks of size %d\n", n);
	tst(0,512+128,n); // no crossings
	tst(254,512+128,n); // dst page crossings
	tst(128,512+254,n); // src page crossings
	tst(253,512+252,n); // both
}

int main()
{
	int i;
	for (i=0; i<10; i++) {
		dotst(5);
		dotst(17);
		dotst(256);
	}
	return 0;
}
