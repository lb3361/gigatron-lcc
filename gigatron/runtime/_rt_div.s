
# worker
#  T3:   a  dividend  (0-8000 only)
#  T2:   d  divisor   (1-8000 only)
#  T1:   q  quotient
#  T0:   c  shift amount
#  T0+1: r  saved shift amount
#  LACx: s  sign

def code0():
   label('_@_divworker')
   PUSH()
   label('.w1loop')
   LDW(T3);SUBW(T2);_BLT('.w2')
   LDW(T2);LSLW();_BLT('.w2')
   STW(T2);INC(T0);_BRA('.w1loop')
   label('.w2')
   LD(T0);ST(T0+1)
   label('.w2loop')
   LDW(T3);SUBW(T2);_BLT('.w3')
   STW(T3);INC(T1)
   label('.w3')
   LD(T0);XORI(128);SUBI(129);_BLT('.w4')
   ST(T0);
   LDW(T3);LSLW();STW(T3)
   LDW(T1);LSLW();STW(T1)
   _BRA('.w2loop')
   label('.w4')
   tryhop(2);POP();RET()

def code1():
   align(2)
   label('_@_SIGdiv')
   space(2)

def code2():
   nohop()
   label('_@_divbyzero')
   _LDW('_@_SIGdiv');POP();BEQ('.z2')
   # call _@_SIGdiv if nonzero
   STW(T0);CALL(T0)
   label('.z2')
   # exit with return code 100
   LDWI('_@_exit');STW(T0);LDI(100);CALL(T0)  

   
# DIVU:  T3/T2 -> vAC
   
def code3():
   label('_@_divu')
   PUSH()
   LDI(0);STW(T1);STW(T0)
   LDW(T2);_BGE('.divuA');_BNE('.divu1')
   _CALLJ('_@_divbyzero')     # case d == 0
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
   STW(T2);INC(T0);_BRA('.divu3')
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
   
def code4():
   label('_@_divs')
   PUSH()
   LDI(0);STW(T1);STW(T0);ST(LACx)
   LDW(T2);_BGE('.divs2');_BNE('.divs1')
   _CALLJ('_@_divbyzero')               # case d == 0
   label('.divs1')
   LDI(0);SUBW(T2);STW(T2);INC(LACx)    # case d < 0
   label('.divs2')
   LDW(T3);_BGE('.divs3')
   LDI(0);SUBW(T3);STW(T3)              # case a < 0
   LD(LACx);XORI(3);ST(LACx)
   label('.divs3')
   _CALLJ('_@_divworker')
   LD(LACx)
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
        ('COMMON', '_@_SIGdiv',  code1, 2, 2),
        ('CODE',   '_@_divbyzero', code2),
        ('CODE', '_@_divu', code3), 
        ('CODE', '_@_divs', code4), 
        ('IMPORT', '_@_exit'),
        ('EXPORT', '_@_divu'),
        ('EXPORT', '_@_divs') ]

module(code=code, name='_rt_div.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
