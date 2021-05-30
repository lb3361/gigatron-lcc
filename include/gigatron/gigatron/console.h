#ifndef __GIGATRON_CONSOLE
#define __GIGATRON_CONSOLE


/* for console_init */
#define CONSOLE_MODE_DEFAULT  0
#define CONSOLE_MODE_26x15    1
#define CONSOLE_MODE_26x11    2

/* default gigatron colors */
#define CONSOLE_COLOR_DEFAULT 0x3f20

/* for getkey/waitkey */
#define KEY_LEFT     0x80
#define KEY_UP       0x81
#define KEY_RIGHT    0x82
#define KEY_DOWN     0x83
#define KEY_A        0x7f
#define KEY_B        0xbf
#define KEY_START    0xef
#define KEY_SELECT   0xdf


void console_init(int mode, int fgbg);

int console_get_fgbg(void);
int console_get_x(void);
int console_get_y(void);

void console_set_fgbg(int fgbg);
int  console_set_xy(int x, int y);

void console_home(void);
void console_clear_line(int y)
void console_scroll(int y1, int y2, int s);

void console_printxy(int x, int y, char c);

void console_print(const char *);

int  console_waitkey();
int  console_getkey();
	

#endif
