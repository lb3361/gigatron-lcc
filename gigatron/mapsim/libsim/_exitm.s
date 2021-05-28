# _exitm(int retcode, const char *msg)
# does not return

def code0():
    nohop()
    label('_exitm');
    LDWI(0xff00);STW('sysFn');SYS(34)
    label('_exitvsp', pc()+1)
    LDI(0);ST(vSP)
    HALT()
    
# ======== (epilog)
code=[
    ('EXPORT', '_exitm'),
    ('EXPORT', '_exitvsp'),
    ('CODE', '_exitm', code0) ]

module(code=code, name='_exitm.s');


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
