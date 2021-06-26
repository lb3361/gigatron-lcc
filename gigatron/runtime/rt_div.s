def scope():


    if 'has_at67_SYS_Divide_s16' in rominfo and args.cpu >= 6:
        # Divide using SYS call
        info = rominfo['has_at67_SYS_Divide_s16']
        addr = int(str(info['addr']),0)
        cycs = int(str(info['cycs']),0)

        # DIVU:  T3/vAC -> vAC
        def code2():
            label('_@_divu')
            PUSH()
            STW('sysArgs2');_BLT('.bigy');_BNE('.divs1')
            LDWI(0x0104);_CALLI('_@_raise'); # divide by zero error
            tryhop(2);POP();RET()
            label('.divs1')
            LDW(T3);STW('sysArgs0');_BLT('.bigx');
            label('.divs2')
            MOVQW(0,'sysArgs4');MOVQW(1,'sysArgs6')
            _LDI(addr);STW('sysFn');SYS(cycs)
            LDW('sysArgs0')
            tryhop(2);POP();RET()
            # special cases
            label('.bigx')                             # x >= 0x8000
            LD('sysArgs3');ANDI(0x40);_BEQ('.divs2')   # - but y is small enough
            label('.bigy')                             # y large
            MOVQW(0,T2);LDW(T3);BRA('.loop1')          # - repeated subtractions will do
            label('.loop0')                            #   (loops at most 3 times)
            INC(T2)
            LDW(T3);SUBW('sysArgs2');STW(T3)
            label('.loop1')
            _CMPWU('sysArgs2');_BGE('.loop0')
            LDW(T3);STW('sysArgs4')                    # - for modu
            LDW(T2)
            tryhop(2);POP();RET()

        module(name='rt_divu.a',
               code=[ ('CODE', '_@_divu', code2),
                      ('IMPORT', '_@_raise'),
                      ('EXPORT', '_@_divu') ] )

        # MODU: T3 % T2 -> AC
        #  saves T3 / T2 in T1
        def code2():
            label('_@_modu')
            PUSH()
            _CALLJ('_@_divu')
            STW(T1)         # quotient
            LDW('sysArgs4') # remainder
            tryhop(2);POP();RET()

        module(name='rt_modu.s',
               code=[ ('CODE', '_@_modu', code2),
                      ('EXPORT', '_@_modu'),
                      ('IMPORT', '_@_divu') ] )

        # DIVS:  T3/vAC -> vAC
        # clobbers B2
        def code2():
            label('_@_divs')
            PUSH();MOVQ(0,B2)
            STW(T2);_BGT('.divs2');_BNE('.divs1')
            LDWI(0x0104);_CALLI('_@_raise')  # divide by zero error
            tryhop(2);POP();RET()
            label('.divs1')
            NEGW(vAC);INC(B2)
            label('.divs2')
            STW('sysArgs2')
            LDW(T3);_BGT('.divs3')
            NEGW(vAC);XORBI(3,B2)
            label('.divs3')
            STW('sysArgs0')
            MOVQW(0,'sysArgs4');MOVQW(1,'sysArgs6')
            _LDI(addr);STW('sysFn');SYS(cycs)
            LD(B2);ANDI(1);_BEQ('.divs4')
            NEGW('sysArgs0')
            label('.divs4')
            LDW('sysArgs0')
            tryhop(2);POP();RET()

        module(name='rt_divs.a',
               code=[ ('CODE', '_@_divs', code2),
                      ('IMPORT', '_@_raise'),
                      ('EXPORT', '_@_divs') ] )

        # MODS: T3 % T2 -> AC
        #  saves T3 / T2 in T1
        #  clobbers B2
        def code2():
            label('_@_mods')
            PUSH()
            _CALLJ('_@_divs')
            STW(T1)                       # quotient
            LD(B2);ANDI(2);_BEQ('.mods1')
            NEGW('sysArgs4')
            label('.mods1')
            LDW('sysArgs4')               # remainder
            tryhop(2);POP();RET()

        module(name='rt_mods.s',
               code=[ ('CODE', '_@_mods', code2),
                      ('EXPORT', '_@_mods'),
                      ('IMPORT', '_@_divs') ] )

    else:
        # Divide using vCPU

        # worker
        #  T3:   a  dividend  (0-8000 only)
        #  T2:   d  divisor   (1-8000 only)
        #  T1:   q  quotient
        #  B0:   c  shift amount
        #  B1  : r  saved shift amount
        #  B2:   s  sign
        def code0():
            nohop()
            label('__@divworker')
            label('.w1loop')
            LDW(T3);SUBW(T2);_BLT('.w2')
            LDW(T2);LSLW();_BLT('.w2')
            STW(T2);INC(B0);_BRA('.w1loop')
            label('.w2')
            LD(B0);ST(B1)
            label('.w2loop')
            LDW(T3);SUBW(T2);_BLT('.w3')
            STW(T3);INC(T1)
            label('.w3')
            LD(B0);XORI(128);SUBI(129);_BLT('.w4')
            ST(B0);
            LDW(T3);LSLW();STW(T3)
            LDW(T1);LSLW();STW(T1)
            _BRA('.w2loop')
            label('.w4')
            RET()

        module(name='rt_divworker.s',
               code=[ ('CODE', '__@divworker', code0),
                      ('EXPORT', '__@divworker') ] )

        # DIVU:  T3/vAC -> vAC
        # clobbers B0-B2, T1,T2
        def code1():
            tryhop(3)
            label('_@_divu')
            STW(T2)
            label('__@divu_t2')
            PUSH()
            LDI(0);STW(T1);STW(B0)
            LDW(T2);_BGT('.divuA');_BNE('.divu1')
            LDWI(0x0104)             # case d == 0
            _CALLI('_@_raise');_BRA('.divu5')
            label('.divu1')          # case d >= 0x8000
            LDW(T3);_BGE('.divu2')
            SUBW(T2);_BLT('.divu2')
            STW(T3);LDI(1);_BRA('.divu5')
            label('.divu2')
            LDI(0);_BRA('.divu5')
            label('.divuA')          # case 0 < d < 0x8000
            LDW(T3);_BGE('.divuB')
            label('.divu3')          # | a >= 0x8000
            LDW(T2);LSLW();_BLT('.divu4')
            STW(T2);INC(B0);_BRA('.divu3')
            label('.divu4')
            INC(T1);
            LDW(T3);SUBW(T2)
            STW(T3);BLT('.divu4')
            label('.divuB')          # | a < 0x8000
            _CALLJ('__@divworker')
            LDW(T1)
            label('.divu5')
            tryhop(2);POP();RET()

        module(name='rt_divu.s',
               code=[ ('CODE', '_@_divu', code1),
                      ('IMPORT', '_@_raise'),
                      ('IMPORT', '__@divworker'),
                      ('EXPORT', '_@_divu'),
                      ('EXPORT', '__@divu_t2')])

        # MODU: T3 % vAC -> AC
        #  saves T3 / vAC in T1
        #  clobbers B0-B2, T1, T2
        def code1():
            label('_@_modu')
            PUSH();STW(T2)
            _CALLJ('__@divu_t2')
            STW(T1);
            LD(B1);_CALLI('_@_shru')
            tryhop(2);POP();RET()

        module(name='rt_modu.s',
               code=[ ('CODE', '_@_modu', code1),
                      ('EXPORT', '_@_modu'),
                      ('IMPORT', '_@_shru'),
                      ('IMPORT', '__@divu_t2') ])

        # DIVS:  T3/vAC -> vAC
        # clobbers B0-B2, T1,T2
        def code2():
            tryhop(3)
            label('_@_divs')
            STW(T2)
            label('__@divs_t2')
            PUSH()
            LDI(0);STW(T1);STW(B0);ST(B2)
            LDW(T2);_BGT('.divs2');_BNE('.divs1')
            LDWI(0x0104)                       # case d == 0
            _CALLI('_@_raise');_BRA('.divs5')
            label('.divs1')
            LDI(0);SUBW(T2);STW(T2);INC(B2)    # case d < 0
            label('.divs2')
            LDW(T3);_BGE('.divs3')
            LDI(0);SUBW(T3);STW(T3)            # case a < 0
            LD(B2);XORI(3);ST(B2)
            label('.divs3')
            _CALLJ('__@divworker')
            LD(B2)
            ANDI(1)
            _BEQ('.divs4')
            LDI(0);
            SUBW(T1);
            _BRA('.divs5')
            label('.divs4')
            LDW(T1)
            label('.divs5')
            tryhop(2);POP();RET()

        module(name='rt_divs.a',
               code=[ ('CODE', '_@_divs', code2),
                      ('IMPORT', '_@_raise'),
                      ('IMPORT', '__@divworker'),
                      ('EXPORT', '_@_divs'),
                      ('EXPORT', '__@divs_t2')] )

        # MODS: T3 % T2 -> AC
        #  saves T3 / T2 in T1
        #  clobbers B0-B2, T1, T2
        def code2():
            label('_@_mods')
            PUSH();STW(T2)
            _CALLJ('__@divs_t2')
            STW(T1);
            LD(B1);_CALLI('_@_shru');STW(T3)
            LD(B2);ANDI(2);_BEQ('.mods1')
            LDI(0);SUBW(T3);_BRA('.mods2')
            label('.mods1')
            LDW(T3)
            label('.mods2')
            tryhop(2);POP();RET()

        module(name='rt_mods.s',
               code=[ ('CODE', '_@_mods', code2),
                      ('EXPORT', '_@_mods'),
                      ('IMPORT', '_@_shru'),
                      ('IMPORT', '_@_divs') ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
