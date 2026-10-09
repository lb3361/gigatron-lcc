
def scope():

    # -- const char *_strend(const char *);
    
    def code0():
        nohop()
        label('_strend')
        LDI(0);STW(T1)
        label('memchr.sub.t2')
        STW(T2)
        label('memchr.sub')
        # R8 (IN)   : start pointer, unchanged
        # T1 (IN)   : target bytes, unchanged
        # T2 (IN)   : end pointer, unchanged
        # vAC (OUT) : match pointer or zero
        # T0/T3     : used
        _MOVW(R8,T0)
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

    module(name='_strend.s',
           code=[('EXPORT', '_strend'),
                 ('EXPORT', 'memchr.sub'),
                 ('EXPORT', 'memchr.sub.t2'),
                 ('CODE', '_strend', code0) ] )

    
    # -- void *memchr(const void *s, int c0, size_t n)
    # scan at most n bytes from s until finding one equal to c0
    # return pointer to the byte if found, 0 if not found.
    # known to leave R8 unchanged!!!
    def code1():
        nohop()
        label('memchr')
        LD(R9);ST(T1);ST(T1+1)
        LDW(R8);ADDW(R10)
        if args.cpu >= 7:
            JMP('memchr.sub.t2')
        elif args.cpu >= 5:
            PUSH();CALLI('memchr.sub.t2')
            tryhop(2);POP();RET()
        else:
            STW(T2);PUSH();_CALLJ('memchr.sub')
            tryhop(2);POP();RET()

    module(name='memchr.s',
           code=[('EXPORT', 'memchr'),
                 ('IMPORT', 'memchr.sub'),
                 ('IMPORT', 'memchr.sub.t2'),
                 ('CODE', 'memchr', code1) ] )


    # -- void *_memchr2(const void *s, char c0, char c1, size_t n)
    # -- void *__memchr2(const void *s, int c0c1, size_t n)
    def code2():
        nohop()
        label('_memchr2')
        LD(R10);ST(R9+1);_MOVW(R11,R10)
        label('__memchr2')
        _MOVW(R9, T1)
        LDW(R8);ADDW(R10)
        if args.cpu >= 7:
            JMP('memchr.sub.t2')
        elif args.cpu >= 5:
            PUSH();CALLI('memchr.sub.t2')
            tryhop(2);POP();RET()
        else:
            STW(T2);PUSH();_CALLJ('memchr.sub')
            tryhop(2);POP();RET()

    module(name='_memchr2.s',
           code=[('EXPORT', '_memchr2'),
                 ('EXPORT', '__memchr2'),
                 ('IMPORT', 'memchr.sub'),
                 ('IMPORT', 'memchr.sub.t2'),
                 ('CODE', '_memchr2', code2) ] )

    
    # -- int strlen(const char *s)
    def code3():
        nohop()
        label('strlen')
        PUSH()
        _CALLJ('_strend')
        SUBW(R8)
        label('.done')
        tryhop(2);POP();RET();

    module(name='strlen.s',
           code=[('EXPORT', 'strlen'),
                 ('IMPORT', '_strend'),
                 ('CODE', 'strlen', code3) ] )


    # -- extern char *strchr(const char *, int);
    def code4():
        nohop()
        label('strchr')
        PUSH()
        LD(R9);STW(T1)
        LDI(0)
        if args.cpu >= 5:
            CALLI('memchr.sub.t2')
        else:
            STW(T2);_CALLJ('memchr.sub')
        STW(T0);PEEK();_BEQ('.ret')
        LDW(T0)
        label('.ret')
        tryhop(2);POP();RET()

    module(name='strchr.s',
           code=[('EXPORT', 'strchr'),
                 ('IMPORT', 'memchr.sub'),
                 ('IMPORT', 'memchr.sub.t2'),
                 ('CODE', 'strchr', code4) ] )

    
scope()


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
