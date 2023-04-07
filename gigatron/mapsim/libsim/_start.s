
### The rom/ram checking code must work on all cpu

def code0():
    ### _start()
    label('_start');
    # ensure stack alignment
    # create stack headroom for argc and argv
    LDWI(0xfffc);ANDW(SP);SUBI(4);STW(SP)
    # call onload functions
    for f in args.onload:
        _CALLJ(f)
    # initialize bss
    if not args.no_runtime_bss_initialization:
        _CALLJ('_init_bss')
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
    LDW(R8);STW(R0)
    LDI(0); STW(R9)
    label('_exitm');
    label('_exitm_msgfunc', pc()+1)
    LDWI(0)                # _exitm_msgfunc is LDWI's argument here
    #####
    ##### Here diverge from the standard start function
    ##### We ignore _exitm_msgfunc and just call the
    ##### gtsim pseudo sys function.
    #####
    LDWI(0xff00);STW('sysFn');SYS(34)
    HALT()

def code1():
    # subroutine to call a chain of init/fini functions
    nohop()
    label('_callchain')
    DEEK(); STW(R7); LDW(vLR); STW(R6)
    LDWI(0xBEEF);XORW(R7);_BEQ('.callchaindone')
    LDW(R7);_BRA('.callchaintst')
    label('.callchainloop')
    DEEK();CALL(vAC)
    LDI(2);ADDW(R7);DEEK();STW(R7)
    label('.callchaintst')
    _BNE('.callchainloop')
    label('.callchaindone')
    LDW(R6); STW(vLR); RET()

def code2():
    align(2)
    label('__glink_magic_init')
    words(0xBEEF)

def code3():
    align(2)
    label('__glink_magic_fini')
    words(0xBEEF)

    
# ======== (epilog)
code=[
    ('EXPORT', '_start'),
    ('EXPORT', 'exit'),
    ('EXPORT', '_exit'),
    ('EXPORT', '_exitm'),
    ('EXPORT', '_exitm_msgfunc'),
    ('EXPORT', '__glink_magic_init'),
    ('EXPORT', '__glink_magic_fini'),
    ('CODE', '_start', code0),
    ('CODE', '.callchain', code1),
    ('DATA', '__glink_magic_init', code2, 2, 2),
    ('DATA', '__glink_magic_fini', code3, 2, 2),
    ('IMPORT', 'main') ]

if args.gt1exec != args.e:
    code.append(('IMPORT', args.gt1exec))        # causes map start stub to be included
for f in args.onload:
    code.append( ('IMPORT', f) )                 # causes onload funcs to be included
if not args.no_runtime_bss_initialization:
    code.append(('IMPORT', '_init_bss'))         # causes _init1.c to be included

module(code=code, name='_start.s');


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
