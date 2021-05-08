
def code0():
    nohop()
    label('_@_exit');
    # Just flashes a pixel on the first line
    # at a position indicative of the return code
    ANDI(0x7f)
    STW(R8)
    LDWI(0x800)
    ADDW(R8)
    label('.loop')
    POKE(R8)
    ADDI(1)
    BRA('.loop')

code=[
    ('EXPORT', '_@_exit'),
    ('CODE', '_@_exit', code0) ]
	
module(code=code, name='_rt_exit.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
