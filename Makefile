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
GLCC=${B}glcc
GTSIM=${B}gtsim

SUBDIRS=${G}runtime ${G}libc ${G}map32k ${G}map64k ${G}mapsim ${G}mapconx
GFILES=${B}glcc ${B}glink ${B}glink.py ${B}interface.json ${B}roms.json
ROMFILES=${wildcard ${G}roms/*.rom}
ROMS=${patsubst ${G}roms/%.rom,%,${ROMFILES}}

default: all

all: build-dir lcc-all gigatron-all
	${MAKE} subdirs-all

clean: lcc-clean gigatron-clean subdirs-clean build-dir-clean

install: all gigatron-install subdirs-install

test: all
	@for rom in ${ROMS}; do \
	    printf "+----------------------------------+\n"; \
	    printf "|  Compiling for rom: %-8s     |\n" $$rom; \
	    printf "+----------------------------------+\n"; \
	    ${MAKE} ROM=$$rom glcc-test subdirs-test || exit; \
	 done
	@echo "+----------------------------------+"
	@echo "|  Test sequence ran successfully! |"
	@echo "+----------------------------------+"

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
		"CFLAGS=${CFLAGS}" \
		"LDFLAGS=${LDFLAGS}" \
		"ROM=${ROM}" \
		`echo $@ | sed -e 's/^subdirs-//'` || exit; \
	   done

gigatron-all: gigatron-include ${GFILES} 

gigatron-clean: FORCE
	-rm -rf ${GFILES} ${B}include
	-rm -rf ${B}tst[0-9]

gigatron-install: FORCE
	-${INSTALL} -d ${libdir}
	${INSTALL} -m 755 "${B}cpp" "${libdir}/cpp"
	${INSTALL} -m 755 "${B}rcc" "${libdir}/rcc"
	${INSTALL} -m 755 "${B}lcc" "${libdir}/lcc"
	for n in ${GFILES}; do \
	    mode=644; test -x "$$n" && mode=755 ; \
	    ${INSTALL} -m $$mode "$$n" ${libdir}/ ; done
	-${INSTALL} -d "${libdir}/include"
	for n in "${B}include/"*.h ; do \
	    ${INSTALL} -m 0644 "$$n" "${libdir}/include/" ; done
	-${INSTALL} -d "${libdir}/include/gigatron"
	for n in "${B}include/gigatron/"*.h ; do \
	    ${INSTALL} -m 0644 "$$n" "${libdir}/include/gigatron/" ; done
	-${INSTALL} -d ${bindir}
	${LN_S} ${libdir}/glcc ${bindir}/glcc
	${LN_S} ${libdir}/glink ${bindir}/glink

gigatron-include: FORCE
	-mkdir -p ${B}include
	cp -r ${TOP}include/gigatron/* ${B}/include/

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


GTSIMR=${GTSIM} -rom ${G}roms/${ROM}.rom
TSTBK1FILES=$(wildcard ${G}tst/*.1bk)
TSTBK2FILES=$(wildcard ${G}tst/*.2bk)
TSTX=${patsubst ${G}tst/%.1bk,${B}tst/%.gt1, ${TSTBK1FILES}}
TSTO=${patsubst ${G}tst/%.1bk,${B}tst/%.xx1, ${TSTBK1FILES}}

ifeq (${ROM},dev)
TSTS=${patsubst ${G}tst/%.2bk,${B}tst/%.s, ${TSTBK2FILES}}
endif

glcc-test: ${TSTS} ${TSTO}

${B}tst/%.s: tst/%.c FORCE
	@test -d ${B}tst || mkdir ${B}tst
	-${GLCC} -S -rom=${ROM} -o $@  $< 2>"${B}tst/$(*F).xx2"
	cmp "${B}tst/$(*F).xx2" "${G}tst/$(*F).2bk"
	[ ! -r "${G}tst/$(*F).sbk" ] || cmp $@ "${G}tst/$(*F).sbk"

${B}tst/%.gt1: tst/%.c FORCE
	@test -d ${B}tst || mkdir ${B}tst
	${GLCC} -map=sim,over -rom=${ROM} -o $@ $< 2>"${B}tst/$(*F).xx2"

${B}tst/%.xx1: ${B}tst/%.gt1 FORCE
	${GTSIMR} $< > "$@" < "tst/$(*F).0"
	cmp $@ ${G}tst/$(*F).1bk


sbk-test:


FORCE: .PHONY

.PHONY:



