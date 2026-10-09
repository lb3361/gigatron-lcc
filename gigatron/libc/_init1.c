#include <string.h>

/* Initializer for bss segments */

/* This is magically populated by glink */
struct bsschain {
  unsigned size;
  struct bsschain *next;
} *__glink_magic_bss = (void*)0xBEEF;


void _init_bss(void)
{
  struct bsschain *r;
  struct bsschain * const beef = (void*)0xBEEF;
  r = __glink_magic_bss;
  __glink_magic_bss = 0;
  while (r  && r != beef)
    {
      struct bsschain *n = r->next;
      memset(r, 0, r->size);
      r = n;
    }
}

/* Local Variables: */
/* mode: c */
/* c-basic-offset: 2 */
/* indent-tabs-mode: () */
/* End: */
