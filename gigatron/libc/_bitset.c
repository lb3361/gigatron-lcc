#include <stdlib.h>
#include <gigatron/libc.h>

static unsigned char _mask[8] = { 1,2,4,8,16,32,64,128 };

void _bitset_clear(char *set, size_t sz)
{
	for(; sz; set++, sz--)
		*set = 0;
}

void _bitset_compl(char *set, size_t sz)
{
	for(; sz; set++, sz--)
		*set ^= 0xff;
}

void (_bitset_set)(register char *set, register unsigned int i)
{
	set[i>>3] |= _mask[i&7];
}

void (_bitset_clr)(register char *set, register unsigned int i)
{
	set[i>>3] &= _mask[i&7] ^ 0xff;
}

int (_bitset_test)(register char *set, register unsigned int i)
{
	return set[i>>3] & _mask[i&7];
}
