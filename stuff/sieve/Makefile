
CC=../../build/glcc
ROM=v5a
MAP=64k,hionly
CFLAGS=-rom=$(ROM) -map=$(MAP)

PGMS=sieve1.gt1 sieve2.gt1 sieve3.gt1

all: $(PGMS)

sieve1.gt1: sieve1.c
	${CC} ${CFLAGS} sieve1.c -o $@

sieve2.gt1: sieve2.c
	${CC} ${CFLAGS} sieve2.c -o $@

sieve3.gt1: sieve3.c
	${CC} ${CFLAGS} sieve3.c -o $@

clean:
	-rm ${PGMS}

