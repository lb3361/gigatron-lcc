
def scope():

    # worker
    #  LAC:    a  dividend  [0x0-0x8000000]
    #  T0T1:   d  divisor   [0x1-0x8000000]
    #  T2T3:   q  quotient
    #  B0:     c  shift amount
    #  B1:     r  saved shift amount
    #  B2:     s  sign information

    def code2():
        label('__@ldivworker')
        PUSH()
        label('.w1')
        LD(T1+1);ANDI(0xc0);_BNE('.w2')
        _CALLJ('__@lcmpu_t0t1');_BLT('.w2')
        _CALLJ('__@lshl1_t0t1')
        INC(B0)
        _BRA('.w1')
        label('.w2')
        LD(B0);ST(B1)
        label('.w3')
        _CALLJ('__@lcmpu_t0t1');_BLT('.w4')
        _CALLJ('__@lsub_t0t1')
        INC(T2)
        label('.w4')
        LD(B0);_BLE('.wret')
        SUBI(1);ST(B0)
        _CALLJ('_@_lshl1')
        _CALLJ('__@lshl1_t2t3')
        _BRA('.w3')
        label('.wret')
        tryhop(2);POP();RET()

    module(name='rt_ldivworker.s',
           code=[ ('EXPORT', '__@ldivworker'),
                  ('IMPORT', '__@lsub_t0t1'),
                  ('IMPORT', '__@lcmpu_t0t1'),
                  ('IMPORT', '_@_lshl1'),
                  ('IMPORT', '__@lshl1_t2t3'),
                  ('IMPORT', '__@lshl1_t0t1'),
                  ('CODE', '__@ldivworker', code2) ])

    # LDIVU : LAC <- LAC / [vAC]
    # - clobbers B[0-2], T[0-3])
    def code3():
        tryhop(16)
        label('_@_ldivu')
        # takes dividend in LAC
        # takes divisor in [vAC]
        # returns quotient in LAC
        PUSH()
        STW(T3);DEEK();STW(T0);
        LDW(T3);ADDI(2);DEEK();STW(T1);
        ORW(T0);_BNE('.ldivu1')
        LDWI(0x0104);_CALLI('_@_raise')
        tryhop(2);POP();RET()
        label('.ldivu1')
        _CALLJ('__@ldivu_t0t1')
        LDW(T2);STW(LAC);LDW(T3);STW(LAC+2)
        tryhop(2);POP();RET()

    module(name='rt_ldivu.s',
           code=[ ('EXPORT', '_@_ldivu'),
                  ('IMPORT', '_@_raise'),
                  ('IMPORT', '__@ldivu_t0t1'),
                  ('CODE',   '_@_ldivu', code3) ] )

    def code3b():
        # takes dividend in LAC
        # takes nonzero divisor in T0T1
        # return quotient in T2T3
        # return remainder<<B1 in LAC
        label('__@ldivu_t0t1')
        PUSH()
        LDI(0);STW(B0);STW(T2);STW(T3)
        LDW(T1);_BGE('.dA')                       # if divisor >= 0x8000000
        _CALLJ('__@lcmpu_t0t1');_BLT('.dret')
        _CALLJ('__@lsub_t0t1');INC(T2);_BRA('.dret')
        label('.dA')                              # 0 < divisor < 0x8000000
        LDW(LAC+2);_BGE('.dB')                    #  if dividend >= 0x80000000
        label('.d3')
        LD(T1+1);ANDI(0xc0);_BNE('.d4')
        _CALLJ('__@lshl1_t0t1')
        INC(B0)
        _BRA('.d3')
        label('.d4')
        INC(T2)
        _CALLJ('__@lsub_t0t1')
        LDW(LAC+2);_BLT('.d4')
        label('.dB')
        _CALLJ('__@ldivworker')
        label('.dret')
        tryhop(2);POP();RET()

    module(name='rt_ldivut0t1.s',
           code=[ ('EXPORT', '__@ldivu_t0t1'),
                  ('IMPORT', '__@lsub_t0t1'),
                  ('IMPORT', '__@lshl1_t0t1'),
                  ('IMPORT', '__@lcmpu_t0t1'),
                  ('IMPORT', '__@ldivworker'),
                  ('CODE',   '_@_ldivu_t0t1', code3b) ] )


    # LDIVS : LAC <- LAC / [vAC]
    # - clobbers B[0-2], T[0-3]

    def code4():
        label('_@_ldivs')
        # takes dividend in LAC
        # takes divisor in [vAC]
        # returns quotient in LAC
        PUSH()
        STW(T3);DEEK();STW(T0);
        LDW(T3);ADDI(2);DEEK();STW(T1);
        ORW(T0);_BNE('.ldivs1')
        LDWI(0x0104);_CALLI('_@_raise')
        tryhop(2);POP();RET()
        label('.ldivs1')
        _CALLJ('__@ldivs_t0t1')
        LDW(T0);STW(LAC);LDW(T1);STW(LAC+2)
        tryhop(2);POP();RET()

    module(name='rt_ldivs.s',
           code=[ ('EXPORT', '_@_ldivs'),
                  ('IMPORT', '_@_raise'),
                  ('IMPORT', '__@ldivs_t0t1'),
                  ('CODE',   '_@_ldivs', code4) ] )

    def code4b():
        label('__@ldivs_t0t1')
        # takes dividend in LAC
        # takes nonzero divisor in T0T1
        # return abs(quotient) in T2T3
        # return quotient in T0T1
        # return abs(remainder)<<B1 in LAC
        PUSH()
        LDI(0);STW(B0);ST(B2);STW(T2);STW(T3)
        LDW(T1);_BGE('.s2')
        _CALLJ('__@lneg_t0t1')
        INC(B2)
        label('.s2')
        LDW(LAC+2);_BGE('.s3')
        _CALLJ('_@_lneg')
        LD(B2);XORI(3);ST(B2)
        label('.s3')
        _CALLJ('__@ldivworker')
        LDW(T2);STW(T0);LDW(T3);STW(T1)
        LD(B2);ANDI(1);_BEQ('.sret')
        _CALLJ('__@lneg_t0t1')
        label('.sret')
        tryhop(2);POP();RET()

    module(name='rt_ldivst0t1.s',
           code=[ ('EXPORT', '__@ldivs_t0t1'),
                  ('IMPORT', '_@_lneg'),
                  ('IMPORT', '__@lneg_t0t1'),
                  ('IMPORT', '__@ldivworker'),
                  ('CODE',   '__@ldivs_t0t1', code4b) ])

    # LMODS: LAC % [vAC] -> LAC
    # LMODU: LAC % [vAC] -> LAC
    # - clobber B0-B2, T0-T3

    def code1():
        label('_@_lmodu')
        # takes dividend in LAC
        # takes divisor in [vAC]
        # returns remainder in LAC
        # returns quotient in T0T1
        PUSH()
        STW(T3);DEEK();STW(T0);
        LDW(T3);ADDI(2);DEEK();STW(T1);
        ORW(T0);_BNE('.lmodu1')
        LDWI(0x0104);_CALLI('_@_raise')
        tryhop(2);POP();RET()
        label('.lmodu1')
        _CALLI('__@ldivu_t0t1')
        LDW(T2);STW(T0);LDW(T3);STW(T1)
        LD(B1);_CALLI('_@_lshru')
        tryhop(2);POP();RET()

    module(name='rt_lmodu.s',
           code=[ ('CODE', '_@_lmodu', code1),
                  ('EXPORT', '_@_lmodu'),
                  ('IMPORT', '_@_lshru'),
                  ('IMPORT', '__@ldivu_t0t1') ])

    def code2():
        label('_@_lmods')
        # takes dividend in LAC
        # takes divisor in [vAC]
        # returns remainder in LAC
        # returns quotient in T0T1
        PUSH()
        STW(T3);DEEK();STW(T0);
        LDW(T3);ADDI(2);DEEK();STW(T1);
        ORW(T0);_BNE('.lmods1')
        LDWI(0x0104);_CALLI('_@_raise')
        tryhop(2);POP();RET()
        label('.lmods1')
        _CALLI('__@ldivs_t0t1')
        LDW(T2);STW(T0);LDW(T3);STW(T1)
        LD(B1);_CALLI('_@_lshru')
        LD(B2);ANDI(2);_BEQ('.m1');_CALLJ('_@_lneg');label('.m1')
        tryhop(2);POP();RET()

    module(name='rt_lmods.s',
           code=[ ('CODE', '_@_lmods', code2),
                  ('EXPORT', '_@_lmods'),
                  ('IMPORT', '_@_lshru'),
                  ('IMPORT', '__@ldivs_t0t1') ] )
    
scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
