def scope():

    def code0():
        nohop()
        label('ldexp')
        LDW(vLR);STW(R22)
        _FMOV(F8, FAC)
        LDW(R11)
        _FSCALB()
        LDW(R22);STW(vLR);RET()
        
    module(name='ldexp.s',
           code=[ ('EXPORT', 'ldexp'),
                  ('CODE', 'ldexp', code0) ] )
	


    def code0():
        nohop()
        label('frexp')
        LDW(vLR);STW(R22)
        LD(F8)
        BEQ('.zero')
        SUBI(128)
        DOKE(R11)
        LDI(128)
        ST(F8)
        BRA('.ret')
        label('.zero')
        LDI(0)
        DOKE(R11)
        label('.ret')
        _FMOV(F8,FAC)
        LDW(R22);STW(vLR);RET()

    module(name='frexp.s',
           code=[ ('EXPORT', 'frexp'),
                  ('CODE', 'frexp', code0) ] )
	
scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
