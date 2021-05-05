
#include <string.h>
#include "_malloc.h"

free_header_t _heap = { &_heap, &_heap, 0 };

static void initcb(unsigned s, unsigned e)
{
  extern char _sbss, _ebss;
  static int state = 0;
  if (state == 0) {
    if (s == (unsigned)&_sbss)
      state = 1;
  }
  if (state == 1) {
    if (s == (unsigned)&_ebss)
      state = 2;
    else if (e > s) {
      if (s & 1) { *(char*)s = 0; s+= 1; }
      if (e & 1) { e -= 1; *(char*)e = 0; }
      while (s != e) { *(int*)s = 0; s += 2; }
    }
  }
  if (state == 2) {
    if (s & 1) { s += 1; }
    if (e & 1) { e -= 1; }
    if (e - s > 24) {
      free_header_t *h = (free_header_t*)s;
      h->size = e - s;
      h->next = &_heap;
      h->prev = _heap.prev;
      h->next->prev = h;
      h->prev->next = h;
    }
  }
}      

void _init1(void)
{
  extern void _segments(void(*)(unsigned,unsigned));
  _segments(initcb);
}  


/* Local Variables: */
/* mode: c */
/* c-basic-offset: 2 */
/* indent-tabs-mode: () */
/* End: */
