
# ------------size----addr----step----end---- dataonly
segments = [ (0x0060, 0x08a0, 0x0100, 0x8000, 0),
	     (0x00fa, 0x0200, 0x0100, 0x0500, 1),
	     (0x0200, 0x0500, None,   None,   1),
	     (0x8000, 0x8000, None,   None,   0)   ]


def map_segments():
    global segments
    for tp in segments:
        eaddr = tp[3] or (tp[1] + 1)
        estep = tp[2] or 1
        for addr in range(tp[1], eaddr, estep):
            yield (tp[0], addr, tp[4])

def map_sp():
    return 0x0000

def map_ram():
    return 0x0000

def map_extra_libs():
    return []

def map_extra_symdefs():
    return {}

def map_extra_modules():
    '''Generate extra modules for this map.
       The following defines the following two symbols:
       -- '_init2' is a pointer to an additional initialization
          function that '_start' will call if non zero.
       -- '_segments' describes the memory segments in order
          to help '_init1' which clears the BSS and initializes
          the malloc heap. '''
    def code0():
        align(2);
        label('_init2');
        words(0); 
    def code1():
        align(2);
        label('_segments');
        for tp in segments:
            words(tp[0], tp[1], tp[2] or 1, tp[3] or tp[1] + 1)
        words(0)
    code=[ ('EXPORT', '_init2'),
           ('DATA', '_init2', code0, 2, 2),
           ('EXPORT', '_segments'),
           ('DATA', '_segments', code1, 0, 2) ]
    name='_map64k.s'
    debug(f"synthetizing module '{name}'")
    module(code=code, name=name);


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
