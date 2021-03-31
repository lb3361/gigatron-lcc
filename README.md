

# Gigatron LCC

This version of LCC targets the [Gigatron](http://gigatron.io) VCPU.
It keeps some of the ideas of the previous attempt to port LCC to the
Gigatron.  For instance it outputs assembly code that can be parsed by
Python and it features a linker writen in Python that can directly
ready these files. It also differs in critical ways. For instance the
code generator is fundamentally different.

## Compiling and installing

Building under Linux should just be a matter of typing
```
$ make PREFIX=/usr/local
```
where variable `PREFIX` indicates where the compiler should be installed.
The installation command
```
$ make PREFIX=/usr/local install
```
copies the compiler files into `${PREFIX}/lib/gigatron-lcc/` and
symlinks the compiler driver `glcc` into `${PREFIX}/bin`.
A minimal set of include files are copied 
into `${PREFIX}/lib/gigatron-lcc/include`
but very few of what they define is currently implemented.


## Compiler invocation

Besides the options listed in the [lcc manual page](doc/lcc.1),
the compiler driver recognizes a few Gigatron-specific options.

  * Option `-cpu=[456]` indicates which VCPU version should be
	targeted.  Version 5 adds the instructions `CALLI`, `CMPHS` and
	`CMPHU` that came with ROMv5a. Version 6 will support AT67's new
	instruction once finalized. 
	
  * Option `-rom=<romversion>` is passed to the linked and
	helps selecting runtime code that uses the SYS functions
	implemented by the indicated rom version. The default is `v5a`
	which does not provide much support at this point.
	
  * Option `-map=<memorymap>` is also passed to the linker and specify
	the memory layout of the code. The default map, `64k`, places 
	code, data, heap, and stack into the conveniently contiguous upper
	memory region `[0x8100,0xffff]`. An alternate map, `32k`, places
	data and stack in region `[0x200-0x7ff]` and spreads the code and
	the heap in the video holes `[0xPPa0,0xPPff]`.
	
## Basic types

  * Types `short` and `int` are 16 bits long.
	Type `long` is 32 bits long. Types `float` and `double`
	are 40 bits long, using the Microsoft Basic floating point 
	format. Both long arithmetic or floating point arithmetic
	incur a significant speed penalty.
	
  * Type `char` is unsigned by default. This is more efficient because
	the C language always promotes `char` values into `int` values to
	perform arithmetic. Promoting a signed byte involves a clumsy sign
	extension. Promoting an unsigned byte comes for free with most
	VCPU opcodes. For signed bytes, use `signed char` or use the
	compiler option `-Wf-unsigned_char=0`. The preprocessor macros
	`__CHAR_UNSIGNED` or `CHAR_IS_SIGNED` are defined accordingly.

## Internals

On the one hand, the VCPU design establishes a three-level hierarchy
of memory locations.  First comes the accumulator `vAC` which is read
or written by virtually all VCPU instructions. Then come the zero page
locations which are conveniently read or written by the VCPU. Finally
come all other memory locations which are only accessible indirectly
at addresses found in zero page locations. On the other hand, the LCC
code generator deals with only two levels, namely a handful of
registers and the memory. 

Treating both the accumulator and the zero page location as registers
causes countless problems because there is essentially nothing the
VCPU can do once the accumulator is allocated to represent a
particular variable or a temporary.  It is then necessary to revise
the allocation by spill the accumulator, that is, storing its contents
elsewhere and patch the remaining code to reload it when needed. Alas
both spilling and reloading the accumulator cannot be done without
using the accumulator.

The GLCC code generator uses a block of zero page locations as 32
sixteen bit registers. It produces code that is made of successive
bursts of VCPU instructions. These bursts are in fact what LCC calls
an "instruction". This is why each burst is packed on a single line of
the generated assembly code. The burst themselves are produced by
abusing the mechanisms defined by LCC to construct various parts of a
typical CPU instruction such as the mnemonic, the address mode,
etc. The accumulator `vAC` is treated as a scratch register inside a
burst. Meanwhile LCC allocates zero page registers to pass data across
bursts.

The registers are named `R0` to `R31`. Register `R0` is in fact the
accumulator `vAC`. Register `R1`, also named `SR`, is a scratch
register that is mostly used within canned instruction sequences.
Register `R31`, also named `SP`, is a stack pointer whose value is
adjusted only twice by each function, once in the prologue to
construct a stack frame, and once in the epilogue to return to the
caller's frame. In addition the prologue saves the link register a`vLR`
into register `R30` and the epilogue restores it just before the `RET`
instruction. Saving `vLR` allows us to use `CALLI` as a long jump
without fearing to erase the function return address.

Long integers are pairs of consecutive registers. These pairs are
named `L2` to `L28`. For instance, `L3` is made of registers `R3` and
`R4`. Register pair `L3` and `L6` are also known as `LAC` and `LARG`
because they're implicitly used by the runtime routines that implement
long arithmetic.  Similarly, floating point numbers are stored in
register triples named `F2` to `F27`. Register triples `F2` and `F5`
are also known as `FAC` and `FARG` for the same reasons.  Floating
point numbers in registers occupy six bytes instead of five. The
additional byte unpack information that is useful for the floating
point emulation runtime such as sign bits and carry flags.

Registers `R8` to `R13` are used to pass arguments to functions.
Registers `R14` to `R23` contain local variables and must be saved and
restored by all functions. Temporary variables are first allocated in
registers `R24` to `R29`, then in other free registers as needed.  The
stack frames are close to MIPS stack frame with an argument building
zone where a function stores arguments for the function it calls, a
local variable zone for the local variables that didn't fit in
registers, and a saved register area for the callee-saved registers.

The compiler produces python files that define a single function whose
argument is an object `x`. This function calls methods that emit the
bytes representing each instruction. Most of these methods are named
in uppercase after the VCPU instruction they represent. Additional
methods, always starting with an underscore, implement synthetic
instructions that can either call a runtime routine or emit a short
sequence of instructions inline.  Finally a couple methods, named in
lowercase, manipulate labels, switches segment, declare imports and
exports for each module, etc.

The linker collects all the python functions generated by the compiler
and all the python functions representing the runtime code.  It
analyzes import and exports to determine which ones should be
kept. Then it repeatedly calls them until all symbols are resolved and
all symbol value dependent code is stabilized. Then it produces a
familar `GT1` file.
