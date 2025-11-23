#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/sys.h>


/* This file contains the functions that need to change when one
   changes the screen geometry by playing with the video table. */

const struct console_info_s console_info = { 10, 26,
					     {  4,   28,  52,  76,  100,
						124, 148, 172, 196, 220  } };

