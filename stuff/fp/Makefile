
CC=../../build/glcc
ROM=v5a
MAP=conx
CFLAGS=-rom=$(ROM) -map=$(MAP)

PGMS=yofp1.gt1 yofp2.gt1 yofp3.gt1

all: $(PGMS)

yofp1.gt1: yofp1.c
	${CC} ${CFLAGS} yofp1.c -o $@

yofp2.gt1: yofp2.c
	${CC} ${CFLAGS} yofp2.c -o $@

yofp3.gt1: yofp3.c
	${CC} ${CFLAGS} yofp3.c -o $@

clean:
	-rm ${PGMS}

