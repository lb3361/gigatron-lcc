#ifndef __MATH
#define __MATH

#define HUGE_VAL 1.701411834209e+38

extern double acos(double);
extern double asin(double);
extern double atan(double);
extern double atan2(double, double);
extern double cos(double);
extern double sin(double);
extern double tan(double);
extern double cosh(double);
extern double sinh(double);
extern double tanh(double);
extern double exp(double);
extern double frexp(double, int *);
extern double ldexp(double, int);
extern double log(double);
extern double log10(double);
extern double modf(double, double *);
extern double pow(double, double);
extern double sqrt(double);
extern double ceil(double);
extern double fabs(double);
extern double floor(double);
extern double fmod(double, double);
extern double copysign(double, double);

extern double remquo(double x, double y, int *quo);
extern double log1p(double x);


#endif /* __MATH */
