
CC=../../build/glcc
ROM=v5a
MAP=conx
CFLAGS=-rom=$(ROM) -map=$(MAP)

PGMS=yofp.gt1 yofp2.gt1

all: $(PGMS)

yofp.gt1: yofp.c
	${CC} ${CFLAGS} yofp.c -o $@

yofp2.gt1: yofp2.c
	${CC} ${CFLAGS} yofp2.c -o $@

clean:
	-rm ${PGMS}

