#include <stdio.h>
#include <math.h>


void test_fmod(double a, double b)
{
	double x, y=0, z=0;
	printf("%.8g %% %.8g = ", a, b);
	x = fmod(a,b);
	z = modf(a / b, &y);
	printf("%.8g  (ratio %.8g frac %.8g -> %.8g) \n", fmod(a,b), y, z, y * b + x);
}

int main()
{
	test_fmod(5, -1.5);
	test_fmod(-235.4, -1.5);
	test_fmod(235.4, -1.5);
	test_fmod(1e25, -1.5);
	test_fmod(-1e25, -1.5);
	test_fmod(100.25, -1.5);
	test_fmod(100.25, 1e-15);
	test_fmod(100.25, 0);
	return 0;
}
