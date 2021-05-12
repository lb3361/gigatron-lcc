
### The rom/ram checking code must work on all cpu

def code0():
    ### _start()
    label('_start');
    # calls init0 in cpu4 compatible way
    LDWI('_init0'); STW(T3); CALL(T3); _BEQ('.init')
    LDI(10); STW(R8); LDWI('.msg'); STW(R9); _BRA('_exitm')
    label('.init')
    # call init chain
    LDWI('__glink_magic_init'); _CALLI('_callchain')
    # call main
    LDI(0); STW(R8); STW(R9); _CALLI('main'); STW(R8)
    ### exit()
    label('exit')
    LDW(R8); STW(R0)
    # call fini chain
    LDWI('__glink_magic_fini'); _CALLI('_callchain')
    LDW(R0); STW(R8)
    ### _exit()
    label('_exit')
    LDI(0); STW(R9)
    label('_exitm')
    # Calls _@_exit with return code in R8 and message or null in R9
    LDWI('_@_exit'); STW(T3); LDW(R8); CALL(T3)
    HALT()

def code1():
    # subroutine to call a chain of init/fini functions
    nohop()
    label('_callchain')
    DEEK(); STW(R7); LDW(vLR); STW(R6)
    LDW(R7); _BRA('.callchaintst')
    label('.callchainloop')
    DEEK();STW(T3);CALL(T3)
    LDI(2);ADDW(R7);DEEK();STW(R7)
    label('.callchaintst')
    _BNE('.callchainloop')
    LDW(R6); STW(vLR); RET()

def code2():
    align(2)
    label('__glink_magic_init')
    words(0xBEEF)

def code3():
    align(2)
    label('__glink_magic_fini')
    words(0xBEEF)

def code4():
    label('.msg')
    bytes(b'Machine check',0)
    
# ======== (epilog)
code=[
    ('EXPORT', '_start'),
    ('EXPORT', '_exit'),
    ('EXPORT', '_exitm'),
    ('EXPORT', 'exit'),
    ('EXPORT', '__glink_magic_init'),
    ('EXPORT', '__glink_magic_fini'),
    ('CODE', '_start', code0),
    ('CODE', '.callchain', code1),
    ('DATA', '__glink_magic_init', code2, 2, 2),
    ('DATA', '__glink_magic_fini', code3, 2, 2),
    ('DATA', '.msg', code4, 0, 1),
    ('IMPORT', 'main'),
    ('IMPORT', '_init0'),
    ('IMPORT', '_@_exit') ]

if not args.no_runtime_bss_initialization:
    code.append(('IMPORT', '__glink_magic_bss')) # causes _init1.c to be included

module(code=code, name='_start.s');


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
