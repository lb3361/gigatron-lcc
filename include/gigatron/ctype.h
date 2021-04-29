#ifndef __CTYPE
#define __CTYPE


extern int isascii(int);
extern int isalnum(int);
extern int isalpha(int);
extern int iscntrl(int);
extern int isdigit(int);
extern int isgraph(int);
extern int islower(int);
extern int isprint(int);
extern int ispunct(int);
extern int isspace(int);
extern int isupper(int);
extern int isxdigit(int);
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

extern unsigned char _ctype[];

#define isascii(c)      ((c)==((c)&0x7f))

#define _isctype(c,f)   (isascii(c)?_ctype[c]&(f):0)

#define	isalnum(c)	(_isctype((c),__U|__L|__N))
#define	isalpha(c)	(_isctype((c),__U|__L))
#define	iscntrl(c)	(_isctype((c),__C))
#define	isdigit(c)	(_isctype((c),__N))
#define	isgraph(c)	(_isctype((c),__P|__U|__L|__N))
#define	islower(c)	(_isctype((c),__L))
#define	isprint(c)	(_isctype((c),__P|__U|__L|__N|__B))
#define	ispunct(c)	(_isctype((c),__P))
#define	isspace(c)	(_isctype((c),__S))
#define	isupper(c)	(_isctype((c),__U))
#define	isxdigit(c)	(_isctype((c),__X))

#endif /* __CTYPE */
