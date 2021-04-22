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

FILES=${B}glcc ${B}glink ${B}glink.py ${B}interface.json ${B}roms.json

MAPS=64k 32k sim

default: all

all: lcc-all gigatron-dirs ${FILES}

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

gigatron-dirs: gigatron-include gigatron-maps

gigatron-include: FORCE
	-mkdir -p ${B}include
	cp ${TOP}/include/gigatron/* ${B}/include/

gigatron-maps: FORCE
	for n in ${MAPS}; do \
		mkdir -p ${B}map$$n;\
		cp ${G}map$$n/* ${B}map$$n;\
	done

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



