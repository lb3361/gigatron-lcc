
def scope():
    # creates a local variable scope

    code = [ ('EXPORT', '_memcpyext') ]

    if 'has_SYS_CopyMemoryExt' in rominfo:
        
        info = rominfo['has_SYS_CopyMemoryExt']
        addr = int(str(info['addr']),0)
        cycs = int(str(info['cycs']),0)
        def m_prepCopyMemoryExt():
            LDWI(addr);STW('sysFn')
        def m_reduceCopyMemoryExt():
            pass
        def m_CopyMemoryExt():
            # copy without page crossings
            # takes destination ptr in sysArgs0/1
            # takes source ptr in sysArgs2/3
            # takes length in vACL (0 means 256)
            # takes bank in vACH
            SYS(cycs)

    else:

        def m_prepCopyMemoryExt():
            _LDI(0x1f8);PEEK();STW(R16);_BEQ('.done')      # R16: copy of 3f8
            XORW(R8);ANDI(0xc0);XORW(R16);STW(R17)         # R17: destination ctrl word
            LDI(0);STW(R8)                                 # R8 = zero
            _LDI('SYS_ExpanderControl_v4_40');STW('sysFn') # prep sys call
        def m_reduceCopyMemoryExt():
            LDI(0xe0);SUBW(R20);_BLE('.memcpy1b')
            LDI(0xe0);STW(R20);label('.memcpy1b')
        def m_CopyMemoryExt():
            STW('sysArgs4');STW('sysArgs5');_CALLJ('_memcpyext0')
        def code0():
            org(0x7fa0)
            label('.memcpyextb')
            space(32)
            label('_memcpyext0')
            _LDI('.memcpyextb');STW(R19)
            label('.loop1')
            if args.cpu <= 5:
                LDW('sysArgs2');PEEK();POKE(R19)
                INC(R19);INC('sysArgs2')
                LD('sysArgs5');SUBI(1);ST('sysArgs5');BNE('.loop1')
            else:
                PEEK+('sysArgs2');POKE+(R19)
                DBNE('sysArgs5','.loop2')
            LDW(R17);SYS(40)
            _LDI('.memcpyextb');STW(R19)
            label('.loop2')
            if args.cpu <= 5:
                LDW(R19);PEEK();POKE('sysArgs0')
                INC(R19);INC('sysArgs0')
                LD('sysArgs4');SUBI(1);ST('sysArgs4');BNE('.loop2')
            else:
                PEEK+(R19);POKE+('sysArgs0')
                DBNE('sysArgs4','.loop2')
            LDW(R16);SYS(40)
            RET()

        code.append(('CODE', '_memcpyext0', code0))


    # void *_memcpyext(int bank, void *dest, const void *src, size_t n);
    def code1():
        label('_memcpyext');                        # R8=bank, R9=d, R10=s, R11=l
        tryhop(4);LDW(vLR);STW(R22)
        m_prepCopyMemoryExt()
        LD(R8);ANDI(0xc0);_SHLI(8);STW(R8)
        LDW(R9);STW(R21);STW('sysArgs0')
        LDW(R10);STW('sysArgs2')
        label('.loop')
        LD(R9);STW(R20)
        LD(R10);SUBW(R20);_BLE('.memcpy1')
        LD(R10);STW(R20)
        label('.memcpy1')
        m_reduceCopyMemoryExt()        
        LDI(255);ST(R20+1)                          # R20 is minus count to page boundary
        LDW(R11);_BGT('.memcpy2')
        _BEQ('.done')                               # a) len is zero
        ADDW(R20);_BRA('.memcpy4')                  # b) len is larger than 0x8000
        label('.memcpy2')
        ADDW(R20);_BLE('.memcpy5')                  # c) len is smaller than -R20
        label('.memcpy4')
        STW(R11)                                    # d) len is larger than -R20
        LDI(0);SUBW(R20);STW(R20);ORW(R8);m_CopyMemoryExt()
        LDW(R9);ADDW(R20);STW(R9);STW('sysArgs0')
        LDW(R10);ADDW(R20);STW(R10);STW('sysArgs2')
        _BRA('.loop')
        label('.memcpy5')
        LDW(R11);ORW(R8);m_CopyMemoryExt()
        label('.done')
        LDW(R22);tryhop(5);STW(vLR);LDW(R21);RET();
        
    code.append(('CODE', '_memcpyext', code1))

            
    return code

module(code=scope(), name='memcpy.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
