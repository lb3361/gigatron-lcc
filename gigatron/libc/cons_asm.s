

def scope():


    # ------------------------------------------------------------
    # LOW LEVEL SCREEN ACCESS
    # ------------------------------------------------------------
    # These functions do not know about the console
    # state and simply access the screen at the provided address.
    # ------------------------------------------------------------



    # -- int _console_printchars(int fgbg, char *addr, const char *s, int len)
    
    # Draws up to `len` characters from string `s` at the screen
    # position given by address `addr`.  This assumes that the
    # horizontal offsets in the string table are all zero. All
    # characters are printed on a single line (no newline).  The
    # function returns when any of the following conditions is met:
    # (1) `len` characters have been printed,
    # (2) the next character would not fit horizontally on the screen, or
    # (3) an unprintable character, i.e. not in [0x20-0x83], has been met.

    def code_printchars():
        label('_console_printchars')
        tryhop(4);PUSH()
        _LDI('SYS_VDrawBits_134');STW('sysFn')   # prep sysFn
        LDW(R8);STW('sysArgs0')                  # move fgbg, freeing R8
        LDI(0);STW(R12)                          # R12: character counter
        label('.loop')
        LDW(R10);PEEK();STW(R8)                  # R8: character code
        LDI(1);ADDW(R10);STW(R10)                # next char
        LDW(R9);STW('sysArgs4')                  # destination address
        ADDI(6);STW(R9);                         # next address
        LD(vACL);SUBI(0xA0);_BGT('.ret')         # beyond screen?
        _LDI('font32up');STW(R13)                # R13: font address
        LDW(R8);SUBI(32);_BLT('.ret'  )          # c<32
        STW(R8);SUBI(50);_BLT('.draw')           # 32 <= c < 82
        STW(R8);SUBI(50);_BGE('.ret')            # >= 132
        _LDI('font82up');STW(R13)
        label('.draw')
        _CALLJ('_printonechar')
        LDI(1);ADDW(R12);STW(R12);               # increment counter
        XORW(R11);_BNE('.loop')                  # loop
        label('.ret')
        tryhop(4);LDW(R12);POP();RET()

    def code_printonechar():
        nohop()
        label('_printonechar')
        LDW(R8);LSLW();LSLW();ADDW(R8);ADDW(R13)
        STW(R13);LUP(0);ST('sysArgs2');SYS(134);INC(R13);INC('sysArgs4')
        LDW(R13);LUP(0);ST('sysArgs2');SYS(134);INC(R13);INC('sysArgs4')
        LDW(R13);LUP(0);ST('sysArgs2');SYS(134);INC(R13);INC('sysArgs4')
        LDW(R13);LUP(0);ST('sysArgs2');SYS(134);INC(R13);INC('sysArgs4')
        LDW(R13);LUP(0);ST('sysArgs2');SYS(134);INC('sysArgs4')
        LDI(0);ST('sysArgs2');SYS(134)
        RET()

    module(name='cons_printchar.s',
           code=[ ('EXPORT', '_console_printchars'),
                  ('CODE', '_console_printchars', code_printchars),
                  ('CODE', '_printonechar', code_printonechar) ] )


    # -- void _console_clear(char *addr, char clr, int nl)
    # Clears from addr to the end of line with color clr.
    # Repeats for nl successive lines.

    def code_clear():
        label('_console_clear')
        PUSH()
        LDWI('SYS_SetMemory_v2_54');STW('sysFn')
        LDI(160);SUBW(R8);ST(R11)
        LD(R9);ANDI(0x3f);ST('sysArgs1')
        label('.loop')
        LD(R11);ST('sysArgs0')
        LDW(R8);STW('sysArgs2')
        SYS(54)
        INC(R8+1)
        LDW(R10)
        SUBI(1);
        STW(R10);
        _BNE('.loop')
        tryhop(2);POP();RET()

    module(name='cons_clear.s',
           code=[ ('EXPORT', '_console_clear'),
                  ('CODE', '_console_clear', code_clear) ] )



    # ------------------------------------------------------------
    # HELPERS FOR CONSOLE_PRINT
    # ------------------------------------------------------------
    # These functions optimize the size of console_print.
    # They depend on the layout of console_state and console_info.
    # They assume console_state is in page zero
    # ------------------------------------------------------------


    # -- char *_console_scroll(void)

    def code_scroll(hires = False):
        nohop()
        label('_console_scroll')
        PUSH()
        # clear first line
        LDWI(v('console_info')+4)                # offset
        PEEK();INC(vACH);PEEK();ST(R8+1)
        LDI(0);ST(R8)
        LD('console_state');STW(R9)              # bg
        LDI(8);STW(R10)
        _CALLJ('_console_clear')
        # scroll videotable lines
        LDWI(v('console_info')+4);STW(R10)       # offset
        PEEK();INC(vACH);PEEK();STW(R9)
        LDWI(v('console_info')+0);DEEK()         # nlines
        SUBI(1);ST(v('console_state')+2)         # cy
        _BRA('.tst1')
        label('.loop1')
        ADDW(R10);PEEK();INC(vACH);STW(R12)
        PEEK();ST(R13)
        if not hires: LDI(7)
        if hires: LDI(3)
        _BRA('.tst2')
        label('.loop2')
        LD(R9);POKE(R12)
        INC(R9)
        if hires: INC(R9)
        INC(R12);INC(R12)
        LD(R14);SUBI(1)
        label('.tst2')
        ST(R14);_BGE('.loop2')
        LD(R13);ST(R9)
        LD(R8);SUBI(1)
        label('.tst1')
        ST(R8);_BGE('.loop1')
        tryhop(2);POP();RET()

    module(name='cons_scroll.s',
           code=[ ('EXPORT', '_console_scroll'),
                  ('IMPORT', '_console_clear'),
                  ('IMPORT', 'console_state'),
                  ('IMPORT', 'console_info'),
                  ('CODE', '_console_scroll', code_scroll) ] )


    # -- char *_console_addr(void)

    # Function _console_addr() returns the screen address of the cursor.
    # If the cursor is outside the screen it tries wrapping or scrolling.
    # Return zero if still outside the screen.
    # Warning: depends on the layout of console_state and console_info

    def code_addr(hires = False):
        nohop()
        label('_console_addr')
        PUSH()
        LD(v('console_state')+3);STW(R8)                # cx
        LDWI(v('console_info')+2);DEEK();               # ncolumns
        SUBW(R8);_BGT('.nw')
        LD(v('console_state')+5);_BEQ('.nw');           # wrapx
        INC(v('console_state')+2)                       # cy++
        LDI(0);ST(v('console_state')+3)                 # cx=0
        label('.nw')
        LD(v('console_state')+2);STW(R8)                # cy 
        LDWI(v('console_info')+0);DEEK();               # nlines
        SUBW(R8);_BGT('.nh')
        LD(v('console_state')+4);_BEQ('.ret0');         # wrapy
        _CALLJ('_console_scroll')                       # spill!
        label('.nh')
        LDWI(v('console_info')+4);STW(R9)               # offset
        LD(v('console_state')+3);STW(R8)                # cx
        LDWI(v('console_info')+2);DEEK()                # ncolumns
        SUBW(R8);_BLE('.ret0')
        LDW(R8);LSLW();ADDW(R8)                         # times 6 for std
        if not hires: LSLW()                            # times 3 for hires
        STW(R10)
        LD(v('console_state')+2);ADDW(R9)               # cy + offset
        PEEK();INC(vACH);PEEK();ST(R10+1)               # page
        LDW(R10);tryhop(2);POP();RET()
        label('.ret0')
        LDI(0);tryhop(2);POP();RET()

    module(name='cons_addr.s',
           code=[ ('EXPORT', '_console_addr'),
                  ('IMPORT', '_console_scroll'),
                  ('IMPORT', 'console_state'),
                  ('IMPORT', 'console_info'),
                  ('CODE', '_console_addr', code_addr) ] )


    # -- int _console_special(const char *s, int len)
    # This function processes control characters BS, CR, and LF,
    # and otherwise calls _console_ctrl if defined.
    
    def code_special():
        nohop()
        label('_console_special')
        LDW(R8);PEEK()
        XORI(8);_BEQ('.ctrl_bs')
        XORI(8 ^ 10);_BEQ('.ctrl_lf')
        XORI(10 ^ 13);_BEQ('.ctrl_cr')
        LDWI('__glink_weak__console_ctrl');
        if args.cpu >= 7:
            JNE('__glink_weak__console_ctrl');
        else:
            _BEQ('.ret')
            PUSH();CALL(vAC);POP();
        label('.ret')
        RET()
        label('.ctrl_bs')
        LD(v('console_state')+3);_BLE('.ctrl_bs1')
        SUBI(1);ST(v('console_state')+3); # cx--
        _BRA('.ctrl_ret1')
        label('.ctrl_bs1')
        LD(v('console_state')+2);_BLE('.ctrl_ret1')
        SUBI(1);ST(v('console_state')+2); # cy--
        LDWI(v('console_info')+2);DEEK()
        SUBI(1);ST(v('console_state')+3); # cx=ncolumns-1
        _BRA('.ctrl_ret1')
        label('.ctrl_lf')
        INC(v('console_state')+2)         # cy++
        label('.ctrl_cr')
        LDI(0);ST(v('console_state')+3)   # cx=0
        label('.ctrl_ret1')
        LDI(1);RET()


    module(name='cons_special.s',
           code=[ ('EXPORT', '_console_special'),
                  ('IMPORT', 'console_state'),
                  ('IMPORT', 'console_info'),
                  ('CODE', '_console_special', code_special) ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
