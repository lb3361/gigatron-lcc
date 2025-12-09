

def scope():


    # ------------------------------------------------------------
    # BANKING
    # ------------------------------------------------------------

    ctrlBits_v5 = 0x1f8
    
    def code_save():
        nohop()
        label('_membank_save')
        LDWI(ctrlBits_v5);PEEK()
        RET()

    module(name='_membank_save.s',
           code=[('EXPORT','_membank_save'),
                 ('CODE','_membank_save',code_save),
                 ('PLACE', '_membank_save', 0x0200, 0x7fff) ] )


    def code_restore():
        nohop()
        label('_membank_restore')
        _MOVIW('SYS_ExpanderControl_v4_40','sysFn')
        LDWI(ctrlBits_v5);PEEK()
        XORW(R8);ANDI(0x3f);XORW(R8);SYS(40)
        RET()

    module(name='_membank_restore.s',
           code=[('EXPORT','_membank_restore'),
                 ('CODE','_membank_restore',code_restore),
                 ('PLACE', '_membank_restore', 0x0200, 0x7fff) ] )

    def code_set():
        nohop()
        label('_membank_set')
        _MOVIW('SYS_LSRW2_52','sysFn')
        LDW(R8-1);SYS(52);ANDI(0xc0);STW(R8)
        if args.cpu >= 6:
            JGE('_membank_restore')
        else:
            PUSH();_CALLI('_membank_restore');POP();RET()
            
    module(name='_membank_set.s',
           code=[('EXPORT','_membank_set'),
                 ('IMPORT','_membank_restore'),
                 ('CODE','_membank_set',code_set),
                 ('PLACE', '_membank_set', 0x0200, 0x7fff) ] )

    def code_get():
        nohop()
        label('_membank_get')
        LDWI(ctrlBits_v5);PEEK()
        LSLW();LSLW();LD(vACH)
        RET()
        
    module(name='_membank_get.s',
           code=[('EXPORT','_membank_get'),
                 ('CODE','_membank_get',code_get),
                 ('PLACE', '_membank_get', 0x0200, 0x7fff) ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
