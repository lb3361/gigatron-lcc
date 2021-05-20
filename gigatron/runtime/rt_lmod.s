
# This is tightly related to _rt_ldiv.s
# but kept in a different module to prevent
# importing _rt_lshr.s if not needed

# LMODS: LAC % [vAC] -> LAC
# LMODU: LAC % [vAC] -> LAC
# - clobber B0-B2, T0-T3

def code1():
    label('_@_lmodu')
    # takes dividend in LAC
    # takes divisor in [vAC]
    # returns remainder in LAC
    # returns quotient in T0T1
    PUSH()
    STW(T3);DEEK();STW(T0);
    LDW(T3);ADDI(2);DEEK();STW(T1);
    ORW(T0);_BNE('.lmodu1')
    LDWI(0x0104);_CALLI('_@_raise')
    tryhop(2);POP();RET()
    label('.lmodu1')
    _CALLI('__@ldivu_t0t1')
    LDW(T2);STW(T0);LDW(T3);STW(T1)
    LD(B1);_CALLI('_@_lshru')
    tryhop(2);POP();RET()
    
def code2():
    label('_@_lmods')
    # takes dividend in LAC
    # takes divisor in [vAC]
    # returns remainder in LAC
    # returns quotient in T0T1
    PUSH()
    STW(T3);DEEK();STW(T0);
    LDW(T3);ADDI(2);DEEK();STW(T1);
    ORW(T0);_BNE('.lmods1')
    LDWI(0x0104);_CALLI('_@_raise')
    tryhop(2);POP();RET()
    label('.lmods1')
    _CALLI('__@ldivs_t0t1')
    LD(B1);_CALLI('_@_lshru')
    LD(B2);ANDI(2);_BEQ('.m1');_CALLJ('_@_lneg');label('.m1')
    tryhop(2);POP();RET()

   
code= [ ('CODE', '_@_lmodu', code1), 
        ('CODE', '_@_lmods', code2),
        ('EXPORT', '_@_lmodu'),
        ('EXPORT', '_@_lmods'),
        ('IMPORT', '_@_lshru'),
        ('IMPORT', '__@ldivu_t0t1'),
        ('IMPORT', '__@ldivs_t0t1') ]

module(code=code, name='rt_lmod.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
