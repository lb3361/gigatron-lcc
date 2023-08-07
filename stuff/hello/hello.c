
#include <stdio.h>

#ifdef USE_RAWCONSOLE
# include <gigatron/console.h>
# define printf(x) do {\
		_console_clear((char*)0x800,0x20,120);\
		_console_printchars(0x3f20,(char*)0x800,(x),255);\
	} while(0)
#endif

#ifdef USE_CONSOLE
# include <gigatron/console.h>
# define printf(x) console_print(x,0xffffu)
#endif

#ifdef USE_CPUTS
# include <conio.h>
# define printf(x) cputs(x)
#endif



int main()
{
	printf("Hello world!\n");
	return 0;
}


/***
                           | GLCC-2.2 |          GLCC-2.2-23            |
                           | -rom=v5a | -rom=v5a |  -rom=v6 | -rom=dev7 |
+--------------------------+----------+----------+----------+-----------+
| glcc                     |     5696 |     4068 |     4030 |      3563 |
| --option=CTRL_SIMPLE     |       -  |     3878 |     3840 |      3374 |
| \ --option=PRINTF_SIMPLE |       -  |     2657 |     2622 |      2274 |
+--------------------------+----------+----------+----------+-----------+
| glcc -Dprintf=cprintf    |     4382 |     3763 |     3725 |      3257 |
| \ --option=PRINTF_SIMPLE |       -  |     2541 |     2506 |      2159 |
+--------------------------+----------+----------+----------+-----------+
| glcc -Dprintf=midcprintf |       -  |     2533 |     2498 |      2149 |
| glcc -Dprintf=mincprintf |     2246 |     1955 |     1917 |      1622 |
+--------------------------+----------+----------+----------+-----------+
| glcc -DUSE_CPUTS         |       -  |     1452 |     1452 |      1261 |
+--------------------------+----------+----------+----------+-----------+
| glcc -DUSE_CONSOLE       |     1736 |     1448 |     1448 |      1256 |
+--------------------------+----------+---------------------+-----------+
| glcc -DUSE_RAWCONSOLE    |      808 |      808 |      808 |       695 |
| \ --no-runtime-bss       |      641 |      641 |      641 |       539 |
+--------------------------+----------+---------------------+-----------+

 ***/
