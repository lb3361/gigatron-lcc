

# MAC32X16:  LAC <-- T0T1 * T2 ; T0T1 <-- T0T1 << 16
def code1():
   label('_@_mac32x16')
   PUSH()
   LDI(1);STW(T3);
   label('.mac2')
   ANDW(T2);_BEQ('.mac3')
   _CALLJ('_@_ladd_t0t1')
   label('.mac3')
   _CALLJ('_@_lshl1_t0t1')
   LDW(T3);LSLW();STW(T3);_BNE('.mac2')
   tryhop(2);POP();RET()
   
# LMUL:   LAC <-- LAC * [vAC]
def code2():
   label('_@_lmul')
   PUSH()
   STW(LACt);DEEK();STW(T2);
   LDW(LAC);STW(T0);LDW(LAC+2);STW(T0+2);
   LDI(0);STW(LAC);STW(LAC+2);
   _CALLJ('_@_mac32x16')
   LDW(LACt);ADDI(2);DEEK();STW(T2)
   _CALLJ('_@_mac32x16')
   tryhop(2);POP();RET()


code= [ ('EXPORT', '_@_lmul'),
        ('IMPORT', '_@_ladd_t0t1'),
        ('IMPORT', '_@_lshl1_t0t1'),
        ('CODE', '_@_mac32x16', code1),
        ('CODE', '_@_lmul', code2) ]

module(code=code, name='_rt_lmul.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
