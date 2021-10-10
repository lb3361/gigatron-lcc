#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/libc.h>
#include <gigatron/sys.h>

/* Providing a new version of this file is all
   that is needed to change the screen geometry. */

const struct console_info_s console_info = { 15, 26,
					     {  0,   16,  32,  48,  64,
						80,  96,  112, 128, 144,
						160, 176, 192, 208, 224  } };

void _console_reset(int fgbg)
{
	int i;
	int *table = (int*)videoTable;
	unsigned int page = (unsigned int)screenMemory >> 8;
	for (i=0; i!=120; i++, table++, page++)
		*table = page;
	if (fgbg >= 0)
		_console_clear(screenMemory[0], fgbg, 120);
}

