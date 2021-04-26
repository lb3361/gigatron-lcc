#VCPUv4

def code0():
    label('_start');
    LDWI('_initsp')
    STW(SP)
    # check rom
    label('.checkrom')
    LD('romType')
    ANDI(0xfc)
    SUBI('_minrom')
    BGE('.checkram')
    LDI(10)
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
    LDW('_init2')
    BEQ('.callmain')
    STW(T3)
    CALL(T3)
    label('.callmain')
    # call main(argc,argv)
    LDI(0)
    STW(R8)
    STW(R9)
    _CALLI('main')
    # call exit in vcpu4 compatible way
    label('.exit')
    STW(R8)
    LDWI('exit')
    STW(T3)
    CALL(T3)
    HALT()


# ======== (epilog)
code=[
    ('EXPORT', '_start'),
    ('CODE', '_start', code0),
    ('IMPORT', 'main'),
    ('IMPORT', '_exit'),
    ('IMPORT', '_init1'),
    ('IMPORT', '_init2'),
    ('IMPORT', '_initsp'),
    ('IMPORT', '_minrom'),
    ('IMPORT', '_minram') ]

module(code=code, name='_start.s', cpu=4);


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
