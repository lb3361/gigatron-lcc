#include <stdlib.h>
#include <string.h>
#include <gigatron/sys.h>
#include <gigatron/libc.h>
#include <stdarg.h>

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
	clear_lines(112,120);
}

void newline(screenpos_t *pos)
{
	pos->x = 0;
	pos->y += 1;
	if (pos->y >  14) {
		scroll();
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
		if (ch == '\b' && pos->x > 0) {
			pos->x -= 1;
			pos->addr -= 6;
		}
		else if (ch == '\r') {
			pos->x = 0;
			pos->addr = (char*)(videoTable[16*pos->y]<<8);
		}
		else if (ch == '\n') {
			newline(pos);
		}
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

void printf(const char *fmt, ...)
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
}

void print_string(screenpos_t *pos, char *str)
{
	while (str && *str)
		print_char(pos, *str++);
}

char * const sbuffer = (void*)(0xe000u);
char * const ibuffer = (void*)(0xe200u); // in bank 2
char * const dbuffer = (void*)(0xe400u);

void setbank(int bank)
{
	int ctrl = ((ctrlBits_v5 ^ (bank<<6)) & 0xc0 ) ^ ctrlBits_v5;
	SYS_ExpanderControl(ctrl);
}

void test(int doff, int soff, int len, int bank)
{
	int i;
	printf("[%d:%x,] <- [%x,+%d]\n", bank, dbuffer+doff, sbuffer+soff, len);

	for (i=0; i<1024;i++)
		sbuffer[i] = (i&0x3f) | 0x80;
	setbank(bank);
	for (i=0; i<1024;i++)
		dbuffer[i] = (i&0x3f) | 0x40;
	setbank(1);

	if (bank == 1)
		memcpy(dbuffer+doff, sbuffer+soff, len);
	else 
		_memcpyext(bank<<6, dbuffer+doff, sbuffer+soff, len);

	setbank(bank);
	for (i=0; i<1024;i++)
		{
			int expected = (i & 0x3f) | 0x40;
			if (i >= doff && i < doff + len)
				expected = ( (i-doff+soff) & 0x3f ) | 0x80;
			if (dbuffer[i] != expected)
				printf(" at %d:%x: not %x, %x\n", bank, dbuffer+i, expected, dbuffer[i]);
		}
	setbank(1);
	for (i=0; i<1024;i++)
		{
			int expected = (i & 0x3f) | 0x80;
			if (sbuffer[i] != expected)
				printf(" at 1:%x: not %x, %x\n", sbuffer+i, expected, sbuffer[i]);
		}
	//exit(100);
}


int main()
{
	int i;

	clear_screen(&pos);
	if (ctrlBits_v5 == 0) {
		printf("No memory expansion\n");
		return 10;
	}
	for (i=1; i<=3; i++) {
		printf("========= bank %d\n", i);
		test(255,256,257,i);
		test(34,0,12,i);
		test(34,65,12,i);
		test(84,63,255,i);
		test(34,63,256,i);
		test(128,256,257,i);
		test(256,63,757,i);
	}
	return 0;
}
