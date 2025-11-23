

def scope():
        
    def code_bank():
        # Clobbers R21, R22
        nohop()
        ## save current bank
        label('_cons_save_current_bank')
        LDWI('.savx');STW(R22);
        LDWI('ctrlBits_v5');PEEK();POKE(R22)
        RET()
        ## restore_saved_bank
        label('_cons_restore_saved_bank')
        LDW('sysFn');STW(R21)
        LDWI('SYS_ExpanderControl_v4_40');STW('sysFn');
        label('.savx', pc()+1)
        LDI(0x00bc);SYS(40)
        LDW(R21);STW('sysFn')
        RET()
        ## set video bank
        label('_cons_set_bank')
        LDW('sysFn');STW(R21)
        LDWI('SYS_ExpanderControl_v4_40');STW('sysFn');
        LDWI('ctrlBits_v5');PEEK();ANDI(0x3c);ORI(0x40);SYS(40)
        LDW(R21);STW('sysFn')
        RET()
        
    module(name='cons_bank.s',
           code=[ ('EXPORT', '_cons_save_current_bank'),
                  ('EXPORT', '_cons_restore_saved_bank'),
                  ('EXPORT', '_cons_set_bank'),
                  ('CODE', '_cons_set_bank', code_bank),
                  ('PLACE', '_cons_set_bank', 0x0200, 0x7fff) ] )

    
scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
