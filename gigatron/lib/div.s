
### The rom/ram checking code must work on all cpu

def code0():
    label('div', '_divmod')
    label('ldiv', '_ldivmod')
    
    
# ======== (epilog)
code=[
    ('EXPORT', 'div'),
    ('EXPORT', 'ldiv'),
    ('CODE', 'aliases', code0),
    ('IMPORT', '_divmod'),
    ('IMPORT', '_ldivmod') ]

module(code=code, name='div.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
