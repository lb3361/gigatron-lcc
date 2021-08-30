
# this file contains a lot of stuff that has not clear place

def scope():

    # -----------------------------------------------
    # This is loaded to handle division by zero exceptions

    def code0():
        nohop()
        label('_@_raise_zdiv')
        LDWI('.msg');STW(T3)
        LDWI(0x104)
        _CALLI('__@raisem')
        POP();RET()

    def code0m():
        label('.msg') # "Division by zero"
        bytes(68,105,118,105,115,105,111,110);
        bytes(32,98,121,32,122,101,114,111);
        bytes(0);

    module(name='raise_zdiv.s',
           code=[ ('IMPORT', '__@raisem'),
                  ('EXPORT', '_@_raise_zdiv'),
                  ('CODE', '_@_raise_zdiv', code0),
                  ('DATA', '.msg', code0m, 0, 1) ] )

    def code1():
        nohop()
        label('_fexception')
        PUSH();_FMOV(F8,FAC);
        label('_@_raise_ferr')
        LDWI('.msg');STW(T3)
        LDWI(0x304)
        _CALLI('__@raisem')
        POP();RET()

    def code1m():
        label('.msg') # "Floating point exception"
        bytes(70,108,111,97,116,105,110,103);
        bytes(32,112,111,105,110,116,32,101);
        bytes(120,99,101,112,116,105,111,110);
        bytes(0);

    module(name='_fexception.s',
           code=[ ('IMPORT', '__@raisem'),
                  ('EXPORT', '_fexception'),
                  ('EXPORT', '_@_raise_ferr'),
                  ('CODE', '_fexception', code1),
                  ('DATA', '.msg', code1m, 0, 1) ] )

    def code2():
        nohop()
        label('_foverflow')
        PUSH();_FMOV(F8,FAC);
        label('_@_raise_fovf')
        _LDI('errno');STW(T2);LDI(2);POKE(T2);  # set errno=ERANGE on overflow.
        LDWI('.msg');STW(T3)
        LDWI(0x204)
        _CALLI('__@raisem')
        POP();RET()

    def code2m():
        label('.msg') # "Floating point overflow"
        bytes(70,108,111,97,116,105,110,103);
        bytes(32,112,111,105,110,116,32,111);
        bytes(118,101,114,102,108,111,119,0);

    module(name='_foverflow.s',
           code=[ ('IMPORT', '__@raisem'),
                  ('IMPORT', 'errno'),
                  ('EXPORT', '_foverflow'),
                  ('EXPORT', '_@_raise_fovf'),
                  ('CODE', '_foverflow', code2),
                  ('DATA', '.msg', code2m, 0, 1) ] )

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

    module(name='_ftwo.s',
           code=[ ('EXPORT', '_ftwo'),
                  ('DATA', '_ftwo', code_ftwo, 5, 1) ] )

    def code_fminus():
        label('_fminus')
        bytes(129,128,0,0,0) # -1.0F

    module(name='_fminus.s',
           code=[ ('EXPORT', '_fminus'),
                  ('DATA', '_fminus', code_fminus, 5, 1) ] )


    def code_fpi():
        label('_pi')
        bytes(130,73,15,218,162); # 0.785398 * 4
        label('_pi_over_2')
        bytes(129,73,15,218,162); # 0.785398 * 2
        label('_pi_over_4')
        bytes(128,73,15,218,162); # 0.785398
        
    module(name='_fpi.s',
           code=[ ('EXPORT', '_pi'),
                  ('EXPORT', '_pi_over_2'),
                  ('EXPORT', '_pi_over_4'),
                  ('DATA', '_pi', code_fpi, 15, 1) ] )
    

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
