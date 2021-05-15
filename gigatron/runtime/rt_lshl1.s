
# LSHL1 : LAC <-- LAC << 1
def code0():
    nohop()
    label('_@_lshl1')
    LDW(LAC);BLT('.l1')
    LSLW();STW(LAC);LDW(LAC+2);LSLW();STW(LAC+2);RET()
    label('.l1')
    LSLW();STW(LAC);LDW(LAC+2);LSLW();ORI(1);STW(LAC+2);RET()

# LSHL1_T0T1:   T0T1 <-- T0T1 << 1
def code1():
   nohop()
   label('_@_lshl1_t0t1')
   LDW(T0);BLT('.lsl1')
   LSLW();STW(T0);LDW(T0+2);LSLW();STW(T0+2);RET()
   label('.lsl1')
   LSLW();STW(T0);LDW(T0+2);LSLW();ORI(1);STW(T0+2);RET()

    
code= [ ('EXPORT', '_@_lshl1'),
        ('CODE', '_@_lshl1', code0),
        ('EXPORT', '_@_lshl1_t0t1'),
        ('CODE', '_@_lshl1_t0t1', code1) ]

module(code=code, name='rt_lshl1.s');

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
