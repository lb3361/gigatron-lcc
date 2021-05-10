

# LSHRU : LAC <-- LAC >> AC
def code0():
    tryhop(3)
    label('_@_lshru')
    STW(LACt)
    label('_@_lshru_lact')
    PUSH()
    LD(LACt);ANDI(16);_BEQ('.l4')
    LDW(LAC+2);STW(LAC);LDI(0);STW(LAC+2)
    label('.l4')
    LD(LACt);ANDI(8);_BEQ('.l5')
    LD(LAC+1);ST(LAC);LD(LAC+2);ST(LAC+1);LD(LAC+3);ST(LAC+2);LDI(0);ST(LAC+3)
    label('.l5')
    LD(LACt);ANDI(7);_BEQ('.ret');ST(LACt)
    LDW(LAC);STW(T3);LD(LACt);STW(T2);_CALLJ('_@_shru');STW(LAC)
    LDW(LAC+1);ORI(255);XORI(255);STW(T3);LD(LACt);STW(T2);_CALLJ('_@_shru');ORW(LAC+1);ST(LAC+1)
    LDW(LAC+2);STW(T3);LD(LACt);STW(T2);_CALLJ('_@_shru');STW(LAC+2)
    label('.ret')
    tryhop(2);POP();RET()


# LSHRU : LAC <-- LAC >> AC (signed) (clobbers T0)
def code1():
    label('_@_lshrs')
    PUSH();STW(LACt)
    LDW(LAC+2);_BLT('.s1')
    _CALLJ('_@_lshru_lact');_BRA('.sret')
    label('.s1')
    LDWI(0xffff);STW(T0);XORW(LAC);STW(LAC)
    LDW(T0);XORW(LAC+2);STW(LAC+2)
    _CALLJ('_@_lshru_lact')
    LDW(T0);XORW(LAC);STW(LAC)
    LDW(T0);XORW(LAC+2);STW(LAC+2)
    label('.sret')
    tryhop(2);POP();RET()
    

code= [ ('EXPORT', '_@_lshru'),
        ('EXPORT', '_@_lshrs'),
        ('IMPORT', '_@_shru'),
        ('CODE', '_@_lshru', code0),
        ('CODE', '_@_lshrs', code1) ]

module(code=code, name='_rt_lshl.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
