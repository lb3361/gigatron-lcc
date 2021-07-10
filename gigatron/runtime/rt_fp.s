


# Floating point routines
# using the Microsoft Floating Point format (5 bytes)
#
#  EEEEEEEE SAAAAAAA BBBBBBBB CCCCCCCC DDDDDDDD
#  =  (-1)^S * 2^(EEEEEEEE-128) * 0.1AAAAAAABBBBBBBBCCCCCCCCDDDDDDDD (base 2)

# The floating point routines operate on a floating point accumulator
# FAC that occupies the same locations [0x81-0x87] as B0,B1,B2 and
# LAC. Register FAC separately stores its sign AS, its exponent AE,
# and a mantissa AM extended to 40 bits.

# These routines also make use of the memory occupied by T0-T3 in
# diverse ways. In particular, the mantissa register BM can be 4 or 5
# bytes long, overlapping T0, T1, and possibly T2L. Therefore, none of
# B0/B1/B2/LAC/T0/T1/T2/T3 should be assumed to be preserved across
# these calls. In addition, some of these calls might use SYS calls in
# the future, meaning that none of the memory locations 'sysFn' and
# 'sysArgs[0-7]' should be assumed preserved.

def scope():

    T2L = T2
    T2H = T2+1
    T3L = T3
    T3H = T3+1

    AS = 0x81     # FAC sign (bit7).
    AE = 0x82     # FAC exponent
    AM = 0x83     # 40 bits FAC mantissa (one extra low byte)
    
    BM = T0       # 40 bits register (high byte overlaps T2L and CM32)
    CM = T2       # 32 bits register (overlaps T2/T3, no fifth byte)
   
    # naming convention for exported symbols
    # '_@_xxxx' are the public api.
    # '__@xxxx' are private.

    # How do we resolve rounding ties (do not change)
    RoundingTies = 'to-inf'

    # Whether we round the result of all operations (do not change)
    RoundResults = True
    
    # ==== common things

    def code_fexception():
        nohop()
        label('__@fexception')   ### SIGFPE/exception
        LDWI(0x304);_BRA('.raise')
        label('__@foverflow')    ### SIGFPE/overflow
        LDWI(0x204);
        label('.raise')
        STLW(-2);_LDI(0xffff);STW(AM+1);STW(AM+3);ST(AE);LDI(0);ST(AM)
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
        '''Clear FAC'''
        nohop()
        label('_@_clrfac')
        LDI(0);ST(AS);STW(AE) # [AS] [AE,AM]
        STW(AM+1);STW(AM+3)   # [AM+1,AM+2] [AM+3,AM+4]
        RET()
        
    module(name='rt_clrfac.s',
           code=[ ('EXPORT', '_@_clrfac'),
                  ('CODE', '_@_clrfac', code_clrfac) ] )

    def code_rndfac():
        '''Round FAC to 32 bit mantissa'''
        nohop()
        label('_@_rndfac')
        LD(AM);_BEQ('.ret')
        if RoundingTies == 'to-inf':
            ANDI(128);_BEQ('.rnd0')
        else:
            XORI(128)
            if RoundingTies == 'to-zero':
                _BEQ('.rnd0')
            else:
                _BNE('.rnd2')
                LD(AM+1);ANDI(1)
                if RoundingTies == 'to-even':
                    _BEQ('.rnd0');_BRA('.rnd1')
                elif RoundingTies == 'to-odd':
                    _BNE('.rnd0');_BRA('.rnd1')
            label('.rnd2')
            ANDI(128);_BNE('.rnd0')
        label('.rnd1')
        LDI(1);ADDW(AM+1);STW(AM+1);_BNE('.rnd0')
        LDI(1);ADDW(AM+3);STW(AM+3);_BNE('.rnd0')
        LDI(128);ST(AM+4);INC(AE);LD(AE);_BNE('.rnd0')
        # overflow during rounding: just revert.
        _LDI(0xffff);STW(AM+1);STW(AM+3);ST(AE)
        label('.rnd0')
        LD(0);ST(AM)
        label('.ret')
        RET()

    module(name='rt_rndfac.s',
           code=[ ('EXPORT', '_@_rndfac'),
                  ('CODE', '_@_rndfac', code_rndfac) ] )

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

    # ==== Load/store

    def load_mantissa(ptr, mantissa):
        '''Load mantissa of float [ptr] into [mantissa,mantissa+3].
           Returns high mantissa byte with sign bit.'''
        if args.cpu <= 5:
            LDI(4);ADDW(ptr);PEEK();ST(mantissa)
            LDI(2);ADDW(ptr);PEEK();ST(mantissa+2)
            LDI(3);ADDW(ptr);PEEK();ST(mantissa+1)
            LDI(1);ADDW(ptr);PEEK();ST(vACH)
            ORI(0x80);ST(mantissa+3);LD(vACH)
        else:
            LDW(ptr);INCW(vAC);
            PEEKAp(mantissa+3)
            PEEKAp(mantissa+2)
            PEEKAp(mantissa+1)
            PEEKA(mantissa)
            LD(mantissa+3)
            ORBI(0x80, mantissa+3)

    def code_fldfac():
        '''[vAC]->FAC'''
        nohop()
        label('_@_fldfac')
        STW(T3);PEEK();ST(AE);_BEQ('.zero')
        load_mantissa(T3,AM+1)
        ANDI(128);ST(AS)
        LDI(0);ST(AM)
        RET()
        label('.zero')
        PUSH();_CALLJ('_@_clrfac');POP()
        RET()

    module(name='rt_fldfac.s',
           code=[ ('EXPORT', '_@_fldfac'),
                  ('IMPORT', '_@_clrfac'),
                  ('CODE', '_@_fldfac', code_fldfac) ] )

    def code_am40load():
        '''[T3] mantissa -> AM40'''
        nohop()
        label('__@am40load')
        LD(0);ST(AM)
        _PEEKV(T3);BEQ('.zero')
        load_mantissa(T3,AM+1)
        ANDI(128);RET()
        label('.zero')
        ST(AM);STW(AM+1);STW(AM+2);RET()

    module(name='rt_am40load.s',
           code=[ ('EXPORT', '__@am40load'),
                  ('CODE', '__@am40load', code_am40load) ] )

    def code_bm40load():
        '''[T3] mantissa -> BM40 [aka T0/T1/T2L]'''
        nohop()
        label('__@bm40load')
        LD(0);ST(BM)
        _PEEKV(T3);BEQ('.zero')
        load_mantissa(T3,BM+1)
        ANDI(128);RET()
        label('.zero')
        STW(BM+1);STW(BM+2);RET()

    module(name='rt_bm40load.s',
           code=[ ('EXPORT', '__@bm40load'),
                  ('CODE', '__@bm40load', code_bm40load) ] )

    def code_bm32load():
        '''[T3] mantissa -> BM32 [aka T0/T1]'''
        nohop()
        label('__@bm32load')
        _PEEKV(T3);BEQ('.zero')
        load_mantissa(T3,BM)
        ANDI(128);RET()
        label('.zero')
        STW(BM);STW(BM+2);RET()

    module(name='rt_bm32load.s',
           code=[ ('EXPORT', '__@bm32load'),
                  ('CODE', '__@bm32load', code_bm32load) ] )

    def code_fstfac():
        nohop()
        '''FAC->[vAC]'''
        label('_@_fstfac')
        PUSH();STW(T2)
        LD(AE);POKE(T2);_BNE('.fst1')
        _CALLJ('_@_clrfac')
        label('.fst1')
        _CALLJ('_@_rndfac')
        LD(T2);SUBI(0xfc);_BGE('.fst3')
        # no page crossings
        INC(T2)
        if args.cpu <= 5:
            LD(AS);ORI(0x7f);ANDW(AM+4);POKE(T2);INC(T2)
            LD(AM+3);POKE(T2);INC(T2)
            LD(AM+2);POKE(T2);INC(T2)
        else:
            LD(AS);ORI(0x7f);ANDW(AM+4);POKEp(T2)
            LD(AM+3);POKEp(T2)
            LD(AM+2);POKEp(T2)
        label('.fst2');
        LD(AM+1);POKE(T2)
        tryhop(2);POP();RET()
        # possible page crossings
        label('.fst3')
        if args.cpu <= 5:
            LDI(1);ADDW(T2);STW(T2)
            LD(AS);ORI(0x7f);ANDW(AM+4);POKE(T2);LDI(1);ADDW(T2);STW(T2)
            LD(AM+3);POKE(T2);LDI(1);ADDW(T2);STW(T2)
            LD(AM+2);POKE(T2);LDI(1);ADDW(T2);STW(T2)
            BRA('.fst2')
        else:
            INCW(T2)
            LD(AS);ORI(0x7f);ANDW(AM+4);POKE(T2);INCW(T2)
            LD(AM+3);POKE(T2);INCW(T2);
            LD(AM+2);POKE(T2);INCW(T2)
            BRA('.fst2')

    module(name='rt_fstfac.s',
           code=[ ('EXPORT', '_@_fstfac'),
                  ('IMPORT', '_@_rndfac'),
                  ('CODE', '_@_fstfac', code_fstfac) ] )


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

    def code_am40shl1():
        nohop()
        label('__@am40shl1')
        macro_shl1(AM, ext=True, ret=True)

    def code_am40shl4():  # AM40 <<= 4
        nohop()
        label('__@am40shl4')
        macro_shl4(AM, ext=True)
        RET()

    def code_am40shl8():  # AM40 <<=8
        nohop()
        label('__@am40shl8')
        macro_shl8(AM, ext=True)
        RET()

    def code_am40shl16(): # AM40 <<= 16
        nohop()
        label('__@am40shl16')
        macro_shl16(AM, ext=True)
        RET()

    module(name='rt_fshl.s',
           code=[ ('EXPORT', '__@am40shl1'),
                  ('EXPORT', '__@am40shl4'),
                  ('EXPORT', '__@am40shl8'),
                  ('EXPORT', '__@am40shl16'),
                  ('CODE', '__@am40shl1', code_am40shl1),
                  ('CODE', '__@am40shl4', code_am40shl4),
                  ('CODE', '__@am40shl8', code_am40shl8),
                  ('CODE', '__@am40shl16', code_am40shl16) ] )

    def code_bm40shl1():
        nohop()
        label('__@bm40shl1')
        macro_shl1(BM, ext=True, ret=True)

    module(name='rt_bm40shl1.s',
           code=[ ('EXPORT', '__@bm40shl1'),
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

    def code_am40shr16():
        nohop()
        label('__@am40shr16')
        macro_shr16(AM, ext=True)
        RET()

    def code_am40shr8():
        nohop()
        label('__@am40shr8')
        macro_shr8(AM, ext=True)
        RET()

    def code_am40shra():
        '''shift am40 right by vAC positions'''
        label('__@am40shra')
        PUSH();ALLOC(-2);STLW(0)
        ANDI(0xe0);_BEQ('.shra16')
        LD(AM+4);ST(AM)
        LDI(0);STW(AM+1);STW(AM+3)
        LDLW(0);ANDI(0xc0);_BEQ('.shra16')
        LDI(0);ST(AM);_BRA('.shraret')
        label('.shra16')
        LDLW(0);ANDI(16);_BEQ('.shra8')
        _CALLJ('__@am40shr16')
        label('.shra8')
        LDLW(0);ANDI(8);_BEQ('.shra1to7')
        _CALLJ('__@am40shr8')
        label('.shra1to7')
        LDLW(0);ANDI(7);_BEQ('.shraret')
        _CALLI('__@shrsysfn')
        LDW(AM);SYS(52);ST(AM)
        LDW(AM+1);SYS(52);ST(AM+1)
        LDW(AM+2);SYS(52);ST(AM+2)
        LDW(AM+3);SYS(52);STW(AM+3)
        label('.shraret')
        tryhop(2);ALLOC(2);POP();RET()

    module(name='rt_fshr.s',
           code=[ ('EXPORT', '__@am40shra'),
                  ('IMPORT', '__@shrsysfn'),
                  ('EXPORT', '__@am40shr16'),
                  ('EXPORT', '__@am40shr8'),
                  ('CODE', '__@am40shr16', code_am40shr16),
                  ('CODE', '__@am40shr8', code_am40shr8),
                  ('CODE', '__@am40shra', code_am40shra) ]  )

    def code_bm40shr8():
        nohop()
        label('__@bm40shr8')
        macro_shr8(BM, ext=True)
        RET()

    module(name='rt_bm40shr8.s',
           code=[ ('EXPORT', '__@bm40shr8'),
                  ('CODE', '__@bm40shr8', code_bm40shr8) ]  )

    def code_bm40shr2():
        nohop()
        label('__@bm40shr2')
        LDWI('SYS_LSRW2_52')
        STW('sysFn')
        LDW(BM);SYS(52);ST(BM)
        LDW(BM+1);SYS(52);ST(BM+1)
        LDW(BM+2);SYS(52);ST(BM+2)
        LDW(BM+3);SYS(52);STW(BM+3)
        RET()

    module(name='rt_bm40shr2.s',
           code=[ ('EXPORT', '__@bm40shr2'),
                  ('CODE', '__@bm40shr2', code_bm40shr2) ]  )


    # ==== two complement

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

    module(name='rt_am40neg.s',
           code=[ ('EXPORT', '__@am40neg'),
                  ('CODE', '__@am40neg', code_am40neg) ])


    # ==== normalization

    def code_fnorm():
        label('__@fnorm')
        PUSH()
        label('.norm1a')
        LDW(AM+3);_BNE('.norm1b')
        LD(AE);SUBI(16);_BLT('.norm1b');ST(AE)
        _CALLJ('__@am40shl16')
        LDW(AM+3);_BNE('.norm1b')
        LDW(AM+1);_BNE('.norm1a')
        ST(AE);_BRA('.done')
        label('.norm1b')
        LD(AM+4);_BNE('.norm1c')
        LD(AE);SUBI(8);_BLT('.norm1c');ST(AE)
        _CALLJ('__@am40shl8')
        label('.norm1c')
        LD(AM+4);ANDI(0xf0);_BNE('.norm1d')
        LD(AE);SUBI(4);_BLT('.norm1d');ST(AE)
        _CALLJ('__@am40shl4')
        label('.norm1d')
        LDW(AM+3);_BLT('.done')
        LD(AE);SUBI(1);_BLT('.done');ST(AE)
        _CALLJ('__@am40shl1');_BRA('.norm1d')
        label('.done')
        tryhop(2);POP();RET()

    def code_fnorm2():
        '''Multiply by four and normalize at the same time'''
        label('__@fnorm2')
        PUSH()
        _CALLJ('__@fnorm')
        LD(AE);_BNE('.frenorm1')
        LDI(2);ST(AE);_CALLJ('.norm1d')
        label('.frenorm1')
        ADDI(2);ST(AE);LD(vACH);_BEQ('.frenorm2')
        _CALLJ('__@foverflow')
        label('.frenorm2')
        tryhop(2);POP();RET()

    module(name='rt_fnorm.s',
           code=[ ('EXPORT', '__@fnorm'),
                  ('EXPORT', '__@fnorm2'),
                  ('IMPORT', '__@am40shl16'),
                  ('IMPORT', '__@am40shl8'),
                  ('IMPORT', '__@am40shl4'),
                  ('IMPORT', '__@am40shl1'),
                  ('IMPORT', '__@foverflow'),
                  ('CODE', '__@fnorm', code_fnorm),
                  ('CODE', '__@fnorm2', code_fnorm2) ] )


    # ==== conversions

    def code_fcv():
        label('_@_fcvu')
        PUSH()
        LDI(0);ST(AM);ST(AS);_BRA('.fcv1')
        label('_@_fcvi')
        PUSH()
        LDI(0);ST(AM)
        LD(AM+4);ANDI(128);STW(AS);_BEQ('.fcv1')
        _CALLJ('__@am40neg')
        label('.fcv1')
        LDI(160);ST(AE)
        _CALLJ('__@fnorm')
        tryhop(2);POP();RET()

    module(name='rt_fcv.s',
           code=[ ('EXPORT', '_@_fcvi'),
                  ('EXPORT', '_@_fcvu'),
                  ('IMPORT', '__@fnorm'),
                  ('IMPORT', '__@am40neg'),
                  ('CODE', '_@_fcvi', code_fcv) ] )

    def code_ftoi():
        label('_@_ftoi')
        PUSH()
        LD(AE);SUBI(160);_BLT('.ok')
        label('.ovf')
        _CALLJ('_@_clrfac')
        LDI(128);ST(LAC+3)
        tryhop(2);POP();RET()
        label('_@_ftou')
        PUSH()
        LD(AS);ANDI(128);BNE('.ovf')
        LD(AE);SUBI(160);_BGT('.ovf')
        label('.ok')
        XORI(255);ANDI(255);INC(vAC)
        _CALLI('__@am40shra')
        LD(AS);ANDI(128);BEQ('.ret')
        _LNEG()
        label('.ret')
        tryhop(2);POP();RET()
        
    module(name='rt_fto.s',
           code=[ ('EXPORT', '_@_ftoi'),
                  ('EXPORT', '_@_ftou'),
                  ('IMPORT', '__@am40shra'),
                  ('IMPORT', '_@_clrfac'),
                  ('CODE', '_@_ftoi', code_ftoi) ] )

    # ==== additions and subtractions

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
            LD(BM);ADDBA(AM);ST(AM);LD(vACH)
            ADDBA(BM+1);ADDBA(AM+1);ST(AM+1);LD(vACH)
            ADDBA(BM+2);ADDBA(AM+2);ST(AM+2);LD(vACH)
            ADDBA(BM+3);ADDBA(AM+3);ST(AM+3);LD(vACH)
            ADDBA(BM+4);ADDBA(AM+4);ST(AM+4)
        RET()

    module(name='rt_am40addbm40.s',
           code=[ ('EXPORT', '__@am40addbm40'),
                  ('CODE', '__@am40addbm40', code_am40addbm40) ])

    def code_am40tobm40():
        nohop()
        label('__@am40tobm40')
        LD(AM);ST(BM)
        LDW(AM+1);STW(BM+1)
        LDW(AM+3);STW(BM+3)
        RET()

    module(name='rt_am40tobm40.s',
           code=[ ('EXPORT', '__@am40tobm40'),
                  ('CODE', '__@am40tobm40', code_am40tobm40) ])

    def code_fadd_t3():
        label('__@fadd_t3')
        PUSH();_PEEKV(T3);STW(T2);_BEQ('.faddx5')
        LD(AE);SUBW(T2);_BGT('.faddx1')
        XORI(255);INC(vAC);ST(T2H)     # FAC exponent <= arg exponent
        LD(T2L);ST(AE)                 # - assume arg exponent
        _CALLJ('__@bm40load')          # - load arg mantissa
        XORW(AS);ST(T3L)               # - T3L bit 7 set for opposite signs
        XORW(AS);ANDI(128);ST(AS)      # - assume arg sign
        _BRA('.faddx2')
        label('.faddx1')               # FAC exponent > arg exponent
        ST(T2H)
        _CALLJ('__@am40tobm40')        # - move FAC mantissa into bm
        _CALLJ('__@am40load')          # - load arg mantissa into am
        XORW(AS);ST(T3L)               # - T3L bit 7 set for opposite signs
        label('.faddx2')
        LD(T2H);ADDI(2)
        _CALLI('__@am40shra')          # - align AM (shift two extra bits)
        LD(T3L);ANDI(128)              # - zero if same sign, nonzero otherwise
        _BEQ('.faddx3')
        _CALLJ('__@am40neg')           # - negate am40 if different signs
        label('.faddx3')
        _CALLJ('__@bm40shr2')          # - shift BM two extra bits
        _CALLJ('__@am40addbm40')       # - add
        LDW(AM+3);_BGE('.faddx4')      # - test sign
        _CALLJ('__@am40neg')
        LD(AS);XORI(128);ST(AS)
        label('.faddx4')
        _CALLJ('__@fnorm2')
        label('.faddx5')
        tryhop(2);POP();RET()

    module(name='rt_faddt3.s',
           code=[ ('EXPORT', '__@fadd_t3'),
                  ('IMPORT', '__@am40shra'),
                  ('IMPORT', '__@bm40shr2'),
                  ('IMPORT', '__@am40neg'),
                  ('IMPORT', '__@am40tobm40'),
                  ('IMPORT', '__@am40addbm40'),
                  ('IMPORT', '__@fnorm2'),
                  ('IMPORT', '__@am40load'),
                  ('IMPORT', '__@bm40load'),
                  ('CODE', '__@fadd_t3', code_fadd_t3) ] )

    def code_fadd():
        label('_@_fadd')
        PUSH();STW(T3)
        _CALLJ('__@fsavevsp')
        _CALLJ('__@fadd_t3')
        if RoundResults:
            _CALLJ('_@_rndfac')
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
        if RoundResults:
            _CALLJ('_@_rndfac')
        tryhop(2);POP();RET()

    module(name='rt_fsub.s',
           code=[ ('EXPORT', '_@_fsub'),
                  ('CODE', '_@_fsub', code_fsub),
                  ('IMPORT', '__@fsavevsp'),
                  ('IMPORT', '_@_fneg'),
                  ('IMPORT', '__@fadd_t3') ] )


    # ==== multiplication by 10

    def code_fmul10():
        '''Multiplies FAC by 10 with 40 bit mantissa precision'''
        label('_@_fmul10')
        PUSH()
        _CALLJ('__@fsavevsp')
        LD(AE);ADDI(3);ST(AE);LD(vACH);_BEQ('.mul10')
        _CALLJ('__@foverflow')
        label('.mul10')
        _CALLJ('__@am40tobm40')
        _CALLJ('__@bm40shr2')
        LDI(4);
        _CALLI('__@am40shra')
        _CALLJ('__@am40addbm40')
        _CALLJ('__@fnorm2')
        tryhop(2);POP();RET()
        
    module(name='rt_fmul10.s',
           code=[ ('EXPORT', '_@_fmul10'),
                  ('IMPORT', '__@am40shra'),
                  ('IMPORT', '__@bm40shr2'),
                  ('IMPORT', '__@am40tobm40'),
                  ('IMPORT', '__@am40addbm40'),
                  ('IMPORT', '__@foverflow'),
                  ('IMPORT', '__@fnorm2'),
                  ('CODE', '_@_fmul10', code_fmul10) ] )


    # ==== multiplication

    def code_macbm32x8():
        '''macbm32x8: Set BM high byte to zero then adds BM x T2H to AM40.'''
        '''smacbm32x8: Same but do AM>>=8 first.'''
        nohop()
        label('__@smacbm32x8')
        PUSH()
        _CALLJ('__@am40shr8')
        _BRA('.prep')
        label('__@macbm32x8')
        PUSH()
        label('.prep')
        ALLOC(-2)
        LDI(0);ST(BM+4)
        LDI(1)
        label('.loop')
        STLW(0);ANDW(T2H);BEQ('.skip')
        _CALLJ('__@am40addbm40')
        label('.skip')
        _CALLJ('__@bm40shl1')
        LDLW(0);LSLW();LD(vAC);_BNE('.loop')
        _CALLJ('__@bm40shr8')   # restore BM
        ALLOC(2);POP();RET()

    def code_fmulmac():
           label('__@fmulmac')
           PUSH()
           LDW(AM+1);STW(BM);LDW(AM+3);STW(BM+2)
           LDI(0);ST(AM);STW(AM+1);STW(AM+3)
           LDI(4);ADDW(T3);PEEK();ST(T2H);_CALLJ('__@macbm32x8')
           LDI(3);ADDW(T3);PEEK();ST(T2H);_CALLJ('__@smacbm32x8')
           LDI(2);ADDW(T3);PEEK();ST(T2H);_CALLJ('__@smacbm32x8')
           LDI(1);ADDW(T3);PEEK();ORI(128);ST(T2H);_CALLJ('__@smacbm32x8')
           tryhop(2);POP();RET()

    module(name='rt_fmulmac.s',
           code=[ ('EXPORT', '__@fmulmac'),
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
           _CALLJ('_@_rndfac')
           LDI(1);ADDW(T3);PEEK();ANDI(128);XORW(AS);ST(AS) # sign 
           _PEEKV(T3);_BEQ('.zero');SUBI(130);STW(T2);      # exponent (two units below for fnorm2)
           LD(AE);_BEQ('.zero');ADDW(T2);ST(AE);_BGT('.fmul1')
           ADDI(2);ST(AE);_BLE('.zero')                     # underflow?
           _CALLJ('__@fmulmac')                             # avoid fnorm2 for small products
           _CALLJ('__@fnorm')
           _BRA('.fmul3')
           label('.fmul1')
           LD(vACH);_BEQ('.fmul2')                          # overflow?
           _CALLJ('__@foverflow')
           label('.fmul2')
           _CALLJ('__@fmulmac')                             # general case
           _CALLJ('__@fnorm2')
           label('.fmul3')
           if RoundResults:
               _CALLJ('_@_rndfac')
           label('.fmul4')
           tryhop(2);POP();RET()
           label('.zero')
           _CALLJ('_@_clrfac')
           tryhop(2);POP();RET()
    
    module(name='_@_fmul',
           code=[ ('EXPORT', '_@_fmul'),
                  ('IMPORT', '__@fsavevsp'),
                  ('IMPORT', '_@_clrfac'),
                  ('IMPORT', '_@_rndfac'),
                  ('IMPORT', '__@foverflow'),
                  ('IMPORT', '__@fmulmac'),
                  ('IMPORT', '__@fnorm'),
                  ('IMPORT', '__@fnorm2'),
                  ('CODE', '_@_fmul', code_fmul) ] )


    # ==== division

    def code_am40cmpbm32():
        # bm40 high byte is assumed zero but never accessed
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
        # bm40 high byte is assumed zero but never accessed
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
            LD(AM);SUBBA(BM);ST(AM);LD(vACH);ST(vACH)
            ADDBA(AM+1);SUBBA(BM+1);ST(AM+1);LD(vACH);ST(vACH)
            ADDBA(AM+2);SUBBA(BM+2);ST(AM+2);LD(vACH);ST(vACH)
            ADDW(AM+3);SUBBA(BM+3);STW(AM+3)
        RET()
        
    module(name='rt_am40subbm32.s',
           code=[ ('EXPORT', '__@am40subbm32'),
                  ('CODE', '__@am40subbm32', code_am40subbm32) ] )

    def code_fdiv():
        label('_@_fdiv')
        PUSH();STW(T3)
        _CALLJ('__@fsavevsp')
        _CALLJ('_@_rndfac')
        _PEEKV(T3);_BNE('.fdiv1')
        _CALLJ('__@fexception')          # divisor is zero
        label('.fdiv1')
        SUBI(129);STW(T2);
        LDI(1);ADDW(T3);PEEK();ANDI(128)
        XORW(AS);ST(AS)                  # set the sign
        LD(AE);_BEQ('.fdivzero')
        SUBW(T2);ST(AE);_BGT('.fdiv2')   # set the exponent
        label('.fdivzero')
        _CALLJ('_@_clrfac')              # result is zero
        tryhop(2);POP();RET()
        label('.fdiv2')
        LD(vACH);_BEQ('.fdiv3')
        _CALLJ('__@foverflow')           # result is too large
        label('.fdiv3')
        _CALLJ('__@am40shr8')            # working with the low 32 bits of AM
        _CALLJ('__@bm32load')            # load divisor
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
        _BLT('.fdivloop1')
        label('__@fdiv2')                # entry point from fdiv!
        INC(CM)                          # set low bit of quotient
        _CALLJ('__@am40subbm32')         # subtract divisor from dividend
        label('.fdivloop1')
        LDW(CM+2);_BGE('.fdivloop')
        STW(AM+3)                        # quotient is now normalized!
        LDW(CM);STW(AM+1);
        LDI(0);ST(AM);                   # and 32 bits only
        tryhop(2);POP();RET()

    module(name='rt_fdiv.s',
           code=[ ('EXPORT', '_@_fdiv'),
                  ('CODE', '_@_fdiv', code_fdiv),
                  ('CODE', '__@fdiv2', code_fdiv2),
                  ('IMPORT', '__@fsavevsp'),
                  ('IMPORT', '__@fexception'),
                  ('IMPORT', '_@_clrfac'),
                  ('IMPORT', '_@_rndfac'),
                  ('IMPORT', '__@foverflow'),
                  ('IMPORT', '__@cm32shl1'),
                  ('IMPORT', '__@bm32load'),
                  ('IMPORT', '__@am40shr8'),
                  ('IMPORT', '__@am40shl1'),
                  ('IMPORT', '__@am40cmpbm32'),
                  ('IMPORT', '__@am40subbm32') ] )


    # ==== fmod

    def code_fmod():
        label('_@_fmod')
        PUSH();STW(T3)
        _CALLJ('__@fsavevsp')
        _CALLJ('_@_rndfac')
        _PEEKV(T3);STW(T2);_BNE('.fmod1')
        _CALLJ('__@fexception')          # divisor is zero
        label('.fmod1')
        LD(AE);_BEQ('.ret')              # if 0/x return zero
        SUBW(T2);STW(T2);                # qexp should be in [0,32)
        _BLT('.ret')                     # if qexp < 0 return dividend
        SUBI(32);_BLT('.fmod2')
        _CALLJ('_@_clrfac')              # if qexp >=32 return zero
        label('.ret')
        LDI(0);STW(CM)                   # for remquo
        tryhop(2);POP();RET()
        label('.fmod2')
        _CALLJ('__@bm32load')            # load mantissa
        ALLOC(-2);LDW(T2);STLW(0)        # save round counter
        LDI(0);STW(CM);STW(CM+2)         # prepare quotient, overwriting T2 T3
        _CALLJ('__@am40shr8')            # working with the low 32 bits of AM
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
        _CALLJ('__@am40shl8')            # reposition remainder
        ALLOC(2)
        _CALLJ('__@fnorm')
        tryhop(2);POP();RET()
        
    module(name='rt_fmod.s',
           code=[ ('EXPORT', '_@_fmod'),
                  ('CODE', '_@_fmod', code_fmod),
                  ('IMPORT', '__@fsavevsp'),
                  ('IMPORT', '__@fexception'),
                  ('IMPORT', '_@_clrfac'),
                  ('IMPORT', '__@foverflow'),
                  ('IMPORT', '__@bm32load'),
                  ('IMPORT', '__@cm32shl1'),
                  ('IMPORT', '__@am40shl1'),
                  ('IMPORT', '__@am40shl8'),
                  ('IMPORT', '__@am40shr8'),
                  ('IMPORT', '__@am40cmpbm32'),
                  ('IMPORT', '__@am40subbm32'),
                  ('IMPORT', '__@fnorm') ] )
    

    # ==== comparisons

    def code_fcmp():
        label('_@_fcmp')
        PUSH();STW(T3)
        _CALLJ('_@_rndfac')
        LD(AE);_BNE('.nonzero');ST(AS);label('.nonzero')
        LDW(T3);ADDI(1);PEEK();XORW(AS);ANDI(128);_BEQ('.fcmp1')
        label('.plus')
        LD(AS);XORI(128);ANDI(128);PEEK();LSLW();SUBI(1)
        tryhop(2);POP();RET()
        label('.minus')
        LD(AS);ANDI(128);PEEK();LSLW();SUBI(1)
        tryhop(2);POP();RET()
        label('.fcmp1')
        _PEEKV(T3);STW(T2)
        LD(AE);SUBW(T2);_BLT('.minus');_BGT('.plus')
        _CALLJ('__@bm40load')
        LDW(AM+3);_CMPWU(BM+3);_BLT('.minus');_BGT('.plus')
        LDW(AM+1);_CMPWU(BM+1);_BLT('.minus');_BGT('.plus')
        label('.zero')
        LDI(0);tryhop(2);POP();RET()

    module(name='rt_fcmp.s',
           code=[ ('EXPORT', '_@_fcmp'),
                  ('IMPORT', '_@_rndfac'),
                  ('IMPORT', '__@bm32load'),
                  ('CODE', '_@_fcmp', code_fcmp) ] )

    def code_fsign():
        '''returns sign of FAC into AC (-1/0/+1)'''
        nohop()
        label('_@_fsign')
        PUSH()
        _CALLJ('_@_rndfac')
        LD(AE);_BEQ('.done')
        LD(AS);ANDI(128);_BEQ('.plus')
        _LDI(-1);RET()
        label('.plus')
        LDI(1)
        label('.done')
        tryhop(2);RET()

    module(name='rt_fsign.s',
           code=[ ('EXPORT', '_@_fsign'),
                  ('IMPORT', '_@_rndfac'),
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
        _CALLJ('_@_clrfac');POP();RET()
        label('.fscalovf')
        _CALLJ('__@fsavevsp')
        _CALLJ('__@foverflow')

    module(name='rt_fscalb.s',
           code=[ ('IMPORT', '_@_clrfac'),
                  ('IMPORT', '__@foverflow'),
                  ('IMPORT', '__@fsavevsp'),
                  ('EXPORT', '_@_fscalb'),
                  ('CODE', '_@_fscalb', code_fscalb) ] )

    def code_fmask():
        label('__@fmask')
        PUSH();
        _CALLJ('__@am40tobm40')
        LDWI(0xffff);STW(T3);ST(AM);STW(AM+1);STW(AM+3)
        LD(AE);SUBI(128);_BLE('.fmask1')
        _CALLI('__@am40shra')
        label('.fmask1')
        tryhop(2);POP();RET()

    module(name='rt_fmask.s',
           code=[ ('IMPORT', '__@am40shra'),
                  ('IMPORT', '__@am40tobm40'),
                  ('EXPORT', '__@fmask'),
                  ('CODE', '__@fmask', code_fmask) ] )

    def code_frndz():
        '''Make integer by rounding towards zero'''
        label('_@_frndz')
        PUSH()
        _CALLJ('__@fmask')
        LDW(T3);XORW(AM);ANDW(BM);ST(AM)
        LDW(T3);XORW(AM+1);ANDW(BM+1);STW(AM+1)
        LDW(T3);XORW(AM+3);ANDW(BM+3);STW(AM+3)
        _BNE('.frndz1')
        LDI(0);ST(AS);ST(AE)
        label('.frndz1')
        tryhop(2);POP();RET()

    module(name='rt_frndz.s',
           code=[ ('IMPORT', '__@fmask'),
                  ('EXPORT', '_@_frndz'),
                  ('CODE', '_@_frndz', code_frndz) ] )

    def code_ffrac():
        '''Extract fractional part.
           Leave unsigned integer part in vAC (if it fits).'''
        label('_@_ffrac')
        PUSH()
        _CALLJ('__@fmask')
        LDW(BM);ANDW(AM);ST(AM)
        LDW(BM+1);ANDW(AM+1);STW(AM+1)
        LDW(BM+3);STW(T3);ANDW(AM+3);STW(AM+3)
        LD(AE);SUBI(145);XORI(255);ST(T2)
        _CALLJ('__@fnorm')
        _CALLJ('__@shru_t2')
        tryhop(2);POP();RET()

    module(name='rt_ffrac.s',
           code=[ ('IMPORT', '__@fmask'),
                  ('IMPORT', '__@fnorm'),
                  ('IMPORT', '__@shru_t2'),
                  ('EXPORT', '_@_ffrac'),
                  ('CODE', '_@_ffrac', code_ffrac) ] )

# create all the modules
scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
