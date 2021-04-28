# GNUmake required

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
BL=${TOP}${BUILDDIR}/libc/
G=${TOP}gigatron/

SFILES=$(wildcard *.s)
CFILES=$(wildcard *.c)
OFILES=${patsubst %.c,${BL}%_4.o,${CFILES}} ${patsubst %.c,${BL}%_5.o,${CFILES}}
RFILES=$(wildcard ../runtime/*.s)

all: ${B}libc.a

${B}libc.a: ${SFILES} ${OFILES} ${RFILES}
	-@mkdir -p ${BL}
	cat ${SFILES} ${OFILES} ${RFILES} > ${B}libc.a


${BL}%_4.o: %.c
	-@mkdir -p ${BL}
	${B}glcc -c -cpu=4 -o $@ $<

${BL}%_5.o: %.c
	-@mkdir -p ${BL}
	${B}glcc -c -cpu=4 -o $@ $<

${BL}%_6.o: %.c
	-@mkdir -p ${BL}
	${B}glcc -c -cpu=6 -o $@  $<

clean: FORCE
	-rm ${B}libc.a
	-rm ${OFILES}
	-rmdir ${BL}

install: FORCE
	${INSTALL} -m 644 ${B}libc.a ${libdir}/libc.a

FORCE: .PHONY

.PHONY: 

.SUFFIXES: .c .s .4s .5s .6s
