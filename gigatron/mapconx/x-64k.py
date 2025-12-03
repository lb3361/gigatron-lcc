
# ------------size----addr----step----end---- flags (1=nocode, 2=nodata)

segments = segments +  [ (0x0100, 0x8100, None,   None,   'CDH'),
                         (0x79c0, 0x8240, None,   None,   'CDH')  ]

args.initsp = 0xfffc

minram = 0x100

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
