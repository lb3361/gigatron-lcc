# _exitm(int retcode, const char *msg)
# does not return

def code0():
    nohop()
    label('_exitm');
    LDWI(0xff00);STW('sysFn');SYS(34)
    HALT()
    
# ======== (epilog)
code=[
    ('EXPORT', '_exitm'),
    ('IMPORT', '_vsp'),
    ('CODE', '_exitm', code0) ]

module(code=code, name='_exitm.s');


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
