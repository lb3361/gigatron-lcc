

def scope():

    screenStart=8
    ctrlBits_v5 = 0x1f8
    videoModeC = 0xb   # contain bankinfo on patched rom

    cons_512k = 'MAP512K' in args.opts
    cons_dblwidth = cons_512k and ('MAP512K_DBLWIDTH' in args.opts)
    cons_dblheight = cons_512k and ('MAP512K_DBLHEIGHT' in args.opts)
    
    if not cons_512k:
        warning('compiling map512k_asm.s without option MAP512K makes no sense')

    def code_setup():
        nohop()
        label('_map512ksetup')
        _MOVIW(0,R8)
        label('_console_reset')
        # setup video mode
        LDWI('SYS_ExpanderControl_v4_40');STW('sysFn')
        if cons_dblwidth:
            # Row YY even pixels at 0x70800 + 0xYY00 + [0..159] (banks 14/15)
            # Row YY odd pixels at  0x60800 + 0xYY00 + [0..159] (banks 12/13)
            LDWI(0x0ee0);SYS(40)
        else:
            # Row Y pixels at 0x70800 + 0xYY00 + [0..159] (banks 14/15)
            LDWI(0x0fe0);SYS(40)
        if cons_dblheight:
            LD(videoModeC);ORI(1);ST(videoModeC)
        # setup video table
        LDWI('videoTable');STW(R10)
        LDI(screenStart);STW(R9)
        label('.c128loop')
        LDW(R9);DOKE(R10)
        if cons_dblheight:
            INC(R9);INC(R9)
        else:
            INC(R9)
        INC(R10);INC(R10)
        LD(R10);XORI(240);BNE('.c128loop')
        # clear screen
        if cons_dblheight:
            _MOVIW(240,R10)
        else:
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
        label('_map512khalt')
        LDWI('SYS_ExpanderControl_v4_40');STW('sysFn')
        LDWI(0xe0f0);SYS(40)
        LDWI('ctrlBits_v5');PEEK();ANDI(0x3f);SYS(40)
        LDWI('videoTable');DEEK();ORI(0x80);ST(R7+1)
        LD(vACH);ADDW(R0);ST(R7)
        label('.loop')
        POKE(R7);ADDW(0x80)
        BRA('.loop')
        RET()
    
    module(name='map512ksetup.s',
           code=[ ('EXPORT', '_map512ksetup'),
                  ('EXPORT', '_map512khalt'),
                  ('EXPORT', '_console_reset'),
                  ('IMPORT', '_console_clear'),
                  ('CODE', '_map512ksetup', code_setup),
                  ('PLACE', '_map512ksetup', 0x0200, 0x7fff),
                  ('CODE', '_map512khalt', code_halt),
                  ('PLACE', '_map512khalt', 0x0200, 0x7fff) ] )
                  

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
