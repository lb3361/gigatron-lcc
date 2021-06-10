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
CFLAGS=-O3 -g

MAPDIR=mapsim

LIBSIMFILES= libsim/printf.s libsim/_exitm.s

all: ${B}gtsim ${B}${MAPDIR}/map.py ${B}${MAPDIR}/libsim.a

${B}gtsim: gtsim.c
	${CC} ${CFLAGS} -o $@ gtsim.c -lm

${B}${MAPDIR}/map.py: map.py
	-mkdir -p ${B}${MAPDIR}
	cp map.py $@

${B}${MAPDIR}/libsim.a: ${LIBSIMFILES}
	-mkdir -p ${B}${MAPDIR}
	cat ${LIBSIMFILES} > $@

clean: FORCE
	-rm -rf ${B}${MAPDIR}/map.py ${B}${MAPDIR}/libsim.a
	-rmdir ${B}${MAPDIR}

install: FORCE
	-${INSTALL} -d "${libdir}/${MAPDIR}"
	${INSTALL} -m 0644 "${B}${MAPDIR}/libsim.a" "${libdir}/${MAPDIR}/"
	${INSTALL} -m 0644 "${B}${MAPDIR}/map.py" "${libdir}/${MAPDIR}/"
	${INSTALL} -m 0755 "${B}gtsim" "${libdir}/"
	${LN_S} ${libdir}/gtsim ${bindir}/gtsim

test: FORCE

FORCE: .PHONY

.PHONY: 

