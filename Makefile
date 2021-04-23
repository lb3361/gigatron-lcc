SHELL=/bin/sh
PREFIX=/usr/local
BUILDDIR=${TOP}/build
DESTDIR=
HOSTFILE=${TOP}/etc/gigatron-lcc.c
TARGET=gigatron
CFLAGS=-g -Wno-abi
LDFLAGS=-g
INSTALL=${TOP}/gigatron/install-sh
bindir=${DESTDIR}${PREFIX}/bin
libdir=${DESTDIR}${PREFIX}/lib/gigatron-lcc/
TOP=.
B=${BUILDDIR}/
G=${TOP}/gigatron/

SUBDIRS=${G}lib ${G}runtime

FILES=${B}glcc ${B}glink ${B}glink.py ${B}interface.json ${B}roms.json

MAPS=64k 32k sim

default: all

all: build-dir lcc-all gigatron-all subdirs-all

clean: lcc-clean gigatron-clean subdirs-clean build-dir-clean

install: all gigatron-install subdirs-install

build-dir: FORCE
	-mkdir -p ${BUILDDIR}

build-dir-clean: FORCE
	-rm -rf ${B}

lcc-%: FORCE
	${MAKE} -f makefile.lcc \
		"PREFIX=${PREFIX}" \
		"BUILDDIR=${BUILDDIR}" \
		"HOSTFILE=${HOSTFILE}" \
                "TARGET=${TARGET}" \
		"CFLAGS=${CFLAGS}" \
		"LDFLAGS=${LDFLAGS}" \
		`echo $@ | sed -e 's/^lcc-//'`

subdirs-%: FORCE
	for n in ${SUBDIRS} ; do \
	   ${MAKE} -C $$n \
		"PREFIX=${PREFIX}" \
		"BUILDDIR=${BUILDDIR}" \
		"CFLAGS=${CFLAGS}" \
		"LDFLAGS=${LDFLAGS}" \
		`echo $@ | sed -e 's/^subdirs-//'`; \
	   done

gigatron-all: gigatron-include gigatron-maps ${FILES} 

gigatron-clean: FORCE
	-rm -rf ${FILES} ${B}include
	-for n in ${MAPS} ; do rm -rf ${B}map$$n; done

gigatron-install: FORCE
	@echo Installing

gigatron-include: FORCE
	-mkdir -p ${B}include
	cp ${TOP}/include/gigatron/* ${B}/include/

gigatron-maps: FORCE
	for n in ${MAPS}; do mkdir -p ${B}map$$n; cp ${G}map$$n/* ${B}map$$n; done

${B}glink: ${G}glink
	cp ${G}glink ${B}glink
	chmod a+x ${B}glink

${B}glink.py: ${G}glink.py
	cp ${G}glink.py ${B}glink.py
	python -m compileall -b ${B}glink.py

${B}glcc: ${G}glcc
	cp ${G}glcc ${B}glcc
	chmod a+x ${B}glcc

${B}%: ${G}%
	cp $< $@

FORCE: .PHONY

.PHONY:



