#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

const char * v[] =
	{ "23",
	  "-245.3",
	  "0",
	  ".0",
	  ".",
	  "429.4967295",
	  "429496.7296",
	  "-0377",
	  "+3000000000e10",
	  "-3000000000e10",
	  " 17e499 overflow",
	  " 17e-499 underflow (should set errno but doesn't)",
	  "83928038989809890809",
	  "0.00000000000000000000000000000000000000001e30",
	  "-100000000000000000000000000000000000000000e-30",
	  "  -9999999999.999",
	  "  23z",
	  "  23e+",
	  "4294967291",
	  "4294967292",
	  "4294967293",
	  "4294967294",
	  "4294967295",
	  "4294967296",
	  "4294967297",
	  "4294967298",
	  "4294967299",
	  "4294967300",
	  "   asdf",
	  0 };

int main()
{
	double x;
	const char **vv = v;
	const char *s;
	char *e;
	while (*vv) {
		s = *vv;
		printf("strtod(\"%s\") = ", s);
		errno = 0;
		x = strtod(s, &e);
		printf("%.8g, delta=%+d errno=%d\n", x, e-s, errno);
		vv += 1;
	}
	return 0;
}

