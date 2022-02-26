#include <stdio.h>

extern void _tstjmpi();

int main()
{
	_tstjmpi();
	printf("_tstjmpi returned\n");
	return 0;
}
