
### The rom/ram checking code must work on all cpu

def code0():
    label('_start');
    # calls init0 in cpu4 compatible way
    LDWI('_init0'); STW(T3); CALL(T3); _BNE('.main')
    LDI(10); _BRA('.exit')
    # calls init1/init2/main
    label('.main')
    _CALLI('_init1')
    _CALLI('_init2')
    LDI(0); STW(R8); STW(R9)
    _CALLI('main')
    STW(R8)
    # exit
    label('exit')
    # call atexit handlers
    LDW(R8); STW(R0)
    LDW('_atexit')
    _BRA('.atexittst')
    label('.atexitloop')
    DEEK(); STW(T3); CALL(T3)
    LDI(2); ADDW(R1); DEEK()
    label('.atexittst')
    STW(R1)
    _BNE('.atexitloop')
    LDW(R0)
    # call _@_exit in vcpu4 compatible way
    label('.exit')
    STW(R8)
    label('_exit')
    LDWI('_@_exit'); STW(T3); LDW(R8); CALL(T3)
    HALT()

def code1():
    align(2)
    label('_atexit')
    words(0)

# ======== (epilog)
code=[
    ('EXPORT', '_start'),
    ('EXPORT', '_exit'),
    ('EXPORT', 'exit'),
    ('CODE', '_start', code0),
    ('COMMON', '_atexit', code1, 2, 2),
    ('IMPORT', 'main'),
    ('IMPORT', '_init0'),
    ('IMPORT', '_init1'),
    ('IMPORT', '_init2'),
    ('IMPORT', '_@_exit') ]
    

module(code=code, name='_start.s');


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
