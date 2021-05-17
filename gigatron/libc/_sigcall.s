
# Call signal subroutine.
# This is only imported when signal() is used.
# Registers R8-R22 must be saved to make sure the signal can return.
# Callee-saved registers R0-R7 need not be saved because
# the signal routine saves them as needed.

def code0():
    '''Redirected from _@_raise with vLR saved in [SP].'''
    label('_sigcall0')
    STW(T0)
    # create a stack frame and save R8-R22 and sysFn,sysArgs
    LDWI(-46);ADDW(SP);STW(SP)
    _SP(6);STW(T2);LDI(R8);STW(T3);LDI(R8+30);STW(T1);_CALLJ('.wcopy')
    _SP(36);STW(T2);LDI('sysFn');STW(T3);ADDI(10);STW(T1);_CALLJ('.wcopy')
    # call _sigcall(signo,fpeinfo)
    # _sigcall saves R0-R7 if used.
    LD(T0);STW(R8);LD(T0+1);STW(R9);_CALLJ('_sigcall');STW(T0)
    # restore R8-R22 and SP
    _SP(6);STW(T3);ADDI(30);STW(T1);LDI(R8);STW(T2);_CALLJ('.wcopy')
    _SP(36);STW(T3);ADDI(10);STW(T1);LDI('sysFn');STW(T2);_CALLJ('.wcopy')
    LDI(46);ADDW(SP);STW(SP)
    # return to vLR saved by raise()
    LDW(SP);DEEK();tryhop(5);STW(vLR);LDW(T0);RET()

def code1():
    nohop()
    label('.wcopy')
    LDW(T3);DEEK();DOKE(T2)
    LDI(2);ADDW(T2);STW(T2)
    LDI(2);ADDW(T3);STW(T3)
    XORW(T1);BNE('.wcopy')
    RET()
    
code=[
    ('IMPORT', '_sigcall'),
    ('EXPORT', '_sigcall0'),
    ('CODE', '_sigcall0', code0),
    ('CODE', '.wcopy', code1) ]

module(code=code, name='_sigcall.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
