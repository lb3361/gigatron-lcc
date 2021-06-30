#include <stddef.h>
#include <stdlib.h>
#include <gigatron/libc.h>

typedef struct aa_s {
	struct aa_s *right, *left;
	int level;
} aa_t;

typedef struct lst_s {
	struct lst_s *next, *prev;
} lst_t;

typedef struct blk_s {
	size_t size;
	lst_t  lst;
	aa_t   aa;
} blk_t;

#define LST2BLK(p) ((blk_t*)(((char*)(&(p)->next))-offsetof(blk_t,lst.next)))
#define AA2BLK(p)  ((blk_t*)(((char*)(&(p)->right))-offsetof(blk_t,aa.right)))
	

/* --------------------------------------- */
/* AA tree of address ordered blocks.      */
/* --------------------------------------- */

/* AA trees are far from the fastest kind of self-balancing tree.
   However code size matters a lot in the Gigatron. */

#define AA_CMPEQ(x,y) (x == y)
#define AA_CMPLT(x,y) (x < y)

static aa_t* aa_find(aa_t *head, aa_t *elm, aa_t **pprev, aa_t **pnext)
{
	/* If the element is not found, pprev and pnext are pointers
	   to the nodes that would be immediately below or above elm.
	   Otherwise the function returns the element, but its subtree
	   must still be examined for the prev and next nodes. */
	register aa_t *p = head;
	if (pprev) { *pprev = 0; }
	if (pnext) { *pnext = 0; }
	while(p) {
		if (AA_CMPEQ(p, elm)) {
			return p;
		} else if (AA_CMPLT(p, elm)) {
			if (pprev) { *pprev = p; }
			p = p->right;
		} else {
			if (pnext) { *pnext = p; }
			p = p->left;
		}
	}
	return 0;
}

static aa_t* _aa_skew(aa_t *p)
{
	if (p && p->left &&
	    p->left->level == p->level) {
		register aa_t *q = p->left;
		p->left = q->right;
		q->right = p;
		return q;
	}
	return p;
}
static aa_t* _aa_split(aa_t *p)
{
	if (p && p->right && p->right->right &&
	    p->right->right->level == p->level) {
		register aa_t *q = p->right;
		p->right = q->left;
		q->left = p;
		q->level += 1;
		return q;
	}
	return p;
}
static aa_t* aa_insert(register aa_t *head, register aa_t *elm)
{
	register aa_t **pp;
	if (!head) {
		elm->left = elm->right = 0;
		elm->level = 1;
		return elm;
	} else if (AA_CMPEQ(head, elm))
		return head;
	else if (AA_CMPLT(head, elm))
		pp = &head->right;
	else 
		pp = &head->left;
	*pp = aa_insert(*pp, elm);
	return _aa_split(_aa_skew(head));
}
static aa_t* _aa_delete_rebal(register aa_t *head)
{
	if ((head->left && head->left->level < head->level - 1) ||
	    (head->right && head->right->level < head->level - 1) ) {
		head->level -= 1;
		if (head->right && head->right->level > head->level)
			head->right->level = head->level;
		head = _aa_split(head);
		if (head->right = _aa_split(head->right))
			head->right->right = _aa_split(head->right->right);
		head = _aa_skew(head);
		head->right = _aa_skew(head->right);
	}
	return head;
}
static aa_t* aa_delete(register aa_t *head, register aa_t *elm)
{
	static aa_t *last, *deleted;
	if (head) {
		/* search */
		register aa_t **pp;
		last = head;
		if (AA_CMPLT(elm, head)) {
			pp = &head->left;
		} else {
			deleted = head;
			pp = &head->right;
		}
		*pp = aa_delete(*pp, elm);
		/* remove */
		if (head == last) {
			if (AA_CMPEQ(deleted, elm))
				head = head->right;
			else
				deleted = 0;
		} else if (head == deleted) {
			last->level = head->level;
			last->left = head->left;
			last->right = head->right;
			head = last;
		}
		/* rebalance */
		return _aa_delete_rebal(head);
	}
	return head;
}


/* glink collects all malloc areas into this singly linked list. */
static struct brk_s {
	unsigned int size;
	struct brk_s *next;
} *__glink_magic_heap = (void*)0xBEEF;



//main(){}
