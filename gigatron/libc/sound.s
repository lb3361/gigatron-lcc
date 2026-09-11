def scope():

    # ----------------------------------------
    # general stuff

    def code_reset():
        # extern void sound_reset(int wave)
        nohop()
        label('sound_reset')
        _MOVIW(0x1fa,T0)
        LDW(R8-1);ORI(255);XORI(255)
        PUSH();_CALLI('.go');POP()
        label('sound_all_off')
        _MOVIW(0x1fc,T0);LDI(0)
        label('.go')
        DOKE(T0);INC(T0+1)
        DOKE(T0);INC(T0+1)
        DOKE(T0);INC(T0+1)
        DOKE(T0);RET()

    module(name='sound_reset.s',
           code=[('EXPORT','sound_reset'),
                 ('EXPORT','sound_all_off'),
                 ('CODE','sound_reset',code_reset)] )

    def code_defwave():
        nohop()
        label('sound_reset_waveforms')
        _MOVIW('SYS_ResetWaveforms_v4_50','sysFn')
        LDI(0);SYS(50)
        _MOVIW('SYS_ShuffleNoise_v4_46','sysFn')
        LDI(0);SYS(46);SYS(46);SYS(46);SYS(46)
        RET()

    module(name='sound_reset_waveforms.s',
           code=[('EXPORT','sound_reset_waveforms'),
                 ('CODE','sound_reset_waveforms',code_defwave)] )

    def code_sinwave():
        nohop()
        label('sound_sine_waveform')
        LD(R8);ANDI(3);STW(R8)
        LDI(v('soundTable')>>8);ST(R10+1);ST(R11+1)
        LDI(0x1f);STW(R9)
        label('.loop')
        LSLW();LSLW();ORW(R8);ST(R10);ORI(128);ST(R11)
        LD(R9);SUBI(16);_BGE('.x0')
        LDWI('.data');ADDW(R9);_BRA('.x1')
        label('.x0')
        LDWI(v('.data')+31);SUBW(R9)
        label('.x1')
        PEEK();POKE(R10);XORI(63);POKE(R11)
        LD(R9);SUBI(1);ST(R9);_BGE('.loop')
        RET()

    def code_sindata():
        label('.data')
        #  int(32.5+31*math.sin((i+0.5)*math.pi/32)) for i in range(16) ]
        bytes(34, 37, 40, 42, 45, 48, 50, 53,
              55, 57, 59, 60, 61, 62, 63, 63)

    module(name='sound_sinwave.s',
           code=[('EXPORT','sound_sine_waveform'),
                 ('CODE','sound_sine_waveform',code_sinwave),
                 ('DATA','sound_sine_wavedata',code_sindata,16,1)] )

    def code_freq():
        nohop()
        label('sound_freq')
        # The frequency key is obtained by multiplying the frequency
        # in Hz by 4.1943 and converting in 7.7 fixed point encoding.
        # Approximation: key = freq * 0x432 / 256.
        LD(R8);ST(R8+1);_MOVIB(0xfc,R8)
        label('_sound_freq_sub')
        _MOVIW('SYS_LSRW4_50','sysFn')
        LDW(R9);LSLW();STW(T0);LSLW();STW(T1)
        SUBW(R9);SYS(50)
        if args.cpu >= 7:
            ADDV(T1);LD(T0+1);ADDV(T1)
            LDW(T1);ADDV(T1);ANDI(0x7f);ST(T1)
        else:
            ADDW(T1);STW(T1);LD(T0+1);ADDW(T1);
            ST(T0);LSLW();STW(T1);LD(T0);ANDI(0x7f);ST(T1)
        LDW(T1);DOKE(R8);RET()
        RET()

    module(name='sound_freq.s',
           code=[('EXPORT','sound_freq'),
                 ('EXPORT','_sound_freq_sub'),
                 ('CODE','sound_freq',code_freq)] )

    def code_sound_on():
        nohop()
        label('sound_on')
        LD(R8);ST(R8+1);_MOVIB(0xfa,R8)
        LDI(127);SUBW(R10);POKE(R8);INC(R8)
        LD(R11);ANDI(3);POKE(R8);INC(R8)
        if args.cpu >= 6:
            JGE('_sound_freq_sub')
        else:
            PUSH();_CALLJ('_sound_freq_sub');POP();RET()

    module(name='sound_on.s',
           code=[('EXPORT','sound_on'),
                 ('IMPORT','_sound_freq_sub'),
                 ('CODE','sound_on',code_sound_on)] )

    def code_note():
        nohop()
        label('sound_note')
        LD(R8);ST(R8+1);_MOVIB(0xfc,R8)
        label('_sound_note_sub')
        LDWI(v('notesTable')-22);ADDW(R9);ADDW(R9);STW(T0)
        LUP(0);ST(R9);LDW(T0);LUP(1);ST(R9+1)
        LDW(R9);DOKE(R8);RET()

    module(name='sound_note.s',
           code=[('EXPORT','sound_note'),
                 ('EXPORT','_sound_note_sub'),
                 ('CODE','sound_note',code_note)] )

    def code_note_on():
        nohop()
        label('note_on')
        LD(R8);ST(R8+1);_MOVIB(0xfa,R8)
        LDI(127);SUBW(R10);POKE(R8);INC(R8)
        LD(R11);ANDI(3);POKE(R8);INC(R8)
        if args.cpu >= 6:
            JGE('_sound_note_sub')
        else:
            PUSH();_CALLJ('_sound_note_sub');POP();RET()

    module(name='note_on.s',
           code=[('EXPORT','note_on'),
                 ('IMPORT','_sound_note_sub'),
                 ('CODE','note_on',code_note_on)] )

    # ----------------------------------------
    # midi stuff

    if args.cpu < 5:

        def code_midi_play():
            warning('midi_play() cannot work without vIRQ (needs rom>=v5a)', dedup=True)
            nohop()
            label('midi_playing')
            label('midi_play')
            label('midi_chain')
            LDI(0);RET()

        module(name='midi_play.s',
               code=[('EXPORT','midi_play'),
                     ('EXPORT','midi_playing'),
                     ('EXPORT','midi_chain'),
                     ('CODE','midi_play',code_midi_play)] )
    else:

        ctrlBits_v5 = 0x1f8
        cons_128k = 'MAP128K' in args.opts
        cons_512k = 'MAP512K' in args.opts

        def code_midi_ivars():
            label('_midi.p')
            words(0)
            label('_midi.q')
            words(0)

        module(name='midi_ptrs.s',
               code=[('EXPORT','_midi.q'),
                     ('EXPORT','_midi.p'),
                     ('DATA', 'midi_ptrs', code_midi_ivars, 4, 1),
                     ('PLACE','midi_ptrs', 0x0000, 0x00ff)] )

        def code_midi_tvars():
            label('_midi.t')
            space(2)
            label('_midi.tmp')
            space(2)
            label('_midi.cmd')
            space(2)
            if cons_128k or cons_512k:
                label('_midi.sysfn')
                space(2)
                label('_midi.bank')
                space(1)

        def code_midi_note():
            nohop()
            label('.midi_note')
            ADDI(0x10);STW(vLR)
            LDW('_midi.p');PEEK();INC('_midi.p');STW('_midi.cmd')
            LDW(vLR);_BLT('.freq')
            LDI(0xfa);ST('_midi.tmp')
            LDW('_midi.p');PEEK();INC('_midi.p');POKE('_midi.tmp')
            label('.freq')
            LDI(0xfc);ST('_midi.tmp')
            LDWI(v('notesTable')-22);ADDW('_midi.cmd');ADDW('_midi.cmd');STW('_midi.cmd')
            LUP(0);ST(vLR);LDW('_midi.cmd');LUP(1);ST(vLR+1)
            LDW(vLR);DOKE('_midi.tmp');_CALLJ('.getcmd')

        def code_midi_tick():
            nohop()
            label('.midi_tick')
            PUSH()
            # obtain command
            label('.getcmd')
            LDW('_midi.p');PEEK();_BNE('.docmd')
            LDW('_midi.q');DEEK();_BEQ('.fin')
            STW('_midi.p');INC('_midi.q');INC('_midi.q');_BRA('.getcmd')
            # process command
            label('.docmd')
            INC('_midi.p');STW('_midi.cmd')
            ANDI(3);INC(vACL);ST(v('_midi.tmp')+1)
            # delay
            LDW('_midi.cmd');SUBI(0x80);_BGE('.xcmd')
            LD('_midi.cmd')
            label('.dly')
            if args.cpu >= 7:
                ADDV('_midi.t')
            else:
                ADDW('_midi.t');STW('_midi.t')
            POP();RET();
            # note off
            label('.xcmd')
            SUBI(0x10);_BGE('.ncmd')
            LDI(0xfc);ST('_midi.tmp')
            LDI(0);DOKE('_midi.tmp');_BRA('.getcmd')
            # note on
            label('.ncmd')
            SUBI(0x20)
            if args.cpu >= 6:
                JLT('.midi_note')
            else:
                _BGE('.fin');CALLI('.midi_note')
            # end
            label('.fin')
            LDI(0);STW('_midi.q')
            LDI(0x80);_BRA('.dly')


        def midi_set_bank():
            # Ensure the program bank is set while processing irq
            if cons_128k or cons_512k:
                LDW('sysFn');STW('_midi.sysfn')
                LDWI('SYS_ExpanderControl_v4_40');STW('sysFn')
                LDWI(ctrlBits_v5);PEEK();ST('_midi.bank')
                ANDI(0x3c);ORI(0x80 if cons_128k else 0x40);SYS(40)

        def midi_restore_bank():
            # Restore the saved bank after irq
            if cons_128k or cons_512k:
                STW('_midi.tmp')
                LDWI('SYS_ExpanderControl_v4_40');STW('sysFn')
                LD('_midi.bank');SYS(40)
                LDW('_midi.sysfn');STW('sysFn')
                LDW('_midi.tmp')

        def code_midi_irq():
            nohop()
            label('_vIrqAltHandler')
            LDW('_midi.q');_BEQ('.rti0')
            midi_set_bank()
            PUSH()
            LDI(255);ST('soundTimer')
            _BRA('.irq1')
            label('.irq0')
            CALLI('.midi_tick')
            CALLI('_vBlnAvoid')
            label('.irq1')
            LD('frameCount');ADDW('_vIrqTicks');SUBW('_midi.t');_BGE('.irq0')
            label('.irqfin')
            POP()
            midi_restore_bank()
            ST('frameCount')
            LDW('_midi.t');ST('_vIrqTicks')
            XORW('_vIrqTicks');_BNE('.rti0') # return to carry in virqticks
            POP();LDWI(0x400);LUP(0)         # no carry
            label('.rti0')
            RET()

        def code_midi_play():
            nohop()
            label('midi_play')
            PUSH()
            LDI(0);STW('_midi.q');STW('_midi.p')
            CALLI('sound_all_off')
            LDW(R8);BEQ('.play3')
            # arrange speedy start
            CALLI('_vBlnAvoid')
            LD('frameCount');INC(vACL);_BEQ('.play1')
            CALLI('_clock.sub')
            STW('_vIrqTicks')
            LDW(LAC+2);STW(v('_vIrqTicks')+2)
            # set interrupt
            label('.play1')
            LDW(R8);STW('_midi.q')
            LDI(0xff);ST('frameCount')
            # wait for first play
            label('.play2')
            LDW('_midi.p');_BEQ('.play2')
            # done
            label('.play3')
            POP();RET()

        module(name='midi_play.s',
               code=[('EXPORT','midi_play'),
                     ('EXPORT','_vIrqAltHandler'),
                     ('IMPORT','_midi.p'),
                     ('IMPORT','_midi.q'),
                     ('IMPORT','sound_all_off'),
                     ('IMPORT','_vIrqTicks'),
                     ('IMPORT','_vBlnAvoid'),
                     ('IMPORT','_clock.sub'),
                     ('BSS',   'midi_tvars', code_midi_tvars, 6, 1),
                     ('PLACE', 'midi_tvars', 0x0000, 0x00ff),
                     ('CODE',  'midi_note', code_midi_note),
                     ('CODE',  'midi_tick', code_midi_tick),
                     ('CODE',  '_vIrqAltHandler', code_midi_irq),
                     ('PLACE', '_vIrqAltHandler', 0x0200, 0x7fff),
                     ('CODE',  'midi.play', code_midi_play) ] )

        def code_midi_playing():
            nohop()
            label('midi_playing')
            LDW('_midi.q');RET()

        module(name='midi_playing.s',
               code=[('EXPORT','midi_playing'),
                     ('IMPORT','_midi.q'),
                     ('CODE', 'midi_playing', code_midi_playing)] )

        def code_midi_chain():
            nohop()
            label('midi_chain')
            PUSH();CALLI('_vIrqAvoid');POP()
            LDW('_midi.q');_BEQ('.ret0')
            DEEK();_BNE('.ret0')
            LDW(R8);STW('_midi.q')
            RET()
            label('.ret0')
            LDI(0);RET()

        module(name='midi_chain.s',
               code=[('EXPORT','midi_chain'),
                     ('IMPORT','_midi.q'),
                     ('IMPORT','_vIrqAvoid'),
                     ('CODE', 'midi_chain', code_midi_chain)] )


scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:

