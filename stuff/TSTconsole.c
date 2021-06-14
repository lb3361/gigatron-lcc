#include <stdlib.h>
#include <gigatron/console.h>


const char *itoa(int x)
{
	int neg = 0;
	static char buffer[8];
	register char *s = buffer+sizeof(buffer);
	*s-- = 0;
	if (x < 0)
		neg = x = -x;
	do {
		*--s = x % 10 + '0';
		x = x / 10;
	} while (x > 0);
	if (neg)
		*--s = '-';
	return s;
}


int main()
{
	int i;
	console_print("\tHello World!\n\a(bell)\n", 256);
	for (i=0; i<100; i++) {
		console_print(itoa(i), 256);
		console_print("\n", 1);
	}

	console_scroll(2,8,-2);

	i = i / 0;
	
	return 0;
}
