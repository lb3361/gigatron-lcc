#include <stdlib.h>
#include <gigatron/libc.h>

typedef struct malloc_header_s {
	unsigned int size;
	struct malloc_header_s *next, *prev;
} malloc_header_t;


/* glink collects all malloc areas into this singly linked list. */
static malloc_header_t *__glink_magic_heap = (void*)0xBEEF;

/* head of the doubly linked list of free regions */
static struct malloc_header_s head = {0,0,0};

/* convert singly linked list into doubly linked list */
static void malloc_init(void)
{
	malloc_header_t *p = __glink_magic_heap;
	__glink_magic_heap = 0;
	while (p && p != (void*)0xBEEF) {
		malloc_header_t *q = p->next;
		p->prev = head.prev;
		p->next = &head;
		p->prev->next = p;
		p->next->prev = p;
		p = q;
	}
}

DECLARE_INIT_FUNCTION(malloc_init);
