def scope():


    # T3<<vAC -> vAC
    def code0():
        nohop()
        label('_@_shl')
        PUSH()
        ANDI(0xf);SUBI(8);_BLT('.try4')
        if args.cpu >= 7:
            MOVW(T3-1,T3);MOVQB(0,T3)
        else:
            ST(T5);LDW(T3-1);ORI(255);XORI(255);STW(T3);LD(T5)
        label('.try4')
        ANDI(7);STW(T5);LDWI('.ret');SUBW(T5);STW(T5)
        LDW(T3);CALL(T5)
        for _ in range(7): LSLW()
        label('.ret')
        POP();RET()

    module(name='rt_shl.s',
           code=[ ('EXPORT', '_@_shl'),
                  ('CODE', '_@_shl', code0) ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
