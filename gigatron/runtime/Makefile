# GNUmake required

SHELL=/bin/sh
TOP=../../
PREFIX=/usr/local
DESTDIR=
BUILDDIR=build
B=${TOP}${BUILDDIR}/
GLCC=${B}glcc

all: FORCE

clean: testclean FORCE

install: FORCE

TSTCFILES=$(wildcard tst/TST*.c)
TSTO4FILES=${patsubst tst/%.c,tst4/%.out,${TSTCFILES}}
TSTO5FILES=${patsubst tst/%.c,tst5/%.out,${TSTCFILES}}
GTSIM=${B}gtsim -rom ${TOP}../gigatron-rom/dev.rom

test: ${TSTO4FILES} ${TSTO5FILES}

testclean: FORCE
	-rm -rf tst4 tst5

tst4/%.out: tst4/%.gt1
	${GTSIM} $< > $@
	cmp $@ tst/`basename $@`

tst5/%.out: tst5/%.gt1
	${GTSIM} $< > $@
	cmp $@ tst/`basename $@`

tst4/%.gt1: tst/%.c FORCE
	test -d tst4 || mkdir tst4
	${GLCC} -map=sim -cpu=4 -o $@ $<

tst5/%.gt1: tst/%.c FORCE
	test -d tst5 || mkdir tst5
	${GLCC} -map=sim -cpu=5 -o $@ $<

FORCE: .PHONY

.PHONY: 
