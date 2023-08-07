#ifndef __GIGATRON_KBGET
#define __GIGATRON_KBGET

/* Input on the Gigatron is tricky because the famicom controller and
   the pluggy keyboard share a same interface and can emit similar
   codes for different events. For instance, code 0x3f can represent
   both the character '?' on a keyboard and buttonB on a TypeC Famicom
   controller. The following low level functions provide increasingly
   sophisticated ways to deal with these problems. */



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
   Example:
     #include <conio.h>
     KBGET_AUTOREPEAT;
     int main() { ...
   Compile with option
     --option=KBGET_AUTOREPEAT
   has the same effect with a lower priority. 
*/
#define KBGET_SIMPLE 		int (*const kbget)(void) = kbgeta
#define KBGET_AUTOBTN		int (*const kbget)(void) = kbgetb
#define KBGET_AUTOREPEAT	int (*const kbget)(void) = kbgetc

#endif

