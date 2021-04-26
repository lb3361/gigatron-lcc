
#ifndef _MALLOC_H
#define _MALLOC_H

typedef struct s_free_header free_header_t;

struct s_free_header {
  free_header_t *next;
  free_header_t *prev;
  unsigned int size;
};

extern free_header_t _heap;


#endif

/* Local Variables: */
/* mode: c */
/* c-basic-offset: 2 */
/* indent-tabs-mode: () */
/* End: */
