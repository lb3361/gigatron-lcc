#ifndef __GIGATRON_CONSOLE
#define __GIGATRON_CONSOLE

#if !defined(_VA_LIST) && !defined(_VA_LIST_DEFINED)
#define _VA_LIST
#define _VA_LIST_DEFINED
typedef char *__va_list;
#endif

/* -------- state ----------- */

extern const struct console_info_s {
	int nlines;		     /* number of lines   */
	int ncolumns;                /* number of columns */
	unsigned char offset[15];    /* offset of each line in the video table */
} console_info;

extern struct console_state_s {
	int fgbg;                    /* foreground and background colors */
	int cx, cy;                  /* cursor coordinates */
	char wrapx, wrapy;           /* whether to line wrap or scroll */
} console_state;

/* -------- output ----------- */

#define CONSOLE_DEFAULT_FGBG 0x3f20

/* Print up to len characters of the zero terminated string s.
   Understands control characters "\a\t\b\n\r\f\v" for
   bell, tab, backspace, newline, cr, clear screen, clear to eol.
   Return the number of characters processed. */
extern int console_print(const char *s, int len);

/* Reset the video tables and clear the screen. */
extern void console_clear_screen(void);

/* Clear to end of line */
extern void console_clear_to_eol(void);


/* -------- input ----------- */

/* Get currently pressed key or -1 */
extern int console_getkey(void);

/* Wait for a key press with a flashing cursor. */
extern int console_waitkey(void);

/* Input a line with rudimentaty editing and return the line length. */
extern int console_readline(char *buffer, int bufsiz);


/* -------- internal ----------- */

/* Handle control characters in _console_print().
   Must return zero if c is not recognized. */
extern int _console_ctrl(int c);

/* Reset videotable and optionally clear screen if fgbg >= 0 */
extern void _console_reset(int fgbg);

/* Initialization: called before main */
extern void _console_setup(void);

/* -------- internal ----------- */

/* Draws up to `len` characters from string `s` at the screen position
   given by address `addr`.  This assumes that the horizontal offsets
   in the string table are all zero. All characters are printed on a
   single line (no newline).  The function returns when any of the
   following conditions is met: (1) `len` characters have been
   printed, (2) the next character would not fit horizontally on the
   screen, or (3), an unprintable character has been met. */
extern int _console_printchars(int fgbg, char *addr, const char *s, int len);

/* Clear with color clr from screen address addr to the end of the row.
   Repeats for nl successive lines. */
extern void _console_clear(char *addr, int clr, int nl);


/* -------- extra ------------ */

/* The following functions are useful for scrolling partial sets of lines.
   These are only linked if used because console_print uses a simpler code. */

/* Clear character row y */
extern void console_clear_line(int y);

/* Rotate rows [y1,y2) by n positions */
extern void console_scroll(int y1, int y2, int n);


#endif
