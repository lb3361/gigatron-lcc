

def code0():
    nohop()
    label('frexp')
    LDW(vLR);STW(R22)
    LD(F8)
    BEQ('.zero')
    SUBI(128)
    DOKE(R11)
    LDI(128)
    ST(F8)
    BRA('.ret')
    label('.zero')
    LDI(0)
    STW(F8)
    STW(F8+2)
    STW(F8+4)
    DOKE(R11)
    label('.ret')
    _FMOV(F8,FAC)
    LDW(R22);STW(vLR);RET()
    
code=[
    ('EXPORT', 'frexp'),
    ('CODE', 'frexp', code0) ]
	
module(code=code, name='frexp.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
