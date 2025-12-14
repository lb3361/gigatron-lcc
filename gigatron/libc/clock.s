def scope():

    def code_wait():
        nohop()
        # Following at67: 179 is normally the start of vBlank, but if
        # a vBlank routine is executing there is a very good chance by
        # the time the vBlank routine is over giga_videoY will have
        # progressed past 179, (by how much is nondeterministic). So
        # instead we wait for the scanline before vBlank, i.e. when
        # videoY = 0xEE, (videoTablePtr = 0x01EE)
        label('.w1')
        LD('videoY');XORI(0xee);_BEQ('.w1')
        label('_wait')
        LD('videoY');XORI(0xee);_BNE('_wait')
        LDW(R8);SUBI(1);STW(R8);BGT('.w1')
        RET();

    module(name='_wait.s',
           code=[ ('EXPORT', '_wait'),
                  ('CODE', '_wait', code_wait) ] )
    

    if 'has_vIRQ' in rominfo:

        # Clock code only makes sense when the rom supports vIrq.
        #
        # Variable '_vIrqTicks' contains the number of ticks between
        # the start of the program and the next vIrq. The value returned
        # by function clock() is adjusted according to the current
        # value of 'frameCount'. This provide means to use the same
        # logic with alternative handlers that schedule interrupts
        # with different intervals.
        #
        # The vIrq handler itself calls '_vIrqAltHandler' if defined.
        # Otherwise it simply adjusts '_vIrqTicks' to reflect the
        # following vIrq in 256 frames (about 4 seconds)

        def code_vars():
            '''zero page variables'''
            label('_vIrqTicks')
            words(0x100,0)

        def code_handler():
            nohop()
            label('_vIrqHandler')
            LDWI('__glink_weak__vIrqAltHandler');BEQ('.rti0')
            PUSH();CALL(vAC);POP()  ## stack must be in low memory!!!
            label('.rti0')
            INC(v('_vIrqTicks')+1);LD(v('_vIrqTicks')+1);BNE('.rti1')
            if args.cpu >= 7:
                INCV(v('_vIrqTicks')+2)
            else:
                LDI(1);ADDW(v('_vIrqTicks')+2);STW(v('_vIrqTicks')+2)
            label('.rti1')
            LDWI(0x400);LUP(0)

        def code_init_sub():
            nohop()
            # Initializer
            label('_vIrqInit')
            LDI(0);ST('frameCount')
            if args.cpu >= 6:
                LDWI('vIRQ_v5');DOKEI('_vIrqHandler');RET()
            else:
                LDWI('_vIrqHandler');BRA('.fin')
            # Finalizer
            label('_vIrqFini')
            if args.cpu >= 7:
                LDWI('vIRQ_v5');DOKEQ(0);RET()
            elif args.cpu >= 6:
                LDWI('vIRQ_v5');DOKEI(0);RET()
            else:
                LDI(0)
                label('.fin')
                STW(T3);LDWI('vIRQ_v5');STW(T2)
                LDW(T3);DOKE(T2);RET()

        def code_init():
            label('__glink_magic_init')
            words('_vIrqInit', 0)

        def code_fini():
            label('__glink_magic_fini')
            words('_vIrqFini', 0)

        module(name='_virq.s',
               code=[ ('EXPORT', '_vIrqTicks'),
                      ('BSS', '_vIrqTicks', code_vars, 4, 1),
                      ('PLACE', '_vIrqTicks', 0x0000, 0x007f),
                      ('CODE', '_vIrqHandler', code_handler),
                      ('PLACE', '_vIrqHandler', 0x0100, 0x7fff),
                      ('CODE', '_vIrqInit', code_init_sub),
                      ('DATA', '__glink_magic_init', code_init, 4, 2),
                      ('DATA', '__glink_magic_fini', code_fini, 4, 2) ])

        def code_avoid():
            nohop()
            '''These function makes sure that there is some time (8 rows * mode)
               before a virtual interrupt or before vertical blanking.'''
            label('_vIrqAvoid')
            LD('frameCount');INC(vAC);_BNE('.ret')
            label('_vBlnAvoid')
            LD('videoY');ORI(0xe);XORI(0xee);_BEQ('_vIrqAvoid')
            label('.ret')
            RET()

        module(name='_virqavoid.s',
               code=[('EXPORT','_vIrqAvoid'),
                     ('EXPORT','_vBlnAvoid'),
                     ('CODE','_vIrqAvoid',code_avoid),
                     ('PLACE', '_vIrqAvoid', 0x0100, 0x7fff)] )

        def code_clock():
            nohop()
            label('clock')
            label('_clock')
            PUSH();CALLI('_vIrqAvoid');POP()
            LD('frameCount')
            label('_clock.sub')
            if args.cpu >= 6:
                ADDHI(255) if args.cpu >= 7 else MOVQB(255,vACH)
                STW(LAC);ORI(255);STW(LAC+2)
                LDI('_vIrqTicks');ADDL()
            else:
                SUBI(128);SUBI(128);ADDW('_vIrqTicks')
                STW(LAC);_BGE('.fin0')
                LDW('_vIrqTicks');_BLT('.fin0')
                LDW(v('_vIrqTicks')+2);SUBI(1);_BRA('.fin1')
                label('.fin0')
                LDW(v('_vIrqTicks')+2)
                label('.fin1')
                STW(LAC+2)
            LDW(LAC)
            RET()

        module(name='clock.s',
               code=[('EXPORT', 'clock'),
                     ('EXPORT', '_clock'),
                     ('EXPORT', '_clock.sub'),
                     ('IMPORT', '_vIrqTicks'),
                     ('IMPORT', '_vIrqAvoid'),
                     ('CODE', 'clock', code_clock)])

    else:

        # Dummy clock functions when vIRQ is not supported.
        # They just return zero.

        def code_clock():
            nohop()
            warning('clock() cannot work without vIRQ (needs rom>=v5a)', dedup=True)
            label('clock')
            label('_clock')
            LDI(0);STW(LAC);STW(LAC+2);RET()

        module(name='clock.s',
               code=[('EXPORT','clock'),
                     ('EXPORT','_clock'),
                     ('CODE','clock',code_clock)] )


scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
	
