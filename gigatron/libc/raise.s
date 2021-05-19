
# Signal functions 

def code0():
    nohop()
    label('raise')
    LDW(R8);
    label('_@_raise')
    STW(T0);ANDI(0xf8);BNE('.raise1');
    label('_raiseptr', pc()+1)
    LDWI(0)                          # calling signal() patches this instruction
    BEQ('.raise2')
    STW(T3);LDW(vLR);DOKE(SP);LDW(T0);CALL(T3);          # dispatcher (no return)
    label('.raise2')
    LD(T0);STW(R8);LD(T0+1);STW(R9);_CALLJ('_exits')     # exit (no return)
    label('.raise1')
    _LDI(0xffff);RET()                                   # err
    
code=[
    ('IMPORT', '_exits'),
    ('EXPORT', 'raise'),
    ('EXPORT', '_@_raise'),
    ('EXPORT', '_raiseptr'),
    ('CODE', 'raise', code0) ]

module(code=code, name='raise.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
