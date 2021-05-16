
# Signal functions 

def code0():
    '''This becomes non zero when signal() is used'''
    align(2);
    label('_sigptr')
    space(2)

def code1():
    nohop()
    label('raise')
    LDW(R8);
    label('_@_raise')
    STW(T0);ANDI(0xf8);BEQ('.raise1');LDWI(0xffff);RET() # bad signo
    label('.raise1')
    LDWI('_sigptr'); DEEK(); BEQ('.raise2')
    PUSH();STW(T3);LDW(T0);CALL(T3);POP();RET()          # dispatcher
    label('.raise2')
    LD(T0);STW(R8);LD(T0+1);STW(R9);_CALLJ('_exits')     # exit
    HALT()
    
code=[
    ('IMPORT', '_exits'),
    ('EXPORT', 'raise'),
    ('EXPORT', '_@_raise'),
    ('COMMON', '_sigptr', code0, 2, 2),
    ('CODE', 'raise', code1) ]

module(code=code, name='raise.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
