
# T3<<T2 -> vAC
# SHRS clobbers T0

def code0():
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

def code1():
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
   
code= [ ('EXPORT', '_@_shru'),
        ('EXPORT', '_@_shrs'),
        ('EXPORT', '__@shrsysfn'),
        ('CODE', '_@_shru', code0),
        ('CODE', '.__@shrsysfn', code1),
        ('CODE', '_@_shrs', code2) ]

module(code=code, name='rt_shr.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
