
# Call signal subroutine.
# This is only imported when signal() is used.
# Registers R8-R22 must be saved to make sure the signal can return.
# Callee-saved registers R0-R7 need not be saved because
# the signal routine saves them as needed.

def code0():
    '''Redirected from _@_raise with vLR saved in [SP].'''
    label('_sigcall0')
    STW(T0)
    # create a stack frame and save R8-R22.
    LDWI(-36);ADDW(SP);STW(SP);_SP(6);_BMOV(R8,[vAC],30)
    # call _sigcall(signo,fpeinfo)
    # _sigcall saves R0-R7 if used.
    LD(T0);STW(R8);LD(T0+1);STW(R9);_CALLJ('_sigcall');STW(T0)
    # restore R8-R22 and SP
    _SP(6);_BMOV([vAC],R8,30);LDI(36);ADDW(SP);STW(SP)
    # return to vLR saved by raise()
    LDW(SP);DEEK();tryhop(5);STW(vLR);LDW(T0);RET()
    
code=[
    ('IMPORT', '_sigcall'),
    ('EXPORT', '_sigcall0'),
    ('CODE', '_sigcall0', code0) ]

module(code=code, name='_sigcall.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
