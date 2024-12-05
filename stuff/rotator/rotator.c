
#include <stdlib.h>
#include <conio.h>
#include <gigatron/pragma.h>
#include <gigatron/sys.h>

#if _GLCC_VER < 204009
# error "Need GLCC >= 2.4.9"
#endif

extern unsigned int table[];

char * const __near center = (char *)(0x800 + (60 << 8) + 80);

static void rotate()
{
	for(;;) {
		register char *dst;
		register char **p = (char**)table;
		*center = entropy[0] & 0x3f;
		while (dst = *p) {
			p++;
			*dst = **p;
			p++;
		}
		while (videoY != 160) {
		}
	}
}


int main()
{
	SYS_SetMode(3);
	clrscr();
	rotate();
	return 0;
}



