
def map_segs():
    return [(addr,0x60) for addr in range(0x8a0,0x8000,0x100)] \
      +    [(addr,0xfa) for addr in range(0x300,0x500)] \
      +    [(0x500,0x200)] \
      +    [(0x8000,0x7000)]

def map_sp():
    return 0x0000

def map_extra_modules():
    return []

def map_extra_libraries():
    return []

def map_extra_symdefs():
    return { '_@_init_sp' : sp }

print('foo')
