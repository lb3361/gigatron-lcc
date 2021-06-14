


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

    T2L = T2
    T2H = T2+1
    T3L = T3
    T3H = T3+1

    AE = 0x82     # FAC exponent
    AM = 0x83     # FAC mantissa with an additional high byte
    AS = 0x81     # FAC sign (bit7).
    
    BM = T0       # T0/T1/T2L. Fifth byte overlaps T2L and CM!
    CM = T2       # T2/T3/---. No fifth byte
   
    # naming convention for exported symbols
    # '_@_xxxx' are the public api.
    # '__@xxxx' are private.
    
    # ==== Load/store

    def m_load(ptr = T3, exponent = AE, mantissa = AM, ret = False, ext = True, checkzero = True):
        '''Load float pointed by `ptr` into `exponent` and `mantissa`.
           Argument `ext` says whether `mantissa` is 32 or 40 bits.
           Preserve the value of pointer `ptr`.
           Argument `exponent` might be None to ignore it.
           Returns sign in bit 7 of vAC.'''
        if exponent or checkzero:
            lbl = genlabel()
            lbr = genlabel()
            LDW(ptr);PEEK()
            if exponent:
                ST(exponent)
            _BNE(lbl)
            LDI(0)
            if mantissa:
                STW(mantissa);STW(mantissa+2)
            if ext:
                ST(mantissa+4)
            if ret:
                RET();
            else:
                _BRA(lbr)
            label(lbl)
        if args.cpu <= 5:
            LDI(1);ADDW(ptr);PEEK();STLW(-2);ORI(128);ST(mantissa+3)
            LDI(2);ADDW(ptr);PEEK();ST(mantissa+2)
            LDI(3);ADDW(ptr);PEEK();ST(mantissa+1)
            LDI(4);ADDW(ptr);PEEK();ST(mantissa)
            if ext:
                LDI(0);ST(mantissa+4)
            LDLW(-2)
        else:
            INCW(vAC);PEEKA(mantissa+3)
            INCW(vAC);PEEKA(mantissa+2)
            INCW(vAC);PEEKA(mantissa+1)
            INCW(vAC);PEEKA(mantissa)
            if ext:
                MOVQ(mantissa+4, 0x00)
            LD(mantissa+3); 
            ORBI(mantissa+3, 0x80)
        if ret:
            RET()
        elif exponent or checkzero:
            label(lbr)

    def m_store(ptr = T3, exponent = AE, mantissa = AM, ret = False, fastpath = False):
        '''Save float at location `ptr`.
           Exponent and mantissa are taken from the specified locations.
           Sign in bit 7 of vAC. Returns if `ret` is true. 
           May use a fast path if `fastpath` is true.
           Pointer `ptr` is not preserved.'''
        ORI(0x7f);STLW(-2)
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

    def code_fldfac():
        '''[T3]->FAC'''
        nohop()
        label('_@_fldfac')
        m_load(T3, exponent=AE, mantissa=AM, ret=False, ext=True)
        ANDI(0x80);ST(AS)
        RET()

    module(name='rt_fldfac.s',
           code=[ ('EXPORT', '_@_fldfac'),
                  ('CODE', '_@_fldfac', code_fldfac) ] )

    def code_fstfac():
        '''FAC->[T2]'''
        nohop()
        label('_@_fstfac')
        LD(AS);ANDI(0x80)
        m_store(T2, exponent=AE, mantissa=AM, ret=True)

    module(name='rt_fstfac.s',
           code=[ ('EXPORT', '_@_fstfac'),
                  ('CODE', '_@_fstfac', code_fstfac) ] )

    def code_am40load():
        nohop()
        label('__@am40load')
        m_load(ptr=T3, exponent=None, mantissa=AM, ret=True, ext=True)

    module(name='rt_am40load.s',
           code=[ ('EXPORT', '__@am40load'),
                  ('CODE', '__@am40load', code_am40load) ] )

    def code_bm40load():
        nohop()
        label('__@bm40load')
        m_load(ptr=T3, exponent=None, mantissa=BM, ret=True, ext=True)

    module(name='rt_bm40load.s',
           code=[ ('EXPORT', '__@bm40load'),
                  ('CODE', '__@bm40load', code_bm40load) ] )


    def code_bm32loadx():
        '''just load the mantissa with no additional checks'''
        label('__@bm32loadx')
        PUSH()
        m_load(ptr=T3, exponent=None, mantissa=BM, checkzero=False, ext=False)
        tryhop(2);POP();RET()
        
    module(name='rt_bm32loadx.s',
           code=[ ('EXPORT', '__@bm32loadx'),
                  ('CODE', '__@bm32loadx', code_bm32loadx) ] )

                
    # ==== common things

    def code_fexception():
        nohop()
        label('__@fexception')   ### SIGFPE/exception
        LDWI(0x304);_BRA('.raise')
        label('__@foverflow')    ### SIGFPE/overflow
        LDWI(0x204);
        label('.raise')
        STLW(-2);_LDI(0xffff);STW(AM);STW(AM+2);ST(AE)
        LDLW(-2);_CALLI('_@_raisefpe')
        label('.vspfpe',pc()+1)        
        LDI(0)  # this instruction is patched by fsavevsp.
        ST(vSP);POP();RET()

    def code_fsavevsp():
        nohop()
        label('__@fsavevsp')
        if args.cpu <= 5:
            LDWI('.vspfpe');STW(T2)
            LD(vSP);POKE(T2)
        else:
            LDWI('.vspfpe');POKEA(vSP)
        RET()
        
    module(name='rt_fexception.s',
           code=[ ('IMPORT', '_@_raisefpe'),
                  ('EXPORT', '__@fexception'),
                  ('EXPORT', '__@foverflow'),
                  ('EXPORT', '__@fsavevsp'),
                  ('CODE', '__@fexception', code_fexception),
                  ('CODE', '__@fsavevsp', code_fsavevsp) ] )

    def code_clrfac():
        nohop()
        label('__@clrfac')
        LDI(0);ST(AE);STW(AM);STW(AM+2);ST(AM+4);ST(AS)
        RET()

    module(name='rt_clrfac.s',
           code=[ ('EXPORT', '__@clrfac'),
                  ('CODE', '__@clrfac', code_clrfac) ] )

    def code_fone():
        label('_@_fone')
        bytes(129,0,0,0,0) # 1.0F

    module(name='rt_fone.s',
           code=[ ('EXPORT', '_@_fone'),
                  ('DATA', '_@_fone', code_fone, 5, 1) ] )

    def code_fhalf():
        label('_@_fhalf')
        bytes(128,0,0,0,0) # 0.5F

    module(name='rt_fhalf.s',
           code=[ ('EXPORT', '_@_fhalf'),
                  ('DATA', '_@_fhalf', code_fhalf, 5, 1) ] )


    # ==== load FAC 

    # ==== shift left

    def macro_shl1(r, ext=True, ret=False):
        if ext:
            LDW(r+3);LSLW();LD(vACH);ST(r+4)
        lbl1 = genlabel()
        lbl2 = genlabel()
        LDW(r);_BLT(lbl1)
        LSLW();STW(r)
        LDW(r+2);LSLW();STW(r+2)
        RET() if ret else _BRA(lbl2)
        label(lbl1)
        LSLW();STW(r)
        LDW(r+2);LSLW();ORI(1);STW(r+2)
        RET() if ret else label(lbl2)

    def macro_shl4(r, ext=True):
        LDWI('SYS_LSLW4_46');STW('sysFn')
        if ext:
            LDW(r+3);SYS(46);LD(vACH);ST(r+4)
        LDW(r+2);SYS(46);LD(vACH);ST(r+3)
        LDW(r+1);SYS(46);LD(vACH);ST(r+2)
        LDW(r);SYS(46);STW(r)

    def macro_shl8(r, ext=True):
        if ext:
            LDW(r+2);STW(r+3)
        else:
            LD(r+2);ST(r+3)
        LDW(r);STW(r+1)
        LDI(0);ST(r)

    def macro_shl16(r, ext=True):
        if ext:
            LD(r+2);ST(r+4)
        LDW(r);STW(r+2)
        LDI(0);STW(r)

    def code_am32shl4():  # AM32 <<= 4
        nohop()
        label('__@am32shl4')
        macro_shl4(AM, ext=False)
        RET()

    def code_am32shl8():  # AM32 <<=8
        nohop()
        label('__@am32shl8')
        macro_shl8(AM, ext=False)
        RET()

    def code_am32shl16(): # AM32 <<= 16
        nohop()
        label('__@am32shl16')
        macro_shl16(AM, ext=False)
        RET()

    module(name='rt_fshl.s',
           code=[ ('EXPORT', '__@am32shl4'),
                  ('EXPORT', '__@am32shl8'),
                  ('EXPORT', '__@am32shl16'),
                  ('CODE', '__@am32shl4', code_am32shl4),
                  ('CODE', '__@am32shl8', code_am32shl8),
                  ('CODE', '__@am32shl16', code_am32shl16) ] )

    def code_am40shl1():
        nohop()
        label('__@am40shl1')
        LDW(AM+3);LSLW();LD(vACH);ST(AM+4)
        label('__@am32shl1')
        macro_shl1(AM, ext=False, ret=True)

    module(name='rt_am40shl1.s',
           code=[ ('EXPORT', '__@am40shl1'),
                  ('EXPORT', '__@am32shl1'),
                  ('CODE', '__@am40shl1', code_am40shl1) ] )

    def code_bm40shl1():
        nohop()
        label('__@bm40shl1')
        LDW(BM+3);LSLW();LD(vACH);ST(BM+4)
        label('__@bm32shl1')
        macro_shl1(BM, ext=False, ret=True)

    module(name='rt_bm40shl1.s',
           code=[ ('EXPORT', '__@bm40shl1'),
                  ('EXPORT', '__@bm32shl1'),
                  ('CODE', '__@bm40shl1', code_bm40shl1) ] )

    def code_cm32shl1():
        nohop()
        label('__@cm32shl1')
        macro_shl1(CM, ext=False, ret=True)

    module(name='rt_cm32shl1.s',
           code=[ ('EXPORT', '__@cm32shl1'),
                  ('CODE', '__@cm40shl1', code_cm32shl1) ] )
    
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

    def code_am40shr8():
        nohop()
        label('__@am40shr8')
        macro_shr8(AM, ext=True)
        RET()

    module(name='rt_am40shr8.s',
           code=[ ('EXPORT', '__@am40shr8'),
                  ('CODE', '__@am40shr8', code_am40shr8) ]  )

    def code_bm40shr8():
        nohop()
        label('__@bm40shr8')
        macro_shr8(BM, ext=True)
        RET()
        
    module(name='rt_bm40shr8.s',
           code=[ ('EXPORT', '__@bm40shr8'),
                  ('CODE', '__@bm40shr8', code_bm40shr8) ]  )

    def code_am40shr1():
        '''shift am40 right by one position'''
        nohop()
        label('__@am40shr1')  # AM40 >>= 1
        _LDI('SYS_LSRW1_48');STW('sysFn')
        LDW(AM);SYS(48);ST(AM)
        LDW(AM+1);SYS(48);ST(AM+1)
        LDW(AM+2);SYS(48);ST(AM+2)
        LDW(AM+3);SYS(48);STW(AM+3)
        RET()

    module(name='rt_fam40shr1.s',
           code=[ ('EXPORT', '__@am40shr1'),
                  ('CODE', '__@am40shr1', code_am40shr1) ]  )

    def code_am32shr16():
        nohop()
        label('__@am32shr16')
        macro_shr16(AM, ext=False)
        RET()

    def code_am32shr8():
        nohop()
        label('__@am32shr8')
        macro_shr8(AM, ext=False)
        RET()
    
    def code_am32shra():
        '''shift am32 right by vAC positions'''
        label('__@am32shra') # AM30 >>= vAC
        PUSH();STLW(-2)
        ANDI(0xe0);_BEQ('.shra16')
        LDI(0);STW(AM);STW(AM+2)
        label('.shraret')
        tryhop(2);POP();RET()
        label('.shra16')
        LDLW(-2);ANDI(16);_BEQ('.shra8')
        _CALLJ('__@am32shr16')
        label('.shra8')
        LDLW(-2);ANDI(8);_BEQ('.shra1to7')
        _CALLJ('__@am32shr8')
        label('.shra1to7')
        LDLW(-2);ANDI(7);_BEQ('.shraret')
        _CALLI('__@shrsysfn')
        LDW(AM);SYS(52);ST(AM)
        LDW(AM+1);SYS(52);ST(AM+1)
        LDW(AM+2);SYS(52);STW(AM+2)
        tryhop(2);POP();RET()

    module(name='rt_fam32shra.s',
           code=[ ('EXPORT', '__@am32shra'),
                  ('IMPORT', '__@shrsysfn'),
                  ('CODE', '__@am32shr16', code_am32shr16),                  
                  ('CODE', '__@am32shr8', code_am32shr8),
                  ('CODE', '__@am32shra', code_am32shra) ]  )

    # ==== normalization

    def code_am40neg():
        nohop()
        label('__@am40neg')
        LDI(0xff);XORW(AM+4);ST(AM+4)
        _LDI(0xffff);XORW(AM+2);STW(AM+2)
        _LDI(0xffff);XORW(AM);ADDI(1);STW(AM);BNE('.ret')
        LDI(1);ADDW(AM+2);STW(AM+2);BNE('.ret')
        INC(AM+4)
        label('.ret')
        RET()

    module(name='rt_fam40neg.s',
           code=[ ('EXPORT', '__@am40neg'),
                  ('CODE', '__@am40neg', code_am40neg) ])

    def code_fnorm3():
        '''There are three normalization levels.
           -- __@fnorm3 just shifts am32 left until normalized.
           -- __@fnorm2 can shift am40 right (occasionally happens once after addition, can overflow).
           -- __@fnorm1 can also two-complement am40 (happens after addition).'''
        # entry point for fnorm3
        label('__@fnorm3')
        PUSH()
        LD(AM+4);_BEQ('.norm1')
        ST(vACH);_BGT('.norm2')
        LD(AS);XORI(128);ST(AS)
        _CALLJ('__@am40neg');_BRA('.norm2')
        # entry point for fnorm2
        label('__@fnorm2')
        PUSH()
        label('.norm2')
        LD(AM+4);_BEQ('.norm1')
        _CALLJ('__@am40shr1')
        INC(AE);LD(AE);_BNE('.norm2')
        _CALLJ('__@foverflow')
        label('.norm1')
        _CALLJ('__@fnorm1')
        tryhop(2);POP();RET()

    def code_fnorm1():
        label('__@fnorm1')
        PUSH()
        LDW(AM+2);_BNE('.norm1b')
        ORW(AM);_BEQ('.norm0')
        LD(AE);SUBI(16);_BLE('.norm0');ST(AE)
        _CALLJ('__@am32shl16')
        label('.norm1b')
        LD(AM+3);_BNE('.norm1c')
        LD(AE);SUBI(8);_BLE('.norm0');ST(AE)
        _CALLJ('__@am32shl8')
        label('.norm1c')
        LD(AM+3);ANDI(0xf0);_BNE('.norm1d')
        LD(AE);SUBI(4);_BLE('.norm0');ST(AE)
        _CALLJ('__@am32shl4')
        label('.norm1d')
        LDW(AM+2);_BLT('.normok')
        LD(AE);SUBI(1);_BLE('.norm0');ST(AE)
        _CALLJ('__@am32shl1');_BRA('.norm1d')
        label('.norm0')
        _CALLJ('__@clrfac')
        label('.normok')
        tryhop(2);POP();RET()

    module(name='rt_fnorm.s',
           code=[ ('EXPORT', '__@fnorm1'),
                  ('EXPORT', '__@fnorm2'),
                  ('EXPORT', '__@fnorm3'),
                  ('IMPORT', '__@am40neg'),
                  ('IMPORT', '__@am40shr1'),
                  ('IMPORT', '__@am32shl16'),
                  ('IMPORT', '__@am32shl8'),
                  ('IMPORT', '__@am32shl4'),
                  ('IMPORT', '__@am32shl1'),
                  ('IMPORT', '__@foverflow'),
                  ('IMPORT', '__@clrfac'),
                  ('CODE', '__@fnorm3', code_fnorm3),
                  ('CODE', '__@fnorm1', code_fnorm1) ] )

    # ==== conversions

    def code_fcvu():
        label('_@_fcvu')
        PUSH()
        # _CALLJ('__@fsavevsp')  # should not throw
        _CALLJ('__@am40shr8')
        LDI(160);ST(AE)
        LDI(0);ST(AS);ST(AM+4)
        _CALLJ('__@fnorm1')
        tryhop(2);POP();RET()

    module(name='rt_fcvu.s',
           code=[ ('EXPORT', '_@_fcvu'),
                  ('IMPORT', '__@fnorm1'),
                  ('IMPORT', '__@am40shr8'),
                  ('CODE', '_@_fcvu', code_fcvu) ] )

    def code_fcvi():
        label('_@_fcvi')
        PUSH()
        # _CALLJ('__@fsavevsp')  # should not throw
        _CALLJ('__@am40shr8')
        LD(AM+3);XORI(128);SUBI(128);STW(AM+3)
        LDI(160);ST(AE)
        LDI(0);ST(AS)
        _CALLJ('__@fnorm3')
        tryhop(2);POP();RET()

    module(name='rt_fcvi.s',
           code=[ ('EXPORT', '_@_fcvi'),
                  ('IMPORT', '__@fnorm3'),
                  ('IMPORT', '__@am40shr8'),
                  ('CODE', '_@_fcvi', code_fcvi) ] )

    def code_ftoi():
        label('_@_ftoi')
        PUSH()
        LD(AE);SUBI(160);_BLT('.ok')
        label('.ovf')
        _CALLJ('__@clrfac')
        LDI(128);ST(LAC+3)
        tryhop(2);POP();RET()
        label('_@_ftou')
        PUSH()
        LD(AS);ANDI(128);BNE('.ovf')
        LD(AE);SUBI(160);_BGT('.ovf')
        label('.ok')
        XORI(255);ANDI(255);INC(vAC)
        _CALLI('__@am32shra')
        LDW(AM+2);STW(LAC+2);
        LDW(AM);STW(LAC);
        LD(AS);ANDI(128);BEQ('.ret')
        _LNEG()
        label('.ret')
        tryhop(2);POP();RET()
        
    module(name='rt_ftoi.s',
           code=[ ('EXPORT', '_@_ftoi'),
                  ('EXPORT', '_@_ftou'),
                  ('IMPORT', '__@am32shra'),
                  ('IMPORT', '__@clrfac'),
                  ('CODE', '_@_ftoi', code_ftoi) ] )

    # ==== additions and subtractions

    # Notes: This code uses an extended mantissa with an additional
    # high byte (am40) However it still aligns the numbers inside the
    # four low bytes, meaning that the high byte is only used for an
    # eventual carry.  One could gain some precision by moving the top
    # mantissa bit inside the extension byte, therefore creating more
    # low bits for the operand with the lowest absolute value.  We
    # would need to replace __@am32shra by __@am40shra and improve
    # fnorm2 for speed. Instead we use __@faddalign to round the
    # bottom bit of the operant with the lowest absolute value, and
    # this seems to work well enough.

    def code_am40addbm40():
        nohop()
        label('__@am40addbm40')
        if args.cpu <= 5:
            LD(AM);ADDW(BM);ST(AM);LD(vACH)
            BNE('.a1');LD(BM+1);BEQ('.a1');LDWI(0x100);label('.a1')
            ADDW(AM+1);ST(AM+1);LD(vACH)
            BNE('.a2');LD(AM+2);BEQ('.a2');LDWI(0x100);label('.a2')
            ADDW(BM+2);ST(AM+2);LD(vACH)
            BNE('.a3');LD(BM+3);BEQ('.a3');LDWI(0x100);label('.a3')
            ADDW(AM+3);ST(AM+3);LD(vACH)
            ADDW(BM+4);ST(AM+4)
        else:
            # untested but sensible
            LD(BM);ADDBA(AM);ST(AM);LD(vACH)
            ADDBA(BM+1);ADDBA(AM+1);ST(AM+1);LD(vACH)
            ADDBA(BM+2);ADDBA(AM+2);ST(AM+2);LD(vACH)
            ADDBA(BM+3);ADDBA(AM+3);ST(AM+3);LD(vACH)
            ADDBA(BM+4);ADDBA(AM+4);ST(AM+4)
        RET()

    module(name='rt_am40addbm40.s',
           code=[ ('EXPORT', '__@am40addbm40'),
                  ('CODE', '__@am40addbm40', code_am40addbm40) ])

    def code_faddalign():
        '''Plugin replacement for __@amshra that rounds the last bit. This
           mildly increases computation time but halves the residual error.'''
        label('__@faddalign')
        PUSH();_BEQ('.aligned')
        SUBI(1);_BEQ('.align1')
        _CALLI('__@am32shra')
        label('.align1')
        _LDI('SYS_LSRW1_48');STW('sysFn')
        LDI(1);ADDW(AM);STW(AM);_BNE('.align2')
        LDI(1);ADDW(AM+2);STW(AM+2);_BRA('.align3')
        label('.align2')
        SYS(48);ST(AM)
        label('.align3')
        LDW(AM+1);SYS(48);ST(AM+1)
        LDW(AM+2);SYS(48);STW(AM+2)
        label('.aligned')
        tryhop(2);POP();RET()

    def code_fadd_t3():
        label('__@fadd_t3')
        PUSH();LDW(T3);PEEK();STW(T2);_BEQ('.faddx4')
        LD(AE);SUBW(T2);_BGT('.faddx1')
        XORI(255);INC(vAC);ANDI(255)   # FAC exponent <= arg exponent
        _CALLI('__@faddalign')         # - align (rounded)
        LD(T2L);ST(AE)                 # - assume arg exponent
        _CALLJ('__@bm40load')          # - load arg mantissa
        XORW(AS);ANDI(128)             # - zero if same sign, nonzero otherwise
        _BRA('.faddx2')
        label('.faddx1')               # FAC exponent > arg exponent
        ST(T2L)
        LDW(AM);STW(BM);               # - move fac mantissa into t0t1
        LDW(AM+2);STW(T1);
        _CALLJ('__@am40load')          # - load arg mantissa into am
        XORW(AS);ANDI(128);ST(T2H  )   # - are signs different?
        XORW(AS);ST(AS)                # - assume arg sign
        LD(T2L)
        _CALLI('__@faddalign')         # - align (rounded)
        LD(T2H);                       # - zero if same sign, nonzero otherwise
        label('.faddx2')
        _BEQ('.faddx3')
        _CALLJ('__@lneg_t0t1')
        LDI(0xff)
        label('.faddx3')
        ST(BM+4)                       # - overwrites T2L
        _CALLJ('__@am40addbm40')
        _CALLJ('__@fnorm3')
        label('.faddx4')
        tryhop(2);POP();RET()

    module(name='rt_faddt3.s',
           code=[ ('EXPORT', '__@fadd_t3'),
                  ('IMPORT', '__@am32shra'),
                  ('IMPORT', '__@lneg_t0t1'),
                  ('IMPORT', '__@am40addbm40'),
                  ('IMPORT', '__@fnorm3'),
                  ('IMPORT', '__@am40load'),
                  ('IMPORT', '__@bm40load'),
                  ('CODE', '__@faddalign', code_faddalign),
                  ('CODE', '__@fadd_t3', code_fadd_t3) ] )

    def code_fadd():
        label('_@_fadd')
        PUSH();STW(T3)
        _CALLJ('__@fsavevsp')
        _CALLJ('__@fadd_t3')
        tryhop(2);POP();RET()

    module(name='rt_fadd.s',
           code=[ ('EXPORT', '_@_fadd'),
                  ('CODE', '_@_fadd', code_fadd),
                  ('IMPORT', '__@fsavevsp'),
                  ('IMPORT', '__@fadd_t3') ] )

    def code_fsub():
        label('_@_fsub')
        PUSH();STW(T3)
        _CALLJ('__@fsavevsp')
        _CALLJ('_@_fneg')
        _CALLJ('__@fadd_t3')
        _CALLJ('_@_fneg')
        tryhop(2);POP();RET()

    module(name='rt_fsub.s',
           code=[ ('EXPORT', '_@_fsub'),
                  ('CODE', '_@_fsub', code_fsub),
                  ('IMPORT', '__@fsavevsp'),
                  ('IMPORT', '_@_fneg'),
                  ('IMPORT', '__@fadd_t3') ] )


    # ==== multiplication


    def code_macbm32x8():
        '''Adds BM32 x T2H to AM40, then AM40>>=8'''
        nohop()
        label('__@macbm32x8')
        PUSH();ALLOC(-2)
        LDI(0);ST(BM+4)
        LDI(1)
        label('.loop')
        STLW(0);ANDW(T2H);BEQ('.skip')
        _CALLJ('__@am40addbm40')
        label('.skip')
        _CALLJ('__@bm40shl1')
        LDLW(0);LSLW();LD(vAC);_BNE('.loop')
        _CALLJ('__@bm40shr8')    # restore BM32
        LDW(AM-1);BGE('.nornd')  # round and shift AM40
        LDI(1);ADDW(AM+1);STW(AM+1);BNE('.nornd')
        LDI(1);ADDW(AM+3);STW(AM+3)
        label('.nornd')
        _CALLJ('__@am40shr8')
        ALLOC(2);POP();RET()

    def code_fmulmac():
           label('__@fmulmac')
           PUSH()
           LDW(AM);STW(BM);LDW(AM+2);STW(BM+2);
           LDI(0);STW(AM);STW(AM+2);ST(AM+4);ST(BM+4)
           LDI(4);ADDW(T3);PEEK();ST(T2H);_CALLJ('__@macbm32x8')
           LDI(3);ADDW(T3);PEEK();ST(T2H);_CALLJ('__@macbm32x8')
           LDI(2);ADDW(T3);PEEK();ST(T2H);_CALLJ('__@macbm32x8')
           LDI(1);ADDW(T3);PEEK();ORI(128);ST(T2H);_CALLJ('__@macbm32x8')
           tryhop(2);POP();RET()

    module(name='__@macbm32x8.s',
           code=[ ('EXPORT', '__@macbm32x8'),
                  ('EXPORT', '__@fmulmac'),
                  ('IMPORT', '__@am40addbm40'),
                  ('IMPORT', '__@bm40shl1'),
                  ('IMPORT', '__@bm40shr8'),
                  ('IMPORT', '__@am40shr8'),
                  ('CODE', '__@macbm32x8', code_macbm32x8),
                  ('CODE', '__@fmulmac', code_fmulmac) ] )
           
    def code_fmul():
           label('_@_fmul')
           PUSH();STW(T3)
           _CALLJ('__@fsavevsp')
           LDW(T3);PEEK();_BEQ('.zero');SUBI(128);STW(T2);
           LD(AE);_BEQ('.zero');ADDW(T2);_BGT('.fmul1')
           label('.zero')
           _CALLJ('__@clrfac')
           tryhop(2);POP();RET()
           label('.fmul1')
           ST(AE);LD(vACH);_BEQ('.fmul2')
           _CALLJ('__@foverflow')
           label('.fmul2')
           LDI(1);ADDW(T3);PEEK();ANDI(128)
           XORW(AS);ST(AS)
           _CALLJ('__@fmulmac')
           _CALLJ('__@fnorm1')
           tryhop(2);POP();RET()
    
    module(name='_@_fmul',
           code=[ ('EXPORT', '_@_fmul'),
                  ('IMPORT', '__@fsavevsp'),
                  ('IMPORT', '__@clrfac'),
                  ('IMPORT', '__@foverflow'),
                  ('IMPORT', '__@fmulmac'),
                  ('IMPORT', '__@fnorm1'),
                  ('CODE', '_@_fmul', code_fmul) ] )


    # ==== division

    def code_am40cmpbm32():
        nohop()
        label('__@am40cmpbm32')
        LD(BM+3);SUBW(AM+3);BLT('.gt');BGT('.lt')
        LDW(BM+1);_CMPWU(AM+1);BLT('.gt');BGT('.lt')
        LDW(BM);_CMPWU(AM);BLT('.gt');BGT('.lt')
        RET()
        label('.gt');LDI(1);RET()
        label('.lt');_LDI(-1);RET()

    module(name='rt_am40cmpbm32.s',
           code=[ ('EXPORT', '__@am40cmpbm32'),
                  ('CODE', '__@am40cmpbm32', code_am40cmpbm32) ] )

    def code_am40subbm32():
        nohop()
        label('__@am40subbm32')
        if args.cpu <= 5:
            # alternating pattern
            LD(AM);SUBW(BM);ST(AM);LD(vACH)
            BNE('.a1');LD(BM+1);XORI(255);BEQ('.a1');LDWI(0x100);label('.a1')
            ADDW(AM+1);ST(AM+1);LD(vACH)
            BNE('.a2');LD(AM+2);BEQ('.a2');LDWI(0x100);label('.a2')
            SUBI(1);SUBW(BM+2);ST(AM+2);LD(vACH)
            BNE('.a3');LD(BM+3);XORI(255);BEQ('.a3');LDWI(0x100);label('.a3')
            ADDW(AM+3);ST(AM+3);LD(vACH);SUBI(1);ST(AM+4)
        else:
            # untested but sensible
            LD(AM);SUBBA(BM);ST(AM);LD(vACH)
            ADDBA(AM+1);SUBBA(BM+1);ST(LAC+1);LD(vACH)
            ADDBA(AM+2);SUBBA(BM+2);ST(LAC+2);LD(vACH)
            ADDW(AM+3);SUBBA(BM+3);ST(LAC+3)
        RET()
        
    module(name='rt_am40subbm32.s',
           code=[ ('EXPORT', '__@am40subbm32'),
                  ('CODE', '__@am40subbm32', code_am40subbm32) ] )

    def code_fdiv():
        label('_@_fdiv')
        PUSH();STW(T3)
        _CALLJ('__@fsavevsp')
        LDW(T3);PEEK();_BNE('.fdiv1')
        _CALLJ('__@fexception')          # divisor is zero
        label('.fdiv1')
        SUBI(129);STW(T2);
        LDI(1);ADDW(T3);PEEK();ANDI(128)
        XORW(AS);ST(AS)                  # set the sign
        LD(AE);_BEQ('.fdivzero')
        SUBW(T2);ST(AE);_BGT('.fdiv2')   # set the exponent
        label('.fdivzero')
        _CALLJ('__@clrfac')              # result is zero
        tryhop(2);POP();RET()
        label('.fdiv2')
        LD(vACH);_BEQ('.fdiv3')
        _CALLJ('__@foverflow')           # result is too large
        label('.fdiv3')
        _CALLJ('__@bm40load')            # load divisor
        LDI(0);STW(CM);STW(CM+2)         # init quotient
        _CALLJ('__@am40cmpbm32')         # compare dividend and divisor
        _BGE('.fdivcont')                # if dividend>=divisor go to loop
        LD(AE);SUBI(1);ST(AE)            # fix exponent to prepare for extra shift
        _BEQ('.fdivzero')                # possible underflow
        _CALLJ('__@am40shl1')            # now dividend>=divisor
        label('.fdivcont')               # entry point
        _CALLJ('__@fdiv2')               # long jump to next piece

    def code_fdiv2():
        label('.fdivloop')
        _CALLJ('__@cm32shl1')            # shift quotient
        _CALLJ('__@am40shl1')            # shift dividend
        _CALLJ('__@am40cmpbm32')
        _BLE('.fdivloop1')
        label('__@fdiv2')                # entry point from fdiv!
        INC(CM)                          # set low bit of quotient
        _CALLJ('__@am40subbm32')         # subtract divisor from dividend
        label('.fdivloop1')
        LDW(CM+2);_BGE('.fdivloop')
        LDW(CM+2);STW(AM+2)              # quotient is now normalized!
        LDW(CM);STW(AM);
        tryhop(2);POP();RET()

    module(name='rt_fdiv.s',
           code=[ ('EXPORT', '_@_fdiv'),
                  ('CODE', '_@_fdiv', code_fdiv),
                  ('CODE', '_@_fdiv2', code_fdiv2),
                  ('IMPORT', '__@fsavevsp'),
                  ('IMPORT', '__@fexception'),
                  ('IMPORT', '__@clrfac'),
                  ('IMPORT', '__@foverflow'),
                  ('IMPORT', '__@cm32shl1'),
                  ('IMPORT', '__@bm40load'),
                  ('IMPORT', '__@am40shl1'),
                  ('IMPORT', '__@am40cmpbm32'),
                  ('IMPORT', '__@am40subbm32') ] )


    # ==== fmod

    def code_fmod():
        label('_@_fmod')
        PUSH();STW(T3)
        _CALLJ('__@fsavevsp')
        LDW(T3);PEEK();STW(T2);_BNE('.fmod1')
        _CALLJ('__@fexception')          # divisor is zero
        label('.fmod1')
        LD(AE);_BEQ('.ret')              # if 0/x return zero
        SUBW(T2);STW(T2);                # qexp should be in [0,32)
        _BLT('.ret')                     # if qexp < 0 return dividend
        SUBI(32);_BLT('.fmod2')
        _CALLJ('__@clrfac')              # if qexp >=32 return zero
        label('.ret')
        LDI(0);STW(CM)                   # for remquo
        tryhop(2);POP();RET()
        label('.fmod2')
        _CALLJ('__@bm32loadx')           # load mantissa
        ALLOC(-2);LDW(T2);STLW(0)        # save round counter
        LDI(0);STW(CM);STW(CM+2)         # prepare quotient, overwriting T2 T3
        label('.fmodloop')
        _CALLJ('__@am40cmpbm32')         # compare dividend and divisor
        _BLT('.fmodcont')
        INC(CM)                          # set low bit of quotient
        _CALLJ('__@am40subbm32')         # subtract divisor from dividend
        label('.fmodcont')
        LDLW(0)
        _BEQ('.fmoddone')
        SUBI(1);STLW(0)
        _CALLJ('__@cm32shl1')            # shift quotient
        _CALLJ('__@am40shl1')            # shift dividend
        LD(AE);SUBI(1);ST(AE)            # adjust divident exponent
        _BRA('.fmodloop')
        label('.fmoddone')
        ALLOC(2)
        _CALLJ('__@fnorm1')
        tryhop(2);POP();RET()
        
    module(name='rt_fmod.s',
           code=[ ('EXPORT', '_@_fmod'),
                  ('CODE', '_@_fmod', code_fmod),
                  ('IMPORT', '__@fsavevsp'),
                  ('IMPORT', '__@fexception'),
                  ('IMPORT', '__@clrfac'),
                  ('IMPORT', '__@foverflow'),
                  ('IMPORT', '__@bm32loadx'),
                  ('IMPORT', '__@cm32shl1'),
                  ('IMPORT', '__@am40shl1'),
                  ('IMPORT', '__@am40cmpbm32'),
                  ('IMPORT', '__@am40subbm32'),
                  ('IMPORT', '__@fnorm1') ] )
    

    # ==== comparisons

    def code_fcmp():
        label('_@_fcmp')
        PUSH();STW(T3)
        ADDI(1);PEEK();XORW(AS);ANDI(128);_BEQ('.fcmp1')
        label('.plus')
        LD(AS);XORI(128);ANDI(128);PEEK();LSLW();SUBI(1)
        tryhop(2);POP();RET()
        label('.minus')
        LD(AS);ANDI(128);PEEK();LSLW();SUBI(1)
        tryhop(2);POP();RET()
        label('.fcmp1')
        LDW(T3);PEEK();STW(T2)
        LD(AE);SUBW(T2);_BLT('.minus');_BGT('.plus')
        LD(AE);_BEQ('.zero')
        _CALLJ('__@bm32loadx')
        LDW(AM+2);_CMPWU(BM+2);_BLT('.minus');_BGT('.plus')
        LDW(AM);_CMPWU(BM);_BLT('.minus');_BGT('.plus')
        label('.zero')
        LDI(0);tryhop(2);POP();RET()

    module(name='rt_fcmp.s',
           code=[ ('EXPORT', '_@_fcmp'),
                  ('IMPORT', '__@bm32loadx'),
                  ('CODE', '_@_fcmp', code_fcmp) ] )

    def code_fsign():
        '''returns sign of FAC into AC (-1/0/+1)'''
        nohop()
        label('_@_fsign')
        LD(AE);BEQ('.done')
        LD(AS);ANDI(128);BEQ('.plus')
        _LDI(-1);RET()
        label('.plus')
        LDI(1)
        label('.done')
        RET()

    module(name='rt_fsign.s',
           code=[ ('EXPORT', '_@_fsign'),
                  ('CODE', '_@_fsign', code_fsign) ] )

    # ==== misc

    def code_fneg():
        nohop()
        label('_@_fneg')
        LD(AE);BEQ('.ret')
        LD(AS);XORI(0x80);ST(AS)
        label('.ret')
        RET()

    module(name='rt_fneg.s',
           code=[ ('EXPORT', '_@_fneg'),
                  ('CODE', '_@_fneg', code_fneg) ] )

    def code_fscalb():
        nohop()
        label('_@_fscalb')
        PUSH()
        STW(BM);LD(AE);ADDW(BM);BLT('.fscalund')
        ST(AE);LD(vACH);BNE('.fscalovf')
        POP();RET()
        label('.fscalund')
        _CALLJ('__@clrfac');POP();RET()
        label('.fscalovf')
        _CALLJ('__@fsavevsp')
        _CALLJ('__@foverflow');HALT()

    module(name='rt_fscalb.s',
           code=[ ('IMPORT', '__@clrfac'),
                  ('IMPORT', '__@foverflow'),
                  ('IMPORT', '__@fsavevsp'),
                  ('EXPORT', '_@_fscalb'),
                  ('CODE', '_@_fscalb', code_fscalb) ] )
    
    def code_frndz():
        '''Make integer by rounding towards zero'''
        label('_@_frndz')
        PUSH()
        LDW(AM);STW(BM);LDW(AM+2);STW(BM+2)
        LDWI(0xffff);STW(T3);STW(AM);STW(AM+2)
        LD(AE);SUBI(128);_BLE('.zero')
        _CALLI('__@am32shra')
        LDW(T3);XORW(AM);ANDW(BM);STW(AM)
        LDW(T3);XORW(AM+2);ANDW(BM+2);STW(AM+2)
        ORW(AM);_BNE('.done')
        label('.zero')
        _CALLJ('__@clrfac')
        label('.done')
        tryhop(2);POP();RET()

    module(name='rt_frndz.s',
           code=[ ('IMPORT', '__@clrfac'),
                  ('IMPORT', '__@am32shra'),
                  ('EXPORT', '_@_frndz'),
                  ('CODE', '_@_frndz', code_frndz) ] )

# create all the modules
scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
