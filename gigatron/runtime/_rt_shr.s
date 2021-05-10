
# T3<<T2 -> vAC
# SHRS clobbers T0

def code0():
   label('_@_shru')
   PUSH()
   LD(T2);ANDI(0x8);_BEQ('.try7')
   LD(T3+1);STW(T3)
   label('.try7')
   LD(T2);ANDI(7);_BNE('.shru1');
   LDW(T3);_BRA('.shru2')
   label('.shru1')
   XORI(7);_BNE('.try6')
   LDWI("SYS_LSRW4_50");STW('sysFn')
   LDW(T3);SYS(50);LSLW();SYS(50);_BRA('.shru2')
   label('.try6')
   LSLW();STW(T2);LDWI(v('.systable')-2);ADDW(T2);DEEK();STW('sysFn')
   LDW(T3);SYS(52)
   label('.shru2')
   tryhop(2);POP();RET()

def code1():
   label(".systable")
   words("SYS_LSRW6_48")
   words("SYS_LSRW5_50")
   words("SYS_LSRW4_50")
   words("SYS_LSRW3_52")
   words("SYS_LSRW2_52")
   words("SYS_LSRW1_48")
   
def code2():
   label('_@_shrs')
   PUSH();
   LDW(T3);_BGE('.shrs1')
   LDWI(0xffff);XORW(T3);STW(T3)
   _CALLJ('_@_shru')
   STW(T3);LDWI(0xffff);XORW(T3)
   _BRA('.shrs2')
   label('.shrs1')
   _CALLJ('_@_shru')
   label('.shrs2')
   tryhop(2);POP();RET()
   
code= [ ('EXPORT', '_@_shru'),
        ('EXPORT', '_@_shrs'),
        ('DATA', '.systable', code1, 12, 2),
        ('CODE', '_@_shru', code0),
        ('CODE', '_@_shrs', code2) ]

module(code=code, name='_rt_shr.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
