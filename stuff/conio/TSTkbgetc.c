#include <stdlib.h>
#include <conio.h>
#include <ctype.h>
#include <stdio.h>
#include <gigatron/sys.h>

KBGET_AUTOREPEAT;

PRINTF_SIMPLE;

const char *kbname(int k)
{
	static char buf[8];
	switch(k) {
	case 0x7f: return "buttonA";
	case 0xbf: return "buttonB";
	case 0xdf: return "select";
	case 0xef: return "start";
	case 0xf7: return "up";
	case 0xfb: return "down";
	case 0xfd: return "left";
	case 0xfe: return "right";
	default:
		if (isprint(k))
			sprintf(buf, "'%c'", k);
		else if (k < 32)
			sprintf(buf, "CTRL-%c", k+64);
		else
			return "";
		break;
	}
	return buf;
}



int main()
{
	int k;
	for(;;) {
		if ((k = kbgetc()) >= 0)
			cprintf("sr=%02x k=%02x %s\n", serialRaw, k, kbname(k));
	}
}
