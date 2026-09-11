# This overlays eats the memory normally allocated to channels 2,3,4
# in order to provide a contiguous memory block from 0x200 to 0x5ff.

# Flags is now a string with letters:
# - 'C' if the segment can contain code
# - 'D' if it can contain data
# - 'H' if it can be used for the malloc heap.
# Using lowercase letters instead mean that use is permitted
# when an explicit placement constraint is provided.
#
# ------------size----addr----step----end------flags
segments = [ (0x0060, 0x08a0, 0x0100, 0x80a0, 'CDH'),
             (0x0400, 0x0200, None,   None,   'cDH') ]

nochan = True  # to clear channel mask
