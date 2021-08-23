
# this file contains a lot of stuff that has not clear place

def scope():

    # -----------------------------------------------
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

    # -----------------------------------------------
    # Floating point constants

    def code_fzero():
        label('_fzero')
        bytes(0,0,0,0,0) # 0.0F

    module(name='_fzero.s',
           code=[ ('EXPORT', '_fzero'),
                  ('DATA', '_fzero', code_fzero, 5, 1) ] )

    def code_fone():
        label('_fone')
        bytes(129,0,0,0,0) # 1.0F

    module(name='_fone.s',
           code=[ ('EXPORT', '_fone'),
                  ('DATA', '_fone', code_fone, 5, 1) ] )

    def code_fhalf():
        label('_fhalf')
        bytes(128,0,0,0,0) # 0.5F

    module(name='_fhalf.s',
           code=[ ('EXPORT', '_fhalf'),
                  ('DATA', '_fhalf', code_fhalf, 5, 1) ] )

    def code_ftwo():
        label('_ftwo')
        bytes(130,0,0,0,0) # 2.0F

    module(name='_fhalf.s',
           code=[ ('EXPORT', '_fhalf'),
                  ('DATA', '_fhalf', code_fhalf, 5, 1) ] )

    def code_fminus():
        label('_fminus')
        bytes(129,128,0,0,0) # -1.0F

    module(name='_fminus.s',
           code=[ ('EXPORT', '_fminus'),
                  ('DATA', '_fminus', code_fminus, 5, 1) ] )


    # -----------------------------------------------
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

    def code_doscan_double():
        nohop()
        label('_doscan_double')
        PUSH()
        LDWI('__glink_weak__doscan_double_imp');_BEQ('.ret')
        CALL(vAC)
        label('.ret')
        POP();RET()

    module(name='_doscan_double.s',
           code=[ ('EXPORT', '_doscan_double'),
                  ('IMPORT', '_doscan_double_imp', 'IF', '_@_using_fmov'),
                  ('CODE', '_doscan_double', code_doscan_double) ] )

    def code_doprint_double():
        nohop()
        label('_doprint_double')
        PUSH()
        LDWI('__glink_weak__doprint_double_imp');_BEQ('.ret')
        CALL(vAC)
        label('.ret')
        POP();RET()

    module(name='_doprint_double.s',
           code=[ ('EXPORT', '_doprint_double'),
                  ('IMPORT', '_doprint_double_imp', 'IF', '_@_using_fmov'),
                  ('CODE', '_doprint_double', code_doprint_double) ] )

    def code_doprint_long():
        nohop()
        label('_doprint_long')
        PUSH()
        LDWI('__glink_weak__doprint_long_imp');_BEQ('.ret')
        CALL(vAC)
        label('.ret')
        POP();RET()

    module(name='_doprint_long.s',
           code=[ ('EXPORT', '_doprint_long'),
                  ('IMPORT', '_doprint_long_imp', 'IF', '_@_using_lmov'),
                  ('CODE', '_doprint_long', code_doprint_long) ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
