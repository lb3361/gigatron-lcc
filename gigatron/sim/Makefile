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

LIBSIMFILES= printf.s _rt_exit.s

all: ${B}gtsim ${B}mapsim/map.py ${B}mapsim/libsim.a

${B}gtsim: gtsim.c
	${CC} -o $@ -g gtsim.c -lm

${B}mapsim/map.py: map.py
	-mkdir -p ${B}mapsim
	cp map.py $@

${B}mapsim/libsim.a: ${LIBSIMFILES}
	-mkdir -p ${B}mapsim
	cat ${LIBSIMFILES} > $@

clean: FORCE
	-rm -rf ${B}mapsim/map.py ${B}mapsim/libsim.a
	-rmdir ${B}mapsim

install: FORCE
	-${INSTALL} -d "${libdir}/mapsim
	${INSTALL} -m 0755 ${B}gtsim ${libdir}/
	${INSTALL} -m 0644 ${B}mapsim/libsim.a ${libdir}/mapsim/
	${INSTALL} -m 0644 ${B}mapsim/map.py ${libdir}/mapsim/

FORCE: .PHONY

.PHONY: 

