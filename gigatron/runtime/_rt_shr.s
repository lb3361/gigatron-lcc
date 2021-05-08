
# T3<<T2 -> vAC

def code0():
   label('_@_shru')
   PUSH()
   _BRA('.shru')
   label('_@_shrs')
   PUSH();
   LDW(T3);_BGE('.shru')
   LDWI(0xffff);STW(T1);XORW(T3);STW(T3);_BRA('.1')
   label('.shru')
   LDI(0);STW(T1)
   label('.1')
   LDWI(0xfff0);ANDW(T2);_BEQ('.try8')
   LDI(0);_BRA('.ret2')
   label('.try8')
   LDW(T2);ANDI(0x8);_BEQ('.try7')
   LD(T3+1);STW(T3)
   label('.try7')
   LDW(T2);ANDI(7);_BEQ('.ret');XORI(7);_BNE('.try6')
   LDWI("SYS_LSRW4_50");STW('sysFn')
   LDW(T3);SYS(50);LSLW();SYS(50);_BRA('.ret2')
   label('.try6')
   LSLW();STW(T2);LDWI(v('.systable')-2);ADDW(T2);DEEK();STW('sysFn')
   LDW(T3);SYS(52);_BRA('.ret2')
   label('.ret')
   LDW(T3)
   label('.ret2')
   XORW(T1)
   tryhop(2);POP();RET()

def code1():
   label(".systable")
   words("SYS_LSRW6_48")
   words("SYS_LSRW5_50")
   words("SYS_LSRW4_50")
   words("SYS_LSRW3_52")
   words("SYS_LSRW2_52")
   words("SYS_LSRW1_48")
   
      
code= [ ('EXPORT', '_@_shru'),
        ('EXPORT', '_@_shrs'),
        ('DATA', '.systable', code1, 12, 2),
        ('CODE', '_@_shru', code0) ]

module(code=code, name='_rt_shr.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
