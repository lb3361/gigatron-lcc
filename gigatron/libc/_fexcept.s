
def scope():

    ##  return _fexception(defval)
    def code0():
        label('_fexception')
        PUSH()
        _FMOV(F8,FAC)
        _LDI(0x304);STW(R8)
        _CALLJ('raise')
        tryhop(2);POP();RET()

    module(name='_fexception.s',
           code=[ ('EXPORT', '_fexception'),
                  ('IMPORT', 'raise'),
                  ('CODE', '_fexception', code0) ] )

    ##  return _foverflow(defval)
    def code1():
        label('_foverflow')
        PUSH()
        _FMOV(F8,FAC)
        _LDI(0x404);STW(R8)
        _CALLJ('raise')
        tryhop(2);POP();RET()

    module(name='_foverflow.s',
           code=[ ('EXPORT', '_foverflow'),
                  ('IMPORT', 'raise'),
                  ('CODE', '_foverflow', code1) ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
