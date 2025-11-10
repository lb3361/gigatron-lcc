#include <stdio.h>
#include <string.h>
#include <stdarg.h>



const char *prec[] = { "", "8", "-8", "1", "-32", "8.4", "-8.6", "1.6", "-32.6", 0 };
const char *precz[] = { "", "8", "-8", "1", "-32", "8.4", "-8.6", "1.6", "-32.6", "08", "010.5", 0 };

const char *flags[] = { "", "+", 0 };
const char *flagu[] = { "", "#", 0 };
const char *flagn[] = { "", 0 };

char *str1 = "abcdefg\0";
char *str2 = "dkhjkwjdkwidhhdiobwbdoidoioiabcdefg\0";
double pi3 = 3.1415965493 / 3.0;


void tst1v(const char *f, const char *p, const char *c, va_list ap)
{
	static char fmtbuf[256];
	const char *cc = c;
#if RUNNING_ON_HOST
	char ccc[8];
	if (c[0]=='l')
		cc = c+1;
	else if (index("iduoxX", c[0])) {
		ccc[0] = 'h';
		strcpy(ccc+1,c);
		cc = ccc;
	}
#endif	
	sprintf(fmtbuf, "[%%%%%s%s%s] -> [%%%s%s%s]\n", f,p,c,f,p,cc);
	vfprintf(stdout, fmtbuf, ap);
}

void tst2f(const char **f, const char *p, const char *c, ...)
{
	const char **fp;
	va_list ap;
	for (fp=f; *fp; fp++) {
		va_start(ap, c);
		tst1v(*fp, p, c, ap);
		va_end(ap);
	}
}

void tst2fp(const char **f, const char **p, const char *c, ...)
{
	const char **fp, **pp;
	va_list ap;
	for (fp=f; *fp; fp++)
		for (pp=p; *pp; pp++) {
			va_start(ap, c);
			tst1v(*fp, *pp, c, ap);
			va_end(ap);
		}
}

#define TST2FP(f,p,c,x)				\
	tst2fp(f,p,c,x);			\
	tst2f(f,"*",c,10,x);			\
	tst2f(f,"10.*",c,4,x);			\
	tst2f(f,"*.*",c,10,6,x)

int main()
{
	TST2FP(flagn, prec, "c", 'c');

	tst2fp(flagn, prec, "s", str1);
	tst2fp(flagn, prec, "s", str2);
	tst2f(flagn, "-*", "s", 10, str1);
	tst2f(flagn, "-*", "s", 10, str2);
	tst2f(flagn, "*.*", "s", 12, 5, str2);
	tst2f(flagn, "*.*", "s", 12, 5, str1);
	
	TST2FP(flags, precz, "i", 34);
	TST2FP(flags, precz, "i", -1244);
	TST2FP(flags, precz, "i", 0);
	TST2FP(flags, precz, "d", 34);
	TST2FP(flags, precz, "d", -1244);
	TST2FP(flags, precz, "d", 0);
	TST2FP(flagu, precz, "u", 34);
	TST2FP(flagu, precz, "u", -1244);
	TST2FP(flagu, precz, "u", 0);
	TST2FP(flagu, precz, "x", 34);
	TST2FP(flagu, precz, "x", -1244);
	TST2FP(flagu, precz, "x", 0);
	TST2FP(flagu, precz, "o", 34);
	TST2FP(flagu, precz, "o", -1244);
	TST2FP(flagu, precz, "o", 0);
	TST2FP(flagu, precz, "X", 34);
	TST2FP(flagu, precz, "X", -1244);
	TST2FP(flagu, precz, "X", 0);
	TST2FP(flags, precz, "ld", 34L);
	TST2FP(flags, precz, "ld", -1244L);
	TST2FP(flags, precz, "ld", 0L);
	TST2FP(flagu, precz, "lu", 34L);
	TST2FP(flagu, precz, "lu", -1244L);
	TST2FP(flagu, precz, "lu", 0L);
	TST2FP(flagu, precz, "lx", 34L);
	TST2FP(flagu, precz, "lx", -1244L);
	TST2FP(flagu, precz, "lx", 0L);
	TST2FP(flagu, precz, "lo", 34L);
	TST2FP(flagu, precz, "lo", -1244L);
	TST2FP(flagu, precz, "lo", 0L);
	TST2FP(flagu, precz, "lX", 34L);
	TST2FP(flagu, precz, "lX", -1244L);
	TST2FP(flagu, precz, "lX", 0L);

	TST2FP(flags, precz, "e", pi3);
	TST2FP(flags, precz, "e", -pi3*7);
	TST2FP(flags, precz, "e", 0.0);
	TST2FP(flags, precz, "e", pi3*1e18);
	TST2FP(flags, precz, "e", pi3*1e-23);
	TST2FP(flags, precz, "f", pi3);
	TST2FP(flags, precz, "f", -pi3*7);
	TST2FP(flags, precz, "f", 0.0);
	TST2FP(flags, precz, "f", pi3*1e18);
	TST2FP(flags, precz, "f", pi3*1e-23);
	TST2FP(flags, precz, "g", pi3);
	TST2FP(flags, precz, "g", -pi3*7);
	TST2FP(flags, precz, "g", 0.0);
	TST2FP(flags, precz, "g", pi3*1e18);
	TST2FP(flags, precz, "g", pi3*1e-23);
	TST2FP(flags, precz, "G", pi3);
	TST2FP(flags, precz, "G", -pi3*7);
	TST2FP(flags, precz, "G", 0.0);
	TST2FP(flags, precz, "G", pi3*1e18);
	TST2FP(flags, precz, "G", pi3*1e-23);

	return 0;
}
