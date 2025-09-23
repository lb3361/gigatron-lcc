
def code0():
    nohop()
    label('labs')
    if args.cpu < 7:
        PUSH()
    _MOVL(L8,LAC)
    LDW(LAC+2);_BGE('.ret')
    _LNEG()
    label('.ret')
    if args.cpu < 7:
        tryhop(2);POP()
    RET()
    
code=[
    ('EXPORT', 'labs'),
    ('CODE', 'labs', code0) ]

module(code=code, name='abs.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
