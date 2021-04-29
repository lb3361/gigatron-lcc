#VCPUv4


# ======== ('CODE', 'memcpy', code1)
#
# Copy [T3..T3+AC) --> [T2..T2+AC)
#
# TODO: optimize

def code0():
        label('_@_memcpy');
        label('.loop')
        STW(T1)
        BEQ('.ret')
        LDW(T3)
        PEEK()
        POKE(T2)
        LDW(T3)
        ADDI(1)
        STW(T3)
        LDW(T2)
        ADDI(1)
        STW(T2)
        LDW(T1)
        SUBI(1)
        BRA('.loop')
        label('.ret')
        RET()

# ======== (epilog)
code=[
        ('EXPORT', '_@_memcpy'),
        ('CODE', '_@_memcpy', code0) ]
	
module(code=code, name='_rt_memcpy.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End: