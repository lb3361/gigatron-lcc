#include <string.h>

/* Initializer for bss segments */

/* This is magically populated by glink */
struct bsschain {
  unsigned size;
  struct bsschain *next;
} *__glink_magic_bss = (void*)0xBEEF;


static void _init_bss(void)
{
  struct bsschain *r = __glink_magic_bss;
  if (r != (void*)0xBEEF)
    {
      while (r)
        {
          struct bsschain *n = r->next;
          memset(r, 0, r->size);
          r = n;
        }
    }
}

/* This is magically chained by glink */
static struct initchain {
  void(*f)(void);
  struct initchain *next;
} __glink_magic_init = { _init_bss, 0 };


/* Local Variables: */
/* mode: c */
/* c-basic-offset: 2 */
/* indent-tabs-mode: () */
/* End: */
