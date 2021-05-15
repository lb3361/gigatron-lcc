
# SHRU1 : AC <-- AC >> 1
def code0():
    nohop()
    label('_@_shru1')
    STW(T3); LDWI('SYS_LSRW1_48'); STW('sysFn'); LDW(T3)
    SYS(48)
    RET()
    label('_@_shrs1')
    BGE('_@_shru1')
    STW(T3); LDWI('SYS_LSRW1_48'); STW('sysFn'); LDWI(0x8000); STW(T2); LDW(T3)
    SYS(48); ORW(T2)
    RET()

    
code= [ ('EXPORT', '_@_shru1'),
        ('EXPORT', '_@_shrs1'),
        ('CODE', '_@_shru1', code0) ]

module(code=code, name='rt_shr1.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
