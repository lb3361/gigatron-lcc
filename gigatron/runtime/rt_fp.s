


# Floating point routines
# using the Microsoft Floating Point format (5 bytes)
#
#  EEEEEEEE SAAAAAAA BBBBBBBB CCCCCCCC DDDDDDDD
#  =  (-1)^S * 2^(EEEEEEEE-128) * 0.1AAAAAAABBBBBBBBCCCCCCCCDDDDDDDD (base 2)

# The fp routines operate on a floating point accumulator FAC that
# occupies the same locations [0x81-0x87] as B0,B1,B2 and LAC.
# Register FAC separately stores its sign, its exponent, and
# a mantissa AM extended to 40 bits with an additional high byte.  The
# routines also make use of the memory occupied by T0-T3 in diverse
# ways. In particular the mantissa BM of the operation argument can be
# stored on 4 or 5 bytes in BM, clobbering T0, T1, and T2L. 

# Conclusion: None of B0/B1/B2/LAC/T0/T1/T2/T3 should be assumed to be
# preserved across these calls. In addition, some of these calls might
# use SYS calls in the future, meaning that none of the memory
# locations 'sysFn' and 'sysArgs[0-7]' should be assumed preserved.

def scope():
    # generate a new scope to hide clobbered register names and
    # temporarily define new register names.
    code = []

    B0 = B1 = B2 = LAC = None
    SIGN = 0x81   # FAC sign in the high bit. Other bits reserved
    AE = 0x82   # FAC exponent
    AM = 0x83     # FAC mantissa with an additional high byte
    BM = T0
    T2L = T2
    T2H = T2+1

    # ==== sigFPE exception

    def code_vsp():
        '''Saved vSP for fpe recovery'''
        label('.vspfpe')
        space(1)

    def macro_save_vsp(r=T2):
        '''Save vSP for returning from a sigFPE exception. 
           Clobbers r which defaults to T2'''
        LDWI('.vspfpe');STW(r);LD(vSP);DOKE(r)

    def code_fpe():
        nohop()
        label('_@_fovf') ### overflow
        _LDI(0xffff);_CALLI('_@_fsetfac')
        LDWI(0x204);BRA('.fpe1')
        label('_@_fpe')  ### floating point error
        LDWI(0x304)
        label('.fpe1')
        _CALLI('_@_raise')
        _LD('.vspfpe'); ST(vSP)
        POP();RET()

    code += [('IMPORT', '_@_raise'),
             ('BSS','.vspfpe', code_vsp, 1, 1),
             ('CODE', '_@_fpe', code_fpe) ]

    # ==== load/store FAC 

    def code_fldfac():
        nohop()
        label('_@_fldfac')
        if args.cpu <= 5:
            # it does not seem worth testing for the lack of page crossings
            LDW(T3);PEEK();ST(AE)
            LDI(1);ADDW(T3);PEEK();ST(AM+3);ANDI(0x80);ST(SIGN)
            LDI(2);ADDW(T3);PEEK();ST(AM+2)
            LDI(3);ADDW(T3);PEEK();ST(AM+1)
            LDI(4);ADDW(T3);PEEK();ST(AM)
            LD(AM+3);ORI(0x80);ST(AM+3)
            LDI(0);ST(AM+4)
            RET()
        else:
            # cpu6 brings (untested) possibilities
            LDW(T3)
            ANDI(0xfc)
            XORI(0xfc)
            BEQ('.fldslow')
            # -- no page crossings
            LDW(T3)
            PEEKA+(AE)
            PEEKA+(AM+3)
            PEEKA+(AM+2)
            PEEKA+(AM+1)
            PEEKA+(AM)
            LD(AM+3);ANDI(0x80);ST(SIGN)
            ORBI(AM+3, 0x80)
            MOVQ(AM+4, 0x00)
            RET()
            # -- with page crossings
            label('.fltslow')
            LDW(T3)
            PEEKA(AE)
            INCW(vAC);PEEKA(AM+3)
            INCW(vAC);PEEKA(AM+2)
            INCW(vAC);PEEKA(AM+1)
            INCW(vAC);PEEKA(AM)
            LD(AM+3);ANDI(0x80);ST(SIGN)
            ORBI(AM+3, 0x80)
            MOVQ(AM+4, 0x00)
            RET()

    def code_fstfac():
        nohop()
        label('_@_fstfac')
        LD(AE);POKE(T2)
        LD(SIGN);BGE('.fst1')
        LD(AM+3);ORI(0x80);BRA('.fst2')      # negative
        label('.fst1');LD(AM+3);ANDI(0x7f)  # positive
        label('.fst2');ST(T3)
        if args.cpu <= 5:
            LDW(T2)
            ANDI(0xfc)
            XORI(0xfc)
            BEQ('.fstslow')
            # -- no page crossings
            INC(T2);LD(T3);POKE(T2)
            INC(T2);LD(AM+2);POKE(T2)
            INC(T2);LD(AM+1);POKE(T2)
            INC(T2);LD(AM);POKE(T2)
            RET()
            # -- page crossings
            label('.fstslow')
            LDI(1);ADDW(T2);STW(T2);LD(T3);POKE(T2)
            LDI(1);ADDW(T2);STW(T2);LD(AM+2);POKE(T2)
            LDI(1);ADDW(T2);STW(T2);LD(AM+1);POKE(T2)
            LDI(1);ADDW(T2);STW(T2);LD(AM);POKE(T2)
            RET()
        else:
            # is it true that cpu6 has no POKEA+ (?)
            LDW(T2)
            INCW(vAC);POKEA(T3)
            INCW(vAC);POKEA(AM+2)
            INCW(vAC);POKEA(AM+1)
            INCW(vAC);POKEA(AM)
            RET()

    def code_fclrfac():
        nohop()
        label('_@_fclrfac')
        LDI(0)
        label('_@_fsetfac')
        ST(AE)
        STW(AM)
        STW(AM+2)
        LDI(0)
        ST(SIGN)
        ST(AM+4)
        RET()


    code += [('EXPORT', '_@_fldfac'),
             ('EXPORT', '_@_fstfac'),
             ('CODE', '_@_fldfac', code_fldfac),
             ('CODE', '_@_fstfac', code_fstfac),
             ('CODE', '_@_fclrfac', code_fclrfac) ]

    # ==== normalization


    # ==== conversions

    #    extern('_@_ftou')
    #    extern('_@_ftoi')
    #    extern('_@_fcvi')
    #    extern('_@_fcvu')

    # ==== additions and subtractions

    #    extern('_@_fadd')
    #    extern('_@_fsub')

    # ==== multiplication

    #    extern('_@_fmul')

    # ==== division

    #    extern('_@_fdiv')

    # ==== comparisons

    #    extern('_@_fcmp')

    # ==== misc

    def code_fneg():
        nohop()
        label('_@_fneg')
        LD(SIGN);XORI(0x80);ST(SIGN)
        RET()

    def code_fscalb():
        nohop()
        label('_@_fscalb')
        PUSH()
        STW(T0);LD(AE);ADDW(T0);BLT('.fscalund')
        ST(AE);LD(vACH);BNE('.fscalovf')
        POP();RET()
        label('.fscalund') # underflow
        _CALLJ('_@_fclrfac');POP();RET()
        label('.fscalovf') # overflow
        macro_save_vsp();_CALLJ('_@_fovf');HALT()

    code += [('EXPORT', '_@_fneg'),
             ('EXPORT', '_@_fscalb'),
             ('CODE', '_@_fneg', code_fneg),
             ('CODE', '_@_fscalb', code_fscalb) ]

    return code


module(code=scope(), name='rt_fp.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
