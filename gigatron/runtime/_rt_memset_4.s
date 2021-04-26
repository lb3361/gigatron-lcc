#VCPUv4


# ======== ('CODE', 'memset', code1)
#
# Copy T3 --> [T2..T2+AC)
#
# TODO: optimize

def code0():
        label('_@_memset');
        label('.loop')
        STW(T1)
        BEQ('.ret')
        LD(T3)
        POKE(T2)
        LDW(T3)
        ADDI(1)
        STW(T3)
        LDW(T1)
        SUBI(1)
        BRA('.loop')
        label('.ret')
        RET()


# ======== (epilog)
code=[
        ('EXPORT', '_@_memset'),
        ('CODE', '_@_memset', code1) ]
	
module(code=code, name='_rt_memset_4.s', cpu=4);

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
