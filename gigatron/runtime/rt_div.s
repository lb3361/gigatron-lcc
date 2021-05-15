
# worker
#  T3:   a  dividend  (0-8000 only)
#  T2:   d  divisor   (1-8000 only)
#  T1:   q  quotient
#  B0:   c  shift amount
#  B1  : r  saved shift amount
#  B2:   s  sign

def code0():
   nohop()
   label('_@_divworker')
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

   
# DIVU:  T3/T2 -> vAC
# clobbers B0-B2, T1
   
def code1():
   label('_@_divu')
   PUSH()
   LDI(0);STW(T1);STW(B0)
   LDW(T2);_BGT('.divuA');_BNE('.divu1')
   _CALLJ('_@_raise_sigdiv')# case d == 0
   label('.divu1')          # case d >= 0x8000
   LDW(T3);_BGE('.divu2')
   SUBW(T2);_BLT('.divu2')
   STW(T3);LDI(1);_BRA('.divuret')
   label('.divu2')
   LDI(0);_BRA('.divuret')
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
   _CALLJ('_@_divworker')
   LDW(T1)
   label('.divuret')
   tryhop(2);POP();RET()


# DIVS:  T3/T2 -> vAC
   
def code2():
   label('_@_divs')
   PUSH()
   LDI(0);STW(T1);STW(B0);ST(B2)
   LDW(T2);_BGE('.divs2');_BNE('.divs1')
   _CALLJ('_@_raise_sigdiv')          # case d == 0
   label('.divs1')
   LDI(0);SUBW(T2);STW(T2);INC(B2)    # case d < 0
   label('.divs2')
   LDW(T3);_BGE('.divs3')
   LDI(0);SUBW(T3);STW(T3)            # case a < 0
   LD(B2);XORI(3);ST(B2)
   label('.divs3')
   _CALLJ('_@_divworker')
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
   
   
code= [ ('CODE',   '_@_divworker', code0),
        ('CODE', '_@_divu', code1), 
        ('CODE', '_@_divs', code2), 
        ('IMPORT', '_@_raise_sigdiv'),
        ('EXPORT', '_@_divu'),
        ('EXPORT', '_@_divs') ]

module(code=code, name='rt_div.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
