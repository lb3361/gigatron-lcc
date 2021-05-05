

/* Initializer for bss segments */

/* This is magically populated by glink */
struct bsschain {
  unsigned size;
  struct bsschain *next;
} *__glink_magic_bss = (void*)0xBEEF;

static void _init_bss(void) {
  struct bsschain *r = __glink_magic_bss;
  while (r && r != (void*)0xBEEF) {
    unsigned s = (unsigned)r;
    unsigned e = s + r->size;
    if (s & 1) { *(char*)s = 0; s+= 1; }
    if (e & 1) { e -= 1; *(char*)e = 0; }
    while (s != e) { *(int*)s = 0; s += 2; }
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
