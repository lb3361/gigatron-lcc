
def scope():

    # Table based ctype does not make sense in the gigatron
    # because it requires too much contiguous memory.
    # Hardcoded quickcall functions instead!
    
    def _ADDI(i):
        i = v(i)
        if i > 0:
            ADDI(i)
        elif i < 0:
            SUBI(-i)
    
    # int isascii(int)
    def code():
        nohop()
        label('isascii')
        LDWI(0xff80)
        ANDW(R8)
        _BEQ('.yes')
        label('.no')
        LDI(0);RET()
        label('.yes')
        LDI(1);RET()

    module(name="isascii.s",
           code=[('EXPORT', 'isascii'),
                 ('CODE', 'isascii', code) ] )

    # int isalnum(int)
    def code():
        nohop()
        label('isalnum')
        PUSH()
        _CALLJ('isalpha')
        _BNE('.ret')
        _CALLJ('isdigit')
        label('.ret')
        tryhop(2);POP();RET()

    module(name="isalnum.s",
           code=[('EXPORT', 'isalnum'),
                 ('IMPORT', 'isalpha'),
                 ('IMPORT', 'isdigit'),
                 ('CODE', 'isalnum', code) ] )

    # int isalpha(int)
    def code():
        nohop()
        label('isalpha')
        LDW(R8);ORI(0x20)
        _ADDI(-ord('a'))
        BLT('.no')
        _ADDI(ord('a')-(ord('z')+1))
        BLT('.yes')
        label('.no')
        LDI(0)
        label('.yes')
        RET()

    module(name="isalpha.s",
           code=[('EXPORT', 'isalpha'),
                 ('CODE', 'isalpha', code) ] )

    # int iscntrl(int)
    def code():
        nohop()
        label('iscntrl')
        LDW(R8)
        _BLT('.no')
        _ADDI(-0x20)
        _BLT('.yes')
        _ADDI(0x20-0x7f)
        _BEQ('.yes')
        label('.no')
        LDI(0);RET()
        label('.yes')
        LDI(1);RET()

    module(name="iscntrl.s",
           code=[('EXPORT', 'iscntrl'),
                 ('CODE', 'iscntrl', code) ] )

    # int isdigit(int)
    def code():
        nohop()
        label('isdigit')
        LDW(R8)
        _ADDI(-ord('0'))
        BLT('.no')
        _ADDI(ord('0')-(ord('9')+1))
        BLT('.yes')
        label('.no')
        LDI(0)
        label('.yes')
        RET()

    module(name="isdigit.s",
           code=[('EXPORT', 'isdigit'),
                 ('CODE', 'isdigit', code) ] )

    # int islower(int)
    def code():
        nohop()
        label('islower')
        LDW(R8)
        _ADDI(-ord('a'))
        BLT('.no')
        _ADDI(ord('a')-(ord('z')+1))
        BLT('.yes')
        label('.no')
        LDI(0);RET()
        label('.yes')
        RET()

    module(name="islower.s",
           code=[('EXPORT', 'islower'),
                 ('CODE', 'islower', code) ] )

    # int isprint(int)
    # int isgraph(int)
    def code():
        nohop()
        label('isgraph')
        LDW(R8)
        _ADDI(-0x20)
        _BEQ('.no')
        label('isprint')
        LDW(R8)
        _ADDI(-0x7f)
        _BEQ('.no')
        _ADDI(0x7f-0x20)
        _BLT('.no')
        _ADDI(0x20-0x84)
        _BLT('.yes')
        label('.no')
        LDI(0)
        label('.yes')
        RET()

    module(name="isprint.s",
           code=[('EXPORT', 'isprint'),
                 ('EXPORT', 'isgraph'),
                 ('CODE', 'isprint', code) ] )

    # int ispunct(int)
    def code():
        nohop()
        label('ispunct')
        PUSH()
        _CALLJ('isalpha')
        _BNE('.no')
        _CALLJ('isdigit')
        _BNE('.no')
        LDW(R8)
        _ADDI(-0x20)
        _BLE('.no')
        _ADDI(0x20-0x7f)
        _BLT('.yes')
        label('.no')
        LDI(0)
        label('.yes')
        tryhop(2);POP();RET()

    module(name="ispunct.s",
           code=[('EXPORT', 'ispunct'),
                 ('IMPORT', 'isdigit'),
                 ('IMPORT', 'isalpha'),
                 ('CODE', 'ispunct', code) ] )

    # int isspace(int)
    def code():
        nohop()
        label('isspace')
        LDW(R8)
        _ADDI(-0x20)
        _BEQ('.yes')
        _ADDI(0x20-9)
        _BLT('.no')
        _ADDI(9-13)
        _BLE('.yes')
        label('.no')
        LDI(0);RET()
        label('.yes')
        LDI(1);RET()

    module(name="isspace.s",
           code=[('EXPORT', 'isspace'),
                 ('CODE', 'isspace', code) ] )

    # int isupper(int)
    def code():
        nohop()
        label('isupper')
        LDW(R8)
        _ADDI(-ord('A'))
        BLT('.no')
        _ADDI(ord('A')-(ord('Z')+1))
        BLT('.yes')
        label('.no')
        LDI(0);RET()
        label('.yes')
        RET()

    module(name="isupper.s",
           code=[('EXPORT', 'isupper'),
                 ('CODE', 'isupper', code) ] )

    # int isxdigit(int)
    def code():
        nohop()
        label('isxdigit')
        LDW(R8)
        _ADDI(-ord('0'))
        BLT('.no')
        _ADDI(ord('0')-(ord('9')+1))
        BLT('.yes')
        LDW(R8);ORI(0x20)
        _ADDI(-ord('a'))
        _BLT('.no')
        _ADDI(ord('a')-(ord('f')+1))
        _BLT('.yes')
        label('.no')
        LDI(0)
        label('.yes')
        tryhop(2);POP();RET()

    module(name="isxdigit.s",
           code=[('EXPORT', 'isxdigit'),
                 ('CODE', 'isxdigit', code) ] )

    # int tolower(int)
    def code():
        nohop()
        label('tolower')
        LDW(R8)
        _ADDI(-ord('A'))
        BLT('.no')
        _ADDI(ord('A')-(ord('Z')))
        BGT('.no')
        _ADDI(ord('Z')+32)
        RET()
        label('.no')
        LDW(R8)
        RET()

    module(name="tolower.s",
           code=[('EXPORT', 'tolower'),
                 ('CODE', 'tolower', code) ] )

    # int toupper(int)
    def code():
        nohop()
        label('toupper')
        LDW(R8)
        _ADDI(-ord('a'))
        BLT('.no')
        _ADDI(ord('a')-(ord('z')))
        BGT('.no')
        _ADDI(ord('z')-32)
        RET()
        label('.no')
        LDW(R8)
        RET()

    module(name="toupper.s",
           code=[('EXPORT', 'toupper'),
                 ('CODE', 'toupper', code) ] )

    # void _strupr(char *s)
    def code():
        nohop()
        label('_strupr')
        _MOVW(R8,T0)
        _BRA('.tst')
        label('.loop')
        _ADDI(-ord('a')); _BLT('.no')
        _ADDI(ord('a')-(ord('z'))); _BGT('.no')
        _ADDI(ord('z')-32); POKE(R8)
        label('.no')
        if args.cpu < 6:
            LDI(1);ADDW(R8);STW(R8)
            label('.tst')
            PEEK()
        else:
            INCV(R8)
            label('.tst')
            PEEKV(R8)
        _BNE('.loop')
        LDW(T0)
        RET()

    module(name="strupr.s",
           code=[('EXPORT', '_strupr'),
                 ('CODE', '_strupr', code) ] )
    
    # void _strlwr(char *s)
    def code():
        nohop()
        label('_strlwr')
        _MOVW(R8,T0)
        _BRA('.tst')
        label('.loop')
        _ADDI(-ord('A')); _BLT('.no')
        _ADDI(ord('A')-(ord('Z'))); _BGT('.no')
        _ADDI(ord('Z')+32); POKE(R8)
        label('.no')
        if args.cpu < 6:
            LDI(1);ADDW(R8);STW(R8)
            label('.tst')
            PEEK()
        else:
            INCV(R8)
            label('.tst')
            PEEKV(R8)
        _BNE('.loop')
        LDW(T0)
        RET()

    module(name="strupr.s",
           code=[('EXPORT', '_strlwr'),
                 ('CODE', '_strlwr', code) ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
