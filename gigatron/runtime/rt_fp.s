


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

    SIGN = 0x81   # sign byte
                  #  bit7 = sign(FAC)
    
    # naming convention for exported symbols
    # '_@_xxxx' are the public api.
    # '__@xxxx' are private.
    
    # ==== Macros

    genlabel_counter = 0
    def genlabel():
        global genlabel_counter
        genlabel_counter += 1
        return ".GL%d" % genlabel_counter

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
           Sign in bit 7 of vAC. Returns if `ret` is true. 
           May use a fast path if `fastpath` is true.
           Pointer `ptr` is not preserved.'''
        ORI(127)
        STLW(-2)
        if args.cpu <= 5:
            if exponent:
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
        else:
            if exponent:
                LD(exponent); POKE(ptr)
            INCW(ptr);LDLW(-2);ANDW(mantissa+3);POKE(ptr)
            INCW(ptr);LD(mantissa+2);POKE(ptr)
            INCW(ptr);LD(mantissa+1);POKE(ptr)
            INCW(ptr);LD(mantissa);POKE(ptr)
            if ret:
                RET()
                
    # ==== common things

    def code_fexception():
        nohop()
        label('__@fexception')   ### SIGFPE/exception
        LDWI(0x304);_BRA('.raise')
        label('__@foverflow')    ### SIGFPE/overflow
        _LDI(0xffff);STW(AM);STW(AM+2);ST(AE);LDWI(0x204);
        label('.raise')
        _CALLI('_@_raise')
        label('.vspfpe',pc()+1)        
        LDI(0)  # this instruction is patched by fsavevsp.
        ST(vSP);POP();RET()

    def code_fsavevsp():
        nohop()
        label('__@fsavevsp')
        if args.cpu <= 5:
            LDWI('.vspfpe');STW(T2)
            LD(vSP);DOKE(T2)
        else:
            LDWI('.vspfpe');POKEA(vLR)
        RET()
        
    def code_clrfac():
        nohop()
        label('__@clrfac')
        LDI(0);ST(AE);STW(AM);STW(AM+2);ST(AM+4)
        RET()

    def code_fzero():
        label('_@_fzero')
        bytes(0,0,0,0,0) # 0.0F

    def code_fone():
        label('_@_fone')
        bytes(129,0,0,0,0) # 1.0F

    def code_fhalf():
        label('_@_fhalf')
        bytes(128,0,0,0,0) # 0.5F
        
    module(name='rt_fexception.s',
           code=[ ('IMPORT', '_@_raise'),
                  ('EXPORT', '__@fexception'),
                  ('EXPORT', '__@foverflow'),
                  ('EXPORT', '__@fsavevsp'),
                  ('EXPORT', '__@clrfac'),
                  ('EXPORT', '_@_fzero'),
                  ('EXPORT', '_@_fone'),
                  ('EXPORT', '_@_fhalf'),
                  ('CODE', '__@fexception', code_fexception),
                  ('CODE', '__@fsavevsp', code_fsavevsp),
                  ('CODE', '__@clrfac', code_clrfac),
                  ('DATA', '_@_fzero', code_fzero, 5, 1),
                  ('DATA', '_@_fone', code_fone, 5, 1),
                  ('DATA', '_@_fhalf', code_fhalf, 5, 1) ] )
    
    # ==== load FAC 

    def code_fldfac():
        '''[T3]->FAC'''
        nohop()
        label('_@_fldfac')
        m_load(T3, exponent=AE, mantissa=AM, ext=True)
        ANDI(0x80);ST(SIGN)
        RET()

    module(name='rt_fldfac.s',
           code=[ ('EXPORT', '_@_fldfac'),
                  ('CODE', '_@_fldfac', code_fldfac) ] )

    # ==== store FAC 

    def code_fstfac():
        '''FAC->[T2]'''
        nohop()
        label('_@_fstfac')
        LDW(SIGN);ANDI(0x80);ORI(0x7f)
        m_store(T2, exponent=AE, mantissa=AM, ret=True)

    module(name='rt_fstfac.s',
           code=[ ('EXPORT', '_@_fstfac'),
                  ('CODE', '_@_fstfac', code_fstfac) ] )



    # ==== shift left

    # ==== shift right

    def macro_shr16(r, ext=True):
        LDW(r+2);STW(r)
        if ext:
            LD(r+4);STW(r+2);LDI(0);ST(r+4)
        else:
            LDI(0);STW(r+2)

    def macro_shr8(r, ext=True):
        LDW(r+1);STW(r);
        if ext:
            LDW(r+3);STW(r+2);LDI(0);ST(r+4)
        else:
            LD(r+3);STW(r+2)

    def code_amshr8():
        nohop()
        label('.amshr7')    # coming from __@amshr
        CALLJ('__@amshl1')
        POP()
        label('.amshr8')    # AM >>= 8
        macro_shr8(AM)
        RET()
            
    def code_amshr1():
        nohop()
        label('__@amshr1')  # AM >>= 1
        _LDI('SYS_LSRW1_48')
        label('.amshrx')
        STW('sysFn')
        LDW(AM);SYS(52);ST(AM)
        LDW(AM+1);SYS(52);ST(AM+1)
        LDW(AM+2);SYS(52);ST(AM+2)
        LDW(AM+3);SYS(52);STW(AM+3)
        label('.amshrdone')
        RET()
        label('.amshra')  # AM >>= vAC for 0<vAC<=8 no check
        XORI(7)
        BNE('.amshr1to6')
        PUSH()
        CALLJ('.amshr7')
        label('.amshr1to6')
        # try not overwriting T2
        LSRW();STW(T2)
        _LDI(v('.shrtable')-2);ADDW(T2);DEEK()
        BRA('.amshrx')


    def code_shrtable():
        label(".shrtable")
        words("SYS_LSRW6_48")
        words("SYS_LSRW5_50")
        words("SYS_LSRW4_50")
        words("SYS_LSRW3_52")
        words("SYS_LSRW2_52")
        words("SYS_LSRW1_48")

    
    
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

    # ==== fneg

    def code_fneg():
        nohop()
        label('_@_fneg')
        LD(SIGN);XORI(0x80);ST(SIGN)
        RET()

    module(name = 'rt_fneg.s',
           code = [ ('EXPORT', '_@_fneg'),
                    ('CODE', '_@_fneg', code_fneg) ] )

    # ===== fscalb
    
    def code_fscalb():
        nohop()
        label('_@_fscalb')
        PUSH()
        STW(T0);LD(AE);ADDW(T0);BLT('.fscalund')
        ST(AE);LD(vACH);BNE('.fscalovf')
        POP();RET()
        label('.fscalund')
        _CALLJ('__@clrfac');POP();RET()
        label('.fscalovf')
        _CALLJ('__@fsavevsp')
        _CALLJ('__@foverflow');HALT()

    module(name = 'rt_fscalb.s',
           code = [ ('IMPORT', '__@clrfac'),
                    ('IMPORT', '__@foverflow'),
                    ('EXPORT', '_@_fscalb'),
                    ('CODE', '_@_fscalb', code_fscalb) ] )

    return code



# create all the modules
scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
