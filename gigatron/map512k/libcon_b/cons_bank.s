

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
    cons_512k = 'MAP512K' in args.opts
    cons_dblwidth = cons_512k and ('MAP512K_DBLWIDTH' in args.opts)
    cons_dblheight = cons_512k and ('MAP512K_DBLHEIGHT' in args.opts)
    if not cons_512k:
        error("This file only makes sense with -map=512k")

    # to be set to True in a little while.
    futureproofed = False

    def code_membank_save():
        nohop()
        label('_membank_save')
        if futureproofed:
            LDWI(ctrlBits_v5);PEEK()
            RET()
        else:
            LDWI(ctrlBits_v5);PEEK();ANDI(0xf0);STW(T3)
            LD(videoModeB);ANDI(0xfc);XORI(0xfc);_BNE('.s1') # no 512k rom
            LD(videoModeC);ST(T3+1)
            label('.s1')
            LDW(T3);RET()

    module(name='_membank_save.s',
           code=[ ('EXPORT', '_membank_save'),
                  ('CODE', '_membank_save', code_membank_save),
                  ('PLACE', '_membank_save', 0x0200, 0x7fff) ] )

    def code_membank_restore():
        nohop()
        label('_membank_restore')
        _MOVIW('SYS_ExpanderControl_v4_40','sysFn')
        LDWI(ctrlBits_v5);PEEK();_BEQ('.ret')
        XORW(R8);ANDI(0xf);XORW(R8)
        if futureproofed:
            LD(vACL);SYS(40)
        else:
            ST(R8);ORI(0xff);XORI(0xf);SYS(40)
            LD(R8);SYS(40)
        label('.ret')
        RET()

    module(name='_membank_restore.s',
           code=[ ('EXPORT', '_membank_restore'),
                  ('CODE', '_membank_restore', code_membank_restore),
                  ('PLACE', '_membank_restore', 0x0200, 0x7fff) ] )

    def code_membank_set():
        nohop()
        label('_membank_set')
        _MOVIW('SYS_LSLW4_46','sysFn')
        if not futureproofed:
            _MOVIW(v('_membank_get')+1,T2);
            LDW(R8);ANDI(0xf);POKE(T2)
        LDW(R8-1);ORI(0xff);SYS(46);STW(R8)
        _MOVIW('SYS_ExpanderControl_v4_40','sysFn')
        LDW(R8);SYS(40)
        if not futureproofed:
            label('_membank_get')
            LDI(0);RET()

    module(name='_membank_set',
           code=[ ('EXPORT', '_membank_set'),
                  ('EXPORT', '_membank_get') if not futureproofed else ('NOP',),
                  ('CODE', '_membank_set', code_membank_set),
                  ('PLACE', '_membank_set', 0x0200, 0x7fff) ] )

    if futureproofed:
        def code_membank_get():
            nohop()
            _MOVIW('SYS_LSRW4_50','sysFn')
            LDWI(ctrlBits_v5);PEEK();LSLW();LSLW();STW(T3)
            SYS(50);ST(T3);LD(T3+1);XORW(T3);ORI(0xc);XORW(T3)
            RET()

        module(name='_membank_get',
               code=[ ('EXPORT', '_membank_get'),
                      ('CODE', '_membank_get', code_membank_get) ] )


    def code_cons_bank():
        nohop()
        # save current bank
        label('_cons_save_current_bank')
        LD(videoModeB);ANDI(0xfc);XORI(0xfc);_BNE('.cscb1')
        LDWI('.savx')
        if args.cpu >= 6:
            POKEA(videoModeC)
        else:
            STW(R22);LD(videoModeC);POKE(R22)
        label('.cscb1')
        RET()
        # restore_saved_bank
        label('_cons_restore_saved_bank')
        _MOVW('sysFn',R21)
        _MOVIW('SYS_ExpanderControl_v4_40','sysFn');
        label('.savx', pc()+2)
        LDWI(0x00F0);SYS(40)
        _MOVW(R21,'sysFn')
        RET()
        # set extended banking code for
        # accessing screen address in vAC
        label('_cons_set_bank_even')
        _BGE('.wbb1')
        LDWI(0xF83C);BRA('.wbb3')
        label('.wbb1')
        LDWI(0xE83C);BRA('.wbb3')
        label('_cons_set_bank_odd')
        _BGE('.wbb2')
        LDWI(0xD83C);BRA('.wbb3')
        label('.wbb2')
        LDWI(0xC83C);BRA('.wbb3')
        label('.wbb3')
        if args.cpu < 7:
            STW(R22)
            _MOVW('sysFn',R21)
            _MOVIW('SYS_ExpanderControl_v4_40','sysFn')
            LDW(R22)
        else:
            MOVW('sysFn',R21)
        SYS(40)
        _MOVW(R21,'sysFn')
        RET()

    module(name='_cons_bank.s',
           code=[ ('EXPORT', '_cons_save_current_bank'),
                  ('EXPORT', '_cons_restore_saved_bank'),
                  ('EXPORT', '_cons_set_bank_even'),
                  ('EXPORT', '_cons_set_bank_odd'),
                  ('CODE', '_cons_bank', code_cons_bank),
                  ('PLACE', '_cons_bank', 0x0200, 0x7fff) ] )


scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
