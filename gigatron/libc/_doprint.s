
def scope():

    # -- int _doprint(const char*, __va_list);
    # aliased to either _doprint_c89 or _doprint_simple

    doprint_default = '_doprint_c89'
    if 'PRINTF_C89' in args.opts:
        doprint_default = '_doprint_c89'
    elif 'PRINTF_SIMPLE' in args.opts:
        doprint_default = '_doprint_simple'

    def code_doprint():
        label('_doprint', doprint_default)

    module(name='doprint.s',
           code=[('EXPORT','_doprint'),
                 ('IMPORT', doprint_default),
                 ('CODE','_doprint',code_doprint) ] )


    # - void _doprint_puts(const char *s, size_t len)
    def code_doprint_puts():
        nohop()
        label('_doprint_puts')
        PUSH();_ALLOC(-6)
        _DEEKV(R0);ADDW(R9);DOKE(R0)
        if args.cpu >= 6:
            LDI(2);ADDW(R0);DEEKA(R10);ADDI(2);DEEK()
        else:
            LDI(2);ADDW(R0);DEEK();STW(R10);LDI(4);ADDW(R0);DEEK()
        CALL(vAC)
        _ALLOC(6);POP();RET()

    module(name='doprint_puts.s',
           code=[('EXPORT', '_doprint_puts'),
                 ('CODE', '_doprint_puts', code_doprint_puts) ] )


    # - void _doprint_putc(int c, size_t cnt)
    def code_doprint_putc():
        label('_doprint_putc')
        _PROLOGUE(12,6,0xc0)
        _SP(12);STW(R6);LD(R8);DOKE(R6)
        _DEEKV(R0);ADDW(R9);DOKE(R0)
        if args.cpu >= 6:
            LDW(R9);STW(R7);_BEQ('.done')
            label('.loop')
        else:
            LDW(R9);_BRA(".tst")
            label('.loop')
            SUBI(1);STW(R7)
        _MOVW(R6,R8)
        _MOVIW(1,R9)
        if args.cpu >= 6:
            LDI(2);ADDW(R0);DEEKA(R10);ADDI(2);DEEK()
        else:
            LDI(2);ADDW(R0);DEEK();STW(R10);LDI(4);ADDW(R0);DEEK()
        CALL(vAC)
        if args.cpu >= 6:
            DBNE(R7,'.loop')
            label('.done')
        else:
            LDW(R7)
            label('.tst')
            _BNE('.loop')
        _EPILOGUE(12,6,0xc0,saveAC=False)

    module(name='doprint_putc.s',
           code=[('EXPORT', '_doprint_putc'),
                 ('CODE', '_doprint_putc', code_doprint_putc) ] )

scope()


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
