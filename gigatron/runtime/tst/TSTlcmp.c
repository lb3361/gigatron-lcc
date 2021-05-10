#include <stdio.h>

#define NELEMS(a) (sizeof(a)/sizeof(a[0]))

#ifdef __GNUC__
# define dword int
#else
# define dword long
#endif


dword p[] = { 0x00000000LU, 0x00000001LU, 0x01001001LU, 0x10801080LU,
	      0x000000ffLU, 0x0000ffffLU, 0x00ffffffLU, 0xffffffffLU,
	      0x12345678LU, 0xabcdeabcLU, 0x0aa0aa0aLU, 0xaa0aa0aaLU };
	
	
int main()
{
	int i, j;
	
	for (i=0; i<NELEMS(p); i++) {
		printf("\n");
		for (j=0; j<NELEMS(p); j++) {
			printf("%ld <= %ld = %c\t", (long)p[i], (long)p[j], (p[i]<=p[j])?'T':'F');
			printf("%ld < %ld = %c\t", (long)p[i], (long)p[j], (p[i]<p[j])?'T':'F');
			printf("%ld > %ld = %c\t", (long)p[i], (long)p[j], (p[i]>p[j])?'T':'F');
			printf("%ld == %ld = %c\n", (long)p[i], (long)p[j], (p[i]==p[j])?'T':'F');
		}
	}
	return 0;
}
