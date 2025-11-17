# Sound demos

To recompile the programs, use the command:

```
$ make clean all ROM=v6 BINDIR=/where/isglcc/
```

ROM can be any of `v5a`, `v6`, `vx0`, or `dev7` (the default). BINDIR can be empty, in which case `glcc` and `gtmid2c` are searched in the path, or omitted, in which case they are searched in the glcc build directory.



### play.c

w.i.p.


### music.c

Program [`music.c`](music.c) is a C reimplementation of at67's midi demo found in `gigatron-rom/Contrib/at67/gbas/audio/Music64k_ROMv5a.gbas` in the Gigatron ROM repository. The midi data is initialized by C files located in the `midi` directory. They can be reconstructed replacing them by the corresponding gtmidi files found in `gigatron-rom/Contrib/at67/res/audio/midi` and using the `make` command.

