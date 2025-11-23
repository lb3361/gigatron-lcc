#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/libc.h>
#include <gigatron/sys.h>

void _console_reset(int fgbg)
{
	int i;
	int *table = (int*)videoTable;
	if (fgbg >= 0)
		_console_clear(screenMemory[0], fgbg, 120);
	for (i=8; i!=128; i++)
		*table++ = i;
}

