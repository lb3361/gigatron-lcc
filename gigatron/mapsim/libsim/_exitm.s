def scope():

    # _exitm(int retcode, const char *msg)
    # does not return

    def code_exitm():
        nohop()
        label('_exitm');
        LDWI(0xff00);STW('sysFn');SYS(34)
        label('_exitvsp', pc()+1)
        LDI(0);ST(vSP)
        HALT()

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
	
