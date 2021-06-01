
# T3*T2 --> vAC 

def code0():
   nohop()
   label('_@_mul')
   # T3: a, T2: b, T1: mask, T0: res
   LDI(0);STW(T0)
   LDW(T2);_BEQ('.ret');_BGE('.go')
   STW(T1);LDW(T3);STW(T2);LDW(T1);STW(T3)
   label('.go')
   _LDI(0xffff);STW(T1)
   label('.loop')
   LDI(0);SUBW(T1);ANDW(T2);_BEQ('.shift')
   LDW(T3);ADDW(T0);STW(T0)
   label('.shift')
   LDW(T3);LSLW();STW(T3)
   LDW(T1);LSLW();STW(T1);ANDW(T2);_BNE('.loop')
   label('.ret')
   LDW(T0);RET()
      
code= [ ('EXPORT', '_@_mul'),
        ('CODE', '_@_mul', code0) ]

module(code=code, name='rt_mul.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
