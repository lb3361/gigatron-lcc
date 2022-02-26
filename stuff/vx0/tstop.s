
def scope():

  def code_tstxla():
    nohop()
    label('_tstxla')
    XLA();STW(R8);XLA()
    LDW(R8);RET()

  module(name="txtxla.s",
         code=[('CODE', '_tstxla', code_tstxla),
               ('EXPORT', '_tstxla') ])
  
  def code_tstjmpi():
    nohop()
    label('_tstjmpi')
    JMPI('.2')
    label('.1')
    JMPI('.3')
    label('.2')
    JMPI('.1')
    label('.3')
    RET()

  module(name="txtjmpi.s",
         code=[('CODE', '_tstjmpi', code_tstjmpi),
               ('EXPORT', '_tstjmpi') ])

  def code_tstncopy():
    # _tstncopy(void *dst, void *src, int n)
    nohop()
    label('_tstncopy')
    LDWI(v('.ncopy')+1);POKEA(R10)
    LDW(R8);STW(0xcc)
    LDW(R9)
    label('.ncopy')
    NCOPY(4)
    RET()
  
  module(name="txtncopy.s",
         code=[('CODE', '_tstncopy', code_tstncopy),
               ('EXPORT', '_tstncopy') ])


scope()

	
# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
