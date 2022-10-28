#include <stdio.h>
#include <gigatron/sys.h>
#include <gigatron/libc.h>
#include <time.h>

#define TIMER 1

/** This is the genuine C program of the sieve benchmark.
    The only additions are the #include directives above
    and the timing code enabled by the preprocessor symbol TIMER. **/

#define true 1
#define false 0
#define size 8190
#define sizepl 8191
char flags[sizepl];
main() {
    int i, prime, k, count, iter;
#if TIMER
    unsigned int ticks = _clock();
#endif
    printf("10 iterations\n");
#ifdef MODE
# if MODE == 4
    videoTop_v5 = 238;
# else
    SYS_SetMode(MODE);
# endif
#endif
    for (iter = 1; iter <= 10; iter ++) {
        count=0 ; 
	for (i = 0; i <= size; i++)
	    flags[i] = true; 
        for (i = 0; i <= size; i++) { 
	    if (flags[i]) {
                prime = i + i + 3; 
                k = i + prime; 
                while (k <= size) { 
                    flags[k] = false; 
                    k += prime; 
                }
                count = count + 1;
            }
        }
    }
#ifdef MODE
# if MODE == 4
    videoTop_v5 = 0;
# else
    SYS_SetMode(-1);
# endif
#endif
    printf("\n%d primes", count);
#if TIMER
    ticks = _clock() - ticks;
    printf("\n%d %d/60 seconds", ticks/60, ticks % 60);
#endif
}

/* Local Variables: */
/* mode: c */
/* c-basic-offset: 4 */
/* indent-tabs-mode: () */
/* End: */
