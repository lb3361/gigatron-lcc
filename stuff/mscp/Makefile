ROM=dev7
B=../../build/
CC=${B}glcc
GTSIM=${B}gtsim -rom ../../gigatron/roms/${ROM}.rom

PGMS=mscp-128k.gt1 mscp-sim.gt1 

all: ${PGMS}

clean:
	-rm ${PGMS}

run: mscp-sim.gt1
	$(GTSIM) -f mscp-sim.gt1

run-no-book: mscp-sim.gt1
	$(GTSIM) mscp-sim.gt1

mscp-sim.gt1: mscp.c
	${CC} -rom=${ROM} -map=sim,allout mscp.c -o $@
	echo "Execute with 'make run' or 'make run-no-book'"

mscp-128k.gt1: mscp.c
	${CC} -rom=${ROM} -map=128k mscp.c -o $@
