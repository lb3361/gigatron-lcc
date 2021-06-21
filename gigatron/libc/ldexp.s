def scope():

    def code0():
        nohop()
        label('ldexp')
        PUSH()
        _FMOV(F8, FAC)
        LDW(R11)
        _FSCALB()
        POP();RET()
        
    module(name='ldexp.s',
           code=[ ('EXPORT', 'ldexp'),
                  ('CODE', 'ldexp', code0) ] )
	


    def code0():
        nohop()
        label('frexp')
        PUSH()
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
        POP();RET()

    module(name='frexp.s',
           code=[ ('EXPORT', 'frexp'),
                  ('CODE', 'frexp', code0) ] )
	
scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
