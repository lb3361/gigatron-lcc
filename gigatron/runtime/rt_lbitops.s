
# LAC + [vAC] --> LAC

def code0():
   nohop()
   label('_@_lcom')
   _LDI(0xffff);XORW(LAC);STW(LAC)
   _LDI(0xffff);XORW(LAC+2);STW(LAC+2)
   RET()

def code1():
   nohop()
   label('_@_land')
   STW(T3);DEEK();ANDW(LAC);STW(LAC)
   LDI(2);ADDW(T3);DEEK();ANDW(LAC+2);STW(LAC+2)
   RET()

def code2():
   nohop()
   label('_@_lor')
   STW(T3);DEEK();ORW(LAC);STW(LAC)
   LDI(2);ADDW(T3);DEEK();ORW(LAC+2);STW(LAC+2)
   RET()
   
def code3():
   nohop()
   label('_@_lxor')
   STW(T3);DEEK();XORW(LAC);STW(LAC)
   LDI(2);ADDW(T3);DEEK();XORW(LAC+2);STW(LAC+2)
   RET()

   
code= [ ('EXPORT', '_@_lcom'),
        ('EXPORT', '_@_land'),
        ('EXPORT', '_@_lor'),
        ('EXPORT', '_@_lxor'),
        ('CODE', '_@_lcom', code0),
        ('CODE', '_@_land', code1),
        ('CODE', '_@_lor',  code2),
        ('CODE', '_@_lxor', code3) ]

module(code=code, name='rt_ladd.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
