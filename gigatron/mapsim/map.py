
def map_describe():
    print('''  Memory map 'sim' targets the simulator 'gtsim'.
             
  Code and data are placed as with memory map '64k'.  The memory map
  causes the linker to load library 'libsim' which overrides various
  libc components. Function 'printf' is directly executed by gtsim and
  prints to gtsim's standard output and function '_exitm' exits
  gtsim. It is expected that libsim will eventually delegate all stdio
  operations to gtsim.  This particularly useful for the glcc test
  suite.  ''')


# ------------size----addr----step----end---- flags (1=nocode, 2=nodata)
segments = [ (0x0060, 0x08a0, 0x0100, 0x80a0, 0),
	     (0x00fa, 0x0200, 0x0100, 0x0500, 1),
	     (0x0200, 0x0500, None,   None,   1),
             (0x0100, 0x8100, None,   None,   0),
	     (0x7000, 0x8240, None,   None,   0)   ]

initsp = 0xfffe
minram = 0x100

def map_segments():
    '''
    Enumerate all segments as tuples (saddr, eaddr, dataonly)
    '''
    global segments
    for tp in segments:
        estep = tp[2] or 1
        eaddr = tp[3] or (tp[1] + estep)
        for addr in range(tp[1], eaddr, estep):
            yield (addr, addr+tp[0], tp[4])

def map_extra_libs(romtype):
    '''
    Returns a list of extra libraries to scan before the standard ones
    '''
    return [ 'sim' ]

def map_extra_modules(romtype):
    '''
    Generate an extra modules for this map. At the minimum this should
    define a function '_gt1exec' that sets the stack pointer,
    checks the rom and ram size, then calls v(args.e). This is ofen
    pinned at address 0x200.
    '''
    def code0():
        nohop()
        label('_gt1exec')
        _LDI(initsp);STW(SP);
        LD('romType');ANDI(0xfc);SUBI(romtype or 0);BLT('.err')
        _LDI(v(args.e));CALL(vAC)
        label('.err')
        LDI(100);STW(R8)
        LDI('.msg');STW(R9)
        LDWI(0xff00);STW('sysFn');SYS(34);HALT()
        label('.msg')
        bytes(b'Machine check failed',0)

    module(name='_gt1exec.s',
           code=[ ('EXPORT', '_gt1exec'),
                  ('IMPORT', '_exit'),
                  ('CODE', '_gt1exec', code0) ] )

    debug(f"synthetizing module '_gt1exec.s'")


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
