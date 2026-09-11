#ifndef __SETJMP
#define __SETJMP




typedef int jmp_buf[12];

extern int setjmp(jmp_buf);
extern void longjmp(jmp_buf, int);

#endif /* __SETJMP */
