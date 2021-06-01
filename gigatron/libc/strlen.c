#include <string.h>

    
    
extern void *_memchr2(const void *s, char c0, char c1, size_t n);

size_t strlen(register const char *s)
{
	return (const char*)_memchr2(s, 0, 0, 0xffffu) - s;
}
