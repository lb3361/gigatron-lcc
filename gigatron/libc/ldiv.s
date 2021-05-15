
def code0():
    label('ldiv', '_ldivmod')
    
    
# ======== (epilog)
code=[
    ('EXPORT', 'ldiv'),
    ('CODE', 'aliases', code0),
    ('IMPORT', '_ldivmod') ]

module(code=code, name='ldiv.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
