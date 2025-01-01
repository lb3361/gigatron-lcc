

# char *utoa(unsigned int value, char *buffer, int radix)
# char *itoa(int value, char *buffer, int radix)
# char *ultoa(unsigned long value, char *buffer, int radix)
# char *ltoa(long value, char *buffer, int radix)

def scope():

    def code_asc():
        ''' T0:  (input) end of string
            T1:  (inout,preserved) start of string '''
        nohop()
        label('.d1')
        if args.cpu >= 7:
            ADDSV(-1,T0);PEEKV(T0)
        else:
            LDW(T0);SUBI(1);STW(T0);PEEK()
        ADDI(0x30);POKE(T0)
        SUBI(0x3a);_BLT('.d2')
        ADDI(0x61);POKE(T0)
        label('_itoa_asc')
        label('.d2')
        LDW(T0);XORW(T1);_BNE('.d1')
        LDW(T1)
        RET()

    def code_prep():
        nohop()
        label('_itoa_prep')
        if args.cpu >= 6:
            STW(R10);POKEQ(0);
            SUBI(1);STW(T1);POKEQ(0)
        else:
            STW(R10);SUBI(1);STW(T1)
            LDI(0);POKE(R10);POKE(T1)
        if args.cpu < 5:
            LDWI('_itoa_ddab');STW(R23)            
        RET()

    def code_ddab1():
        ''' T0:   (input) end of string
            T1:   (inout) start of string (decremented)
            T4:   (input,preserved) base
            vAC:  (input) carry '''
        nohop()
        label('_itoa_ddab1')
        ST(T5+1)
        label('.t0')
        LDW(T0);XORW(T1);_BEQ('.t1')
        LD(T5+1);STW(T5)
        LDW(T0);SUBI(1);STW(T0);PEEK()
        LSLW();ADDW(T5);POKE(T0)
        SUBW(T4);_BLT('.t0')
        POKE(T0);INC(T5+1);_BRA('.t0')
        label('.t1')
        LD(T5+1);_BEQ('.t2')
        LDW(T0);SUBI(1);STW(T1)
        LDI(1);POKE(T1)
        label('.t2')
        RET()

    def code_ddab_sys():
        ''' vAC: (input) binary number
            R10: (input,preserved) end of string
            R11/R12: (used)'''
        nohop()
        label('_itoa_ddab')
        info = rominfo['has_SYS_DoubleDabble']
        addr = int(str(info['addr']),0)
        cycs = int(str(info['cycs']),0)
        STW(R11)
        MOVQB(16,R12)
        MOVW(R10,T0)
        _MOVIW(addr,'sysFn')
        label('.s1')
        LDW(R11);SYS(cycs)
        LDW(R11);ADDV(R11)
        DBNE(R12,'.s1')
        RET()

    def code_ddab_vcpu():
        ''' vAC: (input) binary number
            R10: (input,preserved) end of string
            R11/R12: (used)'''
        nohop()
        label('_itoa_ddab')
        PUSH()
        STW(R11)
        if args.cpu >= 6:
            MOVQB(16,R12)
        else:
            LDI(256-16);ST(R12)
        if args.cpu < 5:
            LDWI('_itoa_ddab1');STW(R22)
        label('.s1')
        _MOVW(R10,T0)
        LD(R11+1);ANDI(0x80);PEEK()
        if args.cpu < 5:
            CALL(R22)
        else:
            CALLI('_itoa_ddab1')
        if args.cpu >= 7:
            LDW(R11);ADDV(R11)
        else:
            LDW(R11);LSLW();STW(R11)
        if args.cpu >= 6:
            DBNE(R12, '.s1')
        else:
            INC(R12);LD(R12);_BNE('.s1')
        _MOVW(R10,T0)
        tryhop(2);POP();RET()

    if args.cpu >= 7 and 'has_SYS_DoubleDabble' in rominfo:
        module(name='itoa_subs.s',
               code=[('EXPORT', '_itoa_ddab'),
                     ('EXPORT', '_itoa_asc'),
                     ('EXPORT', '_itoa_prep'),
                     ('CODE', '_itoa_ddab', code_ddab_sys),
                     ('CODE', '_itoa_prep', code_prep),
                     ('CODE', '_itoa_asc', code_asc) ] )
    else:
        module(name='itoa_subs.s',
               code=[('EXPORT', '_itoa_ddab'),
                     ('EXPORT', '_itoa_asc'),
                     ('EXPORT', '_itoa_prep'),
                     ('CODE', '_itoa_ddab1', code_ddab1),
                     ('CODE', '_itoa_ddab', code_ddab_vcpu),
                     ('CODE', '_itoa_prep', code_prep),
                     ('CODE', '_itoa_asc', code_asc) ] )


    def code_utoa():
        '''char *utoa(unsigned int value, char buffer[8], int radix)'''
        label('utoa')
        PUSH()
        _MOVW(R10,T4)
        if args.cpu < 5:
            LDWI('_itoa_prep');STW(R23)
        LDI(7);ADDW(R9)
        if args.cpu < 5:
            CALL(R23) # prep
            LDW(R8);CALL(R23) # ddab
        else:
            CALLI('_itoa_prep')
            LDW(R8);CALLI('_itoa_ddab')
        _CALLJ('_itoa_asc')
        tryhop(2);POP();RET()

    module(name='utoa.s',
           code=[('EXPORT', 'utoa'),
                 ('IMPORT', '_itoa_ddab'),
                 ('IMPORT', '_itoa_asc'),
                 ('IMPORT', '_itoa_prep'),
                 ('CODE', 'utoa', code_utoa)] )


    def code_ultoa():
        '''char *ultoa(unsigned long value, char buffer[16], int radix)'''
        nohop()
        label('ultoa')
        PUSH()
        _MOVW(R11,T4)
        if args.cpu < 5:
            LDWI('_itoa_prep');STW(R23)
        LDI(15);ADDW(R10)
        if args.cpu < 5:
            CALL(R23) # prep
            LDW(R9);CALL(R23)
            LDW(R8);CALL(R23)
        else:
            CALLI('_itoa_prep')
            LDW(R9);CALLI('_itoa_ddab')
            LDW(R8);CALLI('_itoa_ddab')
        _CALLJ('_itoa_asc')
        tryhop(2);POP();RET()

    module(name='ultoa.s',
           code=[('EXPORT', 'ultoa'),
                 ('IMPORT', '_itoa_ddab'),
                 ('IMPORT', '_itoa_asc'),
                 ('IMPORT', '_itoa_prep'),
                 ('CODE', 'ultoa', code_ultoa)] )


    def code_itoa():
        '''char *itoa(int value, char buffer[16], int radix)'''
        nohop()
        label('itoa')
        if args.cpu >= 6:
            LDW(R8);JGE('utoa')
            PUSH()
            NEGV(R8);CALLI('utoa')
            SUBI(1);POKEQ(45)
            tryhop(2);POP();RET()
        else:
            PUSH();
            LDW(R8);_BLT('.neg')
            _CALLJ('utoa')
            tryhop(2);POP();RET()
            label('.neg')
            LDI(0);SUBW(R8);STW(R8)
            _CALLJ('utoa')
            SUBI(1);STW(R9)
            LDI(45);POKE(R9);LDW(R9)
            tryhop(2);POP();RET()

    module(name="itoa.s",
           code=[('EXPORT', 'itoa'),
                 ('IMPORT', 'utoa'),
                 ('CODE', 'itoa', code_itoa)] )


    def code_ltoa():
        '''char *ltoa(long value, char buffer[16], int radix)'''
        nohop()
        label('ltoa')
        if args.cpu >= 6:
            LDW(L8+2);JGE('ultoa')
            PUSH()
            NEGVL(L8);CALLI('ultoa')
            SUBI(1);POKEQ(45)
            tryhop(2);POP();RET()
        else:
            PUSH();
            LDW(L8+2);_BLT('.neg')
            _CALLJ('ultoa')
            tryhop(2);POP();RET()
            label('.neg')
            LDI(0);SUBW(L8);STW(L8);_BEQ('.n1');LDWI(0xffff)
            label('.n1');SUBW(L8+2);STW(L8+2)
            _CALLJ('ultoa')
            SUBI(1);STW(R9)
            LDI(45);POKE(R9);LDW(R9)
        tryhop(2);POP();RET()

    module(name="ltoa.s",
           code=[('EXPORT', 'ltoa'),
                 ('IMPORT', '_itoa_ddab'),
                 ('IMPORT', '_itoa_asc'),
                 ('CODE', 'ltoa', code_ltoa)] )

    
    def code_uftoa():
        '''char *_uftoa(double, char*);'''
        label('_uftoa')
        PUSH()
        _MOVF(F8,FAC);_FTOU()
        _MOVIW(10,T4)
        if args.cpu < 5:
            LDWI('_itoa_prep');STW(R23)
        LDI(15);ADDW(R11)
        if args.cpu < 5:
            CALL(R23) # prep
            LDW(LAC+2);CALL(R23) # ddab
            LDW(LAC);CALL(R23) # ddab
        else:
            CALLI('_itoa_prep')
            LDW(LAC+2);CALLI('_itoa_ddab')
            LDW(LAC);CALLI('_itoa_ddab')
        _CALLJ('_itoa_asc')
        tryhop(2);POP();RET()

    module(name='uftoa.s',
           code=[('EXPORT', '_uftoa'),
                 ('IMPORT', '_itoa_prep'),
                 ('IMPORT', '_itoa_ddab'),
                 ('IMPORT', '_itoa_asc'),
                 ('CODE', '_uftoa', code_uftoa) ] )

    
    def code_utwoa():
        '''Internal: _utwoa(int) converts a number in range 0..99 into two
           chars returned as the high and low part of vAC.'''
        nohop()
        label('_utwoa')
        LDWI(0x2f2f);STW(R9)
        LDW(R8)
        label('.l1')
        INC(R9+1);SUBI(10);_BGE('.l1')
        ADDI(10)
        label('.l2')
        INC(R9);SUBI(1);_BGE('.l2')
        LDW(R9)
        RET()

    module(name='utwoa.s',
           code=[('EXPORT', '_utwoa'),
                 ('CODE', '_utwoa', code_utwoa)  ] )


scope()
# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
