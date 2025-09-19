def scope():

    def code_setf():
        nohop()
        label('_sim_setf')
        STW(R16);_BLT('.ret4');_BGT('.ret')
        XORW(R10);_BEQ('.ret')     # cnt
        _PEEKV(R8);ORI(8);POKE(R8) # _IOEOF
        _BRA('.ret')
        label('.ret4')
        _PEEKV(R8);ORI(4);POKE(R8) # _IOERR
        label('.ret')
        LDW(R16)
        RET()

    def code_writall():
        nohop()
        label('_sim_writall');
        _MOVW(R10,R11);_MOVW(R9,R10) # swap arguments
        _MOVW(R8,R9);_MOVW(R11,R8)   # for gtsim compatibility
        _MOVIW('errno','sysArgs0')
        _MOVIW(0xff02,'sysFn')
        SYS(36)
        PUSH();_CALLI('_sim_setf');POP();
        RET()

    def code_read():
        nohop()
        label('_sim_read');
        _MOVIW('errno','sysArgs0')
        _MOVIW(0xff03,'sysFn')
        SYS(36)
        PUSH();_CALLI('_sim_setf');POP();
        RET()

    def code_flush():
        nohop()
        label('_sim_flush');
        _MOVIW('errno','sysArgs0')
        _MOVIW(0xff05,'sysFn')
        SYS(36)
        RET()

    def code_lseek():
        nohop()
        label('_sim_lseek');
        _MOVIW('errno','sysArgs0')
        _MOVIW(0xff04,'sysFn')
        SYS(36)
        RET()

    def code_errno():
        align(2)
        label('errno')
        space(2)
        
    def code_iovec():
        align(2)
        label('_sim_iovec')
        words('_sim_writall')
        words('_sim_read')
        words('_sim_flush')
        words('_sim_lseek')
        
    module(name='_iovec.c',
           code=[ ('EXPORT', '_sim_iovec'),
                  ('CODE', '_sim_setf', code_setf),
                  ('CODE', '_sim_writall', code_writall),
                  ('CODE', '_sim_read', code_read),
                  ('CODE', '_sim_flush', code_flush),
                  ('CODE', '_sim_lseek', code_lseek),
                  ('COMMON', 'errno', code_errno, 2, 2),
                  ('DATA', '_sim_iovec', code_iovec, 12, 2) ] )

    def code_openf():
        label('_openf')
        _MOVIW('errno','sysArgs0')
        _MOVIW('_sim_iovec','sysArgs2')
        _MOVIW(0xff06,'sysFn')
        SYS(36)
        RET()

    module(name='_openf.c',
           code=[ ('EXPORT', '_openf'),
                  ('IMPORT', '_sim_iovec'),
                  ('CODE', '_openf', code_openf) ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
