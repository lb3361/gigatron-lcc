#ifndef __GIGATRON_CONSOLE
#define __GIGATRON_CONSOLE


/* default gigatron colors */
#define CONSOLE_DEFAULT_FGBG 0x3f20

/* for getkey/waitkey */
#define KEY_LEFT     0x80
#define KEY_UP       0x81
#define KEY_RIGHT    0x82
#define KEY_DOWN     0x83
#define KEY_A        0x7f
#define KEY_B        0xbf
#define KEY_START    0xef
#define KEY_SELECT   0xdf

/* -------- misc ----------- */

extern void console_init(void);

/* -------- output ----------- */

extern void console_print(const char *s, int len);
extern void console_clear_screen(void);
extern void console_clear_line(int y);
extern void console_scroll(int y1, int y2, int n);
extern void console_printxy(int x, int y, const char *s, int len);

/* -------- input ----------- */

extern int  console_readline(char *buffer, int n);
extern int  console_waitkey();
extern int  console_getkey();

/* -------- implementation ----------- */

extern const struct console_info_s {
	int nlines;		     /* number of lines   */
	int ncolumns;                /* number of columns */
} console_info;

extern struct console_state_s {
	int fgbg;                    /* foreground and background colors */
	int cx, cy;                  /* cursor coordinates */
	int topm, botm;              /* top and bottom margin not touched by scrolling */
	int reserved;                /* tbd */
	void (*controlf)(int);       /* when not zero, called for unknown chars */
	void (*capturef)(int);       /* when not zero, called for all chars */
} console_state;

extern void   _console_setup(void);
extern char  *_console_addr(int x, int y);
extern int    _console_printchars(int fgbg, char *addr, const char *s, int len);

#endif
