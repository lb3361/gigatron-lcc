
# Call signal subroutine.
# This is only imported when signal() is used.
# Registers R8-R22 must be saved to make sure the signal can return.
# Callee-saved registers R0-R7 need not be saved because
# the signal routine saves them as needed.

def code0():
    '''Redirected from _@_raise with vLR saved in [SP].'''
    nohop()
    label('_raise_emits_signal')
    ALLOC(-2);STLW(0)
    # create a stack frame and save R8-R22
    _SP(-38);STW(SP);ADDI(8);STW(T2)
    LDI(R8);STW(T0);LDI(R23);STW(T1);_CALLJ('_@_wcopy_')
    # call _sigcall(signo,fpeinfo)
    LDLW(0);ST(R8);LD(vACH);STW(R9);ALLOC(2)
    LDW(T3);STW(R10);_CALLJ('_sigcall');STW(T3)
    # restore R8-R22 and SP
    LDI(R8);STW(T2)
    _SP(8);STW(T0);ADDI(30);STW(T1);STW(SP);_CALLJ('_@_wcopy_')
    # return to vLR saved by raise()
    LDW(SP);DEEK();tryhop(5);STW(vLR);LDW(T3);RET()

module(name='_sigcall.s',
       code=[ ('IMPORT', '_sigcall'),
              ('IMPORT', '_@_wcopy_'),
              ('EXPORT', '_raise_emits_signal'),
              ('CODE', '_raise_emits_signal', code0) ] )


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
