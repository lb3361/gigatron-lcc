
# Call signal subroutine.
# This is only imported when signal() is used.
# Registers R8-R22 must be saved to make sure the signal can return.
# Callee-saved registers R0-R7 need not be saved because
# the signal routine saves them as needed.

def code0():
    '''save R8-R22'''
    nohop()
    label('.saveR8to22')
    PUSH()
    LDWI(-36);ADDW(SP);STW(SP)
    _SP(6);_BMOV(R8,[vAC],30)
    POP();RET()

def code1():
    '''restore R8-R22'''
    nohop()
    label('.restoreR8to22')
    PUSH()
    _SP(6);_BMOV([vAC],R8,30)
    LDI(36);ADDW(SP);STW(SP)
    POP();RET()

def code2():
    '''Redirected from _@_raise with vLR saved in [SP].'''
    nohop()
    label('_sigcall0')
    STW(T0);_CALLJ('.saveR8to22')
    LD(T0);STW(R8);LD(T0+1);STW(R9);_CALLJ('_sigcall')
    STW(T0);_CALLJ('.restoreR8to22')
    LDW(SP);DEEK();STW(vLR);LDW(T0);RET()
    
code=[
    ('IMPORT', '_sigcall'),
    ('EXPORT', '_sigcall0'),
    ('CODE', '.saveR8to22', code0),
    ('CODE', '.restoreR8to22', code1),
    ('CODE', '_sigcall0', code2) ]

module(code=code, name='_sigcall.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
