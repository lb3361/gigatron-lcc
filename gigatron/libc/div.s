
def code0():
    # div_t *div(int a, int q)
    label('div')
    tryhop(4);LDW(vLR);STW(R22)
    LDW(R9);STW(T3);LDW(R10);STW(T2);_CALLJ('_@_mods')
    #  _@_mods returns T3 % T2 in vAC, T3 / T2 in T1 
    STW(R21);
    LDW(T1);DOKE(R8)
    LDI(2);ADDW(R8);STW(R8);LDW(R21);DOKE(R8)
    LDW(R22);tryhop(3);STW(vLR);RET()
    
code=[
    ('EXPORT', 'div'),
    ('CODE', 'div', code0),
    ('IMPORT', '_@_mods') ]

module(code=code, name='div.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	