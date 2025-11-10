
# Compile with:
# $ glink TSTcontrol.s -o TSTcontrol.gt1 --rom=dev7 --map=64k --gt1-exec-address=main --entry=main --frags

def scope():

    def code_main():
        nohop()
        org(0x200)

        bytes(0,48,3,51,12,60,15,63)
        label('main')
        MOVQW(8,R9)
        MOVIW(0x800,T2)
        label('.loop')
        LDXW(R9,v('main')-9);ST(T3)
        LDWI(0x7814);FILL()
        ADDSV(0x14,T2)
        DBNE(R9,'.loop')
        HALT()

    module(name = 'TSTcontrol.s',
           code = [('EXPORT', 'main'),
                   ('CODE', 'main', code_main) ] )

        
scope()


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
