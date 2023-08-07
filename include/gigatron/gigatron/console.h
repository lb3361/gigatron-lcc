#ifndef __GIGATRON_CONSOLE
#define __GIGATRON_CONSOLE

#if !defined(_VA_LIST) && !defined(_VA_LIST_DEFINED)
#define _VA_LIST
#define _VA_LIST_DEFINED
typedef char *__va_list;
#endif

#ifndef CONSOLE_MAX_LINES
# define CONSOLE_MAX_LINES 15
#endif



/* ---- Console state ---- */

/* Console geometry. */
extern const struct console_info_s {
	int nlines;		                  /* number of lines   */
	int ncolumns;                             /* number of columns */
	unsigned char offset[CONSOLE_MAX_LINES];  /* line offsets      */
} console_info;

/* Console state: colors, cursor, wrapping and scrolling modes.
   These fields can be changed as needed between calls to console functions. */
extern __near struct console_state_s {
	int  fgbg;		/* fg and bg colors   */
	char cy, cx;		/* cursor coordinates */
	char wrapy, wrapx;	/* wrap/scroll enable */
} console_state;

#define console_state_set_cycx(cycx) \
	*(unsigned*)&console_state.cy = (cycx)
#define console_state_set_wrap(wrap) \
	*(unsigned*)&console_state.wrapy = (wrap)



/* ---- Console output ---- */

#define CONSOLE_DEFAULT_FGBG 0x3f20

/* Print up to len characters of the zero terminated string s.
   Understand essential control characters "\b\n\r". More control
   characters can be supported by forcing _console_ctrl to be included
   (as with stdio output) in the build or by defining a customized
   one.  Return the number of characters processed. */
extern int console_print(const char *s, int len);

/* Reset the video tables and clear the screen. */
extern void console_clear_screen(void);


/* ---- Formatted output functions ---- */

/* The formatted output functions are similar to the stdio printf
   functions but they bypass stdio and hit directly the console. The
   cprintf function still import the relatively heavy printf machinery
   but not the stdio machinery.  The midcprintf and mincprintf functions
   are considerably smaller but offer limited capabilities. */

#ifndef _CPRINTF_DEFINED
#define _CPRINTF_DEFINED

/* Print formatted text at the cursor position */
extern int cprintf(const char *fmt, ...);

/* Print formatted text like cprintf except that it is called
   with a va_list instead of a variable number of arguments. */
extern int vcprintf(const char *fmt, __va_list ap);

/* Alternate cprintf functions with less capabilities.
   mincprintf only understands %d and %s without qualifications.
   midcprintf also understands %u, %x, and numeric field sizes.
   None of these functions handles longs or floating point numbers.
   These are not standard conio functions. */
#if defined(cprintf) || defined(printf)
extern int
#else
extern void
#endif
mincprintf(const char *fmt, ...),
midcprintf(const char *fmt, ...);

#endif



/* ---- Low level input routine ---- */

/* Input on the Gigatron is tricky because the famicom controller and
   the pluggy keyboard share a same interface and can emit similar
   codes for different events. For instance, code 0x3f can represent
   both the character '?' on a keyboard and buttonB on a TypeC Famicom
   controller. The following low level functions provide increasingly
   sophisticated ways to deal with these problems. */

#ifndef _KBGET_DEFINED
#define _KBGET_DEFINED 1

/* Function kbgeta() is intended for keyboard centric applications.
   It returns the code as it appears in the Gigatron variable
   serialRaw without further interpretation. */
extern int kbgeta(void);

/* Function kbgetb() heuristically distinguishes keyboard events
   reported in serialRaw from combined button presses reported in
   buttonState. Simultaneous button presses are reported as separate
   events and cleared in buttonState. This function initially reports
   ambiguous codes as button presses but modifies itself when it
   observes ascii codes that can only be produced by a keyboard. */
extern int kbgetb(void);

/* Function kbgetc() works like kbgetb() with autorepeat. */
extern int kbgetc(void);

/* Function pointer kbget() determines which of the following low
   level functions is called by the conio routines. All these
   functions either return an input code or -1 if no key or button is
   currently pressed. */
extern int (* const kbget)(void);  /* Default to kbgeta. */

/* Macros to initialize the global function pointer 'kbget'
   and override the default definition provided by libc.
   Examples:
     #include <conio.h>
     KBGET_AUTOREPEAT;
     int main() { ...
*/
#define KBGET_SIMPLE 		int (*const kbget)(void) = kbgeta
#define KBGET_AUTOBTN		int (*const kbget)(void) = kbgetb
#define KBGET_AUTOREPEAT	int (*const kbget)(void) = kbgetc

#endif



/* ---- Console input routines ---- */


/* Returns an input code or -1 if no key is pressed.
   This function merely calls (*kbget)(void). */
extern int console_getkey(void);

/* Wait for a key press with a flashing cursor. */
extern int console_waitkey(void);

/* Input a line with rudimentary editing.
   The resulting characters, including the final newline and a zero
   terminator, are stored into the specified buffer and are guaranteed
   not to exceed the specified size. This function returns the number
   of characters read. */
extern int console_readline(char *buffer, int bufsiz);


/* -------- internal ----------- */

/* Handle additional control characters in _console_print().
   Override this function to implement more control characters.
   The default version, included when stdio is active, understands
   characters "\t" for tabulation (4 chars) "\f" for clearing the
   screen, "\v" for clearing to the end of the line, and "\a" for an
   audible bell. Return the number of characters consumed. */
extern int _console_ctrl(const char *s, int len);

/* Reset videotable and optionally clear screen if fgbg >= 0 */
extern void _console_reset(int fgbg);

/* Initialization: called before main */
extern void _console_setup(void);

/* -------- internal ----------- */

/* Draws up to `len` characters from string `s` at the screen position
   given by address `addr`.  This assumes that the horizontal offsets
   in the screen table are all zero. All characters are printed on a
   single line (no newline).  The function returns when any of the
   following conditions is met: (1) `len` characters have been
   printed, (2) the next character would not fit horizontally on the
   screen, or (3), an unprintable character has been met. */
extern int _console_printchars(int fgbg, char *addr, const char *s, int len);

/* Clear with color clr from screen address addr to the end of the row.
   Repeats for nl successive lines. */
extern void _console_clear(char *addr, int clr, int nl);

/* Sounds the bell for n frames */
extern void _console_bell(int n);


/* -------- extra ------------ */

/* The following functions are useful for scrolling partial sets of lines.
   These are only linked if used because console_print uses a simpler code. */

/* Clear character row y */
extern void console_clear_line(int y);

/* Rotate rows [y1,y2) by n positions */
extern void console_scroll(int y1, int y2, int n);


#endif
