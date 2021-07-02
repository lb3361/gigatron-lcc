#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/sys.h>


/* This file contains the functions that need to change when one
   changes the screen geometry by playing with the video table. */

#define NLINES  10
#define BLANKMEM  0x2f
#define CHARSMEM  0x30

const struct console_info_s console_info = { NLINES, 26 };

static unsigned int *mkline(unsigned int *table, int page)
{
	int j;
	table[0] = table[1] = table[10] = table[11] = BLANKMEM;
	for (j=2; j!=10; j++, page++)
		table[j] = page;
	return table+12;
}

static void reset()
{
	int i, j;
	unsigned int *table = (unsigned int*)videoTable;
	unsigned int page = CHARSMEM;
	for (i=0; i!=NLINES; i++) {
		table = mkline(table, page);
		page += 8;
	}
	console_state.cx = console_state.cy = 0;
}

char  *_console_addr(int x, int y)
{
	if (y >= 0 && y < console_info.nlines &&
	    x >= 0 && x < console_info.ncolumns )
		return (char*)(videoTable[4+y*24]<<8) + 6 * x;
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
	clear((char*)(BLANKMEM<<8), 81);
}

void console_clear_line(register int y)
{
	clear(_console_addr(0, y), 8);
}

static int scroll0(int y1, int y2, int n, int s)
{
	register int d = y2 - y1;
	if (n >= y1 && n < y2) {
		n += s;
		while (n - y1 < 0)
			n += d;
		while (n - y2 >= 0)
			n -= d;
	}
	return videoTable[4 + n * 24];
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
	unsigned int *table = (unsigned int*)videoTable;
	for (i = 0; i != console_info.nlines; i++) {
		mkline(table, pages[i]);
		table += 12;
	}
}

void console_scroll(register int y1, register int y2,  register int s)
{
	static char pages[12];
	if (y1 < 0)
		y1 = 0;
	if (y2 - 12 > 0)
		y2 = 12;
	scroll1(pages, y1, y2, s);
	scroll2(pages);
}

