
BINDIR=../../build/
ROM=dev7
MAP=64k

CC=${BINDIR}glcc
GTMID2C=${BINDIR}gtmid2c
CFLAGS=-map=${MAP} --no-runtime-bss

PGMS=music.gt1

MIDIS=midi/agony.c midi/bath.c midi/escape.c midi/f1.c \
      midi/freedom.c midi/fzero.c midi/ik.c midi/ment.c \
      midi/virus.c

all: ${PGMS}

music.gt1: music.c ${MIDIS}
	${CC} -o $@ -rom=${ROM} ${CFLAGS} $< ${MIDIS}

clean: FORCE
	rm -rf ${PGMS}

midi/bath.c: midi/bath.gtmid
	${GTMID2C} -s 96 $< $@

midi/freedom.c: midi/freedom.gtmid
	${GTMID2C} -s 96 $< $@

midi/%.c: midi/%.gtmid
	${GTMID2C} -s 256 $< $@

FORCE:

.PHONY: FORCE

.PRECIOUS: ${MIDIS}
