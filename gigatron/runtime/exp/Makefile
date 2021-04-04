SHELL=/bin/sh
GLCC=../../../build/glcc

ALLS=mul.s
ALLT=test-mul

all: all-s all-t run-t

all-s: ${ALLS}

all-t: ${ALLT}

run-t:
	for n in ${ALLT}; do echo -n "** $$n: " ; "./$$n" && echo 'ok' || echo 'failed' ; done

%.s: %.c common.h
	${GLCC} -S -Wf-g,#### $<

test-%: %.c common.h
	${CC} -DTEST -o $@ $< -lm
	./$@

clean:
	-rm ${ALLS}
	-rm ${ALLT}

