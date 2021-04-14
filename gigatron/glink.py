# -------------- glink proper

import argparse, json, string
import os, sys, traceback, functools

args = None
lccdir = '/usr/local/lib/gigatron-lcc'
current_module = None
current_proc = None
interface_dict = {}
map_dict = {}
safe_dict = {}
module_list = []

# --------------- utils


def where(tb=None):
    '''Locate error in a .s/.o/.a file'''
    stb = traceback.extract_tb(tb, limit=8) if tb else \
          traceback.extract_stack(limit=8)
    for s in stb:
        if (s[2] == 'code'):
            return "{0}:{1}".format(s[0],s[1])
    return None


class Module:
    '''Class for assembly modules read from .s/.o/.a files.'''
    def __init__(self, name=None, cpu=None, code=None):
        global args, current_module
        self.code = code
        self.name = name
        self.cpu = cpu if cpu != None else args.cpu
        self.exports = {}
        self.externs = {}
    def __repr__(self):
        return f"Module('{self.name}',...)"
    def run(self,proc):
        '''Execute the module code with the specified delegate''' 
        global current_proc, current_module
        current_proc = proc
        current_module = self
        self.code()
        current_proc = None
        current_module = None


class __metaUnk(type):
    wrapped = ''' 
      __abs__ __add__ __and__ __eq__ __floordiv__ __ge__ __gt__ __invert__
      __le__ __le__ __lshift__ __lt__ __mod__ __mul__ __neg__ __or__ 
      __pos__ __pow__ __radd__ __rand__ __rfloordiv__ __rlshift__ __rmod__
      __rmul__ __ror__ __rpow__ __rrshift__ __rshift__ __rsub__ 
      __rtruediv__ __rxor__ __sub__ __truediv__  __xor__
    '''
    def __new__(cls, name, bases, namespace, **kwargs):
        def wrap(f):
            @functools.wraps(f)
            def wrapper(self, *args):
                return Unk(f(int(self), *map(int, args)))
            return wrapper if f else None
        for m in cls.wrapped.split():
            namespace[m] = wrap(getattr(int, m))
        return type(name, bases, namespace)
    
class Unk(int, metaclass=__metaUnk):
    '''Class to flag unknow integers'''
    __slots__= ()
    def __new__(cls,val):
        return int.__new__(cls,val)
    def __repr__(self):
        return f"Unk({hex(int(self))})"

def is_zero_page(x):
    if not isinstance(x,Unk):
        return int(x) & 0xff00 == 0
    return False

def is_not_zero_page(x):
    if not isinstance(x,Unk):
        return int(x) & 0xff00 == 0
    return False

def is_pc_page(x):
    if not isinstance(x,Unk):
        return int(x) & 0xff00 == pc() & 0xff00
    return False

def is_not_pc_page(x):
    if not isinstance(x,Unk):
        return int(x) & 0xff00 == pc() & 0xff00
    return False

def check_zp(x):
    if is_not_zeropage(x):
        warning(f"zero page argument overflow")
    return x

def check_br(x):
    if is_not_pcpage(x):
        warning(f"short branch overflow")
    return x

def check_cpu(op, v):
    if args.cpu < v:
        warning(f"opcode not implemented for cpu={arg.cpu}")

def emit(*args):
    current_proc.emit(*args)

def emitbcc(op,cc,dd):
    if args.cpu < 6:
        emit(op,cc,dd)
    else:
        emit(cc,dd)

# ------------- usable vocabulary for .s/.o/.a files

def register_names():
    d = {}
    d['R0'] = 0x18
    d['AC'] = 0x18
    d['FACEXT'] = 0x81
    d['FACEXP'] = 0x82
    d['FACSGN'] = 0x83
    d['FACM'] = 0x84
    d['LAC'] = 0x84
    for i in range(4,32): d[f'R{i}'] = 0x80+i+i
    for i in range(4,29): d[f'L{i}'] = d[f'R{i}']
    for i in range(4,28): d[f'F{i}'] = d[f'R{i}']
    d['SP'] = d['R31']
    d['LR'] = d['R30']
    return d

for (k,v) in register_names().items():
    safe_dict[k] = v
    globals()[k] = v

def vasm(func):
    '''Decorator to mark functions usable in .s/.o/.a files'''
    safe_dict[func.__name__] = func
    return func
      
@vasm
def error(s):
    w = where()
    current_proc.error(f"glink: {w}: error: {s}")
@vasm
def warning(s):
    w = where()
    current_proc.warning(f"glink: {w}: warning: {s}")
@vasm
def fatal(s):
    w = where()
    w = "" if w == None else w + ": "
    print(f"glink: {w}fatal error: {s}", file=sys.stderr)
    sys.exit(1)

@vasm
def module(code=None,name=None,cpu=None):
    global module_list
    if current_module or current_proc:
        warning("module() should not be called from the code fragment")
    else:
        module_list.append(Module(name,cpu,code))

@vasm
def pc():
    return current_proc.pc()
@vasm
def v(x):
    return current_proc.v(x) if isinstance(x,str) else x
@vasm
def lo(x):
    return v(x) & 0xff
@vasm
def hi(x):
    return (v(x) >> 8) & 0xff

@vasm
def ST(d):
    emit(0x5e, check_zp(v(d)))
@vasm
def STW(d):
    emit(0x2b, check_zp(v(d)))
@vasm
def STLW(d):
    emit(0xec, check_zp(v(d)))
@vasm
def LD(d):
    emit(0x1a, check_zp(v(d)))
@vasm
def LDI(d):
    emit(0x59, check_zp(v(d)))
@vasm
def LDWI(d):
    emit(0x11, *w(d))
@vasm
def LDW(d):
    emit(0x21, check_zp(v(d)))
@vasm
def LDLW(d):
    emit(0xee, check_zp(v(d)))
@vasm
def ADDW(d):
    emit(0x99, check_zp(v(d)))
@vasm
def SUBW(d):
    emit(0xb8, check_zp(v(d)))
@vasm
def ADDI(d):
    emit(0xe3, check_zp(v(d)))
@vasm
def SUBI(d):
    emit(0x36, check_zp(v(d)))
@vasm
def LSLW():
    emit(0xe9)
@vasm
def INC(d):
    emit(0x93, check_zp(v(d)))
@vasm
def ANDI(d):
    emit(0x82, check_zp(v(d)))
@vasm
def ANDW(d):
    emit(0xf8, check_zp(v(d)))
@vasm
def ORI(d):
    emit(0x88, check_zp(v(d)))
@vasm
def ORW(d):
    emit(0xfa, check_zp(v(d)))
@vasm
def XORI(d):
    emit(0x8c, check_zp(v(d)))
@vasm
def XORW(d):
    emit(0xfc, check_zp(v(d)))
@vasm
def PEEK():
    emit(0xad)
@vasm
def DEEK():
    emit(0xf6)
@vasm
def POKE(d):
    emit(0xf0, check_zp(v(d)))
@vasm
def DOKE(d):
    emit(0xf3, check_zp(v(d)))
@vasm
def LUP(d):
    emit(0x7f, check_zp(v(d)))
@vasm
def BRA(d):
    emit(0x90, check_br(v(d)))
@vasm
def BEQ(d):
    emitbcc(0x35, 0x3f, check_br(v(d)))
@vasm
def BNE(d):
    emitbcc(0x35, 0x72, check_br(v(d)))
@vasm
def BLT(d):
    emitbcc(0x35, 0x50, check_br(v(d)))
@vasm
def BGT(d):
    emitbcc(0x35, 0x4d, check_br(v(d)))
@vasm
def BLE(d):
    emitbcc(0x35, 0x56, check_br(v(d)))
@vasm
def BGE(d):
    emitbcc(0x35, 0x53, check_br(v(d)))
@vasm
def CALL(d):
    emit(0xcf, check_zp(v(d)))
@vasm
def RET():
    emit(0xff)
@vasm
def PUSH():
    emit(0x75)
@vasm
def POP():
    emit(0x63)
@vasm
def ALLOC(d):
    emit(0xdf, check_zp(v(d)))
@vasm
def SYS(op):
    t = 270-op//2 if op>28 else 0
    if not isinstance(t,Unk) and (t <= 128 or t > 255):
        error(f"argument overflow in SYS opcode");
    emit(0xb4, t)
@vasm
def HALT():
    emit(0xb4, 0x80)
@vasm
def DEF(d):
    emit(0xcd, check_br(v(d)))
@vasm
def CALLI(d):
    check_cpu(5); emit(0x85, *w(d))
@vasm
def CMPHS(d):
    check_cpu(5); emit(0x1f, check_zp(v(d)))
@vasm
def CMPHU(d):
    check_cpu(5); emit(0x97, check_zp(v(d)))


        
# ------------- reading .s/.o/.a files
        
              
def new_globals():
    '''Return a pristine global symbol table to read .s/.o/.a files.'''
    global safe_dict
    g = safe_dict.copy()
    g['args'] = { k:vars(args)[k] for k in ('cpu','rom','map') }
    g['__builtins__'] = None
    return g

def read_file(f):
    '''Safely read a .s/.o/.a file.'''
    global code, current_module, current_proc
    with open(f,'r') as fd: 
        c = compile(fd.read(),f,'exec')
    n = len(module_list)
    current_module = None
    current_proc = None
    exec(c, new_globals())
    if len(module_list) <= n:
        fatal(f"no module found")

def read_lib(l):
    '''Search a library file along the library path and read it.'''
    for d in (args.L or []) + [lccdir]:
        f = os.path.join(d, f"lib{l}.a")
        if os.access(f, os.R_OK):
            return read_file(f)
    fatal(f"library -l{l} not found!")
        


# ------------- main function


def main(argv):
    '''Main entry point'''
    global lccdir, args
    global interface_syms
    try:
        ## Obtain LCCDIR
        lccdir = os.getenv("LCCDIR", default=lccdir)

        ## Parse arguments
        parser = argparse.ArgumentParser(
            conflict_handler='resolve',allow_abbrev=False,
            usage='glink [options] {<files.o>} -l<lib> -o <outfile.gt1>',
            description='Collects gigatron .{s,o,a} files into a .gt1 file.',
            epilog=''' 
            	This program accepts the modules generated by
                gigatron-lcc/rcc (suffix .s or .o). These files are
                text files with a python syntax. They contain a single
                function that defines all the VCPU instructions,
                labels and data for this module.  Glink also accepts
                concatenation of such files forming a library (suffix
                .a).  The -cpu, -rom, and -map options provide values
                than handcrafted code inside a module can test to
                select different implementations. The -cpu option
                enables instructions that were added in successive
                implementations of the Gigatron VCPU.  The -rom option
                informs the libraries about the availability of
                natively implemented SYS functions. The -map option
                tells at which addresses the program, the data, and
                the stack should be located. It also tells which
                runtime libraries should be loaded by default. The
                final output file includes the module that exports the
                entry point symbol, then the modules that exports all
                the symbols that it imports, then recursively all the
                modules that are needed to resolve imported
                symbols.''')
        parser.add_argument('-o', type=str, default='a.gt1', metavar='file.gt1',
                            help='select the output filename (default: a.gt1)')
        parser.add_argument('-cpu', type=str, action='store',
                            help='select the target cpu version')
        parser.add_argument('-rom', type=str, action='store',
                            help='select the target rom version')
        parser.add_argument('-map', type=str, action='store',
                            help='select a linker map')
        parser.add_argument('-d', action='store_true',
                            help='enable debug output')
        parser.add_argument('-e', type=str, action='store', default='_start',
                            help='select the entry point symbol (default _start)')
        parser.add_argument('files', type=str, nargs='+',
                            help='input files')
        parser.add_argument('-l', type=str, action='append',
                            help='library files. -lxxx searches for libxxx.a')
        parser.add_argument('-L', type=str, action='append',
                            help='additional library directories')
        args = parser.parse_args(argv)
        if args.map == None:
            args.map = '64k'
        if args.rom == None:
            args.rom = 'v5a'
        if args.cpu == None:
            args.cpu = 5

        ### Read interface.json
        with open(lccdir + '/interface.json') as file:
            for (name, value) in json.load(file).items():
                interface_dict[name] = value if isinstance(value, int) else int(value, base=0)

        ### Read map

        ### Load all .s/.o/.a files and libraries
        for f in args.files or []:
            read_file(f)
        for f in args.l or []:
            read_lib(f)

        return 0
    
    except FileNotFoundError as err:
        fatal(str(err))


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
