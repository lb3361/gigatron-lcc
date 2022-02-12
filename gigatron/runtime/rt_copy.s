def scope():

    # LCOPY [T3..T3+3] --> [T2..]
    # Since longs are even aligned,
    # we cannot cross a page boundary inside the DEEK/DOKE

    def code1():
        nohop()
        label('_@_lcopy')
        if args.cpu >= 6:
            DEEKV(T3);DOKE(T2)
            INCW(T3);INCW(T2)
            INCW(T3);INCW(T2)
            DEEKV(T3);DOKE(T2)
        else:
            LDW(T3);DEEK();DOKE(T2)
            LDI(2);ADDW(T2);STW(T2)
            LDI(2);ADDW(T3);DEEK();DOKE(T2)
        RET()

    module(name='rt_lcopy.s',
           code=[ ('EXPORT', '_@_lcopy'),
                  ('CODE', '_@_lcopy', code1) ] )

    # FCOPYZ LCOPYZ: Zero page copy for floats and longs
    #   with short call sequence:  LDWI(<dst><src>);CALLI
    # FCOPYNC: Float copy when no page crossings
    def code2():
        nohop()
        if args.cpu >= 6:
            label('_@_fcopyz')
            ST(T3);LD(vACH);STW(T2)
            LD(T3);STW(T3)
            label('_@_fcopync')
            PEEKp(T3);POKEp(T2)
            BRA('.cont')
            label('_@_lcopyz')
            ST(T3);LD(vACH);STW(T2)
            LD(T3);STW(T3)
            label('.cont')
            DEEKp(T3);DOKEp(T2)
            DEEKp(T3);DOKEp(T2)
            RET()
        else:
            label('_@_fcopyz')
            ST(T3);LD(vACH);STW(T2)
            LD(T3);STW(T3);
            label('_@_fcopync')
            LDW(T3);PEEK();POKE(T2)
            INC(T2);INC(T3);LDW(T3)
            BRA('.cont')
            label('_@_lcopyz')
            ST(T3);LD(vACH);STW(T2)
            LD(T3);STW(T3)
            label('.cont')
            DEEK();DOKE(T2)
            INC(T2);INC(T3)
            INC(T2);INC(T3)
            LDW(T3);DEEK();DOKE(T2)
            RET()

    module(name='rt_copyz.s',
           code=[ ('EXPORT', '_@_lcopyz'),
                  ('EXPORT', '_@_fcopyz'),
                  ('EXPORT', '_@_fcopync'),
                  ('CODE', '_@_fcopyz', code2) ])


    # FCOPY [T3..T3+5) --> [T2..T2+5)
    # BCOPY [T3..T1) --> [T2..]
    # When we can rely on nothing.
    def code3():
        nohop()
        label('_@_fcopy')
        LDI(5);ADDW(T3);STW(T1)
        label('_@_bcopy')
        _PEEKV(T3);POKE(T2)
        if args.cpu >= 6:
            INCW(T2);INCW(T3);LDW(T3)
        else:
            LDI(1);ADDW(T2);STW(T2)
            LDI(1);ADDW(T3);STW(T3)
        XORW(T1);BNE('_@_bcopy')
        RET()

    module(name='rt_bcopy.s',
           code=[ ('EXPORT', '_@_bcopy'),
                  ('EXPORT', '_@_fcopy'),
                  ('CODE', '_@_bcopy', code3) ])

    # WCOPY [T3..T1) --> [T2..]
    # Same as BCOPY but word aligned

    def code4():
        nohop()
        label('_@_wcopy')
        _DEEKV(T3);DOKE(T2)
        LDI(2);ADDW(T2);STW(T2)
        LDI(2);ADDW(T3);STW(T3)
        XORW(T1);BNE('_@_wcopy')
        RET()

    module(name='rt_wcopy.s',
           code=[ ('EXPORT', '_@_wcopy'),
                  ('CODE', '_@_wcopy', code4) ])

    # LEXTS: (vAC<0) ? -1 : 0 --> vAC
    def code5():
        nohop()
        label('_@_lexts')
        _BLT('.m1')
        LDI(0);RET();
        label('.m1')
        _LDI(-1);RET()

    module(name='rt_lexts.s',
           code=[ ('EXPORT', '_@_lexts'),
                  ('CODE', '_@_lexts', code5) ])

    # LCVI: AC to LAC with sign extension
    def code6():
        nohop()
        label('_@_lcvi')
        STW(LAC);
        LD(vACH);XORI(128);SUBI(128)
        LD(vACH);ST(LAC+2);ST(LAC+3)
        RET()

    module(name='rt_lcvi.s',
           code=[ ('EXPORT', '_@_lcvi'),
                  ('CODE', '_@_lcvi', code6) ])

    # The following are merely markers indicating that _MOVL or _MOVF
    # is used somewhere. These are useful to decide whether to import
    # printf support for longs or floats.
    
    def code_dummy():
        label('_@_using_lmov', 1)

    module(name='rt_lmov',
           code=[('EXPORT', '_@_using_lmov'),
                 ('DATA', '_@_using_lmov', code_dummy, 0, 1) ] )

    def code_dummy():
        label('_@_using_fmov', 1)

    module(name='rt_fmov',
           code=[('EXPORT', '_@_using_fmov'),
                 ('DATA', '_@_using_fmov', code_dummy, 0, 1) ] )
    
scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
