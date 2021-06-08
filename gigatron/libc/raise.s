
def scope():

    def code0():
        nohop()
        label('raise')
        LDW(R8);ANDI(0xf8);BEQ('.raise1');
        _LDI(0xffff);RET()                                   # err
        label('.raise1')
        LDW(R8)
        label('_@_raise')
        STLW(-2);
        label('_raise_disposition', pc()+1)
        LDWI(0)
        BEQ('.raise2')
        STW(T3);LDW(vLR);DOKE(SP);LDLW(-2);CALL(T3);   # dispatcher (no return)
        label('.raise2')
        LDLW(-2);ST(R8);LD(vACH);STW(R9);
        LD(R8);STW(R8);_CALLJ('_exits')                # exit (no return)

    module(name='raise.s',
           code=[ ('IMPORT', '_exits'),
                  ('EXPORT', 'raise'),
                  ('EXPORT', '_@_raise'),
                  ('EXPORT', '_raise_disposition'),
                  ('CODE', 'raise', code0) ] )

    def code1():
        nohop()
        label('_raise_sets_code')
        _LDI('_raise_code');STW(T3)
        LDLW(-2);DOKE(T3)
        LDW(SP);DEEK();STW(vLR);RET()
        align(2);
        label('_raise_code')
        words(0)

    module(name='raise_sets_code.s',
           code=[ ('EXPORT', '_raise_sets_code'),
                  ('EXPORT', '_raise_code'),
                  ('CODE', '_raise_sets_code', code1) ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
