SHELL=/bin/sh
TOP=../../
PREFIX=/usr/local
DESTDIR=
BUILDDIR=build
bindir=${DESTDIR}${PREFIX}/bin
libdir=${DESTDIR}${PREFIX}/lib/gigatron-lcc
INSTALL=${TOP}/gigatron/install-sh
LN_S=ln -s
B=${TOP}${BUILDDIR}/
G=${TOP}gigatron/


FROMCFILES=_init1_4.s _init1_5.s

all: ${FROMCFILES}
	cat *.s ../runtime/*.s > ${B}libc.a

%_4.s: %.c
	${B}glcc -S -cpu=4 -o $@ $*.c

%_5.s: %.c
	${B}glcc -S -cpu=5 -o $@  $*.c

%_6.s: %.c
	${B}glcc -S -cpu=6 -o $@  $*.c

clean: FORCE
	-rm ${B}libc.a
	-rm ${FROMCFILES}

install: FORCE
	${INSTALL} -m 644 ${B}libc.a ${libdir}/libc.a

FORCE: .PHONY

.PHONY: 
