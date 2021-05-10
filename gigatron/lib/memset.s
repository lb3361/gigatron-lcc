

# memset(d,v,l)

def code0():
    nohop()
    label('memset');
    tryhop(4);LDW(vLR);STW(R22);          # R8=d, R9=v, R10=l
    LDW(R8);STW(R11);ADDW(R10);STW(R10)   # now R10 is e, R11 is d
    LD(R9);ST(vACH);STW(R9)               # now R9 is vv
    LDW(R10);ANDI(1);_BEQ('.1')           # if (e & 1)
    LDW(R10);SUBI(1);STW(R10)
    LD(R9);POKE(R10)                      #  *--e = v
    label('.1')                           
    LDW(R11);ANDI(1);_BEQ('.2')           # if (d & 1)
    LD(R9);POKE(R11)                      #  *d++ = v
    LDI(1);ADDW(R11);STW(R11)
    label('.2')
    XORW(R10);_BEQ('.done')
    LDW(R9);DOKE(R11)                     # *(int*)s++ = vv
    LDI(2);ADDW(R11);STW(R11);_BRA('.2')
    label('.done')
    LDW(R22);tryhop(5);STW(vLR);LDW(R8);RET();
    
code=[
    ('EXPORT', 'memset'),
    ('CODE', 'memset', code0) ]
	
module(code=code, name='memset.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
