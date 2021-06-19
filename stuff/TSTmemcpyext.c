

/* Testing code for SYS_CopyMemory, SYS_CopyMemoryExt.

   Compile with  'glcc -map=32k -rom=exp memcpyext.c'
   
   -map=32k is used to allow us to swap banks and check that we wrote what we intended.
   -rom=exp selects implementations of memcpy and _memcpyext that call SYS_CopyMemory
            and SYS_CopyMemoryExt. These can be seen in gigatron-lcc/gigatron/libc.

   Then you can run the resulting gt1 inside gtemuAT67.
   You need of course to load a rom that contains SYS_CopyMemory 
   and SYS_CopyMemoryExt.

*/


#include <stdlib.h>
#include <string.h>
#include <gigatron/sys.h>
#include <gigatron/libc.h>
#include <stdarg.h>


/* -------------------- QUICK PRINTF CODE ---------------- */

#define FGBG 0x3f20

typedef struct {
	char *addr;
	char x;
	char y;
} screenpos_t;

void clear_lines(int l1, int l2)
{
	int i;
	for (i=l1; i<l2; i++) {
		char *row = (char*)(videoTable[i+i]<<8);
		memset(row, FGBG & 0xff, 160);
	}
}

void clear_screen(screenpos_t *pos)
{
	clear_lines(0,120);
	pos->x = pos->y = 0;
	pos->addr = (char*)(videoTable[0]<<8);
}

void scroll(void)
{
	char pages[8];
	int i;
	for (i=0; i<8; i++)
		pages[i] = videoTable[i+i];
	for (i=0; i<112; i++)
		videoTable[i+i] = videoTable[i+i+16];
	for (i=112; i<120; i++)
		videoTable[i+i] = pages[i-112];
}

void newline(screenpos_t *pos)
{
	pos->x = 0;
	pos->y += 1;
	if (pos->y >  14) {
		scroll();
		clear_lines(112,120);
		pos->y = 14;
	}
	pos->addr = (char*)(videoTable[16*pos->y]<<8);
}

void print_char(screenpos_t *pos, int ch)
{
	unsigned int fntp;
	char *addr;
	int i;
	if (ch < 32) {
		if (ch == '\n') 
			newline(pos);
		return;
	} else if (ch < 82) {
		fntp = font32up + 5 * (ch - 32);
	} else if (ch < 132) {
		fntp = font82up + 5 * (ch - 82);
	} else {
		return;
	}
	addr = pos->addr;
	for (i=0; i<5; i++) {
		SYS_VDrawBits(FGBG, SYS_Lup(fntp), addr);
		addr += 1;
		fntp += 1;
	}
	pos->x += 1;
	pos->addr = addr + 1;
	if (pos->x > 24)
		newline(pos);
}

screenpos_t pos;

void print_unsigned(unsigned int n, int radix)
{
	static char digit[] = "0123456789abcdef";
	char buffer[8];
	char *s = buffer;
	do {
		*s++ = digit[n % radix];
		n = n / radix;
	} while (n);
	while (s > buffer)
		print_char(&pos, *--s);
}

void print_int(int n, int radix)
{
	if (n < 0) {
		print_char(&pos, '-');
		n = -n;
	}
	print_unsigned(n, radix);
}

int printf(const char *fmt, ...)
{
	char c;
	va_list ap;
	va_start(ap, fmt);
	while (c = *fmt++) {
		if (c != '%') {
			print_char(&pos, c);
			continue;
		}
		if (c = *fmt++) {
			if (c == 'd')
				print_int(va_arg(ap, int), 10);
			else if (c == 'u')
				print_unsigned(va_arg(ap, unsigned), 10);
			else if (c == 'x')
				print_unsigned(va_arg(ap, unsigned), 16);
			else
				print_char(&pos, c);
		}
	}
	va_end(ap);
	return 0;
}


/* -------------------- THIS IS THE TEST ---------------- */

char * const sbuffer = (void*)(0xe000u);
char * const dbuffer = (void*)(0xe400u);

void setbank(int bank)
{
	int ctrl = ((ctrlBits_v5 ^ (bank<<6)) & 0xc0 ) ^ ctrlBits_v5;
	SYS_ExpanderControl(ctrl);
}

void test(int doff, int soff, int len, int dstbank, int srcbank)
{
	int i;
	printf("[%d:%x,]<-[%d:%x,+%d]\n", dstbank, dbuffer+doff, srcbank, sbuffer+soff, len);

	setbank(srcbank);
	for (i=0; i<1024;i++)
		sbuffer[i] = (i&0x3f) | ((srcbank&3)<<6);
	setbank(dstbank);
	for (i=0; i<1024;i++)
		dbuffer[i] = (i&0x3f) | ((dstbank&3)<<6);

	_memcpyext(((dstbank&3)<<6)|((srcbank&3)<<4),
		   dbuffer+doff, sbuffer+soff, len);

	setbank(dstbank);
	for (i=0; i<1024;i++)
		{
			int expected = (i & 0x3f) | ((dstbank&3)<<6);
			if (i >= doff && i < doff + len)
				expected = ( (i-doff+soff) & 0x3f ) | ((srcbank&3)<<6);
			if (dbuffer[i] != expected)
				printf(" at %d:%x: not %x, %x\n", dstbank, dbuffer+i, expected, dbuffer[i]);
		}
	setbank(srcbank);
	for (i=0; i<1024;i++)
		{
			int expected = (i & 0x3f) | ((srcbank&3)<<6);
			if (sbuffer[i] != expected)
				printf(" at %d:%x: not %x, %x\n", srcbank, sbuffer+i, expected, sbuffer[i]);
		}
	setbank(1);
}


int main()
{
	int i,j;

	clear_screen(&pos);
	if (ctrlBits_v5 == 0) {
		printf("No memory expansion\n");
		return 10;
	}
	for (j=1; j<=3; j++)
		for (i=2; i<=3; i++) {
			printf("========= bank %d to %d\n", j, i);
			test(255,256,257,i,j);
			test(34,0,12,i,j);
			test(34,65,12,i,j);
			test(84,63,255,i,j);
			test(34,63,256,i,j);
			test(128,256,257,i,j);
			test(256,63,757,i,j);
	}
	return 0;
}
