


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

    T2L = T2
    T2H = T2+1
    T3L = T3
    T3H = T3+1

    AE = 0x82     # FAC exponent
    AM = 0x83     # FAC mantissa with an additional high byte
    BE = T0+5     # same as T2H!    
    BM = T0       # T0/T1/T2L

    # naming convention for exported symbols
    # '_@_xxxx' are the public api.
    # '__@xxxx' are private.
    
    # ==== Macros

    genlabel_counter = 0
    def genlabel():
        global genlabel_counter
        genlabel_counter += 1
        return ".GL%d" % genlabel_counter

    def m_savevsp(reg = T2):
        '''Save vSP to be restored on exception'''
        if args.cpu <= 5:
            LDWI('.vspfpe');STW(reg)
            LD(vSP);DOKE(reg)
        else:
            LDWI('.vspfpe');POKEA(vLR)
    
    def m_load(ptr = T3, exponent = AE, mantissa = AM, ext = True):
        '''Load float pointed by `ptr` into `exponent` and `mantissa`.
           Argument `ext` says whether `mantissa` is 32 or 40 bits.
           Preserve the value of pointer `ptr`.
           Argument `exponent` might be None to ignore it.
           Returns sign in bit 7 of vAC.'''
        if args.cpu <= 5:
            if exponent:
                LDW(ptr);PEEK();ST(exponent)
            LDI(1);ADDW(ptr);PEEK();STLW(-2);ORI(128);ST(mantissa+3)
            LDI(2);ADDW(ptr);PEEK();ST(mantissa+2)
            LDI(3);ADDW(ptr);PEEK();ST(mantissa+1)
            LDI(4);ADDW(ptr);PEEK();ST(mantissa)
            if ext:
                LDI(0);ST(mantissa+4)
            LDLW(-2)
        else:
            LDW(ptr)
            if exponent:
                PEEKA(exponent)
            INCW(vAC);PEEKA(mantissa+3)
            INCW(vAC);PEEKA(mantissa+2)
            INCW(vAC);PEEKA(mantissa+1)
            INCW(vAC);PEEKA(mantissa)
            if ext:
                MOVQ(mantissa+4, 0x00)
            LD(mantissa+3); 
            ORBI(mantissa+3, 0x80)

    def m_store(ptr = T3, exponent = AE, mantissa = AM, ret = False, fastpath = False):
        '''Save float at location `ptr`.
           Exponent and mantissa are taken from the specified locations.
           vAC is expected to be 0x7f for a positive number, 0xff for a negative one.
           Returns if `ret` is true. May use a fast path if `fastpath` is true.
           Pointer `ptr` is not preserved.'''
        STLW(-2)
        if args.cpu <= 5:
            LD(exponent);POKE(ptr)
            if fastpath:
                lblslow = genlabel()
                lbldone = genlabel()
                LD(ptr);ANDI(0xfc);XORI(0xfc);_BEQ(lblslow)
                # no page crossing
                INC(ptr);LDLW(-2);ANDW(mantissa+3);POKE(ptr)
                INC(ptr);LD(mantissa+2);POKE(ptr)
                INC(ptr);LD(mantissa+1);POKE(ptr)
                INC(ptr);LD(mantissa);POKE(ptr)
                RET() if ret else _BRA(lbldone)
                label(lblslow)
            # page crossing possible
            LDI(1);ADDW(ptr);STW(ptr);LDLW(-2);ANDW(mantissa+3);POKE(ptr)
            LDI(1);ADDW(ptr);STW(ptr);LD(mantissa+2);POKE(ptr)
            LDI(1);ADDW(ptr);STW(ptr);LD(mantissa+1);POKE(ptr)
            LDI(1);ADDW(ptr);STW(ptr);LD(mantissa);POKE(ptr)
            if fastpath:
                label(lbldone)
            if ret:
                RET() 

        
    
    # ==== sigFPE exception

    def code_fpe():
        nohop()
        label('_@_foverflow')   ### overflow
        _LDI(0xffff);_CALLI('_@_fsetfac')
        LDWI(0x204);BRA('.fpe1')
        label('_@_fexception')  ### floating point error
        LDWI(0x304)
        label('.fpe1')
        _CALLI('_@_raise')
        label('.vspfpe',pc()+1)        
        LDI(0)  # this instruction is patched by macro_save_vsp.
        ST(vSP)
        POP();RET()

    code += [('IMPORT', '_@_raise'),
             ('CODE', '_@_fpe', code_fpe) ]

    # ==== load/store FAC 




    if False:
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
        macro_save_vsp();_CALLJ('_@_foverflow');HALT()

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
