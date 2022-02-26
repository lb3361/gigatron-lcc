#include <stdio.h>

extern unsigned int _tstxla();

int main()
{
	unsigned int pc = _tstxla();
	printf("_tstxla() returns %04x\n", pc);
	return 0;
}
