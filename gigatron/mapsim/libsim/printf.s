
def code0():
	label('printf');
	tryhop(4);LDW(vLR);STW(R22);
	LDWI(0xff01);STW('sysFn');SYS(34)
	STW(R8);LDW(R22);tryhop(5);STW(vLR);LDW(R8);RET();

code=[
	('EXPORT', 'printf'),
	('CODE', 'printf', code0) ]

module(code=code, name='printf.c');

# Local Variables:
# mode: python
# indent-tabs-mode: t
# End:
