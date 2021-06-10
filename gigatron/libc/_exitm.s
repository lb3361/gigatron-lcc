def scope():
    
    # _exitm(int retcode, const char *msg)
    # does not return

    def code_exitm():
        nohop()
        label('_exitm');
        label('_exitvsp', pc()+1)
        LDI(0);ST(vSP)  # _start patches LDI's argument!
        _LDI('_exitm_msgfunc');DEEK();BEQ('.halt')
        CALL(vAC)
        label('.halt')
        # Flash a pixel with a position
        # indicative of the return code
        LDWI(0x101);PEEK();ADDW(R7);ST(R7);
        LDWI(0x100);PEEK();ST(R7+1)
        label('.loop')
        POKE(R7)
        ADDI(1)
        BRA('.loop')

    def code_msgfunc():
        align(2)
        label('_exitm_msgfunc')
        space(2)
        
    module(name='_exitm',
           code=[ ('EXPORT', '_exitm'),
                  ('EXPORT', '_exitvsp'),
                  ('EXPORT', '_exitm_msgfunc'),
                  ('DATA', '_exitm_msgfunc', code_msgfunc, 2, 2),    
                  ('CODE', '_exitm', code_exitm) ] )

scope()
# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
