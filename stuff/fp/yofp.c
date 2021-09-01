#include <stdlib.h>
#include <stdio.h>
#include <math.h>

int main()
{
	char buffer[20];
	const char *s = "pi";
	double x = 3.141592653589793;
	double y;
	for(;;) {
		printf("\fGigatron floating point\n\n");
		printf("- %s=%.8g\n", s, x);
		y = sqrt(x);
		printf("- y=sqrt(%s)=%.8g\n", s, y);
		printf("- y*y=%.8g\n", y*y);
		printf("- log(%s)=%.8g\n", s, log(x));
		printf("- log(y)=%.8g\n", log(y));
		s = "x";
		printf("\nYour number? ");
		fgets(buffer, 20, stdin);
		x = atof(buffer);
	}
}
