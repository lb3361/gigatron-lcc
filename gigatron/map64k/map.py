
def map_describe():
    print('''  Memory map '64k' targets memory expanded Gigatrons.
             
 Code and data can be placed in the video memory holes or 
 in the memory above 0x8000. The stack grows downwards from 0xfffe.
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
	     (0x7000, 0x8000, None,   None,   0)   ]

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
    Generate an extra modules for this map with at least a function
    _init0() that initializes the stack pointer, checks the rom
    version, checks the ram configuration, and returns 0 if all goes well.
    '''
    def code0():
        nohop() # short function that must fit in a single segment
        label('_init0')
        _LDI(initsp);STW(SP);
        LD('romType');ANDI(0xfc);SUBI(romtype or 0);BLT('.err')
        if minram == 0x100:
            LD('memSize');BNE('.err')
        else:
            LD('memSize');SUBI(1);ANDI(0xff);SUBI(minram-1);BLT('.err')
        LDI(0);RET()
        label('.err')
        LDI(1);RET()
    code=[ ('EXPORT', '_init0'), ('CODE', '_init0', code0) ]
    name='_map.s'
    debug(f"synthetizing module '{name}'")
    module(code=code, name=name);


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
