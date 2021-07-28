#include <stddef.h>
#include <stdlib.h>
#include <gigatron/libc.h>


/* ============ definitions ============ */

/* Block head for both free and used blocks */
typedef struct head_s {
	int size;                      /* low bit set for used blocks */
	struct head_s *bnext, *bprev;  /* links all blocks, both used and free */
	struct head_s *fnext, *fprev;  /* only for free blocks */
} head_t;


/* The list head */
static head_t head;

/* Fake freelist entries */
#define f00 (&head)
#define f48 ((head_t*)&fake[0])
#define f96 ((head_t*)&fake[2])

/* Head initialization */
static head_t *fake[] = { 0, 0, 0, f96, f00, f00, f48 };
static head_t head = { 0, &head, &head, f48, f96 };

#define GET_SHORTCUT_HEAD(h, sz) \
	do{h=f96;if((sz-96)<=0){h=f48;if((sz-48)<=0){h=f00;}}}while(0)

/* ============ utilities ============ */

static void  __unfree_block(register head_t *b)
{
	register int size = b->size;
	b->fnext->fprev = b->fprev;
	b->fprev->fnext = b->fnext;
}

static void __refree_block(register head_t *b)
{
	register int size = b->size;
	register head_t *pa, *pb;
	GET_SHORTCUT_HEAD(pb, size);
	pa = pb->fnext;
	b->fprev = pb;
	pb->fnext = b;
	b->fnext = pa;
	pa->fprev = b;
}

static void __unlist_block(register head_t *b)
{
	b->bnext->bprev = b->bprev;
	b->bprev->bnext = b->bnext;
}

static void __relist_block(head_t *b, head_t *pa)
{
	head_t *pb = pa->bprev;
	b->bprev = pb;
	b->bnext = pa;
	pb->bnext = b;
	pa->bprev = b;
}

static void merge_free_blocks(register head_t *b1, register head_t *b2)
{
	register int sz1 = b1->size;
	register int sz2 = b2->size;
	if (((sz1 | sz2) & 1) == 0 && (char*)b1 + sz1 == (char*)b2 ) {
		__unfree_block(b2);
		__unlist_block(b2);
		__unfree_block(b1);
		__unlist_block(b1);
		b1->size = sz1 + sz2;
		__relist_block(b1, b2->bnext);
		__refree_block(b1);
	}
}

static head_t *find_block(register int size)
{
	register int d;
	register head_t *b;
	GET_SHORTCUT_HEAD(b, size);
	for(;;) {
		b = b->fnext;
		if (b == &head)
			return 0;
		if ((d = b->size - size) >= 0)
			break;
	}
	__unfree_block(b);
	if (d > 0) {
		register head_t *nb = (head_t*)((char*)b + size);
		__unlist_block(b);
		b->size = size;
		nb->size = d;
		__relist_block(nb, b->bnext);
		__relist_block(b, nb);
		__refree_block(nb);
	}
	__unfree_block(b);
	b->size |= 1;
	return b;
}

int __chk_block_header(register head_t *b)
{
	if ((b->size & 1) == 1
	    && b->bnext->bprev == b
	    && b->bprev->bnext == b)
		return (b->size | 1) ^ 1;
	return 0;
}

static void check_block_header(register head_t *b)
{
	if (! __chk_block_header(b))
		_exitm(10, "Malloc heap corrupted");
}

/* ============ public functions ============ */

void free(register void *ptr)
{
	if (ptr) {
		register head_t *b = (head_t*)((char*)ptr - 6);
		check_block_header(b);
		b->size = (b->size | 1) ^ 1;
		__refree_block(b);
		merge_free_blocks(b, b->bnext);
		merge_free_blocks(b->bprev, b);
	}
}

void *malloc(register size_t sz)
{
	register head_t *b;
	if ((sz = (sz + (6 + 7)) & 0xfff8) < 0x8000u)
		if (b = find_block(sz))
			return (char*)b + 6;
	return 0;
}



/* ============ initialization ============ */

/* glink collects all malloc areas into this singly linked list. */
head_t *__glink_magic_heap = (void*)0xBEEF;

static void malloc_init(void)
{
	register head_t *p = __glink_magic_heap;
	__glink_magic_heap = 0;
	while(p) {
		register head_t *n = p->bnext;
		__relist_block(p, head.bnext);
		__refree_block(p);
		p = n;
	}
}

DECLARE_INIT_FUNCTION(malloc_init);


/* ============ debug ============ */

#if DEBUG

void print_block(head_t *b)
{
	printf("  block@%04x (%d) %c %04x:%04x %04x:%04x\n",
	       b, b->size & ~1, (b->size & 1) ? 'U' : 'F',
	       b->bnext, b->bprev, b->fnext, b->fprev );
}

void malloc_map(void)
{
	int i;
	head_t *q = &head;
	head_t *p = head.bnext;
	printf("Blocks:\t");
	i = 0;
	while (p != &head) {
		if (++i % 8 == 0)
			printf("\n\t");
		printf("%04x(%d,%c) ", p, p->size&~1, (p->size&1)?'U':'F');
		if (p->bprev != q)
			printf("{bad bprev %04x} ", p->bprev);
		q = p;
		p = p->bnext;
	}
	printf("\nFree:\t[F00] ");
	q = &head;
	p = head.fnext;
	i = 0;
	while(p != &head) {
		if (++i % 8 == 0)
			printf("\n\t");
		if (p == f00)
			{printf("[F00!!] "); i=0;}
		else if (p == f48)
			{printf("\n\t[F48] "); i=0;}
		else if (p == f96)
			{printf("\n\t[F96] "); i=0;}
		else 
			printf("%04x(%d) ", p, p->size);
		if (p->fprev != q)
			printf("{bad fprev %04x} ", p->fprev);
		q = p;
		p = p->fnext;
	}
	printf("\n");
}


#endif
