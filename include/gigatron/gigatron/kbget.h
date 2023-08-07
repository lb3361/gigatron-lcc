#ifndef __GIGATRON_KBGET
#define __GIGATRON_KBGET

/* Input on the Gigatron is tricky because the famicom controller and
   the pluggy keyboard share a same interface and can emit similar
   codes for different events. For instance, code 0x3f can represent
   both the character '?' on a keyboard and buttonB on a TypeC Famicom
   controller. The following low level functions provide increasingly
   sophisticated ways to deal with these problems. */



/* Function kbgeta() is intended for keyboard centric applications.
   It reports all values read from 'serialRaw' that are different from
   both 0xff and the last reported value. Otherwise it returns -1 to
   indicate that no new key is pressed. */
extern int kbgeta(void);

/* Function kbgetb() can work in one of two modes:
   - Keyboard mode works like function kbgeta() but switches to button
     mode whenever the observed code can be understood as a button press.
   - Button mode returns independent button codes (0xff ^ buttonBit)
     for each of the depressed buttons shown in 'buttonState',
     clearing the 'buttonState' bits to mark the button press as
     processed, except for the Start button in order to keep the
     ability to reset the Gigatron with a long press on Start.
   The function reverts to keyboard mode whenever all keys and buttons
   are released. The serialRaw codes returned by a type C controller
   initially cause a switch to button mode. However this behavior
   stops as soon as one observes a code that a Type C controller could
   not emit. This means that typing a question mark (code 0x3f) on a
   keyboard can initially be returned as buttonB, but that this will
   stop as soon as one presses another key. */
extern int kbgetb(void);

/* Function kbgetc() works like kbgetb() but adds autorepeat. */
extern int kbgetc(void);

/* Function pointer kbget() determines which of the following low
   level functions is called by the conio routines. All these
   functions either return an input code or -1 if no key or
   button is currently pressed. */
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

