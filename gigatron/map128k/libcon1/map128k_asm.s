

def scope():

    screenStart=130
    screenEnd=screenStart+120

    def code_setup():
        nohop()
        label('_map128ksetup')
        # copy himem gt1 data into bank2
        PUSH()
        LDWI('SYS_LSRW2_52');STW('sysFn')
        LDI(0);STW(R8)
        LDWI('ctrlBits_v5');PEEK();SYS(52);ANDI(0x30);ORI(0x80);ST(R8+1)
        LDWI('SYS_CopyMemoryExt_v6_100');STW('sysFn')
        LDWI('_egt1');DEEK();SUBI(1);ORI(255);XORI(255);STW(R9)
        _BRA('.m128copytest')
        label('.m128copyloop')
        STW('sysArgs0');STW('sysArgs2')
        LDW(R8);SYS(100)
        LDWI(-256);ADDW(R9);STW(R9)
        label('.m128copytest')
        BLT('.m128copyloop')
        POP()
        LDWI('SYS_ExpanderControl_v4_40');STW('sysFn')
        LDWI('ctrlBits_v5');PEEK();ANDI(0x3c);ORI(0x80);SYS(40)
        # reset screen
        _MOVIW(0,R8)
        label('_console_reset')
        LDWI('videoTable');STW(R10)
        LDI(screenStart);STW(R9)
        label('.c128loop')
        LDW(R9);DOKE(R10)
        INC(R10);INC(R10)
        INC(R9);LD(R9);XORI(screenEnd)
        BNE('.c128loop')
        _MOVIW(120,R10)
        LDW(R8);STW(R9)
        if args.cpu >= 7:
            MOVIW(screenStart << 8,R8)
            JGE('_console_clear')
        else:
            _BLT('.ret')
            LDWI(screenStart << 8);STW(R8)
            PUSH();_CALLJ('_console_clear');POP()
        label('.ret')
        RET()

    def code_halt():
        nohop()
        label('_map128khalt')
        LDWI('SYS_ExpanderControl_v4_40');STW('sysFn')
        LDWI('ctrlBits_v5');PEEK();ANDI(0x3f);ORI(0x40);SYS(40)
        LDWI('videoTable');DEEK();ST(R7+1)
        LD(vACH);ADDW(R0);ST(R7)
        label('.loop')
        POKE(R7);ADDW(0x80)
        BRA('.loop')
        RET()

    module(name='map128ksetup.s',
           code=[ ('EXPORT', '_map128ksetup'),
                  ('EXPORT', '_map128khalt'),
                  ('EXPORT', '_console_reset'),
                  ('IMPORT', '_console_clear'),
                  ('IMPORT', '_egt1'),
                  ('CODE', '_map128ksetup', code_setup),
                  ('PLACE', '_map128ksetup', 0x0200, 0x7fff),
                  ('CODE', '_map128khalt', code_halt),
                  ('PLACE', '_map128khalt', 0x0200, 0x7fff) ] )
                  
    
scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
