
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
   LD(T0+1);STW(T2);_CALLJ('_@_shru')
   tryhop(2);POP();RET()

# T3 % T2 -> AC   [and T3 / T2 -> T1]
#  clobbers B0-B2, T1

def code2():
   label('_@_mods')
   PUSH()
   _CALLJ('_@_divs')
   STW(T1);
   LD(T0+1);STW(T2);_CALLJ('_@_shru');STW(T3)
   LD(LACx);ANDI(2);_BEQ('.mods1')
   LDI(0);SUBW(T3);_BRA('.mods2')
   label('.mods1')
   LDW(T3)
   label('.mods2')
   tryhop(2);POP();RET()



# div_t *_divmod(div_t*,int a, int q)
def code3():
    label('_divmod')
    tryhop(4);LDW(vLR);STW(R22)
    LDW(R9);STW(T3);LDW(R10);STW(T2);_CALLJ('_@_mods')
    STW(T2);
    LDW(T1);DOKE(R8)
    LDI(2);ADDW(R8);STW(T3);LDW(T2);DOKE(T3)
    LDW(R22);tryhop(5);STW(vLR);LDW(R8);RET()

   
   
code= [ ('CODE', '_@_modu', code1), 
        ('CODE', '_@_mods', code2),
        ('CODE', '_divmod', code3),
        ('EXPORT', '_@_modu'),
        ('EXPORT', '_@_mods'),
        ('EXPORT', '_divmod'),
        ('IMPORT', '_@_shru'),
        ('IMPORT', '_@_divu'),
        ('IMPORT', '_@_divs') ]

module(code=code, name='_rt_mod.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
