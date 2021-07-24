

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

    
scope()
# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
