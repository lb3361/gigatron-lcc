#ifndef __GIGATRON_CONSOLE
#define __GIGATRON_CONSOLE



/* -------- output ----------- */

#define CONSOLE_DEFAULT_FGBG 0x3f20

extern void console_print(const char *s, int len);
extern void console_clear_screen(void);
extern void console_clear_line(int y);
extern void console_scroll(int y1, int y2, int n);
extern void console_printxy(int x, int y, const char *s, int len);

/* -------- input ----------- */

extern void console_readline(char *buffer, int bufsiz);
extern int console_waitkey(void);
extern int console_getkey(void);

/* -------- implementation ----------- */

extern const struct console_info_s {
	int nlines;		     /* number of lines   */
	int ncolumns;                /* number of columns */
} console_info;

extern struct console_state_s {
	int fgbg;                    /* foreground and background colors */
	int cx, cy;                  /* cursor coordinates */
	int reserved;                /* tbd */
	void (*controlf)(int);       /* when not zero, called for unknown chars */
} console_state;

extern void   _console_setup(void);
extern char  *_console_addr(int x, int y);
extern int    _console_printchars(int fgbg, char *addr, const char *s, int len);

#endif
