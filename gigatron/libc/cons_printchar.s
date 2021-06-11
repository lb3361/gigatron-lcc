

def scope():

    # -- int _console_printchars(int fgbg, char *addr, const char *s, int len)
    
    # Draws up to `len` characters from string `s` at the screen
    # position given by address `addr`.  This assumes that the
    # horizontal offsets in the string table are all zero. All
    # characters are printed on a single line (no newline).  The
    # function returns when any of the following conditions is met:
    # (1) `len` characters have been printed, (2) the next character
    # would not fit horizontally on the screen, or (3), an unprintable
    # character, i.e. not in [0x20-0x83], has been met.

    def code_printchars():
        label('_console_printchars')
        tryhop(4);LDW(vLR);STW(R22)
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
        tryhop(7);LDW(R22);STW(vLR);LDW(R12);RET()

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
        
scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
