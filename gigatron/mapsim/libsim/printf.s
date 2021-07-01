
def code0():
	label('printf');
	tryhop(4);LDW(vLR);STW(R22);
	LDWI(0xff01);STW('sysFn');SYS(34)
	STW(R8);LDW(R22);tryhop(5);STW(vLR);LDW(R8);RET();

def code1():
	label('fprintf')
	tryhop(4);LDW(vLR);STW(R22);
	LDI(6);ADDW(R8);DEEK();XORI(1);_BEQ('.stdout')
	_LDI(-1);STW(R8);_BRA('.ret')           # error if not stdout
	label('.stdout')
	LDW(R9);STW(R8);LDI(2);ADDW(SP);STW(SP) # simulate prinf layout
	LDWI(0xff01);STW('sysFn');SYS(34);STW(R8)
	LDW(SP);SUBI(2);STW(SP) # restore
	label('.ret')
	LDW(R22);tryhop(5);STW(vLR);LDW(R8);RET();
	
	
code=[
	('EXPORT', 'printf'),
	('CODE', 'printf', code0),
	('EXPORT', 'fprintf'),
	('CODE', 'fprintf', code1) ]

module(code=code, name='printf.c');

# Local Variables:
# mode: python
# indent-tabs-mode: t
# End:
