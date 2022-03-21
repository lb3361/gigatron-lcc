#include <stdio.h>
#include <gigatron/sys.h>
#define TIMER 1

#define true 1
#define false 0
#define size 8190
#define sizepl 8191
char flags[sizepl];
main() {
	int i, prime, k, count, iter, ticks; 
    printf("10 iterations\n");
    ticks = 0;
#if TIMER
    frameCount = 0;
#endif
    for (iter = 1; iter <= 10; iter ++) {
        count=0 ; 
	// for (i = 0; i <= size; i++)
	for (i = 0; i != sizepl; i++)
            flags[i] = true; 
        // for (i = 0; i <= size; i++) { 
	for (i = 0; i != sizepl; i++) { 
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
#if TIMER
	ticks += frameCount;
	frameCount = 0;
#endif
    }
    printf("\n%d primes", count);
#if TIMER
    printf("\n%d %d/60 seconds", ticks/60, ticks % 60, count);
#endif
}
