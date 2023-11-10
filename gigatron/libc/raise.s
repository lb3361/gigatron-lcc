
def scope():

    def code0():
        nohop()
        label('raise')                       # void raise(int signo);
        _MOVIW(0,R9)
        label('_raisem')                     # void _raisem(int signo, const char *msg);
        LDW(R8);ANDI(0xf8);_BEQ('.raise1');
        _LDI(-1);RET()
        label('.raise1')
        _MOVW(R9,T3)
        LDW(R8)
        label('__@raisem')                   # signo in vAC, msg in T3, vSP_v7 long aligned!
        STW(T1)                              # save signo
        label('_raise_disposition', pc()+1)
        LDWI(0)
        _BEQ('.raise2')
        STW(T2)
        PUSH()
        LDW(T1);CALL(T2)   # dispatcher (no return)
        label('.raise2')
        _MOVIW(20,R8);
        _MOVW(T3,R9);
        _CALLJ('_exitm')
        HALT()

    module(name='raise.s',
           code=[ ('IMPORT', '_exitm'),
                  ('EXPORT', 'raise'),
                  ('EXPORT', '_raisem'),
                  ('EXPORT', '__@raisem'),
                  ('EXPORT', '_raise_disposition'),
                  ('CODE', 'raise', code0) ] )

    def code1():
        nohop()
        label('_raise_sets_code')
        STW(T3)
        LDWI('_raise_code');STW(T2)
        LDW(T3);DOKE(T2)
        POP();RET()
        align(2);
        label('_raise_code')
        words(0)

    module(name='raise_sets_code.s',
           code=[ ('EXPORT', '_raise_sets_code'),
                  ('EXPORT', '_raise_code'),
                  ('CODE', '_raise_sets_code', code1) ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
