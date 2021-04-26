
#include <string.h>

#include "_malloc.h"

typedef char *ptr;

typedef struct s_segment_desc segment_desc_t;

typedef struct s_segment_desc {
  unsigned int size;
  ptr addr;
  unsigned int step;
  ptr end;
};

extern segment_desc_t _segments[];

extern char _etext, _edata, _ebss;

free_header_t _heap = { &_heap, &_heap, 0 };

#define nexteven(p) ((ptr)((((unsigned)p)+1u) & ~1u))

#define preveven(p) ((ptr)(((unsigned)p) & ~1u))

static void
add_heap(ptr s, ptr e)
{
  s = nexteven(s);
  e = preveven(e);
  if (e - s > 20) {
    free_header_t *h = (free_header_t*)s;
    h->next = &_heap;
    h->prev = _heap.prev;
    h->next->prev = h;
    h->prev->next = h;
  }
}

static void
clear_bss(ptr s, ptr e)
{
  memset(s, 0, e - s);
}

void _init1()
{
  int state = 0;
  segment_desc_t *p;
  ptr x, y, s, e;
  
  for (p = _segments; p->size; p += 4)
    for (x = p->addr; x < p->end; x += p->step) {
      s = x;
      y = x + p->size;
      
      if (state == 0) {
        if (&_edata >= s && y > &_edata) {
          s = &_edata;
          state = 1;
        }
      }
      if (state == 1) {
        if (&_ebss >= s && y > &_ebss) {
          clear_bss(s, &_ebss);
          state = 2;
          s = &_ebss;
        } else {
          clear_bss(s, y);
        }
      }
      if (state == 3)
        add_heap(s, y);
    }
}


/* Local Variables: */
/* mode: c */
/* c-basic-offset: 2 */
/* indent-tabs-mode: () */
/* End: */
