
CC=../../build/glcc
ROM=dev7
MAP=64k,hionly
DEFS=-Dprintf=mincprintf
CFLAGS=-rom=$(ROM) -map=$(MAP) ${DEFS}

PGMS=sieve0.gt1 sieve1.gt1

all: $(PGMS)

sieve0.gt1: sieve0.c
	${CC} ${CFLAGS} sieve0.c -o $@

sieve1.gt1: sieve1.c
	${CC} ${CFLAGS} sieve1.c -o $@

clean:
	-rm *.gt1 *.s *.frg *.prf

