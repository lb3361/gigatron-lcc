

def scope():

    # ------------------------------------------------------------
    # LOW LEVEL SCREEN ACCESS
    # ------------------------------------------------------------
    # These functions do not know about the console
    # state and simply access the screen at the provided address.
    # ------------------------------------------------------------

    ctrlBits_v5 = 0x1f8
    videoModeB = 0xa   # >= 0xfc on patched rom
    videoModeC = 0xb   # contain bankinfo on patched rom

    def code_membank_save():
        nohop()
        label('_membank_save')
        LDI(T3)
        label('_membank_save.a')
        STW(T2)
        LDWI(ctrlBits_v5);PEEK();DOKE(T2)
        LD(videoModeB);ANDI(0xfc);XORI(0xfc);_BNE('.s1') # no 512k rom
        LD(videoModeC);ORI(1);INC(T2);POKE(T2)
        label('.s1')
        LDW(T3);RET()

    module(name='_membank_save.s',
           code=[ ('EXPORT', '_membank_save'),
                  ('EXPORT', '_membank_save.a'),
                  ('CODE', '_membank_save', code_membank_save),
                  ('PLACE', '_membank_save', 0x0200, 0x7fff) ] )

    def code_membank_restore():
        nohop()
        label('_membank_restore')
        if args.cpu < 7:
            _MOVIW('SYS_ExpanderControl_v4_40','sysFn')
        LDWI(ctrlBits_v5);PEEK()
        XORI(R8);ANDI(0x3f);XORI(R8)
        label('_membank_restore.a')
        if args.cpu >= 7:
            _MOVIW('SYS_ExpanderControl_v4_40','sysFn')
            SYS(40);
            MOVQB(0,vACL);_BEQ('.r1')
        else:
            SYS(40)
            ORI(0xff);XORI(0xff);_BEQ('.r1')
        ORI(0xf0);SYS(40)
        label('.r1')
        _MOVW(R21,'sysFn')
        RET()

    module(name='_membank_restore.s',
           code=[ ('EXPORT', '_membank_restore'),
                  ('EXPORT', '_membank_restore.a'),
                  ('CODE', '_membank_restore', code_membank_restore),
                  ('PLACE', '_membank_restore', 0x0200, 0x7fff) ] )

    def code_membank_set():
        nohop()
        label('_membank_set')
        _MOVIW('SYS_LSLW4_46','sysFn')
        LDW(R8-1);
        if args.cpu >= 7:
            MOVQB(0x10,vACL)
        else:
            ORI(0xff);XORI(0xef)
        SYS(46);STW(R8)
        if args.cpu >= 6:
            JNE('_membank_restore')
        else:
            PUSH();_CALLJ('_membank_restore');POP();RET()

    module(name='_membank_set',
           code=[ ('EXPORT', '_membank_set'),
                  ('IMPORT', '_membank_restore'),
                  ('CODE', '_membank_set', code_membank_set),
                  ('PLACE', '_membank_set', 0x0200, 0x7fff) ] )

    def code_membank_get():
        nohop()
        label('_membank_get')
        LD(videoModeB);ANDI(0xfc);XORI(0xfc);_BNE('.g1')
        LD(videoModeC);ANDI(0x8);_BNE('.g0')
        LDWI(ctrlBits_v5);PEEK();ANDI(0xc0);_BNE('.g1')
        label('.g0')
        _MOVIW('SYS_LSRW4_50','sysFn')
        LD(videoModeC);SYS(50)
        RET()
        label('.g1')
        LDWI(ctrlBits_v5);PEEK()
        LSLW();LSLW();LD(vACH)
        RET()

    module(name='_membank_get',
           code=[ ('EXPORT', '_membank_get'),
                  ('CODE', '_membank_get', code_membank_get),
                  ('PLACE', '_membank_get', 0x0200, 0x7fff) ] )


    def code_cons_bank():
        nohop()
        # save current bank
        label('_cons_save_current_bank')
        LDWI('.savx')
        if args.cpu >= 6:
            JNE('_membank_save.a')
        else:
            PUSH();_CALLI('_membank_save.a');POP();RET()
        # restore saved bank
        label('_cons_restore_saved_bank')
        _MOVW('sysFn',R21)
        if args.cpu < 7:
            _MOVIW('SYS_ExpanderControl_v4_40','sysFn')
        label('.savx', pc()+1)
        LDWI(0x007c)
        if args.cpu >= 6:
            JNE('_membank_restore.a')
        else:
            PUSH();_CALLI('_membank_restore.a');POP()
        RET()
        ## set extended banking code for address in vAC
        label('_cons_set_bank_even')
        _BGE('.wbb1')
        LDWI(0xF03C);BRA('.wbb3')
        label('.wbb1')
        LDWI(0xE03C);BRA('.wbb3')
        label('_cons_set_bank_odd')
        _BGE('.wbb2')
        LDWI(0xD03C);BRA('.wbb3')
        label('.wbb2')
        LDWI(0xC03C);BRA('.wbb3')
        label('.wbb3')
        if args.cpu < 7:
            STW(R22)
            _MOVW('sysFn',R21)
            _MOVIW('SYS_ExpanderControl_v4_40','sysFn')
            LDW(R22)
        else:
            MOVW('sysFn',R21)
        if args.cpu >= 6:
            JNE('_membank_restore.a')
        else:
            PUSH();_CALLI('_membank_restore.a');POP();RET()

    module(name='_cons_bank.s',
           code=[ ('EXPORT', '_cons_save_current_bank'),
                  ('EXPORT', '_cons_restore_saved_bank'),
                  ('EXPORT', '_cons_set_bank_even'),
                  ('EXPORT', '_cons_set_bank_odd'),
                  ('IMPORT', '_membank_save.a'),
                  ('IMPORT', '_membank_restore.a'),
                  ('CODE', '_cons_bank', code_cons_bank),
                  ('PLACE', '_cons_bank', 0x0200, 0x7fff) ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
