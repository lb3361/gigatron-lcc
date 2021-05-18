
# Call signal subroutine.
# This is only imported when signal() is used.
# Registers R8-R22 must be saved to make sure the signal can return.
# Callee-saved registers R0-R7 need not be saved because
# the signal routine saves them as needed.

def code0():
    '''Redirected from _@_raise with vLR saved in [SP].'''
    label('_sigcall0')
    STW(T0)
    # create a stack frame and save R8-R22
    _SP(-36);STW(SP);ADDI(6);STW(T2);LDI(R8);STW(T3);LDI(R23);STW(T1);_CALLJ('_@_wcopy')
    # call _sigcall(signo,fpeinfo)
    # _sigcall saves R0-R7 if used.
    LD(T0);STW(R8);LD(T0+1);STW(R9);_CALLJ('_sigcall');STW(T0)
    # restore R8-R22 and SP
    _SP(6);STW(T3);ADDI(30);STW(T1);STW(SP);LDI(R8);STW(T2);_CALLJ('_@_wcopy')
    # return to vLR saved by raise()
    LDW(SP);DEEK();tryhop(5);STW(vLR);LDW(T0);RET()

def code1():
    '''vIRQ handler'''
    nohop()
    label('_sigvirq0')
    # save vLR/T[1-3] without using registers
    PUSH();ALLOC(-6);LDW(T1);STLW(0);LDW(T2);STLW(2);LDW(T3);STLW(4)
    # clear virq vector (now that we can use T3)
    LDWI('vIRQ_v5');STW(T3);LDI(0);DOKE(T3)  
    # save sysFn/sysArgs[0-7]/B[0-2]/LAC/T0
    LDW(SP);SUBI(22);STW(SP);ADDI(2);STW(T2)
    LDI(B0-1);STW(T3);LDI(T1);STW(T1);_CALLJ('_@_wcopy')
    LDI('sysFn');STW(T3);LDI(v('sysArgs7')+1);STW(T1);_CALLJ('_@_wcopy')
    LDWI('.rti');DOKE(SP);LDI(7);_CALLJ('_sigcall0')  # call sigcall0

def code2():
    '''vIRQ return'''
    nohop()
    label('.rti')    # restore...
    LDI(2);ADDW(SP);STW(T3);ADDI(10);STW(T1);LDI(0x80);STW(T2);_CALLJ('_@_wcopy')
    LDI(10);ADDW(T1);STW(T1);STW(SP);LDI('sysFn');STW(T2);_CALLJ('_@_wcopy')
    LDLW(0);STW(T1);LDLW(2);STW(T2);LDLW(4);STW(T3);ALLOC(6);POP()
    LDWI(0x400);LUP(0)
    
code=[
    ('IMPORT', '_sigcall'),
    ('IMPORT', '_@_wcopy'),
    ('EXPORT', '_sigcall0'),
    ('EXPORT', '_sigvirq0'),
    ('CODE', '_sigcall0', code0),
    ('CODE', '_sigvirq0', code1),
    ('CODE', '.rti', code2) ]

module(code=code, name='_sigcall.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
