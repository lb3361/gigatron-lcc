
### The rom/ram checking code must work on all cpu

def code0():
    ### _start()
    label('_start');
    # calls init0 in cpu4 compatible way
    LDWI('_init0'); STW(T3); CALL(T3); _BEQ('.init')
    LDI(10); _BRA('.exit')
    label('.init')
    # call init chain
    LDWI('__glink_magic_init'); _CALLI('.callchain')
    # call main
    LDI(0); STW(R8); STW(R9); _CALLI('main'); STW(R8)
    ### exit()
    label('exit')
    LDW(R8); STW(R0)
    # call fini chain
    LDWI('__glink_magic_fini'); _CALLI('.callchain')
    LDW(R0)
    label('.exit')
    STW(R8)
    ### _exit()
    label('_exit')
    # call _@_exit
    LDWI('_@_exit'); STW(T3); LDW(R8); CALL(T3)
    HALT()
    # subroutine to call a chain of init/fini functions
    label('.callchain')
    tryhop(32)
    DEEK(); STW(R7); LDW(vLR); STW(R6)
    LDW(R7); BRA('.callchaintst')
    label('.callchainloop')
    DEEK();STW(T3);CALL(T3)
    LDI(2);ADDW(R7);DEEK();STW(R7)
    label('.callchaintst')
    BNE('.callchainloop')
    LDW(R6); STW(vLR); RET()

def code1():
    align(2)
    label('__glink_magic_init')
    words(0xBEEF)

def code2():
    align(2)
    label('__glink_magic_fini')
    words(0xBEEF)
    
# ======== (epilog)
code=[
    ('EXPORT', '_start'),
    ('EXPORT', '_exit'),
    ('EXPORT', 'exit'),
    ('EXPORT', '__glink_magic_init'),
    ('EXPORT', '__glink_magic_fini'),
    ('CODE', '_start', code0),
    ('DATA', '__glink_magic_init', code1, 2, 2),
    ('DATA', '__glink_magic_fini', code2, 2, 2),
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
	
