CC=../../build/glcc
CFLAGS=-map=64k,./music.ovl --no-runtime-bss
GTMID2C=../../build/gtmid2c
ROM=dev7

PGMS=music.gt1

MIDIS=midi/agony.c midi/bath.c midi/escape.c midi/f1.c \
      midi/freedom.c midi/fzero.c midi/ik.c midi/ment.c \
      midi/virus.c

all: ${PGMS}

music.gt1: music.c ${MIDIS}
	${CC} -o $@ -rom=${ROM} ${CFLAGS} $< ${MIDIS}

clean: FORCE
	rm -rf ${PGMS}

midi/%.c: midi/%.gtmid
	${GTMID2C} -s 256 $< $@

FORCE:

.PHONY: FORCE

.PRECIOUS: ${MIDIS}
