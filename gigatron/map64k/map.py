
# ------------size----addr----step----end---- dataonly
segments = [ (0x0060, 0x08a0, 0x0100, 0x80a0, 0),
	     (0x00fa, 0x0200, 0x0100, 0x0500, 1),
	     (0x0200, 0x0500, None,   None,   1),
	     (0x8000, 0x8000, None,   None,   0)   ]

initsp = 0x0000
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
    return []

def map_extra_modules(romtype):
    '''
    Generate an extra modules for this map with at least a function
    _init0() that initializes the stack pointer, checks the rom
    version, checks the ram configuration, and returns 0 if all goes well.
    '''
    def code0():
        tryhop(25, jump=False)
        label('_init0')
        _LDI(initsp);STW(SP);
        LD('romType');ANDI(0xfc);SUBI(romtype or 0);BLT('.err')
        LD('memSize');BNE('.err')
        LDI(0);RET()
        label('.err')
        LDI(1);RET()
    code=[ ('EXPORT', '_init0'), ('CODE', '_init0', code0) ]
    name='_map.s'
    debug(f"synthetizing module '{name}'")
    module(code=code, name=name);


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
