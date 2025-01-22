
ROM=dev7
MAP=64k

CFLAGS=-map=${MAP} -rom=${ROM}
CC=glcc


all: TSTfill.gt1 TSTblit.gt1 TSTrotator.gt1

TSTfill.gt1: TSTfill.c
	${CC} ${CFLAGS} -o $@ $<

TSTblit.gt1: TSTblit.c
	${CC} ${CFLAGS} -o $@ $<

TSTrotator.gt1: TSTrotator.s
	${CC} ${CFLAGS} -o $@ --gt1-exec-address=main --entry=main $<

clean: FORCE
	-rm 2>&1 *.gt1

FORCE:

.PHONY: FORCE
