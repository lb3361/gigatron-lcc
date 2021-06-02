
# LSHL : LAC <-- LAC << AC  (clobbers B0,T2,T3)
def code1():
    label('_@_lshl')
    PUSH()
    STW(B0);XORI(1);_BNE('.l2')        # fast path for shift by one
    _CALLJ('_@_lshl1');_BRA('.ret')
    label('.l2')
    LD(B0);ANDI(16);_BEQ('.l4')
    LDW(LAC);STW(LAC+2);LDI(0);STW(LAC)
    label('.l4')
    LD(B0);ANDI(8);_BEQ('.l5')
    LD(LAC+2);ST(LAC+3);LD(LAC+1);ST(LAC+2);LD(LAC);ST(LAC+1);LDI(0);ST(LAC)
    label('.l5')
    LD(B0);ANDI(4);_BEQ('.l6')
    LDWI('SYS_LSLW4_46');STW('sysFn')
    LDW(LAC+2);SYS(46);LD(vACH);ST(LAC+3)
    LDW(LAC+1);SYS(46);LD(vACH);ST(LAC+2)
    LDW(LAC);SYS(46);STW(LAC)
    label('.l6')
    LD(B0);ANDI(3);_BEQ('.ret')
    label('.l7')
    ST(B0);_CALLJ('_@_lshl1')
    LD(B0);SUBI(1);_BNE('.l7')
    label('.ret')
    tryhop(2);POP();RET()


code= [ ('EXPORT', '_@_lshl'),
        ('IMPORT', '_@_lshl1'),
        ('CODE', '_@_lshl', code1) ]

module(code=code, name='rt_lshl.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
