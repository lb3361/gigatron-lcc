CC=cc
GLCC=glcc -map=64k -rom=dev7 --no-runtime-bss-initialization

rotator_dev7_64k.gt1: rotator.c table.c
	${GLCC} -o $@ rotator.c table.c


table.c: tablegen
	./tablegen > table.c

tablegen: tablegen.c
	${CC} -o $@ tablegen.c

clean: FORCE
	-rm tablegen table.c *.gt1

tar: FORCE
	tar cvfz rotator.tar.gz Makefile tablegen.c rotator.c

FORCE:

.PHONY: FORCE
