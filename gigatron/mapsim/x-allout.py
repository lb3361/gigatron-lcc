
# Map overlay that allows using all the available memory
# Note that we do not use segments greater
# than 32k because this breaks malloc.

# Flags is now a string with letters:
# - 'C' if the segment can contain code
# - 'D' if it can contain data
# - 'H' if it can be used for the malloc heap.
# Using lowercase letters instead mean that use is permitted
# when an explicit placement constraint is provided.
#
# ------------size----addr----step----end------flags
segments = [(0x7e00, 0x0200, None,   None,   'CDH'),
            (0x7c00, 0x8000, None,   None,   'CDH') ]

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
