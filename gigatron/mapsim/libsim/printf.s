
def scope():

    def code0():
        nohop()
        label('printf')
        # calling _sim_flush if already present
        _LDI('__glink_weak__sim_flush');_BEQ('.run')
        LDW(vLR);DOKE(SP);_LDI(-12);ADDW(SP);STW(SP)
        _SP(12-4);STW(R22);LDW(R8);DOKE(R22)
        _CALLJ('__glink_weak__sim_flush')
        _SP(12-4);DEEK();STW(R8)
        _LDI(12);ADDW(SP);STW(SP);DEEK();STW(vLR)
        # done
        label('.run')
        LDWI(0xff01);STW('sysFn');SYS(34)
        RET();

    module(name='printf.s',
           code=[ ('EXPORT', 'printf'),
                  ('CODE', 'printf', code0) ] )


    def code1():
        label('fprintf')
        tryhop(4);LDW(vLR);DOKE(SP)
        # error if not stdout
        _LDI(v('_iob')+16);XORW(R8);_BEQ('.stdout')
        _LDI(-1);RET()
        label('.stdout')
        # call sim_flush
        _LDI(-12);ADDW(SP);STW(SP)
        _SP(12-4);STW(R22);LDW(R9);DOKE(R22)
        _CALLJ('_sim_flush')
        # replicate printf setup
        _SP(12-4);DEEK();STW(R8)
        _LDI(14);ADDW(SP);STW(SP)
        LDWI(0xff01);STW('sysFn');SYS(34);STW(R8)
        # restore
        LDI(-2);ADDW(SP);STW(SP);DEEK()
        tryhop(5);STW(vLR);LDW(R8);RET()

    module(name='fprintf.s',
           code=[ ('EXPORT', 'fprintf'),
                  ('IMPORT', '_iob'),
                  ('IMPORT', '_sim_flush'),
                  ('CODE', 'fprintf', code1) ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
