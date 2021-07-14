
def scope():

    # This is loaded to handle floating point exceptions

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

    # The following stubs define functions
    # _do{print|scan}_{long|float} that conditionally link and call
    # the actual implementation _do{print|scan}_{long|float}_imp if
    # the symbols '_@_using_fmov' or '_@_using_lmov' are defined,
    # indicating that floats or longs are actually used in the code.
    # This is useful because it prevents loading bulky long or float
    # code when it is not needed.
    #
    # This makes use of the weak symbol aliases '__glink_weak_xxx' and
    # the conditional import directive ('IMPORT', sym, 'IF', sym)
    # which are both implemented by glink.

    def code_doscan_float():
        nohop()
        label('_doscan_float')
        _LDI('__glink_weak__doscan_float_imp')
        _BEQ('.ret')
        STW(vLR);
        label('.ret')
        RET()

    module(name='_doscan_float.s',
           code=[ ('EXPORT', '_doscan_float'),
                  ('IMPORT', '_doscan_float_imp', 'IF', '_@_using_fmov'),
                  ('CODE', '_doscan_float', code_doscan_float) ] )

    def code_doscan_long():
        nohop()
        label('_doscan_long')
        _LDI('__glink_weak__doscan_long_imp')
        _BEQ('.ret')
        STW(vLR);
        label('.ret')
        RET()

    module(name='_doscan_long.s',
           code=[ ('EXPORT', '_doscan_long'),
                  ('IMPORT', '_doscan_long_imp', 'IF', '_@_using_lmov'),
                  ('CODE', '_doscan_long', code_doscan_long) ] )

    def code_doprint_float():
        nohop()
        label('_doprint_float')
        _LDI('__glink_weak__doprint_float_imp')
        _BEQ('.ret')
        STW(vLR);
        label('.ret')
        RET()

    module(name='_doprint_float.s',
           code=[ ('EXPORT', '_doprint_float'),
                  ('IMPORT', '_doprint_float_imp', 'IF', '_@_using_fmov'),
                  ('CODE', '_doprint_float', code_doprint_float) ] )

    def code_doprint_long():
        nohop()
        label('_doprint_long')
        _LDI('__glink_weak__doprint_long_imp')
        _BEQ('.ret')
        STW(vLR);
        label('.ret')
        RET()

    module(name='_doprint_long.s',
           code=[ ('EXPORT', '_doprint_long'),
                  ('IMPORT', '_doprint_long_imp', 'IF', '_@_using_lmov'),
                  ('CODE', '_doprint_long', code_doprint_long) ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
