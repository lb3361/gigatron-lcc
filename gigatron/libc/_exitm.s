
# _exitm(int retcode, const char *msg)
# does not return

def code0():
    nohop()
    label('_exitm');
    label('_exitvsp', pc()+1)
    LDI(0) # this instruction is patched by _start
    ST(vSP)
    # At this point we could just do POP();RET() But since the loader
    # only puts the entry point into vLR, this just means one restarts
    # the program.  So we just flash a pixel with a position
    # indicative of the return code
    LDWI(0x101);PEEK();ADDW(R8);ST(R8);
    LDWI(0x100);PEEK();ST(R8+1)
    label('.loop')
    POKE(R8)
    ADDI(1)
    BRA('.loop')
    
# ======== (epilog)
code=[
    ('EXPORT', '_exitm'),
    ('EXPORT', '_exitvsp'),
    ('CODE', '_exitm', code0) ]

module(code=code, name='_exitm.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
