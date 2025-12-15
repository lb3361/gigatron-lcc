
# Marcel's Simple Chess Program

MSCP, Marcel's Simple Chess Program by Marcel van Kervinck, is a
small, simple, yet complete open source chess engine released under
the GNU GPL. This version has been adapted to work on the Gigatron
which is another brainchild of Marcel.

https://www.chessprogramming.org/MSCP


## Changes

The main change relocates the `union core` structure containing the
compiled opening book and the transposition table into bank 3 of the
128k gigatron. Pragmas located in file core.c ensure that all
fragments defined by core.c or called by core.c are placed in low
memory and therefore remain accessible when the banks are switched.

The random generator has been changed to a subtractive generator that
avoids costly long multiplications.

The book data is merged into the gt1 file over addresses 0x4000-0x7fff
which are normally used for bss fragments.  The book data size is
stored into the word at well known address 0x42 An onload function
defined in core.c copies this data into bank3 before the bss region
gets cleared.



# Loading process

The book

