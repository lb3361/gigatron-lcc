#   Copyright (c) 2021, LB3361
#
#    Redistribution and use in source and binary forms, with or
#    without modification, are permitted provided that the following
#    conditions are met:
#
#    1.  Redistributions of source code must retain the above copyright
#        notice, this list of conditions and the following disclaimer.
#
#    2. Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials
#       provided with the distribution.
#
#    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
#    CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
#    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#    MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
#    BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
#    EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
#    TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
#    ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
#    OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#    POSSIBILITY OF SUCH DAMAGE.


# -------------- glink proper

import argparse, json, string
import os, sys, traceback, functools, copy
import builtins

args = None
rominfo = None
romtype = None
romcpu = None
lccdir = '/usr/local/lib/gigatron-lcc'
module_dict = {}
module_builtins = {}
module_list = []
segment_list = []
new_modules = []

symdefs = {}
exporters = {}

the_module = None
the_segment = None
the_fragment = None
the_pc = 0
the_pass = 0

final_pass = False
hops_enabled = False
short_function = False
lbranch_counter = 0
error_counter = 0
warning_counter = 0
genlabel_counter = 0
labelchange_counter = 1
dedup_errors = set()

map_extra_modules = None
map_extra_libs = None
map_segments = None
map_describe = None

# --------------- utils

def debug(s, level=1):
    if args.d and args.d >= level:
        print("(glink debug) " + s, file=sys.stderr)
        
def where(exc=False):
    '''Locate error in a .s/.o/.a file'''
    if exc:
        stb = traceback.extract_tb(sys.exc_info()[2], limit=10)
    else:
        stb = traceback.extract_stack(limit=10)
    for s in stb:
        if isinstance(s[0],str) and not s[0].endswith('.py') \
           and not s[0].endswith('glink') \
           and not s[0].endswith('glcc'):
            fn = s[0] or "<unknown>"
            if fn.startswith(lccdir):
                fn = fn[len(lccdir):].lstrip('/')
            return f"{fn}:{s[1]}"
    return None

class __metaUnk(type):
    wrapped = ''' __abs__ __add__ __and__ __floordiv__ __ge__ __gt__ __invert__
    __le__ __lshift__ __lt__ __mod__ __mul__ __neg__ __or__ __pos__
    __pow__ __radd__ __rand__ __rfloordiv__ __rlshift__ __rmod__
    __rmul__ __ror__ __rpow__ __rrshift__ __rshift__ __rsub__
    __rtruediv__ __rxor__ __sub__ __truediv__ __xor__'''
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
    '''Class to represent unknown symbol values'''
    __slots__= ()
    def __new__(cls,val):
        return int.__new__(cls,val)
    def __repr__(self):
        return f"Unk({hex(int(self))})"
    def __eq__(self, other):
        return False
    def __ne__(self, other):
        return True

def is_zero(x):
    if isinstance(x,int) and not isinstance(x,Unk):
        return int(x) == 0
    return False

def is_zeropage(x, l = 0):
    if isinstance(x,int) and not isinstance(x,Unk):
        if int(x) & 0xff00 == 0:
            return l < 1 or int(x + l) & 0xff00 == 0
    return False

def is_not_zeropage(x):
    if isinstance(x,int) and not isinstance(x,Unk):
        return int(x) & 0xff00 != 0
    return False

def is_pcpage(x):
    if isinstance(x,int) and not isinstance(x,Unk):
        return int(x) & 0xff00 == pc() & 0xff00
    return False

def is_not_pcpage(x):
    if isinstance(x,int) and not isinstance(x,Unk):
        return int(x) & 0xff00 != pc() & 0xff00
    return False

def check_zp(x):
    x = v(x)
    if final_pass and is_not_zeropage(x):
        warning(f"zero page address overflow")
    return x & 0xff

def check_imm8(x):
    x = v(x)
    if final_pass and isinstance(x,int):
        if x < 0 or x > 255:
            warning(f"immediate byte argument overflow")
    return x & 0xff

def check_im8s(x):
    x = v(x)
    if final_pass and isinstance(x,int):
        if x < -128 or x > 255:
            warning(f"immediate byte argument overflow")
    return x & 0xff

def check_br(x):
    x = v(x)
    if is_not_pcpage(x) and final_pass:
        error(f"short branch overflow")
    return (int(x)-2) & 0xff

def check_cpu(v):
    if args.cpu < v and final_pass:
        stb = traceback.extract_stack(limit=2)
        warning(f"opcode {stb[0].name} not implemented by cpu={args.cpu}", dedup=True)

def resolve(s, ignore=None):
    '''Resolve a global symbol and return its value or None'''
    if s in exporters:
        exporter = exporters[s]
        if exporter != ignore:
            if s in exporter.symdefs:
                return exporter.symdefs[s]
            elif final_pass:
                error(f"module {exporter.fname} exports '{s}' but does not define it", dedup=True)
    if s in symdefs:
        return symdefs[s]
    return None
        
class Module:
    '''Class for assembly modules read from .s/.o/.a files.'''
    def __init__(self, name=None, cpu=None, code=None):
        global args, current_module
        self.cpu = cpu if cpu != None else args.cpu
        self.code = code
        self.name = name
        self.fname = name
        self.library = False
        self.used = False
        self.exports = []
        self.imports = []
        self.symdefs = {}
        self.sympass = {}
        for tp in self.code:
            if tp[0] == 'EXPORT':
                self.exports.append(tp[1])
            elif tp[0] == 'IMPORT':
                self.imports.append(tp[1])
    def __repr__(self):
        return f"Module('{self.fname or self.name}',...)"
    def label(self, sym, val):
        '''Define a label within a module.
           Increment counter when label value has changed relative to the previous pass.'''
        if the_pass > 0:
            if sym in self.symdefs and val == self.symdefs[sym]:
                self.sympass[sym] = the_pass
            elif sym in self.symdefs and self.sympass[sym] == the_pass:
                error(f"multiple definitions of label '{sym}'", dedup=True)
            else:
                if sym in self.symdefs and args.d >= 3:
                    debug(f"pass {the_pass}: symbol '{sym}' went from {hex(self.symdefs[sym])} to {hex(val)}")
                global labelchange_counter
                labelchange_counter += 1
                self.symdefs[sym] = val
                self.sympass[sym] = the_pass

class Segment:
    '''Represent memory segments to be populated with code/data'''
    __slots__ = ('saddr', 'eaddr', 'pc', 'flags', 'buffer', 'nbss')
    def __init__(self, saddr, eaddr, flags=False):
        self.saddr = saddr
        self.eaddr = eaddr
        self.pc = saddr
        self.flags = flags or False # 0x1: no code, 0x2 : no data
        self.buffer = None
        self.nbss = None
    def __repr__(self):
        d = f",flags={hex(self.flags)}" if self.flags else ''
        return f"Segment({hex(self.saddr)},{hex(self.eaddr)}{d})"
                
def emit(*args):
    global final_pass, the_pc, the_segment
    if final_pass:
        if not the_segment.buffer:
            the_segment.buffer = bytearray()
        for b in args:
            the_segment.buffer.append(b)
    the_pc += len(args)

def extern(sym):
    '''Adds a symbol to the import list of a module. 
       This happens when `measure_code_fragment' is called.
       Pseudo-instructons need this to make sure the linker
       inserts the appropriate runtime routines.'''
    if the_pass == 0 and sym not in the_module.imports:
        the_module.imports.append(sym)

def is_placed(frag4):
    '''Tells if a code fragment is a placed function'''
    if isinstance(frag4, tuple) and frag4[0] == 'org':
            return frag4[1]
    return False

# ------------- jumps and hops

def bytes_left():
    '''Tells how many bytes are left in the current segment'''
    if the_pass > 0:
        return the_segment.eaddr - the_pc
    return 256

def size_long_jump():
    return 3 if args.cpu >= 5 else 10

def emit_long_jump(d):
    if args.cpu >= 5:
        CALLI(d)          # 3 bytes
    else:
        STLW(-2); LDWI(d); STW(vLR);
        LDLW(-2); RET()   # 10 bytes

def hop(sz, jump):
    '''Ensure, possibly with a hop, that there are at 
       least sz bytes left in the segment. '''
    if bytes_left() < sz:
        global hops_enabled
        if not hops_enabled:
            error(f"internal error: cannot honor hop({sz}) because hops are disabled")
        elif jump and bytes_left() < size_long_jump():
            error(f"internal error: cannot hop because there is no space for a jump")
        else:
            global the_segment, the_pc
            hops_enabled = False
            the_segment.pc = the_pc
            lfss = args.lfss or 32
            ns = find_code_segment(max(lfss, sz))
            if not ns:
                fatal(f"map memory exhausted while fitting function `{the_fragment[1]}'")
            if jump:
                emit_long_jump(ns.pc)
            hops_enabled = True            
            the_segment.pc = the_pc
            the_segment = ns
            the_pc = ns.pc
            if args.d >= 2 or final_pass:
                debug(f"- continuing code fragment '{the_fragment[1]}' at {hex(the_pc)} in {ns}")

def emitjump(d):
    global hops_enabled, lbranch_counter
    save_hops_enabled = hops_enabled
    hops_enabled = False
    if short_function or is_pcpage(d):
        BRA(d)
    else:
        lbranch_counter += size_long_jump() - 2
        emit_long_jump(d)
    hops_enabled = save_hops_enabled
    tryhop(jump=False)
    
def emitjcc(BCC, BNCC, JCC, d):
    global hops_enabled, lbranch_counter
    save_hops_enabled = hops_enabled
    hops_enabled = False
    short_ok = bytes_left() >= 3 + size_long_jump()
    long_ok = bytes_left() >= 3 + 2 * size_long_jump()
    lbl = genlabel()
    while True:
        if short_function:
            BCC(d)
            break;
        elif is_pcpage(d) and short_ok:
            BCC(d)
            break;
        elif args.cpu >= 6 and JCC and short_ok:
            JCC(d)
            break;
        elif not is_pcpage(d) and long_ok:
            BNCC(lbl)
            emit_long_jump(d)
            label(lbl)
            lbranch_counter += size_long_jump()
            break;
        else:
            hops_enabled = True
            hop(3 + 2 * size_long_jump(), jump=True)
            short_ok = long_ok = True
            hops_enabled = False
    hops_enabled = save_hops_enabled

        
# ------------- usable vocabulary for .s/.o/.a files

# Each .s/.o/.a files is exec with a fresh global dictionary and a
# restricted set of builtins.  This prevents a module from
# accidentally changing the global state in other ways than defining
# new modules.  Note that this is not expected to protect against
# malicious modules, just prevent accidental corruption.

module_builtins_okay = '''None True False abs all any ascii bin bool chr
dict divmod enumerate filter float format frozenset getattr hasattr hash
hex id int isinstance issubclass iter len list map max min next oct ord 
pow print property range repr reversed set setattr slice sorted str sum
tuple type zip'''
module_builtins = {}
for s in module_builtins_okay.split():
    if isinstance(__builtins__, dict) and s in __builtins__:
        module_builtins[s] = __builtins__[s]
    elif hasattr(__builtins__,s):
        module_builtins[s] = getattr(__builtins__, s)

def register_names():
    d = { "vPC":  0x0016, "vAC":  0x0018, "vLR":  0x001a, "vSP":  0x001c,
          "vACL": 0x0018, "vACH": 0x0019,
          "B0":   0x0081, "B1":   0x0082, "B2":   0x0083, "LAC":  0x0084,
          # the real FAC overlaps B[0-3] and LAC with a private format
          "FAC":  0x0FAC }
    for i in range(0,4):  d[f'T{i}'] = 0x88+i+i
    for i in range(0,24): d[f'R{i}'] = 0x90+i+i
    for i in range(0,22): d[f'L{i}'] = d[f'R{i}']
    for i in range(0,21): d[f'F{i}'] = d[f'R{i}']
    d['SP'] = d['R23']
    return d
for (k,v) in register_names().items():
    module_dict[k] = v
    globals()[k] = v

def new_globals():
    '''Return a pristine global symbol table to read .s/.o/.a files.'''
    global module_dict
    g = module_dict.copy()
    g['args'] = copy.copy(args)
    g['rominfo'] = copy.copy(rominfo)
    g['__builtins__'] = module_builtins.copy()
    return g

def vasm(func):
    '''Decorator to mark functions usable in .s/.o/.a files'''
    module_dict[func.__name__] = func
    return func

@vasm
def error(s, dedup=False):
    global the_pass, final_pass, error_counter
    if the_pass == 0 or final_pass:
        if dedup and s in dedup_errors: return
        dedup_errors.add(s)
        error_counter += 1
        w = where()
        w = "" if w == None else w + ": "
        print(f"glink: {w}error: {s}", file=sys.stderr)
@vasm
def warning(s, dedup=False):
    global the_pass, final_pass, warning_counter
    if the_pass == 0 or final_pass:
        if dedup and s in dedup_errors: return
        dedup_errors.add(s)
        warning_counter += 1
        w = where()
        w = "" if w == None else w + ": "
        print(f"glink: {w}warning: {s}", file=sys.stderr)
@vasm
def fatal(s, exc=False):
    w = where(exc)
    w = "" if w == None else w + ": "
    print(f"glink: {w}fatal error: {s}", file=sys.stderr)
    sys.exit(1)

@vasm
def module(code=None,name=None,cpu=None):
    '''Called from .s/.o/.a files to declare a module.
       This should be the only way for a .s/.o/.a file
       to change the linker state.'''
    if not name:
        name = "[unknown]"
        tb = traceback.extract_stack(limit=2)
        if len(tb) > 1 and isinstance(tb[0][0], str):
            name = os.path.basename(tb[0][0])
    global new_modules
    if the_module or the_fragment:
        warning("module() should not be called from a code fragment")
    else:
        new_modules.append(Module(name,cpu,code))

@vasm
def genlabel():
    '''Generate a label for use in a pseudo-instruction.
       One should make sure to request the same number
       of labels regardless of the code path.'''
    global genlabel_counter
    genlabel_counter += 1
    return f".LL{genlabel_counter}"

@vasm
def pc():
    return the_pc
@vasm
def v(x):
    '''Possible resolve symbol `x'.'''
    if not isinstance(x,str):
        return x
    if the_module:
        if x in the_module.symdefs:
            return the_module.symdefs[x]
    r = resolve(x)
    if final_pass and not r:
        error(f"undefined symbol '{x}'", dedup=True)
    return r or Unk(0xDEAD)
@vasm
def lo(x):
    return v(x) & 0xff
@vasm
def hi(x):
    return (v(x) >> 8) & 0xff

@vasm
def org(addr):
    '''Force a code fragment to be placed at a specific location.
       The fragment must fit in the page and the required space
       must be available. This currently piggybacks on nohop()
       and does not work for code fragments. I have to find
       a better way of doing this.'''
    global short_function
    # this information is collected in measure_code_fragment()
    if the_pass == 0:
        short_function = True if org == None else ('org', int(addr))
@vasm
def nohop():
    '''Force a code fragment to be fit in a single page.
       An error will be signaled if no page can fit it.'''
    global short_function
    # this information is collected in measure_code_fragment()
    if the_pass == 0:
        short_function = True
@vasm
def tryhop(sz=None, jump=True):
    '''Hops to a new page if the current page cannot hold a long jump
       plus `sz' bytes. This also ensures that no hop will occur during
       the next `sz' bytes. A long jump is generated when `jump' is True.'''
    if hops_enabled:
        sz = sz if sz != None else 4 # max size of an instruction
        sz = sz + size_long_jump()
        if bytes_left() < sz:
            hop(sz, jump=jump)
@vasm
def align(d):
    while the_pc & (d-1):
        emit(0)
@vasm
def bytes(*args):
    for w in args:
        w = v(w)
        if isinstance(w,int):
            emit(v(w))
        elif isinstance(w,builtins.bytes) or isinstance(w,bytearray):
            for b in w:
                emit(b)
        else:
            error(f"Illegal argument {w} for instruction 'bytes()'")
@vasm
def words(*args):
    for w in args:
        emit(lo(w), hi(w))
@vasm
def space(d):
    for i in range(0,d):
        emit(0)
@vasm
def label(sym, val=None, hop=None):
    '''Define label `sym' to the value of PC or to `val'.
       Unless `hop` is False, this function checks whether 
       one needs to hop to a new page before defining the label.'''
    tryhop(hop)
    if the_pass > 0:
        the_module.label(sym, v(val) if val else the_pc)

@vasm
def ST(d):
    tryhop(2); emit(0x5e, check_zp(d))
@vasm
def STW(d):
    tryhop(2); emit(0x2b, check_zp(d))
@vasm
def STLW(d):
    tryhop(2); emit(0xec, check_im8s(d))
@vasm
def LD(d):
    tryhop(2); emit(0x1a, check_zp(d))
@vasm
def LDI(d, hop=True):
    tryhop(2); emit(0x59, check_im8s(d))
@vasm
def LDWI(d):
    tryhop(3); d=int(v(d)); emit(0x11, lo(d), hi(d))
@vasm
def LDW(d):
    tryhop(2); emit(0x21, check_zp(d))
@vasm
def LDLW(d):
    tryhop(2); emit(0xee, check_im8s(d))
@vasm
def ADDW(d):
    tryhop(2); emit(0x99, check_zp(d))
@vasm
def SUBW(d):
    tryhop(2); emit(0xb8, check_zp(d))
@vasm
def ADDI(d):
    tryhop(2); emit(0xe3, check_imm8(d))
@vasm
def SUBI(d):
    tryhop(2); emit(0xe6, check_imm8(d))
@vasm
def LSLW():
    tryhop(1); emit(0xe9)
@vasm
def INC(d):
    tryhop(2); emit(0x93, check_zp(d))
@vasm
def ANDI(d):
    tryhop(2); emit(0x82, check_imm8(d))
@vasm
def ANDW(d):
    tryhop(2); emit(0xf8, check_zp(d))
@vasm
def ORI(d):
    tryhop(2); emit(0x88, check_imm8(d))
@vasm
def ORW(d):
    tryhop(2); emit(0xfa, check_zp(d))
@vasm
def XORI(d):
    tryhop(2); emit(0x8c, check_imm8(d))
@vasm
def XORW(d):
    tryhop(2); emit(0xfc, check_zp(d))
@vasm
def PEEK():
    tryhop(1); emit(0xad)
@vasm
def DEEK():
    tryhop(1); emit(0xf6)
@vasm
def POKE(d):
    tryhop(2); emit(0xf0, check_zp(d))
@vasm
def DOKE(d):
    tryhop(2); emit(0xf3, check_zp(d))
@vasm
def LUP(d):
    tryhop(2); emit(0x7f, check_zp(d))
@vasm
def BRA(d):
    emit(0x90, check_br(d)); tryhop(jump=False)
@vasm
def BEQ(d):
    tryhop(3); emit(0x35, 0x3f, check_br(d))
@vasm
def BNE(d):
    tryhop(3); emit(0x35, 0x72, check_br(d))
@vasm
def BLT(d):
    tryhop(3); emit(0x35, 0x50, check_br(d))
@vasm
def BGT(d):
    tryhop(3); emit(0x35, 0x4d, check_br(d))
@vasm
def BLE(d):
    tryhop(3); emit(0x35, 0x56, check_br(d))
@vasm
def BGE(d):
    tryhop(3); emit(0x35, 0x53, check_br(d))
@vasm
def CALL(d):
    tryhop(3); emit(0xcf, check_zp(d))
@vasm
def RET():
    emit(0xff); tryhop(jump=False)
@vasm
def PUSH():
    tryhop(1); emit(0x75)
@vasm
def POP():
    tryhop(1); emit(0x63)
@vasm
def ALLOC(d):
    tryhop(2); emit(0xdf, check_im8s(d))
@vasm
def SYS(op):
    op = v(op)
    if not isinstance(op ,Unk):
        if op & 1 != 0 or op < 0 or op >= 284:
            error(f"illegal argument {op} for SYS opcode")
        op = min(0, 14 - op // 2) & 0xff
    tryhop(2); emit(0xb4, op)
@vasm
def HALT():
    emit(0xb4, 0x80); tryhop(jump = False)
@vasm
def DEF(d):
    tryhop(2); emit(0xcd, check_br(d))
@vasm
def CALLI(d):
    check_cpu(5); tryhop(3); d=int(v(d)); emit(0x85, lo(d), hi(d))
@vasm
def CMPHS(d):
    check_cpu(5); tryhop(2); emit(0x1f, check_zp(d))
@vasm
def CMPHU(d):
    check_cpu(5); tryhop(2); emit(0x97, check_zp(d))

# instructions for cpu6 (opcodes to be checked once at67's rom is released)
@vasm
def DEC(d):
    '''DEC: Decrement byte var ([D]--), 22 cycles'''
    check_cpu(6); tryhop(2); emit(0x14, check_zp(d))
@vasm
def MOVQ(imm,d):
    '''MOVQ: Load a byte var with a small constant 0..255, 28 cycles'''
    check_cpu(6); tryhop(2); emit(0x16, check_zp(imm), check_zp(d))
@vasm
def LSRB(d):
    '''LSRB: Logical shift right on a byte var, 28 cycles'''
    check_cpu(6); tryhop(2); emit(0x18, check_zp(d))
@vasm
def SEXT(d):
    '''SEXT: Sign extend vAC based on a variable mask, 28 cycles'''
    check_cpu(6); tryhop(2); emit(0x1c, check_zp(d))
@vasm
def PEEKp(d):
    '''PEEK+: Peek byte at address contained in var, inc var, 30 cycles'''
    check_cpu(6); tryhop(2); emit(0x23, check_zp(d))
@vasm
def POKEI(d):
    '''POKEI: Poke immediate byte into address contained in [vAC], 20 cycles'''
    check_cpu(6); tryhop(2); emit(0x25, check_im8s(d))
@vasm
def LSLV(d):
    '''LSLV: Logical shift left word var, 28 cycles'''
    check_cpu(6); tryhop(2);  emit(0x27, check_zp(d))
@vasm
def ADDBA(d):
    '''ADDBA: vAC += var.lo, 28 cycles'''
    check_cpu(6); tryhop(2); emit(0x29, check_zp(d))
@vasm
def ADDBI(imm,d):
    '''ADDBI: Add a constant 0..255 to byte var, 28 cycles'''
    check_cpu(6); tryhop(2); emit(0x2d, check_zp(imm), check_zp(d))
@vasm
def DBNE(v, d):
    '''DBNE:  Decrement byte var and branch if not zero, 28 cycles'''
    check_cpu(6); tryhop(3); emit(0x32, check_br(d), check_zp(v))
@vasm
def DOKEI(d):
    '''DOKEI: Doke immediate word into address contained in [vAC], 30 cycles'''
    check_cpu(6); tryhop(2); d=int(v(d)); emit(0x37, hi(d), lo(d))
@vasm
def PEEKV(d):
    '''PEEKV: Read byte from address contained in var, 30 cycles'''
    check_cpu(6); tryhop(2); emit(0x39, check_zp(d))
@vasm
def DEEKV(d):
    '''DEEKV: Read word from address contained in var, 28 cycles'''
    check_cpu(6); tryhop(2); emit(0x3b, check_zp(d))
@vasm
def XORBI(imm,d):
    '''XORBI: var.lo ^= imm, 28 cycles'''
    check_cpu(6); tryhop(2); emit(0x3d, check_zp(imm), check_zp(d))
@vasm
def ANDBA(d):
    '''ANDBA: vAC &= var.lo, 24 cycles'''
    check_cpu(6); tryhop(2); emit(0x42, check_zp(d))
@vasm
def ORBA(d):
    '''ORBA: vAC |= var.lo, 22 cycles'''
    check_cpu(6); tryhop(2); emit(0x44, check_zp(d))
@vasm
def XORBA(d):
    '''XORBA: vAC ^= var.lo, 22 cycles'''
    check_cpu(6); tryhop(2); emit(0x46, check_zp(d))
@vasm
def NOTB(d):
    '''NOTB: var.lo = var.lo ^ 0xff, 22 cycles'''
    check_cpu(6); tryhop(2); emit(0x48, check_zp(d))
@vasm
def DOKEp(d):
    '''DOKE+: doke word in vAC to address contained in var, var += 2, 30 cycles'''
    check_cpu(6); tryhop(2); emit(0x4a, check_zp(d))
@vasm
def MOVQW(imm,d):
    '''MOVQW: Load a word var with a small constant 0..255, 30 cycles'''
    check_cpu(6); tryhop(2); emit(0x5b, check_zp(imm), check_zp(d))
@vasm
def DEEKp(d):
    '''DEEK+: Deek word at address contained in var, var += 2, 30 cycles'''
    check_cpu(6); tryhop(2); emit(0x60, check_zp(d))
@vasm
def MOV(s,d):
    '''MOV: Moves a byte from src var to dst var, 28 cycles'''
    check_cpu(6); tryhop(2); emit(0x65, check_zp(d), check_zp(s))
@vasm
def PEEKA(d):
    '''PEEKA: Peek a byte from [vAC] to var, 24 cycles'''
    check_cpu(6); tryhop(2); emit(0x67, check_zp(d))
@vasm
def POKEA(d):
    '''POKEA: Poke a byte from var to [vAC], 22 cycles'''
    check_cpu(6); tryhop(2); emit(0x69, check_zp(d))
@vasm
def TEQ(d):
    '''TEQ: Test for EQ, returns 0x0000 or 0x0001 in var, 28 cycles'''
    check_cpu(6); tryhop(2); emit(0x6b, check_zp(d))
@vasm
def TNE(d):
    '''TEQ: Test for NE, returns 0x0000 or 0x0001 in var, 28 cycles'''
    check_cpu(6); tryhop(2); emit(0x6d, check_zp(d))
@vasm
def DEEKA(d):
    '''DEEKA: Deek a word from [vAC] to var, 30 cycles'''
    check_cpu(6); tryhop(2); emit(0x6f, check_zp(d))
@vasm
def SUBBA(d):
    '''SUBBA: vAC -= var.lo, 28 cycles'''
    check_cpu(6); tryhop(2); emit(0x77, check_zp(d))
@vasm
def INCW(d):
    '''INCW: Increment word var, 26 cycles'''
    check_cpu(6); tryhop(2); emit(0x79, check_zp(d))
@vasm
def DECW(d):
    '''DECW: Decrement word var, 26 cycles'''
    check_cpu(6); tryhop(2); emit(0x7b, check_zp(d))
@vasm
def DOKEA(d):
    '''DOKEA: Doke a word from var to [vAC], 30 cycles'''
    check_cpu(6); tryhop(2); emit(0x7d, check_zp(d))
@vasm
def NOTW(d):
    '''NOTW: Boolean invert var'''
    check_cpu(6); tryhop(2); emit(0x8a, check_zp(d))
@vasm
def DBGE(v, d):
    '''DBGE:  Decrement byte var and branch if >= 0, 30 cycles'''
    check_cpu(6); tryhop(3); emit(0x8e, check_br(d), check_zp(v))
@vasm
def ORBI(imm,d):
    '''ORBI: OR immediate byte with byte var, result in byte var, 28 cycles'''
    check_cpu(6); tryhop(2); emit(0x95, check_zp(imm), check_zp(d))
@vasm
def LDNI(d):
    '''LDNI: Load an 8bit immediate as a negative 16bit immediate into vAC'''
    check_cpu(6); tryhop(2); emit(0x9c, check_zp(d))
@vasm
def ANDBK(d,imm):
    '''ANDBK: vAC = var & imm'''
    check_cpu(6); tryhop(2); emit(0x9e, check_zp(imm), check_zp(d))
@vasm
def ORBK(d,imm):
    '''ORBK: vAC = var | imm'''
    check_cpu(6); tryhop(2); emit(0xa0, check_zp(imm), check_zp(d))
@vasm
def XORBK(d,imm):
    '''XORBK: vAC = var ^ imm'''
    check_cpu(6); tryhop(2); emit(0xa2, check_zp(imm), check_zp(d))
@vasm
def PEEKAp(d):
    '''PEEKA+: Peek a byte from [vAC] to var, incw vAC, 26 to 30 cycles'''
    check_cpu(6); tryhop(2); emit(0xa4, check_zp(d))
@vasm
def CMPI(d,imm):
    '''CMPI: Compare byte variable to 8bit immediate, 30 cycles'''
    check_cpu(6); tryhop(2); emit(0xa7, check_zp(imm), check_zp(d))
@vasm
def JEQ(d):
    '''JEQ: jump to 16bit address if vAC=0, 26 cycles'''
    check_cpu(6); tryhop(3); d=int(v(d)); emit(0xbb, lo(d-2), hi(d))
@vasm
def JNE(d):
    '''JNE: jump to 16bit address if vAC!=0, 26 cycles'''
    check_cpu(6); tryhop(3); d=int(v(d)); emit(0xbd, lo(d-2), hi(d))
@vasm
def JLT(d):
    '''JLT: jump to 16bit address if vAC<0, 24 to 26 cycles'''
    check_cpu(6); tryhop(3); d=int(v(d)); emit(0xbf, lo(d-2), hi(d))
@vasm
def JGT(d):
    '''JGT: jump to 16bit address if vAC>0, 24 to 26 cycles'''
    check_cpu(6); tryhop(3); d=int(v(d)); emit(0xc1, lo(d-2), hi(d))
@vasm
def JLE(d):
    '''JLE: jump to 16bit address if vAC<=0, 24 to 28 cycles'''
    check_cpu(6); tryhop(3); d=int(v(d)); emit(0xc3, lo(d-2), hi(d))
@vasm
def JGE(d):
    '''JGE: jump to 16bit address if vAC>=0, 22 to 26 cycles'''
    check_cpu(6); tryhop(3); d=int(v(d)); emit(0xc5, lo(d-2), hi(d))
@vasm
def POKEp(d):
    '''POKE+: Poke byte in vAC to address contained in var, inc var, 30 cycles'''
    check_cpu(6); tryhop(2); emit(0xd1, check_zp(d))
@vasm
def NEGW(d):
    '''NEGW: Arithmetic negate var'''
    check_cpu(6); tryhop(2); emit(0xd3, check_zp(d))
@vasm
def TGE(d):
    '''TEQ: Test for GE, returns 0x0000 or 0x0001 in var, 28 cycles'''
    check_cpu(6); tryhop(2); emit(0xd5, check_zp(d))
@vasm
def TLT(d):
    '''TLT: Test for LT, returns 0x0000 or 0x0001 in var, 28 cycles'''
    check_cpu(6); tryhop(2); emit(0xd7, check_zp(d))
@vasm
def TGT(d):
    '''TGT: Test for GT, returns 0x0000 or 0x0001 in var, 28 cycles'''
    check_cpu(6); tryhop(2); emit(0xd9, check_zp(d))
@vasm
def TLE(d):
    '''TLE: Test for LE, returns 0x0000 or 0x0001 in var, 28 cycles'''
    check_cpu(6); tryhop(2); emit(0xdb, check_zp(d))
@vasm
def ANDBI(imm,d):
    '''ANDBI: And immediate byte with byte var, result in byte var, 28 cycles'''
    check_cpu(6); tryhop(2); emit(0xdd, check_zp(imm), check_zp(d))
@vasm
def SUBBI(imm,d):
    '''SUBBI: Subtract a constant 0..255 from a byte var, 28 cycles'''
    check_cpu(6); tryhop(2); emit(0xe1, check_zp(imm), check_zp(d))
@vasm
def ST2(d):
    '''ST2: Store vAC.lo into 16bit immediate address, (26 + 26 cycles)'''
    check_cpu(6); tryhop(4); d=int(v(d)); emit(0xc7, 0x11, lo(d), hi(d))
@vasm
def STW2(d):
    '''STW2: Store vAC into 16bit immediate address, (26 + 28 cycles)'''
    check_cpu(6); tryhop(4); d=int(v(d)); emit(0xc7, 0x14, lo(d), hi(d))
@vasm
def XCHG(s,d):
    '''XCHG: Swap two zero byte variables, (26 + 30 cycles)'''
    check_cpu(6); tryhop(4); d=int(v(d)); emit(0xc7, 0x17, check_zp(s), check_zp(d))
@vasm
def MOVW(s,d):
    '''MOVW: Move 16bits from src zero page var to dst zero page var, (26 + 28 cycles)'''
    check_cpu(6); tryhop(4); d=int(v(d)); emit(0xc7, 0x19, check_zp(s), check_zp(d))
@vasm
def ADDWI(d):
    '''ADDWI: vAC += immediate 16bit value, (26 + 28 cycles)'''
    check_cpu(6); tryhop(4); d=int(v(d)); emit(0xc7, 0x1b, lo(d), hi(d))
@vasm
def SUBWI(d):
    '''SUBWI: vAC -= immediate 16bit value, (26 + 28 cycles)'''
    check_cpu(6); tryhop(4); d=int(v(d)); emit(0xc7, 0x1d, lo(d), hi(d))
@vasm
def ANDWI(d):
    '''ANDWI: vAC &= immediate 16bit value, (26 + 26 cycles)'''
    check_cpu(6); tryhop(4); d=int(v(d)); emit(0xc7, 0x1f, lo(d), hi(d))
@vasm
def ORWI(d):
    '''ORWI: vAC |= immediate 16bit value, (26 + 22 cycles)'''
    check_cpu(6); tryhop(4); d=int(v(d)); emit(0xc7, 0x21, lo(d), hi(d))
@vasm
def XORWI(d):
    '''XORWI: vAC &= immediate 16bit value, (26 + 22 cycles)'''
    check_cpu(6); tryhop(4); d=int(v(d)); emit(0xc7, 0x23, lo(d), hi(d))
@vasm
def LDPX(a,c):
    '''LDPX: Load Pixel, <address var>, <colour var>, (26 + 30 cycles)'''
    check_cpu(6); tryhop(4); d=int(v(d)); emit(0xc7, 0x25, check_zp(a), check_zp(c))
@vasm
def STPX(a,c):
    '''STPX: Store Pixel, <address var>, <colour var>, (26 + 28 cycles)'''
    check_cpu(6); tryhop(4); d=int(v(d)); emit(0xc7, 0x28, check_zp(a), check_zp(c))
@vasm
def CONDI(i,j):
    '''CONDI: chooses immediate operand based on condition, (vAC == 0), (26 + 26 cycles)'''
    check_cpu(6); tryhop(4); d=int(v(d)); emit(0xc7, 0x2b, check_zp(i), check_zp(j))
@vasm
def CONDB(v,w):
    '''CONDB: chooses zero page byte var based on condition, (vAC == 0), (26 + 28 cycles)'''
    check_cpu(6); tryhop(4); d=int(v(d)); emit(0xc7, 0x2d, check_zp(v), check_zp(w))
@vasm
def CONDIB(i,v):
    '''CONDIB: chooses between imm and zero page byte var based on condition, (vAC == 0), (28 + 26 cycles)'''
    check_cpu(6); tryhop(4); d=int(v(d)); emit(0xc7, 0x30, check_zp(i), check_zp(v))
@vasm
def CONDBI(v,i):
    '''CONDBI: chooses between zero page byte var and imm based on condition, (vAC == 0), (28 + 26 cycles)'''
    check_cpu(6); tryhop(4); d=int(v(d)); emit(0xc7, 0x33, check_zp(v), check_zp(i))

@vasm
def _SP(n):
    '''Pseudo-instruction to compute SP relative addresses'''
    n = v(n)
    if is_zero(n):
        LDW(SP);
    elif isinstance(n,int) and not isinstance(n,Unk) and n < 0 and n > -256:
        LDW(SP); SUBI(-n)
    else:
        _LDI(n); ADDW(SP)
@vasm
def _LDI(d):
    '''Emit LDI or LDWI depending on the size of d.'''
    d = v(d)
    if is_zeropage(d):
        LDI(d)
    elif args.cpu >= 6 and is_zeropage(-d):
        LDNI(-d)
    else:
        LDWI(d)
@vasm
def _LDW(d):
    '''Emit LDW or LDWI+DEEK depending on the size of d.'''
    d = v(d)
    if is_zeropage(d):
        LDW(d)
    else:
        _LDI(d); DEEK()
@vasm
def _LD(d):
    '''Emit LD or LDWI+PEEK depending on the size of d.'''
    d = v(d)
    if is_zeropage(d):
        LD(d)
    else:
        _LDI(d); PEEK()
@vasm
def _SHLI(imm):
    '''Shift vAC left by imm positions'''
    imm &= 0xf
    if (imm & 0x8):
        ST('vACH');ORI(255);XORI(255)
        imm &= 0x7
    # too much overhead calling SYS_LSLW4_46
    for i in range(0, imm):
        LSLW()
@vasm
def _SHRIS(imm):
    '''Shift vAC right (signed) by imm positions'''
    imm &= 0xf
    if imm == 8:
        LD(vACH);XORI(128); SUBI(128)
    elif imm == 1:
        extern("_@_shrs1")
        _CALLI("_@_shrs1")           # T3 << 1 -> vAC
    else:
        STW(T3); LDI(imm)
        extern('_@_shrs')
        _CALLI('_@_shrs')            # T3 << AC -> vAC
@vasm
def _SHRIU(imm):
    '''Shift vAC right (unsigned) by imm positions'''
    imm &= 0xf
    if imm == 8:
        LD(vACH)
    elif imm == 1:
        extern("_@_shru1")
        _CALLI("_@_shru1")
    else:
        STW(T3); LDI(imm)
        extern('_@_shru')
        _CALLI('_@_shru')       # T3 << AC -> vAC
@vasm
def _SHL(d):
    '''Shift vAC left by [d] positions'''
    STW(T3); LDW(d)
    extern('_@_shl') 
    _CALLI('_@_shl')            # T3 << AC -> vAC
@vasm
def _SHRS(d):
    '''Shift vAC right, signed, by [d] positions'''
    STW(T3); LDW(d)
    extern('_@_shrs')
    _CALLI('_@_shrs')           # T3 >> AC --> vAC
@vasm
def _SHRU(d):
    '''Shift vAC right, unsigned, by [d] positions'''
    STW(T3); LDW(d)
    extern('_@_shru')
    _CALLI('_@_shru')           # T3 >> AC --> vAC
@vasm
def _MUL(d):
    STW(T3); LDW(d)
    extern('_@_mul')
    _CALLI('_@_mul')            # T3 * AC --> vAC
@vasm
def _MULI(d):
    STW(T3);_LDI(d)
    extern('_@_mul')
    _CALLI('_@_mul')            # T3 * AC --> vAC
@vasm
def _DIVS(d):
    STW(T3); LDW(d)
    extern('_@_divs')
    _CALLI('_@_divs')           # T3 / AC --> vAC
@vasm
def _DIVU(d):
    STW(T3); LDW(d)
    extern('_@_divu')
    _CALLI('_@_divu')           # T3 / AC --> vAC
@vasm
def _MODS(d):
    STW(T3); LDW(d)
    extern('_@_mods')
    _CALLI('_@_mods')           # T3 % vAC --> vAC
@vasm
def _MODU(d):
    STW(T3); LDW(d)
    extern('_@_modu')
    _CALLI('_@_modu')           # T3 % vAC --> vAC
@vasm
def _DIVIS(d):
    STW(T3);_LDI(d)
    extern('_@_divs')
    _CALLI('_@_divs')           # T3 / AC --> vAC
@vasm
def _DIVIU(d):
    STW(T3);_LDI(d)
    extern('_@_divu')
    _CALLI('_@_divu')           # T3 / AC --> vAC
@vasm
def _MODIS(d):
    STW(T3);_LDI(d)
    extern('_@_mods')
    _CALLI('_@_mods')           # T3 % vAC --> vAC
@vasm
def _MODIU(d):
    STW(T3);_LDI(d)
    extern('_@_modu')
    _CALLI('_@_modu')           # T3 % vAC --> vAC
@vasm
def _MOV(s,d):
    '''Move word from reg/addr s to d. 
       Also accepts [vAC] for s or d.
       Can trash T2 and T3'''
    s = v(s)
    d = v(d)
    if s != d:
        if args.cpu >= 6 and s == [vAC] and is_zeropage(d):
            DEEKA(d)
        elif args.cpu >= 6 and is_zeropage(s) and d == [vAC]:
            DOKEA(s)
        elif d == [vAC]:
            STW(T3)
            if s != vAC:
                _LDW(s)
            DOKE(T3)
        elif is_zeropage(d):
            if s == [vAC]:
                DEEK()
            elif s != vAC:
                _LDW(s)
            if d != vAC:
                STW(d)
        elif s == vAC or s == [vAC]:
            if s == [vAC]:
                DEEK()
            if args.cpu >= 6:
                STW2(d)
            else:
                STW(T3); _LDI(d); STW(T2);
                LDW(T3); DOKE(T2)
        elif args.cpu >= 6:
            _LDW(s); STW2(d)
        else:
            _LDI(d); STW(T2); _LDW(s); DOKE(T2)
@vasm
def _BRA(d):
    emitjump(v(d))
@vasm
def _BEQ(d):
    emitjcc(BEQ, BNE, JEQ, v(d))
@vasm
def _BNE(d):
    emitjcc(BNE, BEQ, JNE, v(d))
@vasm
def _BLT(d):
    emitjcc(BLT, BGE, JLT, v(d))
@vasm
def _BGT(d):
    emitjcc(BGT, BLE, JGT, v(d))
@vasm
def _BLE(d):
    emitjcc(BLE, BGT, JLE, v(d))
@vasm
def _BGE(d):
    emitjcc(BGE, BLT, JGE, v(d))
@vasm
def _CMPIS(d):
    '''Compare vAC (signed) with immediate in range 0..255'''
    if args.cpu >= 5:
        CMPHS(0); SUBI(d)
    else:
        lbl = genlabel()
        tryhop(5)
        BLT(lbl)
        SUBI(d)
        label(lbl, hop=0)
@vasm
def _CMPIU(d):
    '''Compare vAC (unsigned) with immediate in range 0..255'''
    if args.cpu >= 5:
        CMPHU(0); SUBI(d)
    else:
        lbl = genlabel()
        tryhop(8)
        BGE(lbl)
        LDWI(0x100)
        label(lbl, hop=0)
        SUBI(d)
@vasm
def _CMPWS(d):
    '''Compare vAC (signed) with register.'''
    if args.cpu >= 5:
        CMPHS(d+1); SUBW(d)
    else:
        lbl1 = genlabel()
        lbl2 = genlabel()
        # no hops because cpu4 long jumps also use -2(vSP)
        tryhop(18)
        STLW(-2); XORW(d); BGE(lbl1)
        LDLW(-2); ORI(1); BRA(lbl2)
        label(lbl1)
        LDLW(-2); SUBW(d)
        label(lbl2, hop=0)
@vasm
def _CMPWU(d):
    '''Compare vAC (unsigned) with register.'''
    if args.cpu >= 5:
        CMPHU(d+1); SUBW(d)
    else:
        lbl1 = genlabel()
        lbl2 = genlabel()
        # no hops because cpu4 long jumps also use -2(vSP)
        tryhop(18)
        STLW(-2); XORW(d); BGE(lbl1)
        LDW(d); ORI(1); BRA(lbl2)
        label(lbl1)
        LDLW(-2); SUBW(d)
        label(lbl2, hop=0)
@vasm
def _BMOV(s,d,n):
    '''Move memory block of size n from addr s to d.
       Also accepts [vAC] as s and [vAC] or [T2] as d.'''
    d = v(d)
    s = v(s)
    n = v(n)
    if s != d:
        if d == [vAC]:
            STW(T2)
        if s == [vAC]:
            STW(T3)
        if d != [vAC] and d != [T2]:
            _LDI(d); STW(T2)
        if s != [vAC]:
            _LDI(s); STW(T3)
        _LDI(n);ADDW(T3);STW(T1)
        extern('_@_bcopy')
        _CALLI('_@_bcopy')         # [T3..T1) --> [T2..]
@vasm
def _LMOV(s,d):
    '''Move long from reg/addr s to d.
       Also accepts [vAC] as argument s or d.
       Also accept [T2] as argument d.
       Can trash T2 and T3'''
    s = v(s)
    d = v(d)
    if s != d:
        if is_zeropage(d, 3):
            if is_zeropage(s, 3):
                LDWI(((d & 0xff) << 8) | (s & 0xff))
                extern('_@_lcopyz')
                _CALLI('_@_lcopyz')                  # z->z :  6 bytes
            elif args.cpu > 5:
                if s != [vAC]:
                    _LDI(s)
                DEEKA(d); ADDI(2); DEEKA(d+2)        # a|l->z: 6|9 bytes (cpu6)
            elif s != [vAC]:
                _LDW(s); STW(d);
                _LDW(s+2); STW(d+2)                  # l->z:   12 bytes
            else:
                STW(T3); LDI(d); STW(T2);
                extern('_@_lcopy')
                _CALLI('_@_lcopy')                   # a->l:   9 bytes
        elif is_zeropage(s, 3) and args.cpu > 5:
            if d == [T2]:
                LDW(T2)
            elif d != [vAC]:
                _LDI(d)
            DOKEA(s); ADDI(2); DOKEA(s+2)            # z->a|l: 6-9 bytes (cpu 6)
        else:
            if d == [vAC]:
                STW(T2)
            if s == [vAC]:
                STW(T3)
            if d != [vAC] and d != [T2]:
                _LDI(d); STW(T2)
            if s != [vAC]:                            # generic call sequence
                _LDI(s); STW(T3)                      # is 5-13 bytes long
            extern('_@_lcopy')
            _CALLJ('_@_lcopy')  # [T3..T3+4) --> [T2..T2+4)
@vasm
def _LADD():
    extern('_@_ladd')              
    _CALLI('_@_ladd')              # LAC+[vAC] --> LAC
@vasm
def _LSUB():
    extern('_@_lsub') 
    _CALLI('_@_lsub')              # LAC-[vAC] --> LAC
@vasm
def _LMUL():
    extern('_@_lmul')
    _CALLI('_@_lmul')              # LAC*[vAC] --> LAC
@vasm
def _LDIVS():
    extern('_@_ldivs')
    _CALLI('_@_ldivs')              # LAC/[vAC] --> LAC
@vasm
def _LDIVU():
    extern('_@_ldivu')
    _CALLI('_@_ldivu')              # LAC/[vAC] --> LAC
@vasm
def _LMODS():
    extern('_@_lmods')
    _CALLI('_@_lmods')              # LAC%[vAC] --> LAC
@vasm
def _LMODU():
    extern('_@_lmodu')
    _CALLI('_@_lmodu')              # LAC%[vAC] --> LAC
@vasm
def _LSHL():
    extern('_@_lshl')
    _CALLI('_@_lshl')               # LAC<<vAC --> LAC
@vasm
def _LSHRS():
    extern('_@_lshrs')
    _CALLI('_@_lshrs')              # LAC>>vAC --> LAC
@vasm
def _LSHRU():
    extern('_@_lshru')
    _CALLI('_@_lshru')              # LAC>>vAC --> LAC
@vasm
def _LNEG():
    extern('_@_lneg')
    _CALLJ('_@_lneg')              # -LAC --> LAC
@vasm
def _LCOM():
    extern('_@_lcom')
    _CALLJ('_@_lcom')               # ~LAC --> LAC
@vasm
def _LAND():
    extern('_@_land')
    _CALLI('_@_land')               # LAC&[vAC] --> LAC
@vasm
def _LOR():
    extern('_@_lor')
    _CALLI('_@_lor')                # LAC|[vAC] --> LAC
@vasm
def _LXOR():
    extern('_@_lxor')
    _CALLI('_@_lxor')               # LAC^[vAC] --> LAC
@vasm
def _LCMPS():
    extern('_@_lcmps')
    _CALLI('_@_lcmps')              # SGN(LAC-[vAC]) --> vAC
@vasm
def _LCMPU():
    extern('_@_lcmpu')
    _CALLI('_@_lcmpu')              # SGN(LAC-[vAC]) --> vAC
@vasm
def _LCMPX():
    extern('_@_lcmpx')
    _CALLI('_@_lcmpx')              # TST(LAC-[vAC]) --> vAC
@vasm
def _LCVI():
    extern('_@_lcvi')
    _CALLI('_@_lcvi')               # AC -> LAC (signed)
@vasm
def _FMOV(s,d):
    '''Move float from reg s to d with special cases when s or d is FAC.
       Also accepts [vAC] as argument s or d.
       Also accept [T2] as argument d.
       Can trash T2 and T3'''
    s = v(s)
    d = v(d)
    if s != d:
        if d == FAC:
            if s != [vAC]:
                _LDI(s)
            extern('_@_fldfac')
            _CALLI('_@_fldfac')   # [vAC..vAC+5) --> FAC
        elif s == FAC:
            if d != [vAC]:
                _LDI(d)
            extern('_@_fstfac')
            _CALLI('_@_fstfac')   # FAC --> [vAC..vAC+5)
        elif is_zeropage(d, 4) and is_zeropage(s, 4):
            LDWI(((d & 0xff) << 8) | (s & 0xff))
            extern('_@_fcopyz')
            _CALLI('_@_fcopyz')
        else:
            maycross=False
            if d == [vAC]:
                STW(T2)
                maycross = True
            if s == [vAC]:
                STW(T3)
                maycross = True
            if d != [vAC] and d != [T2]:
                _LDI(d); STW(T2)
                maycross = maycross or (int(d) & 0xfc == 0xfc)
            if s != [vAC]:
                _LDI(s); STW(T3)
                maycross = maycross or (int(s) & 0xfc == 0xfc)
            if maycross:
                extern('_@_fcopy')       # [T3..T3+5) --> [T2..]
                _CALLJ('_@_fcopy')
            else:
                extern('_@_fcopync')     # [T3..T3+5) --> [T2..]
                _CALLJ('_@_fcopync')     # without page crossing!
@vasm
def _FADD():
    extern('_@_fadd')
    _CALLI('_@_fadd')               # FAC+[vAC] --> FAC
@vasm
def _FSUB():
    extern('_@_fsub')
    _CALLI('_@_fsub')               # FAC-[vAC] --> FAC
@vasm
def _FMUL():
    extern('_@_fmul')
    _CALLI('_@_fmul')               # FAC*[vAC] --> FAC
@vasm
def _FDIV():
    extern('_@_fdiv')
    _CALLI('_@_fdiv')               # FAC/[vAC] --> FAC
@vasm
def _FNEG():
    extern('_@_fneg')
    _CALLJ('_@_fneg')               # -FAC --> FAC
@vasm
def _FCMP():
    extern('_@_fcmp')
    _CALLI('_@_fcmp')               # SGN(FAC-[vAC]) --> vAC
@vasm
def _FTOU():
    extern('_@_ftou')
    _CALLJ('_@_ftou')
@vasm
def _FTOI():
    extern('_@_ftoi')
    _CALLJ('_@_ftoi')
@vasm
def _FCVI():
    extern('_@_fcvi')
    _CALLJ('_@_fcvi')
@vasm
def _FCVU():
    extern('_@_fcvu')
    _CALLJ('_@_fcvu')
@vasm
def _FSCALB():
    extern('_@_fscalb')
    _CALLI('_@_fscalb')

@vasm
def _CALLI(d):
    '''Call subroutine at far location d.
       - For cpu >= 5. this function just emits a CALLI instruction
       - For cpu < 5, this function trashes 'sysArgs6', 'sysArgs7' and [SP-2].'''
    if args.cpu >= 5:
        CALLI(d)
    else:
        # no hops because cpu4 long jumps also use -2(vSP)
        tryhop(11);STLW(-2);LDWI(d);STW('sysArgs6');LDLW(-2);CALL('sysArgs6')
@vasm
def _CALLJ(d):
    '''Call subroutine at far location d. 
       - For cpu >= 5. this function just emits a CALLI instruction
       - For cpu < 5, this function trashes vAC.'''
    if args.cpu >= 5:
        CALLI(d)
    else:
        tryhop(5);LDWI(d);CALL(vAC)
@vasm
def _PROLOGUE(framesize,maxargoffset,mask):
    '''Function prologue'''
    if args.cpu >= 5:
        tryhop(4);LDW(vLR);DOKE(SP);_SP(-framesize);STW(SP)
        if mask:
            ADDI(maxargoffset)
            extern('_@_save_%02x' % mask)
            _CALLI('_@_save_%02x' % mask)
    else:
        tryhop(4);LDW(vLR);DOKE(SP);_SP(-framesize);STW(SP)
        if mask:
            ADDI(maxargoffset);STW(T3)
            extern('_@_save_%02x' % mask)
            _CALLJ('_@_save_%02x' % mask)
@vasm
def _EPILOGUE(framesize,maxargoffset,mask,saveAC=False):
    '''Function epilogue'''
    if saveAC:
        STW(T2);
    diff = framesize - maxargoffset;
    _SP(framesize);STW(SP);
    if diff >= 0 and diff < 256:
        SUBI(diff)
    else:
        _SP(-framesize);
    extern('_@_rtrn_%02x' % mask)
    if args.cpu >= 5:
        _CALLI('_@_rtrn_%02x' % mask)
    else:
        STW(T3)
        _CALLJ('_@_rtrn_%02x' % mask)
        
# ------------- reading .s/.o/.a files
        
              
def read_file(f):
    '''Reads a .s/.o/.a file in a pristine environment'''
    global the_module, the_fragment, new_modules, module_list
    debug(f"reading '{f}'")
    with open(f, 'r') as fd:
        s = fd.read()
        try: 
            c = compile(s, f, 'exec')
        except SyntaxError as err:
            fatal(str(err))
    the_module = None
    the_fragment = None
    new_modules = []
    exec(c, new_globals())
    if len(new_modules) == 0:
        warning(f"file {f} did not define any module")
    if f.endswith(".a") or len(new_modules) > 1:
        libid = id(new_modules[0])
        libname = os.path.basename(f)
        for m in new_modules:
            m.library = libid
            m.fname = f"{libname}({m.name})"
    module_list += new_modules
    new_modules = []

def search_file(fn, path):
    '''Searches a file along a given path.'''
    for d in path:
        f = os.path.join(d, fn)
        if os.access(f, os.R_OK):
            return f
    return None
        
def read_lib(l):
    '''Search a library file along the library path and read it.'''
    f = search_file(f"lib{l}.a", args.L)
    if not f:
        fatal(f"library -l{l} not found!")
    return read_file(f)

def read_map(m):
    '''Read a linker map file.'''
    dn = os.path.dirname(__file__)
    fn = os.path.join(dn, f"map{m}", "map.py")
    if not os.access(fn, os.R_OK):
        fatal(f"cannot find linker map '{m}'")
    with open(fn, 'r') as fd:
        exec(compile(fd.read(), fn, 'exec'), globals())
    if not map_segments:
        fatal(f"map '{m}' does not define 'map_segments'")

def read_interface():
    '''Read `interface.json' as known symbols.'''
    global symdefs
    with open(os.path.join(lccdir,'interface.json')) as file:
        for (name, value) in json.load(file).items():
            symdefs[name] = value if isinstance(value, int) else int(value, base=0)

def get_rominfo(roms, rom):
    ri = roms[rom]
    if 'inherits' in ri:
        if ri['inherits'] not in roms:
            fatal(f"roms.json: rom '{rom}' inherits from an unknown rom")
        else:
            rj = get_rominfo(roms, ri['inherits'])
            for k in rj:
                if k not in ri:
                    ri[k] = rj[k]
            ri.pop('inherits')
    return ri
            
def read_rominfo(rom):
    '''Read `rom.jsom' to translate rom names into romType byte and cpu version.'''
    global rominfo, romtype, romcpu
    with open(os.path.join(lccdir,'roms.json')) as file:
        rominfo = get_rominfo(json.load(file), rom)
    if rominfo and 'romType' in rominfo and 'cpu' in rominfo:
        romtype = int(str(rominfo['romType']),0)
        romcpu = int(str(rominfo['cpu']),0)
    else:
        print(f"glink: warning: rom '{args.rom}' is not recognized", file=sys.stderr)
        rominfo = {}
    if romcpu and args.cpu and args.cpu > romcpu:
        print(f"glink: warning: rom '{args.rom}' does not implement cpu{args.cpu}", file=sys.stderr)
    


# ------------- compute code closure from import/export information

def find_exporters(sym):
    elist = []
    # collect all modules that export sym
    for m in module_list:
        if sym in m.exports:
            elist.append(m)
    if not elist:
        # otherwise find an input file(not a library) that has a common named sym.
        for m in module_list:
            if not m.library:
                for f in m.code:
                    if f[0] == 'COMMON' and f[1] == sym:
                        return [ m ]
    return elist

def measure_data_fragment(m, frag):
    global the_module, the_fragment, the_pc
    the_module = m
    the_fragment = frag
    the_pc = 0
    try:
        frag[2]()
    except Exception as err:
        fatal(str(err), exc=True)
    return frag[0:3] + (the_pc,) + frag[4:]

def measure_code_fragment(m, frag):
    global the_module, the_fragment, the_pc
    global lbranch_counter, short_function
    the_module = m
    the_fragment = frag
    the_pc = 0
    lbranch_counter = 0
    short_function = False
    try:
        frag[2]()
    except Exception as err:
        fatal(str(err), exc=True)
    function_size = the_pc - lbranch_counter
    if short_function:
        fname = frag[1]
        ftype = is_placed(short_function)
        ftype = f"org:{hex(ftype)}" if ftype else "nohop"
        debug(f"- code fragment '{fname}' is {function_size} bytes long ({ftype})")
        if function_size >= 256:
            error("code fragment '{fname}' declared '{ftype}' but is too long")
    else:
        debug(f"- code fragment '{frag[1]}' is {function_size}+{lbranch_counter} bytes long")
    frag = frag[0:3] + (the_pc - lbranch_counter, short_function)
    return frag

def measure_fragments(m):
    for (i,frag) in enumerate(m.code):
        fragtype = frag[0]
        if fragtype in ('DATA', 'BSS') and frag[3] == 0:
            m.code[i] = measure_data_fragment(m, frag)
        elif fragtype in ('CODE'):
            m.code[i] = measure_code_fragment(m, frag)
    the_module = None
    the_fragment = None

def compute_closure():
    global module_list, exporters
    # compute closure from start symbol
    implist = [ args.e ]
    for sym in implist:
        if sym in exporters:
            pass
        elif sym in symdefs:
            pass
        else:
            e = None
            elist = find_exporters(sym)
            for m in elist:
                if m.library:                      # rules for selecting one of many library 
                    if e and not e.library:        # modules exporting a same required symbol:
                        pass                       # -- cannot override a non-library module
                    elif m.cpu > args.cpu:         # -- ignore exports when module targets too high a cpu.
                        pass                       # -- prefers exports targeting a higher cpu within a same library.
                    elif not e or (m.library == e.library and m.cpu > e.cpu):
                        e = m
                else:                              # complain when a required symbol is exported
                    if e and not e.library:        # by multiple non-library files.
                        error(f"symbol '{sym}' is exported by both '{e.fname}' and '{m.fname}'", dedup=True)
                    e = m
            if e:
                debug(f"including module '{e.fname}' for symbol '{sym}'")
                e.used = True
                for sym in e.exports:              # register all symbols exported by the selected module
                    if sym in exporters:           # -- warn about possible conflicts
                        error(f"symbol '{sym}' is exported by both '{e.fname}' and '{exporters[sym].fname}'", dedup=True)
                    if sym not in exporters or exporters[sym].library:
                        exporters[sym] = e
                measure_fragments(e)               # -- check all fragment code, compute missing lengths or exports
                for sym in e.imports:
                    implist.append(sym)            # -- add all its imports to the list of required imports
    # recompute module_list
    nml = []
    for m in module_list:
        if m.used:
            nml.append(m)
        elif not m.library:
            warning(f"file '{m.fname}' was not used")
    return nml

def convert_common_symbols():
    '''Common symbols are instanciated in one of the module
       and referenced by the other modules.'''
    for m in module_list:
        for (i,decl) in enumerate(m.code):
            if decl[0] == 'COMMON':
                sym = decl[1]
                if sym in exporters:
                    pass
                else:
                    debug(f"instantiating common '{sym}' in '{m.fname}'")
                    m.code[i] = ('BSS', sym) + decl[2:]
                    exporters[sym] = m

def check_undefined_symbols():
    und = {}
    comma = ", "
    for m in module_list:
        for s in m.imports:
            if s not in exporters and s not in symdefs:
                mn = f"'{m.fname}'"
                if s in und:
                    und[s].append(mn)
                else:
                    und[s] = [mn]
    for s in und:
        error(f"undefined symbol '{s}' imported by {comma.join(und[s])}", dedup=True)



# ------------- passes

def round_used_segments():
    '''Split all segments containing code or data into 
       a used segment and a free segment starting on 
       a page boundary. Marks used segment as non-BSS.'''
    for (i,s) in enumerate(segment_list):
        epage = (s.pc + 0xff) & ~0xff
        if s.pc > s.saddr and s.eaddr > epage:
            segment_list.insert(i+1, Segment(epage, s.eaddr, s.flags))
            s.eaddr = epage
            if args.d >= 2:
                debug(f"rounding {segment_list[i:i+2]}")
        if s.pc > s.saddr:
            s.nbss = True
 
def find_data_segment(size, align=None):
    for s in segment_list:
        if s.flags & 0x2:  # not a data segment
            continue
        pc = s.pc
        if align and align > 1:
            pc = align * ((pc + align - 1) // align)
        if s.eaddr - pc > size:
            return s

def find_code_segment(size, addr=None):
    # Since code segments cannot cross page boundaries
    # it is sometimes necessary to carve a code segment from a larger one
    # Argument addr is a requested address.
    size = min(256, size)
    for (i,s) in enumerate(segment_list):
        if addr:
            if addr >= s.saddr and addr < s.eaddr:
                return segment_for_placed_fragment(size, addr, s, i)
            continue
        if s.flags & 0x1:  # not a code segment
            continue
        if s.pc > s.saddr and s.pc + size <= s.eaddr:  # segment has enough free size and does not cross
            return s                                   # a page boundary because it already contains code
        if (s.saddr ^ (s.eaddr-1)) & 0xff00:
            epage = (s.saddr | 0xff) + 1               # segment crosses a page boundary:
            ns = Segment(s.saddr, epage, s.flags)      # carve a non-crossing one and insert it in the list
            s.saddr = s.pc = epage
            segment_list.insert(i, ns)
            s = ns
        if s.pc + size <= s.eaddr:                     # is it large enough?
            return s
    return None

def segment_for_placed_fragment(size, addr, s, i):
    epage = min(s.eaddr, (addr | 0xff) + 1)
    if addr + size > epage:
        error(f"Page overflow for placed fragment {the_fragment[1]}@{hex(addr)}")
    elif s.pc > addr or addr + size > s.eaddr:
        error(f"Requested space for placed fragment {the_fragment[1]}@{hex(addr)} is busy")
    if epage < s.eaddr:                  # - make a single page segment
        ns = Segment(s.saddr, epage, s.flags)
        s.saddr = s.pc = epage
        segment_list.insert(i, ns)
        s = ns
    if addr > s.saddr:                   # - make a segment for [s.saddr,addr)
        ns = Segment(s.saddr, addr, s.flags)
        ns.pc = s.pc
        segment_list.insert(i, ns)
        s.pc = s.saddr = addr
    return s

def assemble_code_fragments(m, placed=False):
    global the_module, the_fragment, the_segment, the_pc
    global hops_enabled, short_function
    the_module = m
    for frag in m.code:
        the_fragment = frag
        if frag[0] == 'CODE':
            shortonly = frag[4]
            addr = is_placed(shortonly)
            if bool(placed) != bool(addr):
                continue
            funcsize = frag[3]
            the_segment = None
            sfst = min(256, args.sfst or 96)
            if shortonly or funcsize <= sfst:
                short_function = True
                hops_enabled = False
                the_segment = find_code_segment(funcsize, addr)
                if shortonly and not the_segment:
                    error(f"cannot find a segment for short code fragment '{frag[1]}' of length {funcsize}")
                if the_segment and (args.d >= 2 or final_pass):
                    debug(f"assembling code fragment '{frag[1]}' at {hex(the_segment.pc)} in {the_segment}")
            if not the_segment:
                short_function = False
                hops_enabled = True
                lfss = args.lfss or 32
                the_segment = find_code_segment(min(lfss, 256))
                if not the_segment:
                    fatal(f"map memory exhausted while fitting code fragment '{frag[1]}'")
                if the_segment and (args.d >= 2 or final_pass):
                    debug(f"assembling code fragment '{frag[1]}' at {hex(the_segment.pc)} in {the_segment}")
            the_pc = the_segment.pc
            try:
                frag[2]()
            except Exception as err:
                fatal(str(err), exc=True)
            the_segment.pc = the_pc

def assemble_data_fragments(m, cseg):
    global the_module, the_fragment, the_segment, hops_enabled, the_pc
    the_module = m
    for frag in m.code:
        the_fragment = frag
        if frag[0] == cseg:
            hops_enabled = False
            the_segment = find_data_segment(frag[3], align=frag[4])
            if not the_segment:
                fatal(f"map memory exhausted while fitting {cseg} fragment '{frag[1]}'")
            elif args.d >= 2 or final_pass:
                debug(f"assembling {cseg} fragment '{frag[1]}' at {hex(the_segment.pc)} in {the_segment}")
            the_pc = the_segment.pc
            try:
                frag[2]()
            except Exception as err:
                fatal(str(err), exc=True)
            the_segment.pc = the_pc
            
def run_pass():
    global the_pass, the_module, the_fragment
    global labelchange_counter, genlabel_counter
    global segment_list, symdefs
    # initialize
    the_pass += 1
    labelchange_counter = 0
    genlabel_counter = 0
    segment_list = []
    for (s,e,d) in map_segments():
        segment_list.append(Segment(s,e,d))
    debug(f"pass {the_pass}")
    # code segments with explicit address
    for m in module_list:
        assemble_code_fragments(m, placed=True)
    # remaining code segments
    for m in module_list:
        assemble_code_fragments(m, placed=False)
    # data segments
    for m in module_list:
        assemble_data_fragments(m, 'DATA')
    round_used_segments()
    # bss segments
    for m in module_list:
        assemble_data_fragments(m, 'BSS')
    # cleanup
    the_module = None
    the_fragment = None

    
def run_passes():
    global final_pass
    final_pass = False
    while labelchange_counter:
        run_pass()
    final_pass = True
    run_pass()


# ------------- final

address_to_segment_cache = {}

def find_segment_for_address(addr):
    if addr in address_to_segment_cache:
        return address_to_segment_cache[addr]
    for s in segment_list:
        if addr >= s.saddr and addr < s.pc:
            address_to_segment_cache[addr] = s
            return s
    fatal(f"internal error: no segment for address {hex(addr)}")

def deek_gt1(addr):
    s = find_segment_for_address(addr)
    o = addr - s.saddr
    return s.buffer[o] + (s.buffer[o+1] << 8)

def doke_gt1(addr, val):
    s = find_segment_for_address(addr)
    o = addr - s.saddr
    s.buffer[o] = val & 0xff
    s.buffer[o+1] = (val >> 8) & 0xff

def process_magic_bss(s, head_module, head_addr):
    '''Construct a linked list of sizeable bss segments to be cleared at runtime.'''
    for s in segment_list:
        if s.pc > s.saddr + 4 and not s.nbss:
            debug(f"BSS segment {hex(s.saddr)}-{hex(s.pc)} will be cleared at runtime")
            size = s.pc - s.saddr
            s.pc = s.saddr + 4
            s.buffer = bytearray(4)
            doke_gt1(s.saddr, size)
            doke_gt1(s.saddr + 2, deek_gt1(head_addr))
            doke_gt1(head_addr, s.saddr)

def process_magic_heap(s, head_module, head_addr):
    '''Construct a linked list of heap segments.'''
    for s in segment_list:
        a0 = (s.pc + 1) & ~0x1
        a1 = s.eaddr &  ~0x1
        if a1 - a0 >= max(24, args.mhss or 24):
            s.buffer.extend(builtins.bytes(4 + (s.pc & 1)))
            doke_gt1(a0, a1 - a0)
            doke_gt1(a0 + 2, deek_gt1(head_addr))
            doke_gt1(head_addr, a0)

def process_magic_list(s, head_module, head_addr):
    '''Constructs a linked list of structures defined in modules.'''
    for m in module_list:
        if m != head_module:
            if s in m.symdefs:
                cons_addr = m.symdefs[s]
                for frag in m.code:
                    if frag[1] == s:
                        break
                if not frag or frag[3] < 4 or frag[4] < 2:
                    return warning(f"ignoring magic symbol '{s}' in {m.fname} (wrong type)")
                doke_gt1(cons_addr + 2, deek_gt1(head_addr))
                doke_gt1(head_addr, cons_addr)

def process_magic_symbols():
    '''
    Magic symbols have names like '__glink_magic_xxx' and cause glink
    to construct a linked list of arbitrary data entries. The head of
    the list must be an *exported* pointer named '__glink_magic_xxx'
    and initialized to the value 0xBEEF. When this happens, glink
    searches each module for a *static* data item named
    '__glink_magic_xxx' large enough to contain at least two
    pointers. The first pointer (car) is left untouched.  The second
    pointer (cdr) is used to construct a linked list.

    The library uses two magic lists for which the
    first pointer is a function pointer:
     * '__glink_magic_init' is a list of initialization
       functions called before main().
     * '__glink_magic_init' is a list of finalization
       functions called by exit().

    In addition, there are two magic lists whose records are 
    not found in modules but allocated by the linker.
     * '__glink_magic_bss' is a linked list of BSS segments
       that must be cleared at runtime. Each list record occupies
       the first 4 bytes of a segment. The first pointer contains
       the segment size. This is used by '_init1.c'.
     * '__glink_magic_heap' is a linked list of heap segments
       for the malloc() function. Each list record occupies
       the first 4 bytes of a segment. The first pointer contains
       the segment size.
    '''
    for s in exporters:
        if s.startswith("__glink_magic_"):
            head_module = exporters[s]
            head_addr = head_module.symdefs[s]
            for frag in head_module.code:
                if frag[0] == 'DATA' and frag[1] == s and frag[3:] != (2,2):
                    return warning(f"ignoring magic symbol '{s}' (list head not a pointer)")
                if deek_gt1(head_addr) != 0xBEEF:
                    return warning(f"ignoring magic symbol '{s}' (list head not 0xBEEF)")
            doke_gt1(head_addr, 0)
            if s == '__glink_magic_bss':
                process_magic_bss(s, head_module, head_addr)
            elif s == '__glink_magic_heap':
                process_magic_heap(s, head_module, head_addr)
            else:
                process_magic_list(s, head_module, head_addr)

def save_gt1(fname, start):
    with open(fname,"wb") as fd:
        seglist = segment_list.copy()
        seglist.sort(key = lambda x : x.saddr)
        for s in seglist:
            if not s.buffer:
                continue
            a0 = s.saddr
            while a0 < s.pc:
                a1 = min(s.eaddr, (a0 | 0xff) + 1)
                buffer = s.buffer[(a0-s.saddr):(a1-s.saddr)]
                fd.write(builtins.bytes((hi(a0),lo(a0),len(buffer)&0xff)))
                fd.write(buffer)
                a0 = a1
        fd.write(builtins.bytes((0, hi(start), lo(start))))
        
def print_symbols(allsymbols=False):
    syms = []
    for m in module_list:
        for s in m.symdefs:
            if allsymbols or not s.startswith('.'):
                exported = (s in exporters) and (exporters[s] == m)
                syms.append((m.symdefs[s], s, exported, m.fname))
    syms.sort(key = lambda x : x[0] )
    print("Symbol table (sorted by address)")
    for s in syms:
        pp="public" if s[2] else "private"
        print(f"\t{s[0]:04x} {pp:<8s}  {s[1]:<22s}  {s[3]:<24s}")

    
# ------------- main function


def main(argv):

    '''Main entry point'''
    global lccdir, args, symdefs, module_list
    try:
        # Obtain LCCDIR
        lccdir = os.path.dirname(os.path.realpath(__file__))
        lccdir = os.getenv("LCCDIR", lccdir)

        ## Parse arguments
        parser = argparse.ArgumentParser(
            conflict_handler='resolve',allow_abbrev=False,
            usage='glink [options] {<files.o>} -l<lib> -o <outfile.gt1>',
            description='Collects gigatron .{s,o,a} files into a .gt1 file.',
            epilog=''' 
            	This program accepts the modules generated by
                gigatron-lcc/rcc (suffix .s or .o). These files are
                text files with a python syntax that construct functions 
                and data structures that defines all the VCPU instructions,
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
        parser.add_argument('files', type=str, nargs='*',
                            help='input files')
        parser.add_argument('-o', type=str, default='a.gt1', metavar='GT1FILE',
                            help='select the output filename (default: a.gt1)')
        parser.add_argument('-cpu', "--cpu", type=int, action='store', default=5,
                            help='select the target cpu version: 4, 5, 6 (default: 5).')
        parser.add_argument('-rom', "--rom", type=str, action='store', default='v5a',
                            help='select the target rom version: v4, v5a (default: v5a).')
        parser.add_argument('-map', "--map", type=str, action='store', 
                            help='select a linker map')
        parser.add_argument('-info', "--info", action='store_true', 
                            help='describe the selected map, cpu, rom')
        parser.add_argument('-l', type=str, action='append', metavar='LIB',
                            help='library files. -lxxx searches for libxxx.a')
        parser.add_argument('-L', type=str, action='append', metavar='LIBDIR',
                            help='specify an additional directory to search for libraries')
        parser.add_argument('--symbols', '--syms', action='store_const', dest='symbols', const=1,
                            help='outputs a sorted list of symbols')
        parser.add_argument('--all-symbols', '--all-syms', action='store_const', dest='symbols', const=2,
                            help='outputs a sorted list of all symbols, including generated ones')
        parser.add_argument('--entry', '-e', dest='e', metavar='START',
                            type=str, action='store', default='_start',
                            help='select the entry point symbol (default _start)')
        parser.add_argument('--gt1-exec-address', dest='gt1exec', metavar='ADDR',
                            type=str, action='store', default='_gt1exec',
                            help='select the gt1 execution address (default _gt1exec)')
        parser.add_argument('--short-function-size-threshold', dest='sfst',
                            metavar='SIZE', type=int, action='store',
                            help='attempts to fit functions smaller than this threshold into a single page.')
        parser.add_argument('--long-function-segment-size', dest='lfss',
                            metavar='SIZE', type=int, action='store',
                            help='minimal segment size for functions split across segments.')
        parser.add_argument('--no-runtime-bss-initialization', action='store_true',
                            help='cause all bss segments to go as zeroes in the gt1 file')
        parser.add_argument('--minimal-heap-segment-size', dest='mhss',
                            metavar='SIZE', type=int, action='store',
                            help='minimal heap segment size for __glink_magic_heap.')
        parser.add_argument('--debug-messages', '-d', dest='d', action='count', default=0,
                            help='enable debugging output. repeat for more.')
        args = parser.parse_args(argv)

        # set defaults
        if args.map == None:
            args.map = '32k'
            print(f"glink: defaulting to map '{args.map}'", file=sys.stderr)

        # process rom and map
        read_rominfo(args.rom)
        args.cpu = args.cpu or romcpu or 5
        args.files = args.files or []
        args.e = args.e or "_start"
        args.l = args.l or []
        args.L = args.L or []
        read_interface()
        read_map(args.map)
        args.L.append(os.path.join(lccdir,f"map{args.map}"))
        args.L.append(os.path.join(lccdir,f"cpu{args.cpu}"))
        args.L.append(lccdir)

        # info request only
        if args.info:
            print('================= ROM INFO')
            if rominfo and romtype and romcpu:
                print(f"  Rom '{args.rom}' (romType={hex(romtype)}) implements cpu {romcpu}")
                print(f"  Keys: {[k for k in rominfo if k not in ('cpu', 'romType')]}")
            else:
                print(f" No information found on rom '{args.rom}'")
            print()
            print('================= CPU INFO')
            if args.cpu == 6:
                print('  vCPU 6 is an experimental cpu with numerous additional opcodes')
            elif args.cpu == 5:
                print('  vCPU 5 was introduced in ROMv5a with opcodes CALLI, CMPHU, CMPHS.')
            elif args.cpu == 4:
                print('  vCPU 4 is the version that comes with ROMv4.')
            print()
            print('================= MAP INFO')
            if map_describe:
                map_describe()
            else:
                print(f"  No information found on map '{args.map}'")
            return 0
        
        # load all .s/.o/.a files
        if not args.files:
            fatal(f"no input files were specified")
        for f in args.files:
            read_file(f)
        for m in module_list:
            if m.cpu > args.cpu:
                warning(f"module '{m.name}' was compiled for cpu {m.cpu} > {args.cpu}")

        # load modules synthetized by the map
        if map_extra_modules:
            global new_modules
            new_modules = []
            map_extra_modules(romtype)
            module_list += new_modules

        # load libraries requested by the map
        global map_extra_libs
        if map_extra_libs:
            for n in map_extra_libs(romtype):
                read_lib(n)

        # load user-specified libraries
        for f in args.l:
            read_lib(f)

        # resolve import/exports/common and prune unused modules
        module_list = compute_closure()
        convert_common_symbols()
        check_undefined_symbols()
        if error_counter > 0:
            print(f"glink: {error_counter} error(s) {warning_counter} warning(s)")
            return 1

        # generate
        run_passes()
        if error_counter > 0:
            print(f"glink: {error_counter} error(s) {warning_counter} warning(s)")
            return 1

        # magic happens here
        process_magic_symbols()

        # verification
        for s in segment_list:
            if s.pc > s.eaddr:
                fatal(f"internal error: segment overflow in {s} (final pc={hex(s.pc)})")
        
        # output
        save_gt1(args.o, args.gt1exec)
        if (args.symbols):
            print_symbols(allsymbols=args.symbols>1)
        return 0
    
    except FileNotFoundError as err:
        fatal(str(err), exc=True)
    except Exception as err:
        fatal(str(err), exc=True)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
