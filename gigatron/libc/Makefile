# GNUmake required

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
BL=${TOP}${BUILDDIR}/libc/
G=${TOP}gigatron/
GLCC=${B}glcc
ROM=../gigatron-rom/dev.rom
GTSIM=${B}gtsim -rom ${TOP}${ROM}

SFILES=$(wildcard *.s)
CFILES=$(wildcard *.c)
O4FILES=${patsubst %.c,${BL}%_4.o,${CFILES}}
O5FILES=${patsubst %.c,${BL}%_5.o,${CFILES}}
O6FILES=${patsubst %.c,${BL}%_6.o,${CFILES}}
OFILES=${O4FILES} ${O5FILES} ${O6FILES}
RFILES=$(wildcard ../runtime/*.s)

all: ${B}cpu4/libc.a ${B}cpu5/libc.a ${B}cpu6/libc.a

${B}cpu4/libc.a: ${SFILES} ${O4FILES} ${RFILES}
	-@mkdir -p ${B}cpu4
	cat ${SFILES} ${O4FILES} ${RFILES} > ${B}/cpu4/libc.a

${B}cpu5/libc.a: ${SFILES} ${O5FILES} ${RFILES}
	-@mkdir -p ${B}cpu5
	cat ${SFILES} ${O5FILES} ${RFILES} > ${B}/cpu5/libc.a

${B}cpu6/libc.a: ${SFILES} ${O6FILES} ${RFILES}
	-@mkdir -p ${B}cpu6
	cat ${SFILES} ${O6FILES} ${RFILES} > ${B}/cpu6/libc.a

${BL}%_4.o: %.c ${B}rcc
	-@mkdir -p ${BL}
	${GLCC} -c -cpu=4 -o $@ $<

${BL}%_5.o: %.c ${B}rcc
	-@mkdir -p ${BL}
	${GLCC} -c -cpu=5 -o $@ $<

${BL}%_6.o: %.c ${B}rcc
	-@mkdir -p ${BL}
	${GLCC} -c -cpu=6 -o $@  $<

clean: FORCE
	-rm ${OFILES}
	-for cpu in 4 5 6; do \
	   rm ${B}cpu$$cpu/libc.a ; \
	   rmdir ${B}cpu$$cpu ; \
	 done
	-rmdir ${BL}

install: FORCE
	for cpu in 4 5 6; do \
	  ${INSTALL} -d ${libdir}/cpu$$cpu/ ; \
	  ${INSTALL} -m 644 ${B}cpu$$cpu/libc.a ${libdir}/cpu$$cpu/libc.a ; \
	done


TSTCFILES=$(wildcard tst/TST*.c)
TSTO4FILES=${patsubst tst/%.c,${B}tst4/%.out,${TSTCFILES}}
TSTO5FILES=${patsubst tst/%.c,${B}tst5/%.out,${TSTCFILES}}

test: ${TSTO4FILES} ${TSTO5FILES}

%.out: %.gt1
	${GTSIM} $< > $@
	cmp $@ tst/`basename $@`

${B}tst4/%.gt1: tst/%.c FORCE
	test -d ${B}tst4 || mkdir ${B}tst4
	${GLCC} -map=sim -cpu=4 -o $@ $<

${B}tst5/%.gt1: tst/%.c FORCE
	test -d ${B}tst5 || mkdir ${B}tst5
	${GLCC} -map=sim -cpu=5 -o $@ $<

${B}tst6/%.gt1: tst/%.c FORCE
	test -d ${B}tst6 || mkdir ${B}tst6
	${GLCC} -map=sim -cpu=6 -o $@ $<

FORCE: .PHONY

.PHONY: 

