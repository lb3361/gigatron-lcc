

# char *utoa(unsigned int value, char *buffer, int radix)
# char *itoa(int value, char *buffer, int radix)
# char *ultoa(unsigned long value, char *buffer, int radix)
# char *ltoa(long value, char *buffer, int radix)

def scope():

    def code_utoa():
        label('utoa')
        PUSH()
        LDI(7);ADDW(R9);STW(R9)
        LDI(0);POKE(R9);BRA('.loop')
        label('_utoa')
        PUSH()
        label('.loop')
        LDW(R8);_MODU(R10);STW(R11)
        LDW(R9);SUBI(1);STW(R9)
        LDW(R11);SUBI(10);_BGE('.letter')
        ADDI(48+10);_BRA('.poke')
        label('.letter')
        ADDI(97);
        label('.poke')
        POKE(R9)
        LDW(T1);STW(R8);_BNE('.loop')
        LDW(R9)
        tryhop(2);POP();RET()

    module(name="utoa.s",
           code=[('EXPORT', 'utoa'),
                 ('EXPORT', '_utoa'),
                 ('CODE', 'utoa', code_utoa)] )

    def code_itoa():
        label('itoa')
        PUSH();
        LDI(0);SUBW(R8);_BGT('.neg')
        _CALLJ('utoa')
        tryhop(2);POP();RET()
        label('.neg')
        STW(R8)
        _CALLJ('utoa')
        SUBI(1);STW(R9);LDI(45);POKE(R9);
        LDW(R9)
        tryhop(2);POP();RET()
    
    module(name="itoa.s",
           code=[('EXPORT', 'itoa'),
                 ('IMPORT', 'utoa'),
                 ('CODE', 'itoa', code_itoa)] )


    def code_ultoa():
        label('ultoa')
        PUSH()
        LDI(15);ADDW(R10);STW(R10)
        LDI(0);POKE(R10);STW(R12)
        _LMOV(L8,LAC);
        label('.loop')
        LDI(R11);_LMODU()
        LDW(LAC);STW(R13)
        LDW(R10);SUBI(1);STW(R10)
        LDW(R13);SUBI(10);_BGE('.letter')
        ADDI(48+10);_BRA('.poke')
        label('.letter')
        ADDI(97);
        label('.poke')
        POKE(R10)
        LDW(T0);STW(LAC);LDW(T1);STW(LAC+2)
        ORW(T0);_BNE('.loop')
        LDW(R10)
        tryhop(2);POP();RET()
        
    module(name="ultoa.s",
           code=[('EXPORT', 'ultoa'),
                 ('IMPORT', '_utoa'),
                 ('CODE', 'ultoa', code_ultoa)] )

    def code_ltoa():
        label('ltoa')
        PUSH();
        LDW(L8+2);_BLT('.neg')
        _CALLJ('ultoa')
        tryhop(2);POP();RET()
        label('.neg')
        _LMOV(L8,LAC);_LNEG();_LMOV(LAC,L8)
        _CALLJ('ultoa')
        SUBI(1);STW(R9);LDI(45);POKE(R9);
        LDW(R9)
        tryhop(2);POP();RET()
    
    module(name="ltoa.s",
           code=[('EXPORT', 'ltoa'),
                 ('IMPORT', 'ultoa'),
                 ('CODE', 'ltoa', code_ltoa)] )

    def code_utwoa():
        '''Internal: _utwoa(int) converts a number in range 0..99 into two
           chars returned as the high and low part of vAC.'''
        label('_utwoa')
        PUSH()
        LDW(R8);_MODIU(10)
        ADDI(48);ST(R8)
        LD(T1);ADDI(48);ST(R8+1)
        LDW(R8)
        tryhop(2);POP();RET()

    module(name='utwoa.s',
           code=[('EXPORT', '_utwoa'),
                 ('CODE', '_utwoa', code_utwoa)  ] )

    def code_uftoa():
        '''Internal: _uftoa(double x, char *buf) does the same
           as _ultoa((unsigned long)x, buf, 10) but using _fmodquo
           instead of a long division.'''
        label('_uftoa')
        PUSH()
        _FMOV(F8,FAC)
        LDI(10);STW(R10)
        LDW(R11);ADDI(15);STW(R22);STW(R21)
        LDI(0);DOKE(R22)
        _LDI('.1e8');_CALLJ('_@_fmod');STW(R20)
        _LDI('.1e4');_CALLJ('_@_fmod');STW(R19)
        _FTOU();LDW(LAC);_CALLI('.uftoa1')
        LDW(R19);_CALLI('.uftoa1')
        LDW(R20);_CALLI('.uftoa1')
        tryhop(2);POP();RET()
        label('.uftoa1')
        PUSH();STW(R8)
        label('.uftoa2')
        LDW(R21);XORW(R22);_BEQ('.uftoa3')
        LDW(R21);SUBI(1);STW(R21)
        LDI(48);POKE(R21);_BRA('.uftoa2')
        label('.uftoa3')
        LDW(R22);STW(R9);SUBI(4);STW(R22)
        _CALLJ('_utoa');STW(R21)
        tryhop(2);POP();RET()
       
    def code_uftoa_cst():
        label('.1e4')
        bytes(142,28,64,0,0) # 1e4
        label('.1e8')
        bytes(155,62,188,32,0) # 1e+08

    module(name='uftoa.s',
           code=[('EXPORT', '_uftoa'),
                 ('CODE', '_uftoa', code_uftoa),
                 ('DATA', '_uftoa', code_uftoa_cst, 0, 1),
                 ('IMPORT', '_@_fmod'),
                 ('IMPORT', '_utoa') ] )

scope()
# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
