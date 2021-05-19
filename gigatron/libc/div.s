
def code0():
    label('div', '_divmod')
    
    
# ======== (epilog)
code=[
    ('EXPORT', 'div'),
    ('CODE', 'aliases', code0),
    ('IMPORT', '_divmod') ]

module(code=code, name='div.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
