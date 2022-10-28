
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
    if args.cpu >= 6:
        LDI(R8);NCOPY(30)
    else:
        LDI(R8);STW(T0);LDI(R23);STW(T1);_CALLJ('_@_wcopy_')
    # call _sigcall(signo,fpeinfo)
    LDLW(0);ST(R8);LD(vACH);STW(R9);ALLOC(2)
    LDW(T3);STW(R10);_CALLJ('_sigcall');STW(T3)
    # restore R8-R22 and SP
    LDI(R8);STW(T2)
    if args.cpu >= 6:
        _SP(8);NCOPY(30);STW(SP)
    else:
        _SP(8);STW(T0);ADDI(30);STW(T1);STW(SP);_CALLJ('_@_wcopy_')
    # return to vLR saved by raise()
    LDW(SP);DEEK();tryhop(5);STW(vLR);LDW(T3);RET()

module(name='_sigcall.s',
       code=[ ('IMPORT', '_sigcall'),
              ('IMPORT', '_@_wcopy_') if args.cpu < 6 else ('NOP',),
              ('EXPORT', '_raise_emits_signal'),
              ('CODE', '_raise_emits_signal', code0) ] )



## SIGVIRQ support

def code0():
    '''Programs that use macro SIGVIRQ will reference this
       constant and cause SIGVIRQ support to be linked'''
    label('_sigvirq')
    bytes(7)

def code1():
    '''vIRQ handler'''
    nohop()
    label('.virq')
    # save vLR/T0-T3 without using registers and clear virq vector
    ALLOC(-8);LDW(T0);STLW(0)
    LDWI('_vIrqRelay');STW(T0);LDI(0);DOKE(T0)
    LDW(T1);STLW(2);LDW(T2);STLW(4);LDW(T3);STLW(6)
    # save sysFn/sysArgs[0-7]/B[0-2]/LAC
    if args.cpu >= 6:
        LDW(SP);SUBI(20);STW(SP);ADDI(2);STW(T2)
        LDW('sysArgs6');DOKEp(T2)  ## cpu6 prefix instructions change sysArgs+[67]
        LDI('_runbase');NCOPY(8);LDI('sysFn');NCOPY(8)
    else:
        LDW(SP);SUBI(20);STW(SP);ADDI(2);STW(T2)
        LDI('_runbase');STW(T0);ADDI(8);STW(T1);_CALLJ('_@_wcopy_')
        LDI('sysFn');STW(T0);LDI(v('sysArgs7')+1);STW(T1);_CALLJ('_@_wcopy_')
    LDWI('.vrti');DOKE(SP)
    LDI(0);STW(T3);LDI(7);_CALLI('_raise_emits_signal')

def code2():
    '''vIRQ return'''
    nohop()
    label('.vrti')    # restore...
    if args.cpu >= 6:
        LDI(4);ADDW(SP);MOVQW('_runbase',T2);NCOPY(8)
        MOVQW('sysFn',T2);NCOPY(8);STW(SP)
        SUBI(18);DEEK();STW('sysArgs6')
    else:
        LDI(2);ADDW(SP);STW(T0);ADDI(8);STW(T1);LDI('_runbase');STW(T2);_CALLJ('_@_wcopy_')
        LDI(10);ADDW(T1);STW(T1);STW(SP);LDI('sysFn');STW(T2);_CALLJ('_@_wcopy_')
    LDLW(0);STW(T0);LDLW(2);STW(T1);LDLW(4);STW(T2);LDLW(6);STW(T3);ALLOC(8)
    POP();LDWI(0x400);LUP(0)

def code3():
    nohop()
    label('_setsigvirq')
    if 'has_vIRQ' in rominfo:
        LDWI(0xfffe);ANDW(R8);BEQ('.s1')
        LDWI('.virq')
        label('.s1')
        STW(T1)
        LDWI('_vIrqRelay');STW(T2)
        LDW(T1);DOKE(T2)
    else:
        warning('SIGVIRQ cannot work without vIRQ (needs rom>=v5a)', dedup=True)
    RET()
    
module(name='_sigvirq.s',
       code=[ ('IMPORT', '_vIrqRelay'),
              ('IMPORT', '_raise_emits_signal'),
              ('IMPORT', '_@_wcopy_') if args.cpu < 6 else ('NOP',),
              ('EXPORT', '_sigvirq'),
              ('EXPORT', '_setsigvirq'),
              ('DATA', '_sigvirq', code0, 1, 1),
              ('CODE', '.virq', code1) if 'has_vIRQ' in rominfo else ('NOP',),
              ('CODE', '.vrti', code2) if 'has_vIRQ' in rominfo else ('NOP',),
              ('CODE', '_setsigvirq', code3) ] )

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
