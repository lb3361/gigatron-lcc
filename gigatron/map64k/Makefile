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

MAPDIR=map64k

all: ${B}${MAPDIR}/map.py

${B}${MAPDIR}/map.py: map.py
	-mkdir -p ${B}${MAPDIR}
	cp map.py $@

clean: FORCE
	-rm -rf ${B}mapsim/map.py ${B}mapsim/libsim.a
	-rmdir ${B}mapsim

install: FORCE
	-${INSTALL} -d "${libdir}/${MAPDIR}
	${INSTALL} -m 0644 ${B}${MAPDIR}/map.py ${libdir}/${MAPDIR}/

FORCE: .PHONY

.PHONY: 

