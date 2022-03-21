#include <gigatron/libc.h>
#include <gigatron/sys.h>
#include <gigatron/console.h>
#include <stdlib.h>
#include <string.h>

#ifndef USE_CPRINTF
# define USE_CPRINTF 0
#endif
#ifndef USE_CONSPRINT
# define USE_CONSPRINT 1
#endif


#define true 1
#define false 0
#define size 8190
#define sizepl 8191


#if USE_CONSPRINT
void console_printi(int i)
{
  char buf8[8];
  console_print(itoa(i,buf8,10),8);
}
#endif

char flags[sizepl];

int sieve() {
  int i, prime, k, count;
  count=0 ; 
  for (i = 0; i <= size; i++) { 
    if (flags[i]) {
      prime = i + i + 3; 
      k = i + prime; 
      while (size - k >= 0) { 
        flags[k] = false; 
        k += prime; 
      }
      count = count + 1;
    }
  }
  return count;
}

int main() {
  int iter, count, ticks;
  char buf8[8];
#if USE_CPRINTF
  cprintf("10 iterations\n\n");
#elif USE_CONSPRINT
  console_print("10 iterations\n\n",26);
#endif  
  ticks = 0;
  frameCount = 0;
  for (iter = 1; iter <= 10; iter ++) {
    memset(flags, 1, sizepl);
    count = sieve();
    ticks += frameCount;
    frameCount = 0;
  }
#if USE_CPRINTF
  cprintf("%d primes\n", count);
  cprintf("%d %d/60 seconds\n", ticks/60, ticks%60);
#elif USE_CONSPRINT
  console_printi(count);
  console_print(" primes\n", 10);
  console_printi(ticks/60);
  console_print(" ", 1);
  console_printi(ticks%60);
  console_print("/60 seconds\n", 26);
#endif  
  
  return 0;
}

/* Local Variables: */
/* mode: c */
/* c-basic-offset: 2 */
/* indent-tabs-mode: () */
/* End: */
