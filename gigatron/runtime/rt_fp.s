


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
    AEXP = 0x82   # FAC exponent
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
        label('_@_ovf') ############ overflow
        LDWI(0x204);BRA('.fpe1')
        label('_@_fpe') ############ floating point error
        LDWI(0x304)
        label('.fpe1')
        _CALLI('_@_raise')
        _LD('.vspfpe'); ST(vSP)
        POP();RET()

    code += [('BSS','.vspfpe', code_vsp, 1, 1),
             ('CODE', '_@_fpe', code_fpe) ]

    # ==== load/store FAC 

    #    extern('_@_fstorefac')
    #    extern('_@_floadfac') 
    #    extern('_@_fadd')
    #    extern('_@_fsub')
    #    extern('_@_fmul')
    #    extern('_@_fdiv')
    #    extern('_@_fneg')
    #    extern('_@_fcmp')
    #    extern('_@_ftou')
    #    extern('_@_ftoi')
    #    extern('_@_fcvi')
    #    extern('_@_fcvu')


    return code


module(code=scope(), name='rt_fp.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
