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
        label('_@_fcopyz')
        ST(T3);LD(vACH);STW(T2)
        LD(T3);PEEK();POKE(T2)
        INC(T2);INC(T3)
        LD(T3);STW(T3);BRA('.cont')
        label('_@_lcopyz')
        ST(T3);LD(vACH);STW(T2)
        LD(T3);STW(T3);BRA('.cont')
        label('_@_fcopync')
        LDW(T3);PEEK();POKE(T2)
        INC(T2);INC(T3);LDW(T3)
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
        LDW(T3);PEEK();POKE(T2)
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
        LDW(T3);DEEK();DOKE(T2)
        LDI(2);ADDW(T2);STW(T2)
        LDI(2);ADDW(T3);STW(T3)
        XORW(T1);BNE('_@_wcopy')
        RET()

    module(name='rt_wcopy.s',
           code=[ ('EXPORT', '_@_wcopy'),
                  ('CODE', '_@_wcopy', code4) ])


    # LCVI: AC to LAC with sign extension
    def code5():
        nohop()
        label('_@_lcvi')
        STW(LAC);
        LD(vACH);XORI(128);SUBI(128)
        LD(vACH);ST(LAC+2);ST(LAC+3)
        RET()

    module(name='rt_lcvi.s',
           code=[ ('EXPORT', '_@_lcvi'),
                  ('CODE', '_@_lcvi', code5) ])


scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
