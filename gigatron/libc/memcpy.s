
def scope():
    # creates a local variable scope

    code = [ ('EXPORT', 'memcpy') ]

    if 'has_SYS_CopyMemory' in rominfo:
        info = rominfo['has_SYS_CopyMemory']
        addr = int(str(info['addr']),0)
        cycs = int(str(info['cycs']),0)
        def m_prepCopyMemory():
            LDWI(addr);STW('sysFn')
        def m_CopyMemory():
            # copy without page crossings
            # takes destination ptr in sysArgs0/1
            # takes source ptr in sysArgs2/3
            # takes length in vACL (0 means 256)
            SYS(cycs)
    else:
        def m_prepCopyMemory():
            pass
        def m_CopyMemory():
            STW('sysArgs4');_CALLJ('_memcpy0')
        def code0():
            nohop()
            # copy without page crossings
            # takes destination ptr in sysArgs0/1
            # takes source ptr in sysArgs2/3
            # takes length in sysArgs4 (not vAC)
            label('_memcpy0')
            # single byte
            LD('sysArgs4');ANDI(1);BEQ('.cpy2')
            LDW('sysArgs2');PEEK();POKE('sysArgs0')
            INC('sysArgs2');INC('sysArgs0')
            LD('sysArgs4');ANDI(0xfe);ST('sysArgs4');BEQ('.cpydone')
            # even length
            label('.cpy2')
            if args.cpu <= 5:
                label('.cpy2loop')
                LDW('sysArgs2');DEEK();DOKE('sysArgs0')
                INC('sysArgs2');INC('sysArgs0')
                INC('sysArgs2');INC('sysArgs0')
                LD('sysArgs4');SUBI(2);ST('sysArgs4');BNE('.cpy2loop')
            else:
                label('.cpy2loop')
                DEEKp('sysArgs2'); DOKEp('sysArgs0')
                DEC('sysArgs4'); DBNE('sysArgs4', '.cpy2loop')
            label('.cpydone')
            RET()
        code.append(('CODE', '_memcpy0', code0))

    # void *memcpy(void *dest, const void *src, size_t n);

    def code1():
        label('memcpy');                            # R8=d, R9=s, R10=l
        tryhop(4);LDW(vLR);STW(R22)
        m_prepCopyMemory()
        LDW(R8);STW(R21);STW('sysArgs0')
        LDW(R9);STW('sysArgs2')
        label('.loop')
        LD(R8);STW(R20)
        LD(R9);SUBW(R20);_BLE('.memcpy1')
        LD(R9);STW(R20)
        label('.memcpy1')
        LDI(255);ST(R20+1)                          # R20 is minus count to page boundary
        LDW(R10);_BGT('.memcpy2')
        _BEQ('.done')                               # a) len is zero
        ADDW(R20);_BRA('.memcpy4')                  # b) len is larger than 0x8000
        label('.memcpy2')
        ADDW(R20);_BLE('.memcpy5')                  # c) len is smaller than -R20
        label('.memcpy4')
        STW(R10)                                    # d) len is larger than -R20
        LDI(0);SUBW(R20);STW(R20);m_CopyMemory()
        LDW(R8);ADDW(R20);STW(R8);STW('sysArgs0')
        LDW(R9);ADDW(R20);STW(R9);STW('sysArgs2')
        _BRA('.loop')
        label('.memcpy5')
        LDW(R10);m_CopyMemory()
        label('.done')
        LDW(R22);tryhop(5);STW(vLR);LDW(R21);RET();

    code.append(('CODE', 'memcpy', code1))
	
    return code

module(code=scope(), name='memcpy.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
