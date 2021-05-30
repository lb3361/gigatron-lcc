#ifndef __CTYPE
#define __CTYPE


extern int tolower(int);
extern int toupper(int);

#define	__U	01
#define	__L	02
#define	__N	04
#define	__S	010
#define	__P	020
#define	__C	040
#define	__B	0100
#define	__X	0200

extern unsigned char _ctype(unsigned int);

#define isascii(c)      ((c)==((c)&0x7f))
#define	isalnum(c)	(_ctype(c)&(__U|__L|__N))
#define	isalpha(c)	(_ctype(c)&(__U|__L))
#define	iscntrl(c)	(_ctype(c)&(__C))
#define	isdigit(c)	(_ctype(c)&(__N))
#define	isgraph(c)	(_ctype(c)&(__P|__U|__L|__N))
#define	islower(c)	(_ctype(c)&(__L))
#define	isprint(c)	(_ctype(c)&(__P|__U|__L|__N|__B))
#define	ispunct(c)	(_ctype(c)&(__P))
#define	isspace(c)	(_ctype(c)&(__S))
#define	isupper(c)	(_ctype(c)&(__U))
#define	isxdigit(c)	(_ctype(c)&(__X))

#endif /* __CTYPE */
