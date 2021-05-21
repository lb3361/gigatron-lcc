
code = [ ('EXPORT', 'memcpy') ]

if 'has_SYS_CopyMemory' in rominfo:
    # no rom has this yet
    def m_prepCopyMemory():
        LDWI('SYS_CopyMemory_v6_54'); STW('sysFn')
    def m_CopyMemory():
        # copy without page crossings
        # takes source ptr in sysArgs0/1
        # takes dest ptr in sysArgs2/3
        # takes length in sysArgs4/5
        SYS(54)
else:
    def m_prepCopyMemory():
        pass
    def m_CopyMemory():
        _CALLJ('_memcpy0')
    def code0():
        nohop()
        # copy without page crossings
        # takes source ptr in sysArgs0/1
        # takes dest ptr in sysArgs2/3
        # takes length in sysArgs4/5
        label('_memcpy0')
        # single byte
        LD('sysArgs4');ANDI(1);BEQ('.cpy2')
        LDW('sysArgs2');PEEK();POKE('sysArgs0')
        INC('sysArgs2');INC('sysArgs0')
        # even length
        label('.cpy2')
        LDWI("SYS_LSRW1_48"); STW('sysFn'); LDW('sysArgs4'); SYS(48);
        STW('sysArgs4');BEQ('.cpydone')
        if args.cpu <= 5:
            label('.cpy2loop')
            LDW('sysArgs2');DEEK();DOKE('sysArgs0')
            INC('sysArgs2');INC('sysArgs0')
            INC('sysArgs2');INC('sysArgs0')
            LD('sysArgs4');SUBI(1);ST('sysArgs4');BNE('.cpy2loop')
        else:
            label('.cpy2loop')
            DEEK+('sysArgs0'); DOKE+('sysArgs2')
            DBNE('sysArgs4', '.cpy2loop')
        label('.cpydone')
        RET()
    code.append(('CODE', '_memcpy0', code0))


# void *memcpy(void *dest, const void *src, size_t n);

def code1():
    label('memcpy');                            # R8=d, R9=s, R10=l
    tryhop(4);LDW(vLR);STW(R22)
    LDW(R8);STW(R21)                            # save R8 into R21
    m_prepCopyMemory()
    label('.loop')
    LDW(R8);ORI(255);ADDI(1);SUBW(R8);STW(R11)  # R11: bytes until end of source page
    LDW(R9);ORI(255);ADDI(1);SUBW(R9);STW(R12)  # R12: bytes until end of destination page
    if args.cpu < 5:
        _BLT('.memcpy1')
        SUBW(R11);_BGE('.memcpy1')  # we know R12&0x8000 == 0
    else:
        _CMPWU(R11);_BGE('.memcpy1')
    LDW(R12);STW(R11)
    label('.memcpy1')                           # R11=min(R11,R12)
    if args.cpu < 5:
        LDW(R10);_BLT('.memcpy2')
        SUBW(R11);_BGE('.memcpy2')
    else:
        LDW(R10);_CMPWU(R11);_BGE('.memcpy2')
    LDW(R10);STW(R11)
    label('.memcpy2')                           # R11=min(R11,R10)
    # calls in-page-copy
    LDW(R8);STW('sysArgs0');ADDW(R11);STW(R8)
    LDW(R9);STW('sysArgs2');ADDW(R11);STW(R9)
    LD(R11);STW('sysArgs4')
    m_CopyMemory()
    LDW(R10);SUBW(R11);STW(R10);_BNE('.loop')
    label('.done')
    LDW(R22);tryhop(5);STW(vLR);LDW(R21);RET();

code.append(('CODE', '_memcpy', code1))
	
module(code=code, name='memcpy.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
