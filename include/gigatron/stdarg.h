#ifndef __STDARG
#define __STDARG

#if !defined(_VA_LIST) && !defined(__VA_LIST_DEFINED)
#define _VA_LIST
#define _VA_LIST_DEFINED
typedef char *__va_list;
#endif
typedef __va_list va_list;

#define va_start(list, start) \
  ((void)((list)=(__va_list)&((&start)[1])))
#define va_arg(list, mode)    \
  ((list=(__va_list)&(((mode*)list)[1])),((mode*)list)[-1])
#define va_end(list)          \
  ((void) 0)

#endif
