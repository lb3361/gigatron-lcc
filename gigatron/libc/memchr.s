
def scope():

    
    # -- void *memchr(const void *s, int c0, size_t n)
    # -- void *__memchr2(const void *s, int c0c1, size_t n)
    # scan at most n bytes from s until finding one equal to c0 or c1
    # return pointer to the byte if found, 0 if not found.
    # known to leave R8 unchanged!!!
    def code1():
        nohop()
        label('memchr')
        LD(R9);ST(R9+1)
        label('__memchr2')
        _MOVW(R9,T1)
        LDW(R8);STW(T0);ADDW(R10);STW(T2)
        label('memchr.sub')
        # T0 (IO)   : start pointer / match pointer
        # T1 (IN)   : target bytes
        # T2 (IN)   : end pointer
        # vAC (OUT) : match pointer or zero
        # T3        : used
        if 'has_SYS_ScanMemory' in rominfo:
            info = rominfo['has_SYS_ScanMemory']
            addr = int(str(info['addr']),0)
            cycs = int(str(info['cycs']),0)
            _MOVIW(addr,'sysFn')
            label('.loop')
            LDW(T2);XORW(T0);_BEQ('.done')
            LD(vACH);_BNE('.s1')
            LDW(T2);SUBW(T0);_BLT('.s1')
            SYS(cycs);RET()
            label('.s1')
            LDI(0);SUBW(T0)
            SYS(cycs);INC(T0+1);_BEQ('.loop')
            label('.done')
            RET()
        else:
            LDW('sysArgs0')
            label('.loop')
            XORW(T2);_BEQ('.done')
            LDW(T0);PEEK();ST(vACH);XORW(T1);ST(T3)
            LD(vACH);_BEQ('.ok')
            LD(T3);_BEQ('.ok')
            LDI(1);ADDW(T0);STW(T0)
            _BRA('.loop')
            label('.ok')
            LDW(T0)
            label('.done')
            RET()

    module(name='memchr.s',
           code=[('EXPORT', 'memchr'),
                 ('EXPORT', '__memchr2'),
                 ('EXPORT', 'memchr.sub'),
                 ('CODE', 'memchr', code1) ] )


    # -- void *_memchr2(const void *s, char c0, char c1, size_t n)
    def code2():
        nohop()
        label('_memchr2');
        LD(R9);ST(T1)
        LD(R10);ST(T1+1)
        LDW(R8);STW(T0);ADDW(R10);STW(T2)
        if args.cpu >= 6:
            JNE('memchr.sub')
        else:
            PUSH();_CALLJ('memchr.sub');POP()
        RET()

    module(name='_memchr2.s',
           code=[('EXPORT', '_memchr2'),
                 ('IMPORT', 'memchr.sub'),
                 ('CODE', '_memchr2', code2) ] )

    
    # -- int strlen(const char *s)
    def code3():
        nohop()
        label('strlen')
        PUSH()
        LDI(0);STW(T1);STW(T2)
        _MOVW(R8,T0)
        _CALLJ('memchr.sub')  # preserve R8!
        SUBW(R8)
        label('.done')
        tryhop(2);POP();RET();

    module(name='strlen.s',
           code=[('EXPORT', 'strlen'),
                 ('IMPORT', 'memchr.sub'),
                 ('CODE', 'strlen', code3) ] )

scope()


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
