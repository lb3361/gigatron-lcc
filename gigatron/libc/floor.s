
def scope():
    
    def code0():
        nohop()
        label('modf')
        LDW(vLR);STW(R22)
        _FMOV(F8, FAC)
        _CALLJ('_@_frndz')
        LDW(R11)
        _FMOV(FAC, [vAC])
        _FNEG();_LDI(F8);_FADD()
        LDW(R22);STW(vLR);RET()

    module(name='modf.s',
           code=[ ('EXPORT', 'modf'),
                  ('IMPORT', '_@_frndz'),
                  ('CODE', 'modf', code0) ] )

    SIGN = 0x81   # sign byte
    EXP = 0x82    # exponent
    
    def code0():
        nohop()
        label('floor')
        LDW(vLR);STW(R22)
        _FMOV(F8, FAC)
        _CALLJ('_@_frndz')
        LDI(F8);_FCMP();_BLE('.ret')
        _LDI('_@_fone');_FSUB()
        label('.ret')
        LDW(R22);STW(vLR);RET()
    
    module(name='floor.s',
           code=[ ('EXPORT', 'floor'),
                  ('IMPORT', '_@_frndz'),
                  ('IMPORT', '_@_fone'),
                  ('CODE', 'floor', code0) ] )

    def code0():
        nohop()
        label('ceil')
        LDW(vLR);STW(R22)
        _FMOV(F8, FAC)
        _CALLJ('_@_frndz')
        LDI(F8);_FCMP();_BGE('.ret')
        _LDI('_@_fone');_FADD()
        label('.ret')
        LDW(R22);STW(vLR);RET()
    
    module(name='ceil.s',
           code=[ ('EXPORT', 'ceil'),
                  ('IMPORT', '_@_frndz'),
                  ('IMPORT', '_@_fone'),
                  ('CODE', 'ceil', code0) ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End: