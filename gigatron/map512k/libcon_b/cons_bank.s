

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


    def code_bank():
        # Clobbers R21, R22
        nohop()
        ## save current bank
        label('_cons_save_current_bank')
        LD(videoModeB);ANDI(0xfc);XORI(0xfc);_BNE('.cscb1')
        LDWI('.savx')
        if args.cpu >= 6:
            POKEA(videoModeC)
        else:
            STW(R22);LD(videoModeC);POKE(R22)
        label('.cscb1')
        RET()
        ## restore_saved_bank
        label('_cons_restore_saved_bank')
        _MOVW('sysFn',R21)
        LDWI('SYS_ExpanderControl_v4_40');STW('sysFn');
        label('.savx', pc()+2)
        LDWI(0x00F0);SYS(40)
        _MOVW(R21,'sysFn')
        RET()
        ## set extended banking code for address in vAC
        label('_cons_set_bank_even')
        _BGE('.wbb1')
        LDWI(0xF8F0);BRA('.wbb3')
        label('.wbb1')
        LDWI(0xE8F0);BRA('.wbb3')
        label('_cons_set_bank_odd')
        _BGE('.wbb2')
        LDWI(0xD8F0);BRA('.wbb3')
        label('.wbb2')
        LDWI(0xC8F0);BRA('.wbb3')
        label('.wbb3')
        if args.cpu >= 7:
            MOVW('sysFn',R21)
            MOVIW('SYS_ExpanderControl_v4_40','sysFn')
        else:
            STW(R22)
            _MOVW('sysFn',R21)
            _MOVIW('SYS_ExpanderControl_v4_40','sysFn')
            LDW(R22)
        SYS(40)
        _MOVW(R21,'sysFn')
        RET()

    module(name='cons_bank.s',
           code=[ ('EXPORT', '_cons_save_current_bank'),
                  ('EXPORT', '_cons_restore_saved_bank'),
                  ('EXPORT', '_cons_set_bank_even'),
                  ('EXPORT', '_cons_set_bank_odd'),
                  ('CODE', '_cons_set_bank', code_bank),
                  ('PLACE', '_cons_set_bank', 0x0200, 0x7fff) ] )


scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
