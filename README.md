

# Gigatron LCC


This version of LCC targets the [Gigatron](http://gigatron.io) VCPU.
It keeps many of the ideas of the previous attempt to port LCC to the
Gigatron (pgavlin's).  For instance it outputs assembly code that can be parsed by
Python and it features a linker writen in Python that can directly
read these files. It also differs in important ways. For instance the
code generator is fundamentally different.

## Status

### What works

* The compiler compiles
* The linker/assembler assembles and links.
* The runtime is complete (including LONG and FP support)
* The emulator (build/gtsim) can run gt1 files and redirect printf to stdout (compile with glcc -map=sim)
* signal(SIGVIRQ, xxx) captures vCPU interrupts
* signal(SIGFPE, xxx) captures division by zero and floating point issues.
* libc has optimized memset and memcpy
* half of the standard libc functions are there.
* sqrt() works

### What remains to be done:

There is substantial work needed on the libraries

* stdio
* malloc (there is already support to collect a heap)
* printf (but you can printf when using -map=sim)
* transcendental functions in libm
* writing to the gigatron screen
* reading lines with a pluggy keyboard.
* adding more gigatron SYS stubs

The compiler could also be improved

* Although the code generator uses vAC quite well within a tree, it cannot use vAC at all to pass data from one tree to the next. This was improved by adding a `preralloc` callback in the lcc code generator, but the current code does not know which instructions preserve vAC and is therefore very conservative. There are multiple ways to address this. One is to write a python peephole optimizer that runs as a separable pass. The correct way would be to make the lburg code selection aware of the input state of the registers. This is much harder.
* One could rewrite the compiler driver `glcc` to be self-contained instead of delegating much work to the historical lcc driver `lcc`. That would make option processing simpler to understand. This is harder than it seems.


## Compiling and installing

Building under Linux should just be a matter of typing
```
$ make PREFIX=/usr/local
```
where variable `PREFIX` indicates where the compiler should be installed.
You can either invoke the compilier from its build location `./build/glcc` or
install it into your system with command
```
$ make PREFIX=/usr/local install
```
This command copies the compiler files into `${PREFIX}/lib/gigatron-lcc/` 
and symlinks the compiler driver `glcc` and linker driver `glink` 
into `${PREFIX}/bin`. A minimal set of include files are copied 
into `${PREFIX}/lib/gigatron-lcc/include` but very little of what 
they define is currently implemented.

There is also 
```
$ make test
```
to run the current test suite. The LCC test files are in `tst`
but some need pieces of the runtime or library that are still missing.
The runtime and library test files are in `gigatron/{runtime,libc,libm}/tst`.
They give a good idea of what works at the moment.



## Compiler invocation

Besides the options listed in the [lcc manual page](doc/lcc.1),
the compiler driver recognizes a few Gigatron-specific options.
Additional options recognized by the assembler/linker `glink'
are documented by typing `glink -h`
 	
  * Option `-rom=<romversion>` is passed to the linked and
	helps selecting runtime code that uses the SYS functions
	implemented by the indicated rom version. The default is `v5a`
	which does not provide much support at this point.
	
 * Option `-cpu=[456]` indicates which VCPU version should be
	targeted.  Version 5 adds the instructions `CALLI`, `CMPHS` and
	`CMPHU` that came with ROMv5a. Version 6 will support AT67's new
	instruction once finalized. The default CPU is the one
	implemented by the selected ROM.

  * Option `-map=<memorymap>` is also passed to the linker and specify
	the memory layout for the generated code. The default map, `64k` 
	uses all little bits of memory available on a 64KB Gigatron,
	starting with the video memory holes `[0x?a0-0x?ff]`, 
	the low memory `[0x200-0x6ff]`, and finally the 32KB of high 
	memory `[0x8000-0xffff]`.  
	
	Maps can also manipulate
	the linker arguments, insert libraries, and define
	the initialization function that checks the rom type
	and the ram configuration. A second map `sim` is similar
	but produces gt1 files that run in the 
	emulator [`gtsim`](gigatron/mapsim) with a library that
	redirects `printf` (and only this for now) to the 
	emulator standard output. This is my main debugging tool.
	
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
	
## Examples

Running the LCC 8 queens program:

```
$ ./build/glcc -map=sim tst/8q.c 
tst/8q.c:30: warning: missing return value
tst/8q.c:37: warning: implicit declaration of function `printf'
tst/8q.c:39: warning: missing return value
$ ./build/gtsim a.gt1 
1 5 8 6 3 7 2 4 
1 6 8 3 7 4 2 5 
1 7 4 6 8 2 5 3 
1 7 5 8 2 4 6 3 
2 4 6 8 3 1 7 5 
2 5 7 1 3 8 6 4 
2 5 7 4 1 8 6 3 
2 6 1 7 4 8 3 5 
2 6 8 3 1 4 7 5 
2 7 3 6 8 5 1 4 
2 7 5 8 1 4 6 3 
2 8 6 1 3 5 7 4 
...
```

Capturing signals:
```
$ cat gigatron/libc/tst/TSTsignal.c 
#include <string.h>
#include <stdio.h>
#include <signal.h>

int a = 3;
long b = 323421L;
volatile int vblcount = 0;
extern char frameCount;

int handler(int signo, int fpeinfo)
{
	printf("handle %d %d\n", signo, fpeinfo);
	return 1234;
}

long lhandler(int signo, int fpeinfo)
{
	printf("handle %d %d\n", signo, fpeinfo);
	return 1234L;
}

void vhandler(int signo)
{
	printf("SIGVIRQ(%d): count=%d\n", signo, vblcount++);
	frameCount=255;
	signal(SIGVIRQ, vhandler);
}

int main()
{
	signal(SIGFPE, (sig_handler_t)handler);
	printf("%d/0 = %d\n", a, a / 0);
	signal(SIGFPE, (sig_handler_t)lhandler);
	printf("%ld/0 = %ld\n", b , b / 0);
	signal(SIGVIRQ, vhandler);
	while (vblcount < 10) { 
		b = b * b;
	}
	return 0;
}
$ ./build/glcc -map=sim  gigatron/libc/tst/TSTsignal.c 
$ ./build/gtsim a.gt1 
handle 4 1
3/0 = 1234
handle 4 1
323421/0 = 1234
SIGVIRQ(7): count=0
SIGVIRQ(7): count=1
SIGVIRQ(7): count=2
SIGVIRQ(7): count=3
SIGVIRQ(7): count=4
SIGVIRQ(7): count=5
SIGVIRQ(7): count=6
SIGVIRQ(7): count=7
SIGVIRQ(7): count=8
SIGVIRQ(7): count=9
```




## Internals

The code generator uses two consecutive blocks of zero page locations:
  *  The first block, located at addresses `0x81-0x8f`, is dedicated to
     the routines that implement long and float arithmetic. The long accumulator `LAC`
     uses locations `0x84-0x87`. The floating point accumulator `FAC` uses location `0x81-0x87`.
     The remaining locations `0x88-0x8f` are working space for these routines.
     They are also known as scratch registers `T0` to `T3` which are
     occasionally used as scratch registers by the code generator.
  *  The second block, located at addresses `0x90-0xbf`, contains 24 general 
     purpose sixteen bits registers named `R0` to `R23`. 
     Register pairs named can hold longs. Register triplets named
     can hold floats. Registers `R0` to `R7` are callee-saved
     registers. Registers `R8` to `R15` are used to pass
     arguments to functions. Registers `R15` to `R22` are used
     for temporaries. Register `R23` or `SP` is the stack pointer.
     
The function prologue first saves `vLR` and constructs a stack frame
by adjusting `SP`. It then saves the callee-saved registers onto the stack.
Nonleaf functions save 'vLR' in the stack frame and copy the argument 
passed in a registers to their final location. In contrast, leaf functions
keep arguments passed in registers
where they are because these registers are no longer needed for further calls.
In the same vein, nonleaf functions allocate callee-saved registers
for local variables, whereas leaf functions use callee-saved registers
in last resord and often avoid having to construct a stack-frame alltogether. 
Leaf functions that do not need to allocate space on the stack can 
use a register to save VLR and become entirely frameless.
Sometimes one can help this by using `register` when declaring 
local variables. I have to find a way to make lcc more aggressive in that respect. 

Saving `vLR` allows us to use `CALLI` as a long jump
without fearing to erase the function return address.
This is especially useful when one needs to hop over page boundaries.

The VCPU accumulator `AC` is not treated by the compiler as a normal 
register because there is essentially nothing the VCPU can do once the 
accumulator is allocated to represent a particular variable or a temporary.
This would force the compiler to spill its content to a stack location
in ways that not only produce less efficient code, but often result
in an infinite loop because the spilling code must itself use `AC`.
Instead, the GLCC code generator produces VCPU instructions in bursts 
that are packed on a single line of the generated assembly code. 
Each burst is in fact what LCC calls an instruction. Bursts are
produced by subverting the mechanisms defined by LCC to construct 
various parts of a typical CPU instruction such as the mnemonic, 
the address mode, etc. The VCPU accumulator `AC` is treated as a scratch 
register inside a burst. Meanwhile LCC allocates zero page registers 
to pass data across bursts. This approach avoid the spilling problems
but sometimes needs improving because we do not keep track
of what data is left on the accumulator after each burst.
This could be improved by adding a peephole optimization pass
at some point.

The compiler produces a python file that first define a function for each
code or data fragment. The file then constructs a module that
holds a list of all the fragments, as well as all the imported and
exported symbols. The linker/assembler `glink` can read such files
or can read a library file that is merely the concatenation
of individual modules.  Each fragment is represented as a function
that calls predefined functions whose uppercase name mirrors the name
of the instruction they emit. Additional functions implement synthetic
opcodes that can be implemented differently by different VCPU versions.
More predefined functions are used to define labels or control
when to check for a page boundary. The source of truth for 
all this is the file `glink.py`.

The linker collects all the code and data fragments generated by the compiler.
It then analyzes import and exports to determine which ones should be
kept. It tries hard to place short functions into single segments in order
to avoid costly hops. Then it iterates until all symbols are resolved and
all symbol value dependent code is stabilized. Finally it produces a
familar `GT1` file.
