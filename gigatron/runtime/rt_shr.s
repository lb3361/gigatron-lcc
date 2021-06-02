

def scope():
   
    def code0():
        nohop()
        label('__@shrsysfn')
        PUSH();LSLW();STW(vLR)
        LDWI(v('.shrtable')-2)
        ADDW(vLR);DEEK();STW('sysFn')
        POP();RET()
        label(".shrtable")
        words("SYS_LSRW1_48")
        words("SYS_LSRW2_52")
        words("SYS_LSRW3_52")
        words("SYS_LSRW4_50")
        words("SYS_LSRW5_50")
        words("SYS_LSRW6_48")
        words('SYS_LSRW7_30')

    module(name='rt_shrtable.s',
           code=[('EXPORT', '__@shrsysfn'),
                 ('CODE', '__@shrsysfn', code0) ] )

    # SHRU: T3<<T2 -> vAC  (unsigned)
    def code1():
       label('_@_shru')
       PUSH()
       LD(T2);ANDI(8);_BEQ('.shru7')
       LD(T3+1);STW(T3)
       label('.shru7')
       LD(T2);ANDI(7);_BEQ('.shru1');
       _CALLI('__@shrsysfn')
       LDW(T3);SYS(52)
       tryhop(2);POP();RET()
       label('.shru1')
       LDW(T3)
       tryhop(2);POP();RET()

    module(name='rt_shru.s',
           code=[('EXPORT', '_@_shru'),
                 ('IMPORT', '__@shrsysfn'),
                 ('CODE', '_@_shru', code1) ] )

    # SHRS: T3<<T2 -> vAC  (signed)
    # clobbers T0
    def code2():
       label('_@_shrs')
       PUSH();
       LDW(T3);_BGE('.shrs1')
       _LDI(0xffff);XORW(T3);STW(T3)
       _CALLJ('_@_shru')
       STW(T3);_LDI(0xffff);XORW(T3)
       _BRA('.shrs2')
       label('.shrs1')
       _CALLJ('_@_shru')
       label('.shrs2')
       tryhop(2);POP();RET()

    module(name='rt_shru.s',
           code=[('EXPORT', '_@_shrs'),
                 ('IMPORT', '_@_shru'),
                 ('CODE', '_@_shrs2', code2) ] )

    # SHRU1/SHRS1 : AC <-- AC >> 1 (unsigned)
    def code0():
        nohop()
        label('_@_shru1')
        STW(T3); LDWI('SYS_LSRW1_48'); STW('sysFn'); LDW(T3)
        SYS(48)
        RET()
        label('_@_shrs1')
        BGE('_@_shru1')
        STW(T3); LDWI('SYS_LSRW1_48'); STW('sysFn'); LDWI(0x8000); STW(T2); LDW(T3)
        SYS(48); ORW(T2)
        RET()

    module(name='rt_shr1.s',
           code=[('EXPORT', '_@_shrs1'),
                 ('EXPORT', '_@_shru1'),
                 ('CODE', '_@_shru1', code0) ] )
   
scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
