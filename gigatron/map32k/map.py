

def map_describe():
    print('''  Memory map '32k' targets the 32KB Gigatron.
             
  Program and data are scattered in the video memory holes starting in
  0x8a0-0x8ff and progressing towards 0x7fa0-0x7fff. Data items larger
  than 96 bytes can be located in page 2 to 5. The stack grows
  downwards from 0x6fe. The map also inserts a stub in 0x200
  that jumps to the actual entry point.

  This memory map is very constraining because it only provides space
  for a couple data items larger than 96 bytes. Problems can arise if
  the stack grows into a data region.
  ''')


# ------------size----addr----step----end---- flags (1=nocode, 2=nodata)
segments = [ (0x0060, 0x08a0, 0x0100, 0x80a0, 0),
	     (0x00fa, 0x0200, 0x0100, 0x0500, 1),
	     (0x0100, 0x0500, None,   None,   1)   ]

initsp = 0x6fe
minram = 0x80

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
        '''Init function.'''
        nohop()
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
    def code1():
        '''Jump to the entry point in 0x200.'''
        org(0x200)
        LDWI(args.e)
        CALL(vAC)
    code=[ ('EXPORT', '_init0'),
           ('CODE', '_init0', code0),
           ('CODE', '_usercode', code1) ]
    name='_map.s'
    debug(f"synthetizing module '{name}'")
    module(code=code, name=name);



# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End: