


# LSHL_T2T3 : T2T3 <<= 1
def code0():
    nohop()
    label('_@_lshl1_t2t3')
    LDW(T2);BLT('.lsl1')
    LSLW();STW(T2);LDW(T2+2);LSLW();STW(T2+2);RET()
    label('.lsl1')
    LSLW();STW(T2);LDW(T2+2);LSLW();ORI(1);STW(T2+2);RET()

# LNEG_T0T1 : -LAC --> LAC
def code1():
    nohop()
    label('_@_lneg_t0t1')
    LDWI(0xffff);XORW(T0+2);STW(T0+2)
    LDWI(0xffff);XORW(T0);ADDI(1);STW(T0)
    BNE('.lneg1')
    LDI(1);ADDW(T0+2);STW(T0+2)
    label('.lneg1')
    RET()
   
# worker
#  LAC:    a  dividend  [0x0-0x8000000]
#  T0T1:   d  divisor   [0x1-0x8000000]
#  T2T3:   q  quotient
#  LACt:   c  shift amount
#  LACt+1: r  saved shift amount
#  LACx:   s  sign information

def code2():
    label('_@_ldivworker')
    PUSH()
    label('.w1')
    LD(T1+1);ANDI(0xc0);_BNE('.w2')
    _CALLJ('_@_lcmpu_t0t1');_BLT('.w2')
    _CALLJ('_@_lshl1_t0t1')
    INC(LACt)
    _BRA('.w1')
    label('.w2')
    LD(LACt);ST(LACt+1)
    label('.w3')
    _CALLJ('_@_lcmpu_t0t1');_BLT('.w4')
    _CALLJ('_@_lsub_t0t1')
    INC(T2)
    label('.w4')
    LD(LACt);_BLE('.wret')
    SUBI(1);ST(LACt)
    _CALLJ('_@_lshl1')
    _CALLJ('_@_lshl1_t2t3')
    _BRA('.w3')
    label('.wret')
    tryhop(2);POP();RET()

def code3():
    align(2)
    label('_@_SIGdiv')
    space(2)

def code4():
    nohop()
    label('_@_ldivbyzero')
    _LDW('_@_SIGdiv');POP();BEQ('.z2')
    # call _@_SIGdiv if nonzero
    STW(T0);CALL(T0)
    label('.z2')
    # exit with return code 100
    LDWI('_@_exit');STW(T0);LDI(100);CALL(T0)  
    
def code5():
    tryhop(16)
    label('_@_ldivu')
    STW(T3);DEEK();STW(T0);
    LDW(T3);ADDI(2);DEEK();STW(T0+2);
    label('_@_ldivu_t0t1')
    PUSH()
    LDI(0);STW(LACt);STW(T2);STW(T2+2)
    LDW(T0);ORW(T0+2);_BNE('.d1')             # if divisor is zero
    _CALLJ('_@_ldivbyzero')
    label('.d1')
    LDW(T0+2);_BGE('.dA')                     # if divisor >= 0x8000000
    _CALLJ('_@_lcmpu_t0t1');_BLT('.dret')
    _CALLJ('_@_lsub_t0t1');INC(T2);_BRA('.dret')
    label('.dA')                              # 0 < divisor < 0x8000000
    LDW(LAC+2);_BGE('.dB')                    #  if dividend >= 0x80000000
    label('.d3')
    LD(T1+1);ANDI(0xc0);_BNE('.d4')
    _CALLJ('_@_lshl1_t0t1')
    INC(LACt)
    _BRA('.d3')
    label('.d4')
    INC(T2)
    _CALLJ('_@_lsub_t0t1')
    LDW(LAC+2);_BLT('.d4')
    label('.dB')
    _CALLJ('_@_ldivworker')
    label('.dret')
    LDW(LAC);STW(T0);LDW(LAC+2);STW(T0+2)    # Save remainder for modu
    LDW(T2);STW(LAC);LDW(T2+2);STW(LAC+2)
    tryhop(2);POP();RET()

def code6():
    tryhop(16)
    label('_@_ldivs')
    STW(T3);DEEK();STW(T0);
    LDW(T3);ADDI(2);DEEK();STW(T0+2);
    label('_@_ldivs_t0t1')
    PUSH()
    LDI(0);STW(LACt);STW(T2);STW(T2+2);ST(LACx)
    LDW(T0);ORW(T0+2);_BNE('.s1')             # if divisor is zero
    _CALLJ('_@_ldivbyzero')
    label('.s1')                              # store signs
    LDW(T0+2);_BGE('.s2')
    _CALLJ('_@_lneg_t0t1')
    INC(LACx)
    label('.s2')
    LDW(LAC+2);_BGE('.s3')
    _CALLJ('_@_lneg')
    LD(LACx);XORI(3);ST(LACx)
    label('.s3')
    _CALLJ('_@_ldivworker')
    LDW(LAC);STW(T0);LDW(LAC+2);STW(T0+2)    # Save remainder for modu
    LDW(T2);STW(LAC);LDW(T2+2);STW(LAC+2)
    LD(LACx);ANDI(1);_BEQ('.sret')
    _CALLJ('_@_lneg')
    label('.sret')
    tryhop(2);POP();RET()

code= [ ('EXPORT', '_@_ldivu'),
        ('EXPORT', '_@_ldivu_t0t1'),
        ('EXPORT', '_@_ldivs'),
        ('EXPORT', '_@_ldivs_t0t1'),
        ('IMPORT', '_@_lsub_t0t1'),
        ('IMPORT', '_@_lcmpu_t0t1'),
        ('IMPORT', '_@_lshl1'),
        ('IMPORT', '_@_lshl1_t0t1'),
        ('IMPORT', '_@_lneg'),
        ('CODE', '_@_lshl1_t2t3', code0),
        ('CODE', '_@_lneg_t0t1', code1),
        ('CODE', '_@_ldivworker', code2),
        ('COMMON', '_@_SIGdiv',  code3, 2, 2),
        ('CODE',   '_@_ldivbyzero', code4),
        ('CODE',   '_@_ldivu', code5),
        ('CODE',   '_@_ldivs', code6) ]

module(code=code, name='_rt_ldiv.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
