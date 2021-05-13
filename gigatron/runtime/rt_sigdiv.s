
def code0():
    align(2)
    label('_@_SIGdiv')
    space(2)

def code1():
    label('.msg')
    bytes(b'Division by zero', 0)

def code2():
    nohop()
    label('_@_raise_sigdiv')
    _LDW('_@_SIGdiv');BEQ('.z2')
    # call _@_SIGdiv if nonzero
    STW(T0);CALL(T0)
    label('.z2')
    # exit with return code 100
    LDI(20);STW(R8);LDWI('.msg');STW(R9)
    _CALLJ('_exitm');HALT()

code= [ ('EXPORT', '_@_raise_sigdiv'),
        ('IMPORT', '_exitm'),
        ('COMMON', '_@_SIGdiv',  code0, 2, 2),
        ('DATA', '.msg', code1, 0, 1),
        ('CODE', '_@_raise_sigdiv', code2) ]

module(code=code, name='_rt_sigdiv.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
