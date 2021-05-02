
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
        LDW(R28);STW(R10)
        DEEK();STW(T3);CALL(T3)
        POP();RET()
        
    def code1():
        label('_segments')
        LDW(vLR);STW(LR);_SP(-12);STW(SP);
        _SP(6);_MOV(R28,[vAC]);_SP(8);_MOV(R29,[vAC]);_SP(10);_MOV(LR,[vAC])
        LDW(R8); STW(R28)
        for (i,tp) in enumerate(segments):
            if tp[2] == None:
                LDWI(tp[0]);STW(R9);LDW(tp[1]);CALLI('.callcb')
            else:
                LDWI(tp[1]);STW(R29)
                label(f".L{i}")
                LDWI(tp[0]);STW(R9);LDW(R29);CALLI('.callcb')
                LDWI(tp[2]);ADDW(R29);STW(R29);LDWI(tp[3]);XORW(R29);BNE(f".L{i}")
        _SP(6);_MOV([vAC],R28);_SP(8);_MOV([vAC],R29);_SP(10);_MOV([vAC],LR)
        _SP(10);STW(SP);LDW(LR);STW(vLR);RET();
    code=[ ('EXPORT', '_segments'),
           ('CODE', '_prep', code0),
           ('CODE', '_segments', code1) ]
    name='_map.s'
    debug(f"synthetizing module '{name}'")
    module(code=code, name=name);


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
