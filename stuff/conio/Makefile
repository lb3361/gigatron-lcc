ROM=v5a
MAP=32k,nochan
CC=../../build/glcc
CFLAGS=-rom=$(ROM) -map=$(MAP)

PROGS=TSTkbgetb.gt1 TSTkbgetc.gt1 TSTsnake.gt1

all: $(PROGS)

%.gt1: %.c
	$(CC) $(CFLAGS) -o $@ $<

snake: TSTsnake.c unix/conio.h unix/conio.c
	gcc -o $@ -Iunix TSTsnake.c unix/conio.c

clean: FORCE
	-rm -rf $(PROGS) snake

FORCE:
