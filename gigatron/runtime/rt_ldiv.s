
def scope():


    def code_ldivworker():
        # inputs
        #  LAC:    a  dividend  [unsigned]
        #  T0T1:   d  divisor   [unsigned, nonzero]
        # returns
        #  B0:     shift amount
        #  T2T3:   quotient
        #  LAC:    remainder<<B1
        # uses
        #  B1:     shift counter
        label('__@ldivworker')
        PUSH()
        LDI(0);STW(B0);STW(T2);STW(T3)                     # clear
        label('.ldw1')
        _CALLJ('__@lcmpu_t0t1');_BLT('.ldw5')              # stop if q>a
        _LDI(0xff80);ANDW(T0+2);_BNE('.ldw2')
        LDW(T0+1);STW(T0+2);LD(T0);ST(T0+1);LDI(0);ST(T0)  # shift by 8 positions
        LD(B0);ADDI(8);ST(B0);_BRA('.ldw1')
        label('.ldw2')
        LD(T0+3);ANDI(0xc0);_BNE('.ldw3')
        _CALLJ('__@lshl1_t0t1')                            # shift by 1 position
        INC(B0);_BRA('.ldw1')
        label('.ldw3')                                     # cannot safely shift anymore
        _CALLJ('__@lsub_t0t1');INC(T2);_BRA('.ldw1')       # subtract q from a until q>a
        label('.ldw4')
        INC(B1);                                           # incr shift counter
        _CALLJ('_@_lshl1')                                 # shift a
        _CALLJ('__@lshl1_t2t3')                            # shift q
        _CALLJ('__@lcmpu_t0t1');_BLT('.ldw5')              # can we subtract
        _CALLJ('__@lsub_t0t1');INC(T2);                    # yes: subtract and set low bit of q
        label('.ldw5')
        LD(B1);XORW(B0);LD(vACL);_BNE('.ldw4')             # shift more?
        tryhop(2);POP();RET()

    module(name='rt_ldivworker.s',
           code=[ ('EXPORT', '__@ldivworker'),
                  ('IMPORT', '__@lsub_t0t1'),
                  ('IMPORT', '__@lcmpu_t0t1'),
                  ('IMPORT', '_@_lshl1'),
                  ('IMPORT', '__@lshl1_t2t3'),
                  ('IMPORT', '__@lshl1_t0t1'),
                  ('CODE', '__@ldivworker', code_ldivworker) ])

    def code_ldivprep():
        nohop()
        label('__@ldivprep')
        STW(T3);DEEK();STW(T0);
        LDW(T3);ADDI(2);DEEK();STW(T0+2);
        ORW(T0);_BNE('.ldp1')
        LDWI(0x0104);_CALLI('_@_raise');POP() # get return address from caller
        label('.ldp1')
        RET()

    module(name='rt_ldivprep.s',
           code=[ ('EXPORT', '__@ldivprep'),
                  ('IMPORT', '_@_raise'),
                  ('CODE',   '__@ldivprep', code_ldivprep) ] )

    def code_ldivu():
        # LDIVU : LAC <- LAC / [vAC]
        label('_@_ldivu')
        PUSH()
        _CALLI('__@ldivprep')
        _CALLJ('__@ldivworker')
        LDW(T2);STW(LAC);LDW(T2+2);STW(LAC+2)
        tryhop(2);POP();RET()

    module(name='rt_ldivu.s',
           code=[ ('EXPORT', '_@_ldivu'),
                  ('IMPORT', '__@ldivprep'),
                  ('IMPORT', '__@ldivworker'),
                  ('CODE',   '_@_ldivu', code_ldivu) ] )

    def code_lmodu():
        # LMODU : LAC <- LAC % [vAC]
        #        T0T1 <- LAC / [vAC]
        label('_@_lmodu')
        PUSH()
        _CALLI('__@ldivprep')
        _CALLJ('__@ldivworker')
        _CALLI('__@lshru_b0')
        LDW(T2);STW(T0);LDW(T2+2);STW(T0+2)
        tryhop(2);POP();RET()

    module(name='rt_lmodu.s',
           code=[ ('EXPORT', '_@_lmodu'),
                  ('IMPORT', '__@ldivprep'),
                  ('IMPORT', '__@ldivworker'),
                  ('IMPORT', '__@lshru_b0'),
                  ('CODE',   '_@_lmodu', code_lmodu) ] )

    def code_ldivsign():
        # B2 bit 7 : quotient sign
        # B2 bit 1 : remainder sign
        label('__@ldivsign')
        PUSH()
        LDI(0);ST(B2)
        LDW(LAC+2);_BGE('.lds1')
        _CALLJ('_@_lneg')
        LD(B2);XORI(0x81);ST(B2)
        label('.lds1')
        LDW(T0+2);_BGE('.lds2')
        _CALLJ('__@lneg_t0t1')
        LD(B2);XORI(0x80);ST(B2)
        label('.lds2')
        tryhop(2);POP();RET()

    module(name='rt_ldivsign.s',
           code=[ ('EXPORT', '__@ldivsign'),
                  ('IMPORT', '__@lneg_t0t1'),
                  ('IMPORT', '_@_lneg'),
                  ('CODE',   '__@ldivsign', code_ldivsign) ] )

    def code_ldivs():
        # LDIVS : LAC <- LAC / [vAC]
        label('_@_ldivs')
        PUSH()
        _CALLI('__@ldivprep')
        _CALLJ('__@ldivsign')
        _CALLJ('__@ldivworker')
        LDW(T2);STW(LAC);LDW(T2+2);STW(LAC+2)
        LD(B2);ANDI(0x80);_BEQ('.ret')
        _CALLJ('_@_lneg')
        label('.ret')
        tryhop(2);POP();RET()

    module(name='rt_ldivs.s',
           code=[ ('EXPORT', '_@_ldivs'),
                  ('IMPORT', '__@ldivprep'),
                  ('IMPORT', '__@ldivsign'),
                  ('IMPORT', '__@ldivworker'),
                  ('IMPORT', '_@_lneg'),
                  ('CODE',   '_@_ldivs', code_ldivs) ] )

    def code_lmods():
        # LMODS : LAC <- LAC % [vAC]
        #        T0T1 <- LAC / [vAC]
        label('_@_lmods')
        PUSH()
        _CALLI('__@ldivprep')
        _CALLJ('__@ldivsign')
        _CALLJ('__@ldivworker')
        _CALLI('__@lshru_b0')
        LDW(T2);STW(T0);LDW(T2+2);STW(T0+2)
        LD(B2);ANDI(0x80);_BEQ('.lms1')
        _CALLJ('__@lneg_t0t1')
        label('.lms1')
        LD(B2);ANDI(0x01);BEQ('.lms2')
        _CALLJ('_@_lneg')
        label('.lms2')
        tryhop(2);POP();RET()

    module(name='rt_lmods.s',
           code=[ ('EXPORT', '_@_lmods'),
                  ('IMPORT', '__@ldivprep'),
                  ('IMPORT', '__@ldivsign'),
                  ('IMPORT', '__@ldivworker'),
                  ('IMPORT', '__@lneg_t0t1'),
                  ('IMPORT', '_@_lneg'),
                  ('IMPORT', '__@lshru_b0'),
                  ('CODE',   '_@_lmods', code_lmods) ] )


scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
