#include <stdlib.h>
#include <stdio.h>

int main()
{
   int i;
   for(i=0; i<50000; i++)
	printf("%d\n", rand());
}
