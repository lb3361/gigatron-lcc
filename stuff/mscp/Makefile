ROM=dev7
B=../../build/
CC=${B}glcc
CFLAGS=-map=sim,allout -rom=${ROM}
GTSIM=${B}gtsim -rom ../../gigatron/roms/${ROM}.rom

mscp.gt1: mscp.c
	${CC} ${CFLAGS} mscp.c -o $@
	echo "Execute with 'make run' or 'make run-no-book'"

clean:
	-rm mscp.gt1

run: mscp.gt1
	$(GTSIM) -f mscp.gt1

run-no-book: mscp.gt1
	$(GTSIM) mscp.gt1
