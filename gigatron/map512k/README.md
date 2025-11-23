* Memory map '512k'

This map targets Gigatrons equipped with the 512k board.

Thanks to the video snooping capabilities of the 512k board, the video
buffer is displaced into banks 12 to 15 depending on the chosen video
mode. Code and data can then use the entire 64k addressable by the
Gigatron CPU.

Overlay 'lo' limits code and data to memory below 0x8000 allowing the
code to remap the range 0x8000-0xffff without risk.  Overlays 'hr' and
'nr' respectively link the high-resolution (320x240) or narrow
resolution (320x120) console library. Otherwise one gets a standard
resolution console in page 14.  Overlay 'noromcheck' prevents the
startup code from checking the presence of a 512k patched ROM which is
nevertheless necessary for several programs.

* Implementation notes

The generic console code in libc/cons_asm.s depends on options
MAP512K, MAP512K_DBLWIDTH, MAP512K_DBLHEIGHT which are set in the map
or the map options. The map also sets an onload initialization
function '_map512k_setup'.

The map forces linking with libraries libcon_b, libcon_n, or libcon_h
for the regular, double width, and high-resolution modes.  These
libraries provide replacement for various generic routines, and in
particular the console banking code (file cons_bank.s) and the
initialization code (file `map512k_asm.s). These last two files are
identical for all three libraries but depend on options MAP512K,
MAP512K_DBLWIDTH, MAP512K_DBLHEIGHT.


