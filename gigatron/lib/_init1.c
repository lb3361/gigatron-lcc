
#include <string.h>
#include "_malloc.h"

extern char _etext, _edata, _ebss;

#define etext       ((unsigned)(&_etext))
#define edata       ((unsigned)(&_edata))
#define ebss        ((unsigned)(&_ebss))

#define minheap 20

free_header_t _heap = { &_heap, &_heap, 0 };

static void initf2(unsigned s, unsigned e, void(**cbptr)())
{
  s = (s + 1) & (~1u);
  e = e & (~1u);
  if (e - s > minheap) {
    free_header_t *h = (free_header_t*)s;
    h->size = e - s;
    h->next = &_heap;
    h->prev = _heap.prev;
    h->next->prev = h;
    h->prev->next = h;
  }
}

static void initf1(unsigned s, unsigned e, void (**cbptr)())
{
  if (s <= ebss && ebss < e) {
    initf1(s, ebss, cbptr);
    *cbptr = initf2;
    initf2(ebss, e, cbptr);
  } else {
    memset((char*)s, 0, e-s);
  }
}

static void initf0(unsigned s, unsigned e, void (**cbptr)())
{
  if (s <= edata && edata < e) {
    *cbptr = initf1;
    initf1(edata, e, cbptr);
  }
}

void _init1(void)
{
  void (*cbptr)() = initf1;
  extern void _segments(void (**cbptr)());
  _segments(&cbptr);
}  


/* Local Variables: */
/* mode: c */
/* c-basic-offset: 2 */
/* indent-tabs-mode: () */
/* End: */
