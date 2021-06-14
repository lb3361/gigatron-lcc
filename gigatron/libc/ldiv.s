
# ldiv_t ldiv(long a, long q)

def code0():
    label('ldiv')
    tryhop(4);LDW(vLR);STW(R22)
    _LMOV(L9,LAC);LDI(L11);_LMODS()
    # save quotient
    LDW(T0);DOKE(R8);
    LDI(2);ADDW(R8);STW(T3);LDW(T1);DOKE(T3);
    # save remainder
    LDI(4);ADDW(R8);STW(T3);LDW(LAC);DOKE(T3);
    LDI(6);ADDW(R8);STW(T3);LDW(LAC+2);DOKE(T3);
    # return
    LDW(R22);tryhop(3);STW(vLR);RET()
    
# ======== (epilog)
code=[
    ('EXPORT', 'ldiv'),
    ('CODE', 'ldiv', code0),
    ('IMPORT', '_@_lmods') ]

module(code=code, name='ldiv.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
