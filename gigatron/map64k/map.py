
# ------------size----addr----step----end---- dataonly
segments = [ (0x0060, 0x08a0, 0x0100, 0x80a0, 0),
	     (0x00f4, 0x0206, None,   None,   1),
	     (0x00fa, 0x0300, 0x0100, 0x0500, 1),
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
    Generate extra modules for this map with functions:
      int _init0(void); 
         - init stack pointer; check rom and ram; return 0 on error.
      void _segments(void ((*cb)(unsigned,unsigned)) 
         - call cb for all segments in the map
    '''
    def code0():
        tryhop(25, jump=False)
        label('_init0')
        _LDI(initsp);STW(SP);
        LD('romType');ANDI(0xfc);SUBI(romtype or 0);BLT('.err')
        LD('memSize');BNE('.err')
        LDI(1);RET()
        label('.err')
        LDI(0);RET()
    def code1():
        label('_segments')
        tryhop(4);LDW(vLR);STW(R22);_SP(-10);STW(SP);_SAVE(4,0x4000c0); # R6-7,22
        LDW(R8); STW(R6)
        for (i,tp) in enumerate(segments):
            if tp[2] == None:
                _LDI(tp[0]);STW(R9);_LDI(tp[1]);ADDW(R9);STW(R8);CALL(R6)
            else:
                _LDI(tp[1]);STW(R7)
                label(f".L{i}")
                _LDI(tp[0]);STW(R9);LDW(R7);ADDW(R9);STW(R8);CALL(R6)
                _LDI(tp[2]);ADDW(R7);STW(R7);_LDI(tp[3]);XORW(R7);_BNE(f".L{i}")
        _RESTORE(4,0x4000c0);_SP(10);STW(SP);LDW(R22);tryhop(3);STW(vLR);RET();
        
    code=[ ('EXPORT', '_init0'),
           ('CODE', '_init0', code0),
           ('EXPORT', '_segments'),
           ('CODE', '_segments', code1) ]
           
    name='_map.s'
    debug(f"synthetizing module '{name}'")
    module(code=code, name=name);


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
