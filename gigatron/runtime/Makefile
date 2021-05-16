# GNUmake required

SHELL=/bin/sh
TOP=../../
PREFIX=/usr/local
DESTDIR=
BUILDDIR=build
B=${TOP}${BUILDDIR}/
GLCC=${B}glcc
ROM=../gigatron-rom/dev.rom
GTSIM=${B}gtsim -rom ${TOP}${ROM}

all: FORCE

clean: FORCE

install: FORCE

TSTCFILES=$(wildcard tst/TST*.c)
TSTO4FILES=${patsubst tst/%.c,${B}tst4/%.out,${TSTCFILES}}
TSTO5FILES=${patsubst tst/%.c,${B}tst5/%.out,${TSTCFILES}}

test: ${TSTO4FILES} ${TSTO5FILES}

%.out: %.gt1
	${GTSIM} $< > $@
	cmp $@ tst/$(@F)

${B}tst4/%.gt1: tst/%.c FORCE
	test -d ${B}tst4 || mkdir ${B}tst4
	${GLCC} -map=sim -cpu=4 -o $@ $<

${B}tst5/%.gt1: tst/%.c FORCE
	test -d ${B}tst5 || mkdir ${B}tst5
	${GLCC} -map=sim -cpu=5 -o $@ $<

${B}tst6/%.gt1: tst/%.c FORCE
	test -d ${B}tst5 || mkdir ${B}tst5
	${GLCC} -map=sim -cpu=5 -o $@ $<

FORCE: .PHONY

.PHONY: 
