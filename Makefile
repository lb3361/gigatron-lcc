SHELL=/bin/sh
TOP=$(shell pwd)
BUILDDIR=${TOP}/build
HOSTFILE=${TOP}/etc/gigatron-lcc.c
TARGET=gigatron

TARGETS=all rcc lburg cpp lcc bprint liblcc triple clean clobber

default: all

${TARGETS}: .PHONY
	mkdir -p ${BUILDDIR}
	${MAKE} -f makefile.lcc BUILDDIR=${BUILDDIR} HOSTFILE=${HOSTFILE} $@


.PHONY:



