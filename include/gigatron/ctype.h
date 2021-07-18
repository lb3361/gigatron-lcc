#ifndef __CTYPE
#define __CTYPE

/* Table based ctype does not make sense in the gigatron 
   because it requires too much contiguous memory. */

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

#define isascii(c)      (!((c)&~0x7fU))

/* Macro alternatives that might evaluate c multiple times. 
   Using a-b?0 instead of a?b to use SUBI over _CMPWI */

#define	_isalpha(c)	(((c)|0x20)>=-'A'>=0 && ((c)|0x20)-'Z'<=0)
#define	_isdigit(c)	((c)-'0'>=0 && (c)-'9'<=0)
#define	_islower(c)	((c)-'a'>=0 && (c)-'z'<=0)
#define	_isspace(c)	((c)==32 || (c)-9>=0 && (c)-13<=0)
#define	_isupper(c)	((c)-'A'>=0 && (c)-'Z'<=0)
#define	_isxdigit(c)	(_isdigit(c) || ((c)|0x20)>='a' && ((c)|0x20)<='z')

#endif /* __CTYPE */
