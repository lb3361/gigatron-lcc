
def scope():

    def code0():
        nohop()
        label('_fexception')
        PUSH();_FMOV(F8,FAC)
        _LDI(0x304);BRA('.3')
        label('_foverflow')
        PUSH();_FMOV(F8,FAC)
        _LDI(0x204);STW(T3);BRA('.1')
        label('_@_raisefpe')
        STW(T3);LDWI(0x204);XORW(T3);BNE('.2')
        label('.1')
        _LDI('errno');STW(T2);LDI(2);POKE(T2);  # set errno=ERANGE on overflow.
        label('.2')
        LDW(T3);
        label('.3')
        _CALLI('_@_raise')
        POP();RET()

    module(name='_@_raisefpe.s',
           code=[ ('EXPORT', '_@_raisefpe'),
                  ('EXPORT', '_fexception'),
                  ('EXPORT', '_foverflow'),
                  ('IMPORT', '_@_raise'),
                  ('IMPORT', 'errno'),
                  ('CODE', '_@_raisefpe', code0) ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
