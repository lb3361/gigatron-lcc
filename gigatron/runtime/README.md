
# Runtime for Gigatron LCC code

These files provide all the routines that are needed to implement
things that are not provided by VCPU or that are simply eating too
much code space.


 * `rt_save.s`: save/restore callee-saved registers
 * `rt_copy.s`: various functions to copy longs, floats, or structs.
 * `rt_mul.s`, `rt_div.s` : multiplication and division for ints (16 bits)
 * `rt_shl.s`, `rt_shr.s` : left and right shifts for ints (16 bits)
 * `rt_ladd.s`, `rt_lmul.s`, `rt_ldiv.s`: arithmetic on longs (32 bits)
 * `rt_lbitops.s`: bitwise operations on longs (32 bits)
 * `rt_lcmp.s` : comparison on longs (32 bits)
 * `rt_lshl.s`, `rt_lshr.s`: left and right shifts on longs (32 bits)
 * `rt_fp.s` : floating point routines (40 bits)

## API

Symbols named `_@_xxxx` are public API. Comments are scarse.
Their function is best understood by looking how they are called
by VCPU pseudo-instuctions defined inside `glink.py`.

As explained in the main [`README.md`](../../README.md) file, these functions
operate entirely using the `[0x81-0x8f]` block of zero page memory and 
they only use the normal VCPU stack.

The only runtime function that is not defined here is `_@_raise` which
is used to raise an exception when dividing by zero or computing a
floating point value that overflows. This function, defined in the
libc file [`raise.s`](../libc/raise.s), takes then signal code in vACL
and the fpe exception code in vACH.  These codes are defined in the
include file [`signal.h`](../../include/gigatron/signal.h).

Symbols named `__@xxxx` are private to the runtime.



## Status

This is complete and passes the test suite.



Improvement opportunities:

 * The long division code (`rt_ldiv.s`) could be refactored. 
   It was modeled after the 16 bits division which avoids
   the vCPU comparison problems. But it inherits its
   complexity without its benefits.

 * One should add fast code for supporting function `fmod`.

 * One should investigate SYS calls to speedup these operations. 
   Sixteen bits multiplication and division are to be provided by at67's new rom.
   
 * The structure copy code (`rt_copy.s`) could benefit from the same level
   of optimization than [`memcpy`](../libc/memcpy.s).  This is hard
   because these functions must have low overhead for small sizes.

