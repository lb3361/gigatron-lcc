#ifndef __GIGATRON_CONIO
#define __GIGATRON_CONIO

#if !defined(_VA_LIST) && !defined(_VA_LIST_DEFINED)
#define _VA_LIST
#define _VA_LIST_DEFINED
typedef char *__va_list;
#endif

/* This file provides a semi-standard conio interface to the gigatron
   console. The output routines are thin wrappers to the
   gigatron/console.h ones. The new input routines replace the
   original functions provided by gigatron/console.h ones. */





/* ---- Conio output functions ---- */

/* The following functions are thin wrappers to the corresponding
   routines in gigatron/console.h. By default they only process
   the essential control characters BS, CR, and LF, but this can
   be expanded by redefining _console_ctrl whose prototype appears
   in gigatron/console.h */

/* Writes one character to the console. Return c. */
extern int putch(int c);

/* Writes one character string to the console. */
extern void cputs(const char *s);

/* Cursor position functions.
   Unlike the console_state variables cx and cy, these function
   address the top left screen corner as (1,1). */
int wherex(void);
int wherey(void);
void gotoxy(int x, int y);

/* Color functions.
   Either use one of the macros or use six bit gigatron colors. */
void textcolor(int color);
void textbackground(int color);

#define BLACK		(0x00)
#define BLUE		(0x20)
#define GREEN		(0x08)
#define CYAN		(0x28)
#define RED		(0x02)
#define MAGENTA		(0x22)
#define BROWN		(0x16)
#define LIGHTGRAY	(0x2a)
#define DARKGRAY	(0x15)
#define LIGHTBLUE	(0x3a)
#define LIGHTGREEN	(0x1d)
#define LIGHTCYAN	(0x3d)
#define LIGHTRED	(0x17)
#define LIGHTMAGENTA	(0x37)
#define YELLOW		(0x0f)
#define WHITE		(0x3f)

/* Clear screen and reset cursor */
void clrscr(void);

/* Clear from the cursor to the end of line */
void clreol(void);

/* Print at specific cursor position without moving the cursor. */
void cputsxy(int x, int y, const char *s);




/* ---- Formatted output functions ---- */

/* The formatted output functions are similar to the stdio printf
   functions but they bypass stdio and hit directly the console. The
   cprintf function still import the relatively heavy printf machinery
   but not the stdio machinery.  The midcprintf and mincprintf functions
   are considerably smaller but offer limited capabilities. */

#ifndef _CPRINTF_DEFINED
#define _CPRINTF_DEFINED

/* Print formatted text at the cursor position */
#if !defined(cprintf)
extern int cprintf(const char *fmt, ...);
#endif

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


/* ---- Conio input functions ---- */

/* Returns non zero when a following getch() will return immediately. */
extern int kbhit(void);

/* Returns an input code, waiting without screen feedback as necessary. */
extern int getch(void);

/* Puts a character back into the getch buffer.
   The next getch() will immediately return c.
   This function can only be called once before the next read.
   Returns c or EOF */
extern int ungetch(int c);

/* These functions work like getch() but provide feedback
   on the console by displaying a flashing square at the
   console cursor position and by printing the received
   character on the console.
     See also console_waitkey() defined in gigatron/console.h
   which displays the flashing cursor but does not echo
   the received character. */
extern int getche(void);

/* Gets a character string from the console and stores it in the
   character array pointed to by buffer. The array's first element,
   buffer[0], must contain the maximum length, in characters, of the
   string to be read. The array's second element, buffer[1], is where
   _cgets stores the string's actual length cgets reads characters
   until it reads a line feed character. Returns a pointer to
   buffer[2] which is where the characters are stored.
     See also console_readline() defined in gigatron/console.h which
   takes different arguments and is used to implement cgets(). */
extern char *cgets(char *buffer);



/* ---- Conio alternate names ---- */

#define _putch   putch
#define _cputs   cputs
#define _cprintf cprintf
#define _kbhit   kbhit
#define _getch   getch
#define _getche  getche
#define _ungetch ungetch
#define _cgets   cgets


#endif
