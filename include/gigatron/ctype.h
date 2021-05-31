#ifndef __CTYPE
#define __CTYPE

#define	__U	01
#define	__L	02
#define	__N	04
#define	__S	010
#define	__P	020
#define	__C	040
#define	__B	0100
#define	__X	0200

enum {
      _isalnum  = __U|__L|__N,
      _isalpha  = __U|__L,
      _iscntrl  = __C,
      _isdigit  = __N,
      _isgraph  = __P|__U|__L|__N,
      _islower  = __L,
      _isprint  = __P|__U|__L|__N|__B,
      _ispunct  = __P,
      _isspace  = __S,
      _isupper  = __U,
      _isxdigit = __X
};

extern unsigned char _ctype(unsigned int);

#define isascii(c)      (!((c)&~0x7fU))
#define	isalnum(c)	(_ctype(c)&_isalnum)
#define	isalpha(c)	(_ctype(c)&_isalpha)
#define	iscntrl(c)	(_ctype(c)&_iscntrl)
#define	isdigit(c)	(_ctype(c)&_isdigit)
#define	isgraph(c)	(_ctype(c)&_isgraph)
#define	islower(c)	(_ctype(c)&_islower)
#define	isprint(c)	(_ctype(c)&_isprint)
#define	ispunct(c)	(_ctype(c)&_ispunct)
#define	isspace(c)	(_ctype(c)&_isspace)
#define	isupper(c)	(_ctype(c)&_isupper)
#define	isxdigit(c)	(_ctype(c)&_isxdigit)

extern int tolower(int);
extern int toupper(int);

#endif /* __CTYPE */
