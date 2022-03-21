#include <gigatron/libc.h>
#include <gigatron/sys.h>
#include <gigatron/console.h>
#include <stdlib.h>
#include <string.h>


#define true 1
#define false 0
#define size 8190
#define sizepl 8191

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
  cprintf("10 iterations\n\n");
  ticks = 0;
  frameCount = 0;
  for (iter = 1; iter <= 10; iter ++) {
    memset(flags, 1, sizepl);
    count = sieve();
    ticks += frameCount;
    frameCount = 0;
  }
  cprintf("%d primes\n", count);
  cprintf("%d %d/60 seconds\n", ticks/60, ticks%60);
  return 0;
}

/* Local Variables: */
/* mode: c */
/* c-basic-offset: 2 */
/* indent-tabs-mode: () */
/* End: */
