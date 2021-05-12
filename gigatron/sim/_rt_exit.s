
def code0():
    tryhop(15, jump=False)
    label('_@_exit');
    LDWI(0xff00);STW('sysFn');SYS(34)
    label('.loop')
    BRA('.loop')

code=[
    ('EXPORT', '_@_exit'),
    ('CODE', '_@_exit', code0) ]
	
module(code=code, name='_rt_exit.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
