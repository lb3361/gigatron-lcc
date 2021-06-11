#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/sys.h>


/* This file contains the functions that need to change when one
   changes the screen geometry by playing with the video table. */

const struct console_info_s console_info = { 15, 26 };

static void reset()
{
	int i;
	unsigned int *table = videoTable;
	unsigned int page = (unsigned int)screenMemory >> 8;
	for (i=0; i!=120; i++, table++, page++)
		*table = page;
	console_state.cx = console_state.cy = 0;
}

char  *_console_addr(int x, int y)
{
	register unsigned char *table = videoTable;
	if (y >= 0 && y < console_info.nlines &&
	    x >= 0 && x < console_info.ncolumns )
		return (char*)(table[y*16]<<8) + 6 * x;
	return 0;
}

static void clear(register char *addr, register int nl)
{
	register int bg = (unsigned char)console_state.fgbg;
	while (addr && nl) {
		memset(addr, bg, 160);
		addr += 0x100;
		nl -= 1;
	}
}

void console_clear_screen(void)
{
	reset();
	clear(screenMemory, 120);
}

void console_clear_line(register int y)
{
	clear(_console_addr(0, y), 8);
}

static int scroll0(int y1, int y2, int n, int s)
{
	register char *table = videoTable;
	register int d = y2 - y1;
	if (n >= y1 && n < y2) {
		n += s;
		while (n - y1 < 0)
			n += d;
		while (n - y2 >= 0)
			n -= d;
	}
	return table[n * 16];
}

static void scroll1(char *pages, int y1, int y2, int s)
{
	register int i;
	for (i = 0; i != 15; i++) {
		*pages = scroll0(y1, y2, i, s);
		pages++;
	}
}

static void scroll2(char *pages)
{
	register int i, j;
	char *table = videoTable;
	for (i = 0; i != 15; i++) {
		int p = pages[i];
		for(j = 0; j != 8; j++) {
			*table = p + j;
			table += 2;
		}
	}
}

void console_scroll(register int y1, register int y2,  register int s)
{
	static char pages[15];
	if (y1 < 0)
		y1 = 0;
	if (y2 - 15 > 0)
		y2 = 15;
	scroll1(pages, y1, y2, s);
	scroll2(pages);
}

