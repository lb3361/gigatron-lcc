SHELL=/bin/sh
TOP=$(shell pwd)
PREFIX=/usr/local
BUILDDIR=${TOP}/build
HOSTFILE=${TOP}/etc/gigatron-lcc.c
TARGET=gigatron
CFLAGS=-g -Wno-abi
LDFLAGS=-g

B=${BUILDDIR}/
G=${TOP}/gigatron/
FILES=${B}include ${B}glcc ${B}glink ${B}glink.py ${B}interface.json

default: all

all: lcc-all ${FILES}

clean: lcc-clean
	rm -rf ${FILES}

lcc-%: FORCE
	mkdir -p ${BUILDDIR}
	${MAKE} -f makefile.lcc \
		"PREFIX=${PREFIX}" \
		"BUILDDIR=${BUILDDIR}" \
		"HOSTFILE=${HOSTFILE}" \
                "TARGET=${TARGET}" \
		"CFLAGS=${CFLAGS}" \
		"LDFLAGS=${LDFLAGS}" \
		`echo $@ | sed -e 's/^lcc-//'`

${B}include:
	-rm ${B}include
	ln -s ${TOP}/include/gigatron ${B}include

${B}glink: ${G}glink
	cp ${G}glink ${B}glink
	chmod a+x ${B}glink

${B}glink.py: ${G}glink.py
	cp ${G}glink.py ${B}glink.py
	python -m compileall -b ${B}glink.py

${B}glcc: ${G}glcc.sh
	cp ${G}glcc.sh ${B}glcc
	chmod a+x ${B}glcc

${B}%: ${G}%
	cp $< $@

FORCE: .PHONY

.PHONY:



