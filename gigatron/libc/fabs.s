
# double copysign(double, double);

def code0():
    nohop()
    label('fabs')
    LDW(vLR);STW(R22)
    LD(F8+1);ANDI(127);ST(F8+1)
    _FMOV(F8, FAC)
    LDW(R22);STW(vLR);RET()
    
code=[
    ('EXPORT', 'fabs'),
    ('CODE', 'fabs', code0) ]
	
module(code=code, name='fabs.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
