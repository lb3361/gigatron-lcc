#ifndef __CTYPE
#define __CTYPE

/* Table based ctype does not make sense in the gigatron 
   because it requires too much contiguous memory. */

extern int isascii(int)  __attribute__((quickcall));
extern int isalnum(int)  __attribute__((quickcall));
extern int isalpha(int)  __attribute__((quickcall));
extern int iscntrl(int)  __attribute__((quickcall));
extern int isdigit(int)  __attribute__((quickcall));
extern int isgraph(int)  __attribute__((quickcall));
extern int islower(int)  __attribute__((quickcall));
extern int isprint(int)  __attribute__((quickcall));
extern int ispunct(int)  __attribute__((quickcall));
extern int isspace(int)  __attribute__((quickcall));
extern int isupper(int)  __attribute__((quickcall));
extern int isxdigit(int) __attribute__((quickcall));
extern int tolower(int)  __attribute__((quickcall));
extern int toupper(int)  __attribute__((quickcall));

#define isascii(c)      (!((c)&~0x7fU))

/* Macro versions can be cheaper */

#define _isalpha(c)     isalpha(c)
#define	_isdigit(c)	((int)((c)-'0')>=0 && (int)((c)-'9')<=0)
//#define	_islower(c)	((int)((c)-'a')>=0 && (int)((c)-'z')<=0)
#define _islower(c)     islower(c)
#define _isspace(c)     isspace(c)
//#define	_isupper(c)	((int)((c)-'A')>=0 && (int)((c)-'Z')<=0)
#define _isupper(c)     isupper(c)
#define	_isxdigit(c)    isxdigit(c)



#if 0
#endif

#endif /* __CTYPE */
