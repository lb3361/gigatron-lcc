
# double copysign(double, double);

def code0():
    nohop()
    label('copysign')
    LDW(vLR);STW(R22)
    LD(F8+1);XORW(F11+1);ANDI(0x80);XORW(F8+1);ST(F8+1)
    _FMOV(F8,FAC)
    LDW(R22);STW(vLR);RET()
    
code=[
    ('EXPORT', 'copysign'),
    ('CODE', 'copysign', code0) ]
	
module(code=code, name='copysign.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
