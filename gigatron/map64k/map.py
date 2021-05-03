
# ------------size----addr----step----end---- dataonly
segments = [ (0x0060, 0x08a0, 0x0100, 0x8000, 0),
	     (0x00f4, 0x0206, None,   None,   1),
	     (0x00fa, 0x0300, 0x0100, 0x0500, 1),
	     (0x0200, 0x0500, None,   None,   1),
	     (0x8000, 0x8000, None,   None,   0)   ]


def map_segments():
    global segments
    for tp in segments:
        eaddr = tp[3] or (tp[1] + 1)
        estep = tp[2] or 1
        for addr in range(tp[1], eaddr, estep):
            yield (tp[0], addr, tp[4])

def map_sp():
    return 0x0000

def map_ram():
    return 0x0000

def map_extra_libs():
    return []

def map_extra_symdefs():
    return {}

def map_extra_modules():
    '''Generate extra modules for this map.
       The minimal module defines a function
       
        typedef void cb(unsigned s, unsigned e, (**cbpp)());
        void _segments(cb **cbpp) { .. }

        that alls (**cbpp)() for each segment in the map.'''
    
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
                LDWI(tp[0]);STW(R9);LDW(tp[1]);CALLI('.callcb')
            else:
                LDWI(tp[1]);STW(R7)
                label(f".L{i}")
                LDWI(tp[0]);STW(R9);LDW(R7);CALLI('.callcb')
                LDWI(tp[2]);ADDW(R7);STW(R7);LDWI(tp[3]);XORW(R7);BNE(f".L{i}")
        _RESTORE(6,0x4000c0);_SP(12);STW(SP);LDW(R22);tryhop(3);STW(vLR);RET();
    code=[ ('EXPORT', '_segments'),
           ('CODE', '.callcb', code0),
           ('CODE', '_segments', code1) ]
    name='_map.s'
    debug(f"synthetizing module '{name}'")
    module(code=code, name=name);


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
