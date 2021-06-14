
def scope():

    def code_ldexp10p():
        label('_ldexp10p')
        bytes(22,79,177,30,173); # 1e-32
        bytes(75,102,149,148,190); # 1e-16
        bytes(102,43,204,119,17); # 1e-08
        bytes(115,81,183,23,88); # 0.0001
        bytes(122,35,215,10,61); # 0.01
        bytes(125,76,204,204,204); # 0.1

    def code_ldexp10n():
        label('_ldexp10n')
        _LDI('_ldexp10p');STW(R21);ADDI(30);STW(R20)
        LDI(0);SUBW(R11);STW(R11);
        _CMPIS(80);_BLE('.neg1')
        LDI(80);STW(R11)
        label('.neg1')
        LDW(R11);ANDI(31);XORW(R11);_BEQ('.neg3')
        LDW(R21);_FMUL()
        LDW(R11);SUBI(32);STW(R11);_BRA('.neg1')
        label('.neg2')
        LDW(R11);LSLW();STW(R11);ANDI(0x20);_BEQ('.neg3')
        LDW(R21);_FMUL()
        label('.neg3')
        LDI(5);ADDW(R21);STW(R21);XORW(R20);_BNE('.neg2')
        tryhop(5);LDW(R22);STW(vLR);RET()
        
    def code_ldexp10():
        label('_ldexp10')
        LDW(vLR);STW(R22)
        _FMOV(F8,FAC)
        LDW(R11);_BGE('.pos')
        _CALLJ('_ldexp10n') # no return
        label('.pos')
        _CMPIS(80);_BLE('.pos1')
        LDI(80);STW(R11);_BRA('.pos1')
        label('.pos2')
        SUBI(1);STW(R11)
        _FMOV(FAC,F8)
        LDI(2);_FSCALB();  # *4
        LDI(F8);_FADD();   # +1
        LDI(1);_FSCALB();  # *2
        label('.pos1')
        LDW(R11);_BNE('.pos2')
        tryhop(5);LDW(R22);STW(vLR);RET()

    module(name='_ldexp10',
           code=[ ('EXPORT', '_ldexp10'),
	          ('DATA', '_ldexp10p', code_ldexp10p, 0, 1),
                  ('CODE', '_ldexp10n', code_ldexp10n), 
                  ('CODE', '_ldexp10', code_ldexp10) ] )
	
scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
