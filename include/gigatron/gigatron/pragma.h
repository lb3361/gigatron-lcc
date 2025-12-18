#ifndef __GIGATRON_PRAGMA
#define __GIGATRON_PRAGMA

/* This file defines syntax constructions whose semantic is specific
   to the gigatron platform. These constructions include declaration
   attributes and pragmas. Convenient definitions are provided
   to cover common use cases and to ensure forward and backward
   compatibility. */

/* ==== Pragmas ====

   The following pragmas are supported:

   * #pragma glcc option("OPTION")
     Passes argument --option=OPTION to the linker.

   * #pragma glcc lomem("MODNAME","FRAGNAME")
     Causes fragment "FRAGNAME" from module "MODNAME" to be placed in
     the lower half of the Gigatron address space, making it
     accessible regardless of the selected bank.  Usually "FRAGNAME"
     is a source file name, and "MODNAME" is a function name or a
     variable name. However, both "FRAGNAME" and "MODNAME" can be
     patterns similar to the shell filename pattere. For instance,
         #pragma glcc lomem("lomem.c","*")
     causes everything defined in file "lomem.c" to be
     placed in low memory, whereas
         #pragma glcc lomem("*", "SYS_*")
         #pragma glcc lomem("rt_*.s", "_*@*")
     does the same for all functions whose name starts with "SYS_"
     and all functions defined in files matching pattern "rt_*.s"
     and whose name starts with "_" and contain a "@". This matches
     in fact the C runtime functions that glcc uses to implement C.
     There are useful to keep in low memory when bank switching
     is involved.

   * #pragma glcc segment(SADDR, EADDR, "USES")
     Redefines which uses are permitted for a segment of the Gigatron
     address space. Integers SADDR and EADDR define the start address
     (inclusive) and the end address (exclusive) of the segment.
     String "USES" may contain any combination of the following letters:
     - "C" for a segment that can be used for vcpu code,
     - "D" for a segment that can be used for data variables,
     - "H" for a segment that can be used for the malloc heap,
     - "c" for a segment that can be used for code with only when
       explicit placement constraints have been provided.
     - "d" for a segment that can be used for code with only when
       explicit placement constraints have been provided.
     This segment specification overrides any overlapping segment
     definition provided by the map of by a map overlay. The linker
     option --segments can be used to examine the resulting segment list.

   * #pragma initsp(ADDR)
     Defines the initial value of the stack pointer,
     overriding that value specified in the map file.

   * #pragma glcc lib("LIB")
     Causes library LIB to be linked with the program
     by passing argument -lLIB to the linker

   * #pragma glcc onload("FUNCNAME")
     Defines an early initialization function by passing
     argument --onload=FUNCNAME to the linker.

   Pragma arguments must be constants defined at compile time.
   Limited support is offered for simple expressions as long as they
   are legal in both C and Python and produce a constant result.  For
   instance, numbers can be expressed in decimal or in hexadecimal
   (but not in octal because python and C disagree on the proper syntax).


   ==== Declaration attributes ====

   The syntax `__attribute__((LIST))`, where `LIST` is a
   comma-separated list of identifiers optionally followed by a comma
   separated list of argumentds in parentheses. The `__attribute__`
   keyword can appear in the declaration specifier (in which case it
   applies to all the declared symbols) or after each declarator (in
   which case it only applies to one symbol).

   Definition attributes follow the glink constraint specifications.
   They can be used in variable definitions and function definitions.

   * `__attribute__((nohop))`
     Variable cannot cross a page boundary.
   * `__attribute__((org(ADDRESS)))
     Variable must be allocated at the specified address.
     This attribute overrides all other placement constraints.
   * `__attribute__((offset(ADDRESS)))
     Variable must be allocated at page offset ADDRESS&0xff.
   * `__attribute__((place(AMIN,AMAX)))`
     Variable must be allocated between addresses `AMIN` and `AMAX`.

   Three attributes are recognized on extern declarations:

   * `__attribute__((alias(STRING)))`
     Define an external variable that references the linker symbol
     `STRING` instead of a symbol whose name is equal to the variable
     name. When `STRING` starts with prefix "__glink_weak_", this is a
     weak reference.
   * `__attribute__((regalias(STRING)))`
     Define an  external variable that references register `STRING`
     and prevents subsequent functions from allocating this register.
     This only makes sense when the variable is declared `__near`
     and can be used with to create a side channel to share information
     between functions.
   * `__attribute__((org(ADDRESS)))`
     Define an external variable assumed in the current compilation
     unit to be located at absolute address `ADDRESS`.
   * '__attribute__((quickcall))'
     Declares that an external function can be called by passing all its
     arguments by register and without need to spill the caller-saved
     registers. This reduces the cost of the call and occasionally
     makes it possible to treat the calling function as a leaf
     function or a frameless one.

   ==== Attribute macros ====

   The following definitions are provided as convenience
   and also to protect programs against possible changes
   in attribute syntax or semantics: */

/*  `__nohop` --
    Mark a variable or a function that should
    not cross page boundaries.
    Example:
    | char sprite[] __nohop = { 0x40, 0x23, ... }; */

#define __nohop __attribute__((nohop))

/* `__lomem` --
   Mark a variable or a function that should be allocated in bank0,
   that is at locations below 0x8000.
   Example:
   | void somebankingwork(int args) __lomem { ... } */

#define __lomem __attribute__((place(0x0200,0x7fff)))

/* `__himem` --
   Mark a variable or a function that should be allocated
   at addresses greater than 0x8000 on a gigatron with at
   least 64k of memory.
   Example:
   | struct foo array[20][20] __himem; */

#define __himem __attribute__((place(0x8000,0xffff)))

/* `__weakref(x)` --
   Causes an external variable to be a weak reference to linker symbol
   `s`.  If no module defines this variable, no compilation error will
   be reported, and the address of the variable will be set to
   zero. */

#define __weakref(x) __attribute__((alias("__glink_weak_" x)))

/* `__at(ADDRESS)` --
   Indicate that a variable lives at a fixed address.
   In a variable definition, the linker will be asked to
   allocate the variable at the specified address.
   In an external variable declaration, the linker will
   resolve the variable with the specified address in
   the current compilation unit.
   Example:
   | extern unsigned char ctrlBits __at(0x1f8); */

#define __at(x) __attribute__((org(x)))


/* `__offset(ADDRESS)` --
   Indicates that the variable should be located
   at an address whose last byte matches ADDRESS.
   Example:
   | extern struct vCpuContext_s context __offset(0xe0); */

#define __offset(x) __attribute__((offset(x)))

/* `__quickcall` --
   Declares that an external function can be called by passing
   all its arguments by register and without need to spill
   the caller-saved registers. This reduces the cost of the
   call and occasionally makes it possible to treat the
   calling function as a leaf function or a frameless one.
   Example:
   | extern int SYS_Lup(unsigned int addr) __quickcall; */

#define __quickcall __attribute__((quickcall))


/* Note that the keywords `__near` and `__far` are not attributes but
   are type qualifiers comparable to `const` or `volatile`.  They can
   be used in typedefs and inside declarators.  For instance `int *
   __near a;` and `int __near *a` are quite different. The first one
   locates pointer a in page zero, the second one says that pointer a
   points to integers located in page zero. Such subtleties do not
   exist for attributes.  An attribute, even in a typedef, will be
   applied to the declared variables regardless of its position in the
   type specifier or the declarator. */


#endif
