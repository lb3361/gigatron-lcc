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
ROM=../gigatron-rom/dev.rom
GTSIM=${B}gtsim -rom ${TOP}${ROM}

SUBDIRS=${G}runtime ${G}libc ${G}map32k ${G}map64k ${G}mapsim ${G}map32kx

FILES=${B}glcc ${B}glink ${B}glink.py ${B}interface.json ${B}roms.json

default: all

all: build-dir lcc-all gigatron-all
	${MAKE} subdirs-all

clean: lcc-clean gigatron-clean subdirs-clean build-dir-clean

install: all gigatron-install subdirs-install

test: all glcc-test subdirs-test
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

gigatron-all: gigatron-include ${FILES} 

gigatron-clean: FORCE
	-rm -rf ${FILES} ${B}include
	-rm -rf ${B}tst[0-9]

gigatron-install: FORCE
	-${INSTALL} -d ${libdir}
	${INSTALL} -m 755 "${B}cpp" "${libdir}/cpp"
	${INSTALL} -m 755 "${B}rcc" "${libdir}/rcc"
	${INSTALL} -m 755 "${B}lcc" "${libdir}/lcc"
	for n in ${FILES}; do \
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


TSTBK1FILES=$(wildcard ${G}tst/*.1bk)
TSTBK2FILES=$(wildcard ${G}tst/*.2bk)

TST0=${patsubst ${G}tst/%.2bk,${B}tst0/%.s, ${TSTBK2FILES}}
TST4=${patsubst ${G}tst/%.1bk,${B}tst4/%.out, ${TSTBK1FILES}}
TST5=${patsubst ${G}tst/%.1bk,${B}tst5/%.out, ${TSTBK1FILES}}
TST6=${patsubst ${G}tst/%.1bk,${B}tst6/%.out, ${TSTBK1FILES}}

%.out: %.gt1
	@echo "${GTSIM} $< >$@"
	@m="tst/$(*F).0"; test -r "$m" && ${GTSIM} $< > "$@" < "$m" || ${GTSIM} $< > "$@"
	cmp $@ ${G}tst/$(*F).1bk

${B}tst0/%.s: tst/%.c FORCE
	test -d ${B}tst0 || mkdir ${B}tst0
	-${GLCC} -S -o $@  $< 2>"${B}tst0/$(*F).out"
	cmp "${B}tst0/$(*F).out" "${G}tst/$(*F).2bk"
	[ ! -r "${G}tst/$(*F).sbk" ] || cmp $@ "${G}tst/$(*F).sbk"

${B}tst4/%.gt1: tst/%.c FORCE
	test -d ${B}tst4 || mkdir ${B}tst4
	${GLCC} -map=sim -cpu=4 -o $@ $< 2>"${B}tst0/$(*F).out"

${B}tst5/%.gt1: tst/%.c FORCE
	test -d ${B}tst5 || mkdir ${B}tst5
	${GLCC} -map=sim -cpu=5 -o $@ $< 2>"${B}tst0/$(*F).out"

${B}tst6/%.gt1: tst/%.c FORCE
	test -d ${B}tst6 || mkdir ${B}tst6
	${GLCC} -map=sim -cpu=6 -o $@ $< 2>"${B}tst0/$(*F).out"

glcc-test: ${TST0} ${TST4} ${TST5}


FORCE: .PHONY

.PHONY:



