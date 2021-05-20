

# int setjmp(jmp_buf)

def code0():
    label('setjmp')
    tryhop(4);LDW(vLR);STW(R22)
    # save SP, R22, R0-R7
    LDW(SP);DOKE(R8);LDI(2);ADDW(R8);STW(R8)
    LDW(R22);DOKE(R8);LDI(2);ADDW(R8);STW(R8)
    LDI(R0);STW(T3);LDW(R8);STW(T2);LDI(R8);STW(T1);_CALLJ('_@_wcopy')
    # return 0
    LDW(R22);tryhop(5);STW(vLR);LDI(0);RET()

# void longjmp(jmp_buf, int)

def code1():
    label('longjmp')
    # restore SP, R22, R0-R7
    LDW(R8);DEEK();STW(SP)
    LDI(2);ADDW(R8);DEEK();STW(R22);
    LDI(4);ADDW(R8);STW(T3);ADDI(8+8);STW(T1);LDI(R0);STW(T2);_CALLJ('_@_wcopy')
    # return R9
    LDW(R22);tryhop(5);STW(vLR);LDW(R9);RET()
    
code=[
    ('IMPORT', '_@_wcopy'),
    ('EXPORT', 'setjmp'),
    ('EXPORT', 'longjmp'),
    ('CODE', 'setjmp', code0),
    ('CODE', 'longjmp', code1) ]
	
module(code=code, name='setjmp.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
