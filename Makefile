SHELL=/bin/sh
TOP=$(shell pwd)
PREFIX=/usr/local
BUILDDIR=${TOP}/build
HOSTFILE=${TOP}/etc/gigatron-lcc.c
TARGET=gigatron
CFLAGS=-g -Wno-abi
LDFLAGS=-g

TARGETS= all rcc lburg cpp lcc bprint ops \
         liblcc triple clean clobber 

default: all

${TARGETS}: FORCE
	mkdir -p ${BUILDDIR}
	${MAKE} -f makefile.lcc \
		"PREFIX=${PREFIX}" \
		"BUILDDIR=${BUILDDIR}" \
		"HOSTFILE=${HOSTFILE}" \
		"CFLAGS=${CFLAGS}" \
		"LDFLAGS=${LDFLAGS}" \
		$@


FORCE: .PHONY

.PHONY:



