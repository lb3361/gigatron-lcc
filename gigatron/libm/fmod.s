
def scope():
    
    def code0():
        nohop()
        label('fmod')
        LDW(vLR);STW(R22)
        _FMOV(F8, FAC)
        LDI(F11);_CALLI('_@_fmod')
        LDW(R22);STW(vLR);RET()

    module(name='fmod.s',
           code=[ ('EXPORT', 'fmod'),
                  ('IMPORT', '_@_fmod'),
                  ('CODE', 'fmod', code0) ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
