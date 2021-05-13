

# memset(d,v,l)

def code0():
    '''version that uses Sys_SetMemory_v2_54'''
    label('memset');                            # R8=d, R9=v, R10=l
    tryhop(4);LDW(vLR);STW(R22)
    LDW(R8);STW(R21)                            # save R8 into R21
    LDWI('SYS_SetMemory_v2_54');STW('sysFn')    # prep sys
    LD(R9);ST('sysArgs1')
    label('.loop')
    LDW(R8);ORI(255);ADDI(1);SUBW(R8);STW(R11)           # R11: bytes until end of page
    LDW(R10);_BGE('.test2');SUBW(R11);_BRA('.partial')
    label('.test2');SUBW(R11);_BLE('.final')             # if R10>R11 goto partial else final
    label('.partial')
    STW(R10)
    LDW(R8);STW('sysArgs2');ADDW(R11);STW(R8)
    LDW(R11);ST('sysArgs0')
    SYS(54)
    _BRA('.loop')
    label('.final')
    LDW(R10);_BEQ('.done');ST('sysArgs0')
    LDW(R8);STW('sysArgs2')
    SYS(54)
    label('.done')
    LDW(R22);tryhop(5);STW(vLR);LDW(R21);RET();

    
code=[
    ('EXPORT', 'memset'),
    ('CODE', 'memset', code0) ]
	
module(code=code, name='memset.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
