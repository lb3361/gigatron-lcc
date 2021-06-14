
def map_describe():
    print('''  Memory map '64k' targets memory expanded Gigatrons.
             
 Code and data can be placed in the video memory holes or 
 in the memory above 0x8280. The stack grows downwards from 0xfffe.
 Space in page 2 to 6 is reserved for data items. Small data
 objects often fit in the memory holes. Meanwhile the high
 32KB of memory provides space for large data objects.

 Option '--short-function-size-threshold=256' has the effect of using
 high memory for all functions that fit in a page but do not fit in a
 video memory hole. Option '--long-function-segment-size=128' has the
 effect of moving all long functions in high memory, minimizing the
 need to hop from page to page inside the same function. Function
 placement can be seen with glink option '-d' or glcc option '-Wl-d'.
 ''')


# ------------size----addr----step----end---- flags (1=nocode, 2=nodata)
segments = [ (0x0060, 0x08a0, 0x0100, 0x80a0, 0),
	     (0x00fa, 0x0200, 0x0100, 0x0500, 1),
	     (0x0200, 0x0500, None,   None,   1),
             (0x0100, 0x8100, None,   None,   0),
	     (0x7000, 0x8240, None,   None,   0)   ]

initsp = 0xfffe
minram = 0x100

def map_segments():
    '''
    Enumerate all segments as tuples (saddr, eaddr, dataonly)
    '''
    global segments
    for tp in segments:
        estep = tp[2] or 1
        eaddr = tp[3] or (tp[1] + estep)
        for addr in range(tp[1], eaddr, estep):
            yield (addr, addr+tp[0], tp[4])

def map_extra_libs(romtype):
    '''
    Returns a list of extra libraries to scan before the standard ones
    '''
    return []

def map_extra_modules(romtype):
    '''
    Generate an extra modules for this map. At the minimum this should
    define a function '_gt1exec' that sets the stack pointer,
    checks the rom and ram size, then calls v(args.e). This is ofen
    pinned at address 0x200.
    '''
    def code0():
        org(0x200)
        label('_gt1exec')
        # Set stack
        _LDI(initsp);STW(SP);
        # Check rom and ram
        if romtype:
            LD('romType');ANDI(0xfc);SUBI(romtype);BLT('.err')
        if minram == 0x100:
            LD('memSize');BNE('.err')
        else:
            LD('memSize');SUBI(1);ANDI(0xff);SUBI(minram-1);BLT('.err')
        # Call _start
        _LDI(v(args.e));CALL(vAC)
        # Run Marcel's smallest program when machine check fails
        label('.err')
        LDW('frameCount');DOKE(vPC+1);BRA('.err')

    module(name='_gt1exec.s',
           code=[ ('EXPORT', '_gt1exec'),
                  ('CODE', '_gt1exec', code0) ] )

    debug(f"synthetizing module '_gt1exec.s' at address 0x200")


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
