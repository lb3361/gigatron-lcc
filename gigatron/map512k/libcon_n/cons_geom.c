#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/libc.h>
#include <gigatron/sys.h>

/* Providing a new version of this file is all
   that is needed to change the screen geometry. */

const struct console_info_s console_info = { 15, 52,
					     {  0,   16,  32,  48,  64,
						80,  96,  112, 128, 144,
						160, 176, 192, 208, 224  } };


