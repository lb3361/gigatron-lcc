
### The rom/ram checking code must work on all cpu

def code0():
    label('_start');
    LDWI('_initsp')
    STW(SP)
    # check rom
    label('.checkrom')
    LD('romType');
    ANDI(0xfc);
    SUBI('_minrom');
    BGE('.checkram')
    LDI(10); 
    BRA('.exit')
    # check ramsize
    label('.checkram')
    LD('memSize')
    BEQ('.init')
    SUBI('_minram')
    BGE('.init')
    LDI(11)
    BRA('.exit')
    # call init1 and init2
    label('.init')
    _CALLI('_init1')
    _CALLI('_init2')
    # call main(argc,argv)
    LDI(0)
    STW(R8)
    STW(R9)
    _CALLI('main')
    STW(R8)
    # exit
    label('exit')
    # call atexit handlers
    LDW(R8)
    STW(R0)
    LDW('_atexit')
    BRA('.atexittst')
    label('.atexitloop')
    DEEK(); STW(T3); CALL(T3)
    LDI(2); ADDW(R1); DEEK()
    label('.atexittst')
    STW(R1)
    BNE('.atexitloop')
    LDW(R0)
    # call exit in vcpu4 compatible way
    label('.exit')
    STW(R8)
    label('_exit')
    LDWI('_@_exit')
    STW(T3)
    LDW(R8)
    CALL(T3)
    HALT()

def code1():
    align(2)
    label('_atexit')
    word(0)

def code2():
    align(2)
    label('_init2')
    word(0)

# ======== (epilog)
code=[
    ('EXPORT', '_start'),
    ('EXPORT', '_exit'),
    ('EXPORT', 'exit'),
    ('CODE', '_start', code0),
    ('COMMON', '_atexit', code1, 2, 2),
    ('COMMON', '_init2', code2, 2, 2),
    ('IMPORT', 'main'),
    ('IMPORT', '_init1'),
    ('IMPORT', '_initsp'),
    ('IMPORT', '_minrom'),
    ('IMPORT', '_minram'),
    ('IMPORT', '_@_exit') ]
    

module(code=code, name='_start.s');


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
