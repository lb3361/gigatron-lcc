
# This is tightly related to _rt_div.s
# but kept in a different module to prevent
# importing _rt_shr.s if not needed

# T3 % T2 -> AC   [and T3 / T2 -> T1]
#  clobbers B0-B2, T1

def code1():
   label('_@_modu')
   PUSH()
   _CALLJ('_@_divu')
   STW(T1);
   LD(B1);STW(T2);_CALLJ('_@_shru')
   tryhop(2);POP();RET()

# T3 % T2 -> AC   [and T3 / T2 -> T1]
#  clobbers B0-B2, T1

def code2():
   label('_@_mods')
   PUSH()
   _CALLJ('_@_divs')
   STW(T1);
   LD(B1);STW(T2);_CALLJ('_@_shru');STW(T3)
   LD(B2);ANDI(2);_BEQ('.mods1')
   LDI(0);SUBW(T3);_BRA('.mods2')
   label('.mods1')
   LDW(T3)
   label('.mods2')
   tryhop(2);POP();RET()

   
code= [ ('CODE', '_@_modu', code1), 
        ('CODE', '_@_mods', code2),
        ('EXPORT', '_@_modu'),
        ('EXPORT', '_@_mods'),
        ('IMPORT', '_@_shru'),
        ('IMPORT', '_@_divu'),
        ('IMPORT', '_@_divs') ]

module(code=code, name='rt_mod.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
