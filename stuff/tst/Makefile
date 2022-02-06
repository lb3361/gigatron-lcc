CC=../../build/glcc
ROM=v5a
MAP=32k
CFLAGS=-rom=${ROM} -map=${MAP}

PGMS=TSTconsole.gt1 TSTio.gt1 TSTcontroller.gt1 TSTmemcpyext.gt1

all: $(PGMS)

clean:
	-rm $(PGMS)

TSTconsole.gt1: TSTconsole.c
	${CC} ${CFLAGS} TSTconsole.c -o $@

TSTio.gt1: TSTio.c
	${CC} ${CFLAGS} TSTio.c -o $@

TSTcontroller.gt1: TSTcontroller.c
	${CC} ${CFLAGS} TSTcontroller.c -o $@

TSTmemcpyext.gt1: TSTmemcpyext.c
	@if [ "$(MAP)" != 32k ] || [ "$(ROM)" != dev ] ; then \
	    test -r $@ && rm $@; \
	    echo "Cannot compile TSTmemcpyext unless MAP=32k and ROM=dev"; \
	    false ; fi
	${CC} ${CFLAGS} TSTmemcpyext.c -o $@
