
def scope():

    def code_ldexp10p():
        label('_ldexp10p')
        bytes(235,29,197,173,168); # 1e+32
        bytes(182,14,27,201,191); # 1e+16
        bytes(155,62,188,32,0); # 1e+08
        bytes(142,28,64,0,0); # 10000
        bytes(135,72,0,0,0); # 100
        bytes(132,32,0,0,0); # 10

    def code_ldexp10n():
        label('_ldexp10n')
        _LDI('_ldexp10p');STW(R21);ADDI(30);STW(R20)
        LDI(0);SUBW(R11);STW(R11);
        _CMPIS(80);_BLE('.neg1')
        LDI(80);STW(R11)
        label('.neg1')
        LDW(R11);ANDI(31);XORW(R11);_BEQ('.neg3')
        LDW(R21);_FDIV()
        LDW(R11);SUBI(32);STW(R11);_BRA('.neg1')
        label('.neg2')
        LDW(R11);LSLW();STW(R11);ANDI(0x20);_BEQ('.neg3')
        LDW(R21);_FDIV()
        label('.neg3')
        LDI(5);ADDW(R21);STW(R21);XORW(R20);_BNE('.neg2')
        tryhop(2);POP();RET()
        
    def code_ldexp10():
        label('_ldexp10')
        PUSH()
        _FMOV(F8,FAC)
        LDW(R11);_BGE('.pos')
        _CALLJ('_ldexp10n') # no return
        label('.pos')
        _CMPIS(80);_BLE('.pos1')
        LDI(80);STW(R11);_BRA('.pos1')
        label('.pos2')
        SUBI(1);STW(R11)
        _CALLJ('_@_fmul10')
        label('.pos1')
        LDW(R11);_BNE('.pos2')
        _CALLJ('_@_rndfac')
        tryhop(2);POP();RET()

    module(name='_ldexp10',
           code=[ ('EXPORT', '_ldexp10'),
                  ('IMPORT', '_@_fmul10'),
                  ('IMPORT', '_@_rndfac'),
                  ('DATA', '_ldexp10p', code_ldexp10p, 0, 1),
                  ('CODE', '_ldexp10n', code_ldexp10n), 
                  ('CODE', '_ldexp10', code_ldexp10) ] )

    def code_frexp10():
        label('_frexp10')
        # Calling _ldexp10 will not damage R16-R19
        PUSH()
        LDW(R11);STW(R18)
        LD(F8);_BEQ('.zero')
        SUBI(158);STW(R17);LSLW();ADDW(R17);_DIVIS(10);STW(R17)
        LDI(0);SUBW(R17);STW(R11);_CALLJ('_ldexp10')
        label('.loop1')
        _FMOV(FAC,F8)
        LD(F8);SUBI(160);_BGT('.fix1')
        ADDI(3);_BGT('.ret');_BLT('.fix0')
        LD(F8+1);ORI(0x80);SUBI(0xcc);_BGE('.ret')
        label('.fix0')
        LDI(1);_BRA('.fix2')
        label('.fix1')
        _LDI(-1);
        label('.fix2')
        STW(R11);LDW(R17);SUBW(R11);STW(R17)
        _CALLJ('_ldexp10');_BRA('.loop1')
        label('.zero')
        STW(R17);_CALLJ('_@_clrfac')
        label('.ret')
        LDW(R17);DOKE(R18)
        tryhop(2);POP();RET();

    module(name='_frexp10',
           code=[ ('EXPORT', '_frexp10'),
                  ('IMPORT', '_ldexp10'),
                  ('IMPORT', '_@_clrfac'),
                  ('CODE', '_frexp10', code_frexp10) ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
