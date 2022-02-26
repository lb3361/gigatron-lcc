CC=glcc
ROM=vx0
MAP=sim
CFLAGS=-rom=${ROM} -map=${MAP}

PROGS=tstxla.gt1 tstjmpi.gt1 tstncopy.gt1

all: ${PROGS}

clean: FORCE
	-rm ${PROGS} *.o


tstxla.gt1: tstxla.o tstop.s
	${CC} ${CFLAGS} -o $@ $+

tstjmpi.gt1: tstjmpi.o tstop.s
	${CC} ${CFLAGS} -o $@ $+

tstncopy.gt1: tstncopy.o tstop.s
	${CC} ${CFLAGS} -o $@ $+

%.o : %.c
	${CC} ${CFLAGS} -c $<

FORCE:

.PHONY: FORCE
