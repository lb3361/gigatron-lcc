
# LSHL1 : LAC <<= 1

def code0():
    nohop()
    label('_@_lshl1')
    LDW(LAC);BLT('.l1')
    LSLW();STW(LAC);LDW(LAC+2);LSLW();STW(LAC+2);RET()
    label('.l1')
    LSLW();STW(LAC);LDW(LAC+2);LSLW();ORI(1);STW(LAC+2);RET()
    
def code1():
    label('_@_lshl')
    PUSH()
    STW(LACt);XORI(1);_BNE('.l2')        # fast path for shift by one
    _CALLJ('_@_lshl1');_BRA('.ret')
    label('.l2')
    LD(LACt);ANDI(16);_BEQ('.l4')
    LDW(LAC);STW(LAC+2);LDI(0);STW(LAC)
    label('.l4')
    LD(LACt);ANDI(8);_BEQ('.l5')
    LD(LAC+2);ST(LAC+3);LD(LAC+1);ST(LAC+2);LD(LAC);ST(LAC+1);LDI(0);ST(LAC)
    label('.l5')
    LD(LACt);ANDI(7);_BEQ('.ret');ST(LACt)
    LDW(LAC+2);STW(T3);LD(LACt);STW(T2);_CALLJ('_@_shl');STW(LAC+2)
    LD(LAC+1);STW(T3);LD(LACt);STW(T2);_CALLJ('_@_shl');LD(vACH);ORW(LAC+2);STW(LAC+2)
    LDW(LAC);STW(T3);LD(LACt);STW(T2);_CALLJ('_@_shl');STW(LAC)
    label('.ret')
    tryhop(2);POP();RET()


code= [ ('EXPORT', '_@_lshl1'),
        ('EXPORT', '_@_lshl'),
        ('IMPORT', '_@_shl'),
        ('CODE', '_@_lshl1', code0),
        ('CODE', '_@_lshl', code1) ]

module(code=code, name='_rt_lshl.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
