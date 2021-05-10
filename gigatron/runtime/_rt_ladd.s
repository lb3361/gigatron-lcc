
# LAC + [vAC] --> LAC

def code0():
   nohop()
   label('_@_ladd')
   # load arg into T0/T1
   STW(T3);DEEK();STW(T0)
   LDI(2);ADDW(T3);DEEK();STW(T1)
   label('_@_ladd_t0')
   if args.cpu <= 5:
      # alternating pattern
      LD(LAC);ADDW(T0);ST(LAC);LD(vACH)
      BNE('.a1');LD(T0+1);BEQ('.a1');LDWI(0x100);label('.a1')
      ADDW(LAC+1);ST(LAC+1);LD(vACH)
      BNE('.a2');LD(LAC+2);BEQ('.a2');LDWI(0x100);label('.a2')
      ADDW(T0+2);ST(LAC+2);LD(vACH)
      BNE('.a3');LD(T0+3);BEQ('.a3');LDWI(0x100);label('.a3')
      ADDW(LAC+3);ST(LAC+3)
   else:
      # untested but sensible
      LD(LAC);ADDBA(T0);ST(LAC);LD(vACH)
      ADDBA(LAC+1);ADDBA(T0+1);ST(LAC+1);LD(vACH)
      ADDBA(LAC+2);ADDBA(T0+2);ST(LAC+2);LD(vACH)
      ADDBA(LAC+3);ADDBA(T0+3);ST(LAC+3)
   RET()
      
code= [ ('EXPORT', '_@_ladd'),
        ('EXPORT', '_@_ladd_t0'),
        ('CODE', '_@_ladd', code0) ]

module(code=code, name='_rt_ladd.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
