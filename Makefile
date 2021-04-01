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
FILES=${B}include ${B}glcc ${B}glink

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
		"CFLAGS=${CFLAGS}" \
		"LDFLAGS=${LDFLAGS}" \
		`echo $@ | sed -e 's/^lcc-//'`

${B}include:
	-rm ${B}include
	ln -s ${TOP}/include/gigatron ${B}include

${B}glink: ${G}glink.py
	cp ${G}glink.py ${B}glink
	chmod a+x ${B}glink

${B}glcc: ${G}glcc.sh
	cp ${G}glcc.sh ${B}glcc
	chmod a+x ${B}glcc

FORCE: .PHONY

.PHONY:



