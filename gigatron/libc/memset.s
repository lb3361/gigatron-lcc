
def scope():
    
    # memset(d,v,l)

    def code0():
        '''version that uses either FILL or Sys_SetMemory_v2_54'''
        nohop()
        label('memset');                            # R8=d, R9=v, R10=l
        if args.cpu >= 7:
            #
            # Using the FILL opcode
            #
            LDW(R8);STW(T2);ADDW(R10);STW(T1)
            LD(R9);STW(T3);_BRA('.test')
            label('.loop')
            LDI(0);SUBW(T2);MOVQB(1,vACH);FILL()
            MOVQB(0,T2);INC(T2+1)
            label('.test')
            LDW(T2);XORW(T1);_BEQ('.done')
            LD(vACH);_BNE('.loop')
            LDW(T1);SUBW(T2);INC(vACH);FILL()

        elif not "without_SYS_SetMemory" in rominfo:
            #
            # Using SYS_SetMemory_v2
            #
            LDW(R8);STW(T2);ADDW(R10);STW(T4)
            LD(R9);ST('sysArgs1')
            _MOVIW('SYS_SetMemory_v2_54','sysFn')
            _BRA('.test')
            label('.loop')
            LDI(0);SUBW(T2);ST('sysArgs0')
            LDI(0);ST(T2);INC(T2+1)
            SYS(54)
            label('.test')
            LDW(T2);STW('sysArgs2');XORW(T4);_BEQ('.done')
            LD(vACH);_BNE('.loop')
            LDW(T4);SUBW(T2);ST('sysArgs0')
            SYS(54)

        else:
            #
            # Byte per byte for ROMv1
            #
            LDW(R8);STW(T2);ADDW(R10);STW(T4)
            LDW(T2);_BRA('.test')
            label('.loop')
            LD(R9);POKE(T2)
            LDI(1);ADDW(T2);STW(T2)
            label('.test')
            XORW(T4);_BNE('.loop')

        label('.done')
        LDW(R8);RET()


    return [('EXPORT', 'memset'),
            ('CODE', 'memset', code0) ]

module(code=scope(), name='memset.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
