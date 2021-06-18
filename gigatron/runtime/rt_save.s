
def scope():

    def savemask(i):
        return (0xff << i) & 0xff
    def savename(i):
        return "_@_save_%02x" % savemask(i)
    def restorename(i):
        return "_@_restore_%02x" % savemask(i)

    def code0():
        nohop()
        for i in range(0,8):
            label(savename(i))
            if args.cpu >= 6:
                DOKEA(R0+i+i);ADDI(2)
            elif args.cpu >= 5:
                STW(T3);LDW(R0+i+i);DOKE(T3);LDI(2);ADDW(T3)
            else:
                LDW(R0+i+i);DOKE(T3);LDI(2);ADDW(T3);STW(T3)
        RET()

    def code1():
        nohop()
        for i in range(0,8):
            label(restorename(i))
            if args.cpu >= 6:
                DEEKA(R0+i+i);ADDI(2)
            elif args.cpu >= 5:
                STW(T3);DEEK();STW(R0+i+i);LDI(2);ADDW(T3)
            else:
                STW(T3);DEEK();STW(R0+i+i);LDI(2);ADDW(T3)
        RET()

    def code2():
        nohop()
        label('_@_endframe')
        if args.cpu >= 5:
            ADDW(SP);STW(SP)
        else:
            LDW(T3);ADDW(SP);STW(SP)
        DEEK();STW(vLR)
        LDW(T2);RET()

    module(name='rt_save.s', code=
           [ ('EXPORT', savename(i)) for i in range(0,8) ] + \
           [ ('EXPORT', restorename(i)) for i in range(0,8) ] + \
           [ ('CODE', savename(0), code0),
             ('CODE', restorename(0), code1),
             ('EXPORT', '_@_endframe'),
             ('CODE', '_@_endframe', code2) ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
