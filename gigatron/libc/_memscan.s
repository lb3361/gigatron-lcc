
def scope():
    
    code = [ ('EXPORT', '_memscan') ]

    if 'has_SYS_ScanMemory' in rominfo:
        # no rom has this yet
        def m_prepScanMemory():
            LDWI('SYS_ScanMemory_v6_54'); STW('sysFn')
        def m_ScanMemory():
            # scan memory without page crossings
            # takes data ptr in sysArgs0/1
            # takes two byte targets in sysArgs2/3
            # takes length in vACL (0 means 256)
            # returns pointer to target or 0
            SYS(54)
    else:
        def m_prepScanMemory():
            pass
        def m_ScanMemory():
            ST('sysArgs4');_CALLJ('_memscan0')
        def code0():
            # scan memory without page crossings
            # takes data ptr in sysArgs0/1
            # takes two byte targets in sysArgs2/3
            # takes length in sysArgs4 (not vACL)
            # returns pointer to target or 0
            nohop()
            label('_memscan0')
            LDW('sysArgs0');PEEK();STW(T3)
            LD('sysArgs2');XORW(T3);BEQ('.scanok')
            LD('sysArgs3');XORW(T3);BEQ('.scanok')
            INC('sysArgs0')
            if args.cpu <= 5:
                LD('sysArgs4');SUBI(1);ST('sysArgs4');BNE('_memscan0')
            else:
                DBNE('sysArgs4','_memscan0')
            LDI(0);RET()
            label('.scanok')
            LDW('sysArgs0');RET()

        code.append(('CODE', '_memscan0', code0))


    # void *_memscan(void *s, int c0c1, size_t n)
    # - scans at most n bytes from s until finding one equal to c0 or c1
    # - return pointer to the byte if found, 0 if not found.

    def code1():
        label('_memscan');                          # R8=d, R9=c0c1, R10=l
        tryhop(4);LDW(vLR);STW(R22)
        LDW(R9);STW('sysArgs2')
        m_prepScanMemory()
        label('.loop')
        LDW(R8);ORI(255);ADDI(1);SUBW(R8);STW(R11)  # R11: bytes until end of page
        LDW(R10);_BEQ('.done')
        if args.cpu < 5:
            _BLT('.memscan1')
            SUBW(R11);_BGE('.memscan1')  # we know R11 & 0x8000 == 0
        else:
            _CMPWU(R11);_BGE('.memscan1')
        LDW(R10);STW(R11)
        label('.memscan1')                           # R11=min(R11,R12)
        # calls page version
        LDW(R8);STW('sysArgs0');ADDW(R11);STW(R8)
        LD(R11);m_ScanMemory();_BNE('.done')
        LDW(R10);SUBW(R11);STW(R10);_BNE('.loop')
        label('.done')
        STW(R21);LDW(R22);tryhop(5);STW(vLR);LDW(R21);RET();

    code.append(('CODE', '_memscan', code1))

    return code

module(code=scope(), name='memscan.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
