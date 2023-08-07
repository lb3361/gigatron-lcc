
def scope():

    # -- int (*_doprint)(doprint_t*, const char*, __va_list) = _doprint_c89;
    # Default value for function pointer _doprint.

    doprint_default = '_doprint_c89'
    if 'PRINTF_SIMPLE' in args.opts:
        doprint_default = '_doprint_simple'

    def code_doprint():
        align(2)
        label('_doprint')
        words(doprint_default)

    module(name='doprint.s',
           code=[('EXPORT','_doprint'),
                 ('IMPORT',doprint_default),
                 ('DATA','_doprint',code_doprint, 2, 2) ] )


    # -- void _doprint_putc(doprint_t *dp, int c, size_t cnt)
    # Output cnt copies of character c.
    # This code epends on the layout of struct doprint_s defined in _doprint.h
    def code_dp_putc():
        nohop()
        label('_doprint_putc')
        PUSH();ALLOC(-6)
        LDW(R8);STLW(4);DEEK();ADDW(R10);DOKE(R8)
        LD(R9);STLW(0)
        LDW(R10);_BRA('.tst')
        label('.loop')
        LDLW(4);ADDI(2);DEEK();STW(R8)
        if args.cpu >= 7:
            LDW(vSP);STW(R9)
        else:
            LD(vSP);STW(R9)
        LDI(1);STW(R10)
        LDLW(4);ADDI(4);DEEK();CALL(vAC)
        LDLW(2);SUBI(1)
        label('.tst')
        STLW(2)
        _BNE('.loop')
        ALLOC(6);tryhop(2);POP();RET()

    module(name='_doprint_putc.s',
           code=[('EXPORT', '_doprint_putc'),
                 ('CODE', '_doprint_putc', code_dp_putc) ] )

    # -- void _doprint_puts(doprint_t *dp, const char *s, size_t cnt)
    # Output at most cnt chars of string s
    # This code epends on the layout of struct doprint_s defined in _doprint.h
    def code_dp_puts():
        nohop()
        label('_doprint_puts')
        PUSH();ALLOC(-2)
        LDW(R8);STLW(0)
        LDW(R9);STW(R8)
        LDI(0);STW(R9)
        _CALLJ('__memchr2') # known to preserve R8-R10
        _BEQ('.nz')
        SUBW(R8);STW(R10)
        label('.nz')
        LDW(R8);STW(R9)
        LDLW(0);STW(R11);ADDI(2);DEEK();STW(R8)
        LDW(R11);DEEK();ADDW(R10);DOKE(R11)
        LDW(R11);ADDI(4);DEEK();CALL(vAC)
        ALLOC(2);tryhop(2);POP();RET()

    module(name='_doprint_puts.s',
           code=[('EXPORT', '_doprint_puts'),
                 ('IMPORT', '__memchr2'),
                 ('CODE', '_doprint_puts', code_dp_puts) ] )


    # -- void _doprint_console(void *closure, const char *buf, size_t sz)
    # Helper for cprintf
    def code_dp_cons():
        nohop()
        label('_doprint_console')
        LDW(R9);STW(R8);LDW(R10);STW(R9)
        if args.cpu >= 6:
            JNE('console_print')
        else:
            PUSH();_CALLJ('console_print');POP()
        RET()

    module(name='_doprint_console',
           code=[('EXPORT', '_doprint_console'),
                 ('IMPORT', 'console_print'),
                 ('CODE', '_doprint_console', code_dp_cons) ] )

scope()


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
