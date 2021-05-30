#ifndef __GIGATRON_CONSOLE
#define __GIGATRON_CONSOLE


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

extern int  console_get_fgbg(void);
extern int  console_get_x(void);
extern int  console_get_y(void);
extern void console_set_fgbg(int fgbg);
extern int  console_set_xy(int x, int y);
extern void console_home(void);
extern void console_clear_line(int y)
extern void console_scroll(int y1, int y2, int s);
extern void console_printxy(int x, int y, const char *s, int len);
extern void console_print(const char *s, int len);
extern int  console_waitkey();
extern int  console_getkey();
	

#endif
