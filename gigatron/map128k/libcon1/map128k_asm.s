

def scope():

    screenStart=0x88
    screenEnd=screenStart+120

    if not "has_SYS_CopyMemoryExt" in rominfo:
        error("this rom cannot run map128k because it lacks SYS_CopyMemoryExt")

    def code_setup():
        nohop()
        label('_map128ksetup')
        LDWI(0x8000);STW(R9);STW(R8)
        # copy all upper memory from current bank to bank 2
        PUSH()
        _MOVIW('SYS_LSRW2_52','sysFn')
        LDWI('ctrlBits_v5');PEEK();SYS(52);ANDI(0x30);ORI(0x80);ST(R8+1)
        _MOVIW('SYS_CopyMemoryExt_v6_100','sysFn')
        label('.m128copyloop')
        STW('sysArgs0');STW('sysArgs2')
        LDW(R8);SYS(100)
        INC(R9+1);LDW(R9);_BNE('.m128copyloop')
        POP()
        # move to bank 2
        LDWI('SYS_ExpanderControl_v4_40');STW('sysFn')
        LDWI('ctrlBits_v5');PEEK();ANDI(0x3c);ORI(0x80);SYS(40)
        # reset screen in black
        _MOVIW(0,R8)
        # new implementation of console_reset
        label('_console_reset')
        LDWI('videoTable');STW(R10)
        LDI(screenStart);STW(R9)
        label('.c128loop')
        LDW(R9);DOKE(R10)
        INC(R10);INC(R10)
        INC(R9);LD(R9)
        XORI(screenEnd) if screenEnd < 256 else None
        BNE('.c128loop')
        # clear screen (black)
        _MOVW(R8,R9)
        _MOVIW(120,R10)
        LDWI(screenStart<<8);STW(R8)
        if args.cpu >= 6:
            JNE('_console_clear')
        else:
            PUSH();_CALLJ('_console_clear');POP();RET()

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
                  ('CODE', '_map128ksetup', code_setup),
                  ('PLACE', '_map128ksetup', 0x0200, 0x7fff),
                  ('CODE', '_map128khalt', code_halt),
                  ('PLACE', '_map128khalt', 0x0200, 0x7fff) ] )


scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
