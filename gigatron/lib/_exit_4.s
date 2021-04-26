#VCPUv4

def code0():
        label('exit')
	label('_exit');
        LDW(R8)
        STW('_exitstatus')
        # Marcel's smallest program (for now)
        label('.final')
        LDW(0xe)
        DOKE(v('vPC')+1)
        BRA('.final')

def code1():
        label('_exitstatus')
        word(0)



# ======== (epilog)
code=[  ('EXPORT', 'exit'),
        ('EXPORT', '_exit'),
	('CODE', 'exit', code0),
	('EXPORT', '_exitstatus'),
        ('DATA', '_exitstatus', code1, 2, 1) ]

module(code=code, name='_exit_4.s', cpu=4);


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
