
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
    Generate extra modules for this map.
    The minimal module defines a function
       
        typedef void cb(unsigned s, unsigned e, (**cbpp)());
        void _segments(cb **cbpp) { 
          /* calls (**cbpp)() for each segment in the map */
        }

        int _init0(void) {
          /* initializes sp, checks rom and ram, return 0 if error */
    '''
    def code0():
        label('.callcb')
        PUSH()
        STW(R8)
        ADDW(R9);STW(R9)
        LDW(R6);STW(R7)
        DEEK();STW(T3);CALL(T3)
        POP();RET()
    def code1():
        label('_segments')
        tryhop(4);LDW(vLR);STW(R22);_SP(-12);STW(SP);_SAVE(6,0x4000c0); # R6-7,22
        LDW(R8); STW(R6)
        for (i,tp) in enumerate(segments):
            if tp[2] == None:
                _LDI(tp[0]);STW(R9);_LDI(tp[1]);CALLI('.callcb')
            else:
                _LDI(tp[1]);STW(R7)
                label(f".L{i}")
                _LDI(tp[0]);STW(R9);LDW(R7);CALLI('.callcb')
                _LDI(tp[2]);ADDW(R7);STW(R7);_LDI(tp[3]);XORW(R7);_BNE(f".L{i}")
        _RESTORE(6,0x4000c0);_SP(12);STW(SP);LDW(R22);tryhop(3);STW(vLR);RET();
    def code2():
        tryhop(25)
        label('_init0')
        LDWI(initsp);STW(SP);
        LD('romType');ANDI(0xfc);SUBI(romtype or 0);BLT('.err')
        LD('memSize');BNE('.err')
        LDI(1);RET()
        label('.err')
        LDI(0);RET()

    code=[ ('EXPORT', '_segments'),
           ('CODE', '.callcb', code0),
           ('CODE', '_segments', code1),
           ('EXPORT', '_init0'),
           ('CODE', '_init0', code2) ]
           
    name='_map.s'
    debug(f"synthetizing module '{name}'")
    module(code=code, name=name);


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
