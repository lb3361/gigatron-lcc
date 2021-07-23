def scope():

    def _INCW(r):
        if args.cpu >= 6:
            INCW(r)
        else:
            LDI(1);ADDW(r);STW(r)

    def code_halfm():
        label('halfm');
        bytes(127,127,255,255,255); # 0.5-eps

    def code_billion():
        label('billion');
        bytes(158,110,107,40,0); # 1e+09

    def code_gcvt():
        framesize = 38
        bufoffset = framesize - 16

        label('gcvt');
        _PROLOGUE(framesize,10,0xfc); # save=R2-7
        LDW(R11);STW(R7);      # R7: ndigits
        LDW(R12);STW(R6);      # R6: buffer
        LDI(9);STW(R5);        # R5: nd
        LDW(R6);STW(R4);       # R4: q
                               # R3: p
                               # R2: exp
        LD(F8);_BNE('.g1')                     # if zero
        LDI(48);DOKE(R4);_BRA('.ret')          # - yes
        label('.g1')
        LDW(F8);_BGE('.g2')                    # if negative
        LD(F8+1);ANDI(0x7f);ST(F8+1)           # | make positive
        LDI(45);POKE(R4);_INCW(R4)             # | output minus sign
        label('.g2')
        _SP(bufoffset);STW(R3);STW(R11)
        _CALLJ('_frexp10')                     # _frexp10(x,buf)
        _LDI('halfm');_FADD()                  #    + halfm -> FAC
        _LDI('billion');_FCMP();_BLT('.g3')    # if FAC >= 1e9
        LDI(10);STW(R5)                        # | nd = 10
        label('.g3')
        LDW(R3);DEEK()
        ADDW(R5);SUBI(1);STW(R2)               # exp += nd - 1
        LDW(R7);_BLE('.g4')                    # if ndigits > 0
        LDW(R7);SUBW(R5);_BGE('.g4')           # and ndigits - nd < 0
        STW(R11);_FMOV(FAC, F8)                # |
        _CALLJ('_ldexp10')                     # | truncate FAC
        _LDI('halfm');_FADD()                  # |  + halfm -> FAC
        LDW(R7);STW(R5)                        # | nd = ndigits
        label('.g4')
        LDI(10);STW(R11)                       # ultoa base
        LDW(R3);STW(R10)                       # ultoa buffer
        _FTOU();_LMOV(LAC,F8)                  # convert to unsigned long
        _CALLJ('ultoa')                        # call ultoa -> p
        STW(R3)
        LDI(4);ADDW(R2);_BLT('.g5')            # if 4+exp >= 0
        LDW(R2);SUBW(R5);_BGE('.g5')           # and exp-nd < 0
        LDI(1);ADDW(R2);STW(R5);               # | nd = 1 + exp
        LDI(0);STW(R2);_BRA('.g7')             # | exp = 0
        label('.g5')                           # else
        LDI(1);STW(R5);_BRA('.g7')             # | nd = 1 (period position now)
        label('.g6')                           # while (nd <= 0)
        LDI(48);POKE(R4);_INCW(R4)             # | *q++ = '0'
        _INCW(R5)                              # | nd++
        label('.g7')
        LDW(R5);_BLE('.g6')
        _BRA('.g10')
        label('.g8')                           # while(*p)
        LDW(R5);_BNE('.g9')                    # | if (nd == 0)
        LDI(46);POKE(R4);_INCW(R4)             # | | *q++ = '.'
        label('.g9')                           # |
        LDW(R3);PEEK();POKE(R4)                # | *q++ = *p++
        _INCW(R3);_INCW(R4)                    # |
        LDW(R5);SUBI(1);STW(R5)                # | nd--
        label('.g10')
        LDW(R3);PEEK();_BNE('.g8')
        label('.g11')
        LDW(R4);SUBI(1);STW(R4);PEEK()         # do { q--;
        XORI(48);_BEQ('.g11')                  # } while (*q == '0')
        XORI(48 ^ 46);_BEQ('.g13')             # if (q != '.')
        _INCW(R4)                              # | q++
        label('.g13')
        LDW(R2);_BEQ('.fin')                   # if (exp)
        LDI(101);POKE(R4);_INCW(R4)            # | *q++ = 'e'
        LDW(R2);_BGE('.g14')                   # | if (exp < 0)
        LDI(0);SUBW(R2);STW(R2)                # | | exp = -exp
        LDI(45);_BRA('.g15')                   # | | vAC = '-'
        label('.g14')                          # | else
        LDI(43)                                # | | vAC = '+'
        label('.g15')
        POKE(R4);_INCW(R4)                     # | *q++ = vAC
        LDW(R2);STW(T3);_MODIU(10);STW(R7)     # | divmod(exp,10)
        LDW(T1);ADDI(48);POKE(R4);_INCW(R4)    # | *q++ = quo + '0'
        LDW(R7);ADDI(48);POKE(R4);_INCW(R4)    # | *q++ = rem + '0'
        label('.fin')
        LDI(0);POKE(R4);
        label('.ret')
        LDW(R6);
        _EPILOGUE(framesize,10,0xfc,saveAC=True);

    module(name='gcvt.s',
           code=[('DATA', 'halfm', code_halfm, 0, 1),
                 ('DATA', 'billion', code_billion, 0, 1),
                 ('EXPORT', 'gcvt'),
                 ('CODE', 'gcvt', code_gcvt),
                 ('IMPORT', 'ultoa'),
                 ('IMPORT', '_frexp10'),
                 ('IMPORT', '_ldexp10') ] )

scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
