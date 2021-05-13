
# _exitm(int retcode, const char *msg)
# does not return

def code0():
    nohop()
    label('_exitm');
    LDWI('_vsp');PEEK();ST(vSP)
    LDW(R8);BEQ('.ret')
    # Just flashes a pixel with a
    # position indicative of the return code
    LDWI(0x102);PEEK();ADDW(R8);ST(R8);
    LDWI(0x100);PEEK();ST(R8+1)
    label('.loop')
    POKE(R8)
    ADDI(1)
    BRA('.loop')
    label('.ret')
    POP();RET();
    
# ======== (epilog)
code=[
    ('EXPORT', '_exitm'),
    ('IMPORT', '_vsp'),
    ('CODE', '_exitm', code0) ]

module(code=code, name='_exitm.s');


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
