

def code0():
    nohop()
    label('ldexp')
    LDW(vLR);STW(R22)
    _FMOV(F8, FAC)
    LDW(R11)
    _FSCALB()
    LDW(R22);STW(vLR);RET()
    
code=[
    ('EXPORT', 'ldexp'),
    ('CODE', 'ldexp', code0) ]
	
module(code=code, name='ldexp.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
