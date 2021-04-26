#VCPUv4

# ======== ('CODE', 'memset', code0)
def code0():
	label('memset');
        LDW(LR);STW(vLR);
	LDW(R8); STW(T2); LD(R9); STW(T3); LDW(R10); STW(T1);
        _CALLI('_@_memset')
	LDW(LR);STW(vLR);
        RET();

# ======== (epilog)
code=[
	('EXPORT', 'memset'),
	('CODE', 'memset', code0) ]

module(code=code, name='_memset_4.s', cpu=4);


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
