
def code0():
    align(2)
    label('_@_SIGFPE')
    space(2)

def code1():
    label('.msg')
    bytes(b'Division by zero', 0)

def code2():
    nohop()
    label('_@_raise_sigdiv')
    LDWI('_@_SIGFPE');STW(T0);DEEK();BEQ('.z2');STW(T1)
    LDW(0);DOKE(T0) # reset SIGFPE to default
    LDI(1);STW(R9)  # FPE_INTDIV
    LDI(8);STW(R8)  # SIGFPE
    CALL(T1)
    # Continue with results returned by the signal
    POP();RET()
    label('.z2')
    # exit with return code 20
    LDI(20);STW(R8);LDWI('.msg');STW(R9)
    _CALLJ('_exitm');HALT()

code= [ ('EXPORT', '_@_raise_sigdiv'),
        ('IMPORT', '_exitm'),
        ('COMMON', '_@_SIGFPE',  code0, 2, 2),
        ('DATA', '.msg', code1, 0, 1),
        ('CODE', '_@_raise_sigdiv', code2) ]

module(code=code, name='rt_sigdiv.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
