

def scope():


    ctrlBits_v5 = 0x1f8
    cons_128k = 'MAP128K' in args.opts
    cons_512k = 'MAP512K' in args.opts
    cons_dblwidth = cons_512k and ('MAP512K_DBLWIDTH' in args.opts)
    cons_dblheight = cons_512k and ('MAP512K_DBLHEIGHT' in args.opts)

    # ------------------------------------------------------------
    # BANKING
    # ------------------------------------------------------------
    
    
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
        label('_membank_set_program_bank')
        LDI(0x80);_BRA('.r0')
        label('_membank_set_framebuffer_bank')
        LDI(0x40)
        label('.r0')
        STW(R8)
        label('_membank_restore')
        _MOVIW('SYS_ExpanderControl_v4_40','sysFn')
        LDWI(ctrlBits_v5);PEEK();_BEQ('.ret')
        XORW(R8);ANDI(0x3f);XORW(R8);LD(vACL);SYS(40)
        label('.ret')
        RET()

    module(name='_membank_restore.s',
           code=[('EXPORT','_membank_restore'),
                 ('EXPORT','_membank_set_program_bank') if cons_128k else ('NOP',),
                 ('EXPORT','_membank_set_framebuffer_bank') if cons_128k else ('NOP',),
                 ('CODE','_membank_restore',code_restore),
                 ('PLACE', '_membank_restore', 0x0200, 0x7fff) ] )

    if not cons_128k:
        def code_set_bank():
            if cons_512k:
                error("_membank_set_framebuffer_bank() cannot work with -map=512k")
            label('_membank_set_program_bank')
            label('_membank_set_framebuffer_bank')
            RET()

        module(name='_membank_set_bank',
               code=[('EXPORT','_membank_set_program_bank'),
                     ('EXPORT','_membank_set_framebuffer_bank'),
                     ('CODE','_membank_set_bank', code_set_bank) ])

    def code_set():
        nohop()
        label('_membank_set')
        _MOVIW('SYS_LSRW2_52','sysFn')
        LDW(R8-1);SYS(52);ANDI(0xc0);STW(R8)
        if args.cpu >= 6:
            JGE('_membank_restore')
        else:
            _JMP('_membank_restore')
            
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
