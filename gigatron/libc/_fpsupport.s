
# This module is inserted whenever fp is used.
# This (will be) used to trigger the inclusion of
# the bulky printf/scanf code that supports floats.

def code0():
    label('_@_raisefpe', '_@_raise')

module(name='_fpsupport.s',
       code=[ ('EXPORT', '_@_raisefpe'),
              ('IMPORT', '_@_raise'),
              ('CODE', '_@_raisefpe', code0) ] )


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
