
# This is tightly related to _rt_ldiv.s
# but kept in a different module to prevent
# importing _rt_lshr.s if not needed

# LMODS: LAC % [vAC] -> LAC
# LMODU: LAC % [vAC] -> LAC
# - clobber B0-B2, T0-T3

def code1():
    label('_@_lmodu')
    PUSH()
    _CALLI('_@_ldivu')
    LDW(T0);STW(LAC);LDW(T0+2);STW(LAC+2)
    LD(B1);
    _CALLI('_@_lshru')
    tryhop(2);POP();RET()
    
def code2():
    label('_@_lmods')
    PUSH()
    _CALLI('_@_ldivs')
    LDW(T0);STW(LAC);LDW(T0+2);STW(LAC+2)
    LD(B1);_CALLI('_@_lshru')
    LD(B2);ANDI(2);_BEQ('.m1');_CALLJ('_@_lneg');label('.m1')
    tryhop(2);POP();RET()

# ldiv_t *_ldivmod(ldiv_t*,int a, int q)

def code3():
    label('_ldivmod')
    tryhop(4);LDW(vLR);STW(R22)
    _LMOV(L9,LAC);LDI(L11);_CALLI('_@_ldivs')
    # save quotient
    LDW(LAC);DOKE(R8);
    LDI(2);ADDW(R8);STW(T3);LDW(LAC+2);DOKE(T3);
    # compute remainder
    LDW(T0);STW(LAC);LDW(T0+2);STW(LAC+2)
    LD(B1);_CALLI('_@_lshru')
    LD(B2);ANDI(2);_BEQ('.m2');_CALLJ('_@_lneg');label('.m2')
    # save remainder
    LDI(4);ADDW(R8);STW(T3);LDW(LAC);DOKE(T3);
    LDI(6);ADDW(R8);STW(T3);LDW(LAC+2);DOKE(T3);
    # return
    LDW(R22);tryhop(5);STW(vLR);LDW(R8);RET()
   
   
code= [ ('CODE', '_@_lmodu', code1), 
        ('CODE', '_@_lmods', code2),
        ('CODE', '_ldivmod', code3),
        ('EXPORT', '_@_lmodu'),
        ('EXPORT', '_@_lmods'),
        ('EXPORT', '_ldivmod'),
        ('IMPORT', '_@_lshru'),
        ('IMPORT', '_@_ldivu'),
        ('IMPORT', '_@_ldivs') ]

module(code=code, name='rt_lmod.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
