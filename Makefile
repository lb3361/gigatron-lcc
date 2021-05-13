SHELL=/bin/sh
TOP=
PREFIX=/usr/local
DESTDIR=
BUILDDIR=build
bindir=${DESTDIR}${PREFIX}/bin
libdir=${DESTDIR}${PREFIX}/lib/gigatron-lcc
INSTALL=${TOP}gigatron/install-sh
LN_S=ln -s
B=${TOP}${BUILDDIR}/
G=${TOP}gigatron/

TARGET=gigatron
CFLAGS=-g -Wno-abi
LDFLAGS=-g
HOSTFILE=${TOP}etc/gigatron-lcc.c


SUBDIRS=${G}runtime ${G}lib ${G}map64k ${G}mapsim 

FILES=${B}glcc ${B}glink ${B}glink.py ${B}interface.json ${B}roms.json

default: all

all: build-dir lcc-all gigatron-all
	${MAKE} subdirs-all

clean: lcc-clean gigatron-clean subdirs-clean build-dir-clean

install: all gigatron-install subdirs-install

build-dir: FORCE
	-mkdir -p ${BUILDDIR}

build-dir-clean: FORCE
	-rm -rf ${B}

lcc-%: FORCE
	@${MAKE} -f makefile.lcc \
		"PREFIX=${PREFIX}" \
		"BUILDDIR=${BUILDDIR}" \
		"HOSTFILE=${HOSTFILE}" \
                "TARGET=${TARGET}" \
		"CFLAGS=${CFLAGS}" \
		"LDFLAGS=${LDFLAGS}" \
		`echo $@ | sed -e 's/^lcc-//'`

subdirs-%: FORCE
	@for n in ${SUBDIRS} ; do \
	   ${MAKE} -C $$n \
		"PREFIX=${PREFIX}" \
		"BUILDDIR=${BUILDDIR}" \
		"DESTDIR=${DESTDIR}" \
		`echo $@ | sed -e 's/^subdirs-//'`; \
	   done

gigatron-all: gigatron-include ${FILES} 

gigatron-clean: FORCE
	-rm -rf ${FILES} ${B}include

gigatron-install: FORCE
	-${INSTALL} -d ${libdir}
	${INSTALL} -m 755 ${B}cpp ${libdir}/cpp
	${INSTALL} -m 755 ${B}rcc ${libdir}/rcc
	${INSTALL} -m 755 ${B}lcc ${libdir}/lcc
	for n in ${FILES}; do \
	    mode=644; test -x "$$n" && mode=755 ; \
	    ${INSTALL} -m $$mode "$$n" ${libdir}/ ; done
	-${INSTALL} -d "${libdir}/include"
	for n in "${B}include"/* ; do \
	    ${INSTALL} -m 0644 "$$n" "${libdir}/include/" ; done
	-${INSTALL} -d ${bindir}
	${LN_S} ${libdir}/glcc ${bindir}/glcc
	${LN_S} ${libdir}/glink ${bindir}/glink


gigatron-include: FORCE
	-mkdir -p ${B}include
	cp ${TOP}include/gigatron/* ${B}/include/

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



