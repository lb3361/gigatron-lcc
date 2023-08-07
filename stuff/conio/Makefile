ROM=v5a
MAP=32k
CC=../../build/glcc
CFLAGS=-rom=$(ROM) -map=$(MAP)

PROGS=TSTkbgetb.gt1 TSTkbgetc.gt1

all: $(PROGS)

%.gt1: %.c
	$(CC) $(CFLAGS) -o $@ $< 

clean: FORCE
	-rm -rf $(PROGS)

FORCE:
