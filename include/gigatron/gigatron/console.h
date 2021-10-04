#ifndef __GIGATRON_CONSOLE
#define __GIGATRON_CONSOLE



/* -------- output ----------- */

#define CONSOLE_DEFAULT_FGBG 0x3f20

/* Print up to len characters of the zero terminated string s.
   Understands control characters "\t\b\n\r\f". 
   Return the number of printed characters. */
extern int console_print(const char *s, int len);

/* Reset the video tables and clear the screen. */
extern void console_clear_screen(void);

/* Clear character row y */
extern void console_clear_line(int y);

/* Scroll rows [y1,y2) by n position */
extern void console_scroll(int y1, int y2, int n);

/* -------- input ----------- */

/* Get currently pressed key or -1 */
extern int console_getkey(void);

/* Wait for a key press with a flashing cursor. */
extern int console_waitkey(void);

/* Input a line with rudimentaty editing and return the line length. */
extern int console_readline(char *buffer, int bufsiz);

/* -------- implementation ----------- */

extern const struct console_info_s {
	int nlines;		     /* number of lines   */
	int ncolumns;                /* number of columns */
} console_info;

extern struct console_state_s {
	int fgbg;                    /* foreground and background colors */
	int cx, cy;                  /* cursor coordinates */
	void (*controlf)(int);       /* called for unknown chars when not zero */
} console_state;

/* Called before main() to setup the console. */
extern void _console_setup(void);

/* Compute the address of the top-left pixel of char(x,y) */
extern char *_console_addr(int x, int y);

/* Draws up to `len` characters from string `s` at the screen position
   given by address `addr`.  This assumes that the horizontal offsets
   in the string table are all zero. All characters are printed on a
   single line (no newline).  The function returns when any of the
   following conditions is met: (1) `len` characters have been
   printed, (2) the next character would not fit horizontally on the
   screen, or (3), an unprintable character has been met. */
extern int _console_printchars(int fgbg, char *addr, const char *s, int len);

#endif
