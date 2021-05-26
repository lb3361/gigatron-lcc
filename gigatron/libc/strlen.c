#include <string.h>

    
    
extern void *_memscan(const void *s, char c0, char c1, size_t n);

size_t strlen(register const char *s)
{
	return (const char*)_memscan(s, 0, 0, 0xffffu) - s;
}
