#  SPDX-License-Identifier: BSD-3-Clause
#
#  Copyright (c) 2021  LB3361
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#  3. Neither the name of the University nor the names of its contributors
#     may be used to endorse or promote products derived from this software
#     without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
#  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
#  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
#  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
#  OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
#  SUCH DAMAGE.


# -------------- glink proper

import argparse, json, string
import os, sys, traceback, functools, copy
import builtins

args = None
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
lbranch_counter = 0
error_counter = 0
warning_counter = 0
genlabel_counter = 0
labelchange_counter = 1
dedup_errors = set()

map_extra_modules = None
map_extra_libs = None
map_segments = None

# --------------- utils

def debug(s, level=1):
    if args.d and args.d >= level:
        print("(glink debug) " + s, file=sys.stderr)
        
def where(exc=False):
    '''Locate error in a .s/.o/.a file'''
    if exc:
        stb = traceback.extract_tb(sys.exc_info()[2], limit=8)
    else:
        stb = traceback.extract_stack(limit=8)
    for s in stb:
        if (s[2].startswith('code')):
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

def genlabel():
    '''Generate a label for use in a pseudo-instruction.
       One should make sure to request the same number
       of labels regardless of the code path.'''
    global genlabel_counter
    genlabel_counter += 1
    return f".LL{genlabel_counter}"

def check_zp(x):
    x = v(x)
    if final_pass and is_not_zeropage(x):
        warning(f"zero page address overflow")
    return x

def check_imm8(x):
    x = v(x)
    if final_pass and isinstance(x,int):
        if x < 0 or x > 255:
            warning(f"immediate byte argument overflow")
    return x

def check_im8s(x):
    x = v(x)
    if final_pass and isinstance(x,int):
        if x < -128 or x > 255:
            warning(f"immediate byte argument overflow")
    return x

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
                error(f"Module {exporter.fname} exports '{s}' but does not define it", dedup=True)
    if s in symdefs:
        return symdefs[s]
    return None
        
class Module:
    '''Class for assembly modules read from .s/.o/.a files.'''
    def __init__(self, name=None, cpu=None, code=None, library=True):
        global args, current_module
        self.cpu = cpu if cpu != None else args.cpu
        self.code = code
        self.name = name
        self.fname = name
        self.exports = []
        self.imports = []
        self.library = library
        self.symdefs = {}
        self.sympass = {}
        self.symrefs = {}
        self.used = False
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
                error(f"Multiple definitions of label '{sym}'", dedup=True)
            else:
                if sym in self.symdefs and args.d >= 3:
                    debug(f"Pass {the_pass}: symbol '{sym}' when from {hex(self.symdefs[sym])} to {hex(val)}")
                global labelchange_counter
                labelchange_counter += 1
                self.symdefs[sym] = val
                self.sympass[sym] = the_pass

class Segment:
    '''Represent memory segments to be populated with code/data'''
    __slots__ = ('saddr', 'eaddr', 'pc', 'dataonly', 'buffer', 'nbss')
    def __init__(self, saddr, eaddr, dataonly=False):
        self.saddr = saddr
        self.eaddr = eaddr
        self.pc = saddr
        self.dataonly = dataonly or False
        self.buffer = None
        self.nbss = None
    def __repr__(self):
        d = ',dataonly=True' if self.dataonly else ''
        return f"Segment({hex(self.saddr)},{hex(self.eaddr)}{d})"
                
def emit(*args):
    global final_pass, the_pc, the_segment
    if final_pass:
        if not the_segment.buffer:
            the_segment.buffer = bytearray()
        for b in args:
            the_segment.buffer.append(b)
    the_pc += len(args)

def emitjmp(d, saveAC=False):
    '''Emit code to jump to address d.  This can use a short BRA or use
       CALLI because vLR has been saved.  Without CALLI, long jumps
       needs to use vAC. Argument `saveAC' says whether one should
       preserve vAC by saving and restoring its value. '''
    if is_pcpage(d): # 2 bytes
        BRA(d)
        return
    global lbranch_counter
    if args.cpu >= 5: # 3 bytes
        lbranch_counter += 3
        CALLI(d)
    elif not saveAC:  # 5 bytes
        lbranch_counter += 5
        emit(0x11, lo(int(d)-2), hi(int(d))) # LDWI (nohop)
        STW(vPC)
    else:             # 10 bytes (sigh!)
        lbranch_counter += 10
        STLW(-2)
        emit(0x11, lo(int(d)), hi(int(d)))   # LDWI (nohop)
        STW(vLR)
        LDLW(-2)
        RET()
    
def emitjcc(BCC, BNCC, d, saveAC=False):
    '''Emits a conditional jump, either using a short BCC, 
       or using its converse BNCC to skip a long jump.'''
    lbl = genlabel()
    tryhop(3)           # make sure there is no hop before the short jump
    if is_pcpage(d):
        BCC(d)
    else:               # than make sure there is no hop during the long jump
        tryhop(13 if args.cpu < 5 else 6)
        BNCC(lbl);
        emitjmp(int(d), saveAC=saveAC)
        label(lbl, hop=False)

def extern(sym):
    '''Adds a symbol to the import list of a module. 
       This happens when `measure_code_fragment' is called.
       Pseudo-instructons need this to make sure the linker
       inserts the appropriate runtime routines.'''
    if the_pass == 0 and sym not in the_module.imports:
        the_module.imports.append(sym)

        
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
    d = { "vPC":  0x0016, "vAC":  0x0018, "vACL": 0x0018, "vACH": 0x0019,
          "vLR":  0x001a, "vSP":  0x001c, "LAC":  0x0084, "FAC":  0x0081 }
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
def pc():
    return the_pc
@vasm
def v(x):
    '''Possible resolve symbol `x'.'''
    if not isinstance(x,str):
        return x
    if the_module:
        the_module.symrefs[x] = the_pass
        if x in the_module.symdefs:
            return the_module.symdefs[x]
    r = resolve(x)
    if final_pass and not r:
        error(f"Undefined symbol '{x}'", dedup=True)
    return r or Unk(0xDEAD)
@vasm
def lo(x):
    return v(x) & 0xff
@vasm
def hi(x):
    return (v(x) >> 8) & 0xff

@vasm
def tryhop(sz = 0, jump=True):
    '''Hops to a new page if the current page cannot hold a long jump
       plus `sz' bytes. This also ensures that no hop will occur during
       the next `sz' bytes. A long jump is generated when `jump' is True.'''
    global the_pass, the_fragment, hops_enabled, the_segment, the_pc
    if hops_enabled:
        sz = 4 if sz < 4 else sz           # enough space for one instruction
        sz += 10 if args.cpu < 5 else 3    # enough space for the jump
        if the_pc + sz >= the_segment.eaddr:
            hops_enabled = False                       # avoid infinite recursion
            the_segment.pc = the_pc
            lfss = args.lfss or 16
            ns = find_code_segment(max(lfss, sz)) # give at least what was requested
            if not ns:
                fatal(f"Map memory exhausted while fitting function `{the_fragment[1]}'.")
            if jump:
                emitjmp(ns.pc, saveAC=True)
            hops_enabled = True            
            the_segment.pc = the_pc
            if the_pc > the_segment.eaddr:
                fatal(f"Internal error: insufficient memory left to insert a hop")
            the_segment = ns
            the_pc = ns.pc
            if args.d >= 2:
                debug(f"Pass {the_pass}: Continuing '{the_fragment[1]}' at {hex(the_pc)} in {ns}")

@vasm
def align(d):
    while the_pc & (d-1):
        emit(0)
@vasm
def bytes(*args):
    for w in args:
        emit(v(w))
@vasm
def words(*args):
    for w in args:
        emit(lo(w), hi(w))
@vasm
def space(d):
    for i in range(0,d):
        emit(0)
@vasm
def label(sym, val=None, hop=True):
    '''Define label `sym' to the value of PC or to `val'.
       Unless `hop` is False, this function checks whether 
       one needs to hop to a new page before defining the label.'''
    refd = sym in the_module.symrefs and the_module.symrefs[sym] == the_pass
    if hop:  # alternate: hop and not refd:
        tryhop(0 if refd else 16)
    if the_pass > 0:
        the_module.label(sym, v(val) if val else the_pc)

@vasm
def ST(d):
    tryhop(); emit(0x5e, check_zp(d))
@vasm
def STW(d):
    tryhop(); emit(0x2b, check_zp(d))
@vasm
def STLW(d):
    tryhop(); emit(0xec, check_zp(d))
@vasm
def LD(d):
    tryhop(); emit(0x1a, check_zp(d))
@vasm
def LDI(d, hop=True):
    tryhop(); emit(0x59, check_im8s(d))
@vasm
def LDWI(d):
    tryhop(); d=int(v(d)); emit(0x11, lo(d), hi(d))
@vasm
def LDW(d):
    tryhop(); emit(0x21, check_zp(d))
@vasm
def LDLW(d):
    tryhop(); emit(0xee, check_zp(d))
@vasm
def ADDW(d):
    tryhop(); emit(0x99, check_zp(d))
@vasm
def SUBW(d):
    tryhop(); emit(0xb8, check_zp(d))
@vasm
def ADDI(d):
    tryhop(); emit(0xe3, check_imm8(d))
@vasm
def SUBI(d):
    tryhop(); emit(0xe6, check_imm8(d))
@vasm
def LSLW():
    tryhop(); emit(0xe9)
@vasm
def INC(d):
    tryhop(); emit(0x93, check_zp(d))
@vasm
def ANDI(d):
    tryhop(); emit(0x82, check_imm8(d))
@vasm
def ANDW(d):
    tryhop(); emit(0xf8, check_zp(d))
@vasm
def ORI(d):
    tryhop(); emit(0x88, check_imm8(d))
@vasm
def ORW(d):
    tryhop(); emit(0xfa, check_zp(d))
@vasm
def XORI(d):
    tryhop(); emit(0x8c, check_imm8(d))
@vasm
def XORW(d):
    tryhop(); emit(0xfc, check_zp(d))
@vasm
def PEEK():
    tryhop(); emit(0xad)
@vasm
def DEEK():
    tryhop(); emit(0xf6)
@vasm
def POKE(d):
    tryhop(); emit(0xf0, check_zp(d))
@vasm
def DOKE(d):
    tryhop(); emit(0xf3, check_zp(d))
@vasm
def LUP(d):
    tryhop(); emit(0x7f, check_zp(d))
@vasm
def BRA(d):
    tryhop(); emit(0x90, check_br(d)); tryhop(jump=False)
@vasm
def BEQ(d):
    tryhop(); emit(0x35, 0x3f, check_br(d))
@vasm
def BNE(d):
    tryhop(); emit(0x35, 0x72, check_br(d))
@vasm
def BLT(d):
    tryhop(); emit(0x35, 0x50, check_br(d))
@vasm
def BGT(d):
    tryhop(); emit(0x35, 0x4d, check_br(d))
@vasm
def BLE(d):
    tryhop(); emit(0x35, 0x56, check_br(d))
@vasm
def BGE(d):
    tryhop(); emit(0x35, 0x53, check_br(d))
@vasm
def CALL(d):
    tryhop(); emit(0xcf, check_zp(d))
@vasm
def RET():
    tryhop(); emit(0xff); tryhop(jump=False)
@vasm
def PUSH():
    tryhop(); emit(0x75)
@vasm
def POP():
    tryhop(); emit(0x63)
@vasm
def ALLOC(d):
    tryhop(); emit(0xdf, check_zp(d))
@vasm
def SYS(op):
    op = v(op)
    if not isinstance(op ,Unk):
        if op & 1 != 0 or op < 0 or op >= 284:
            error(f"illegal argument {op} for SYS opcode")
        op = min(0, 14 - op // 2) & 0xff
    tryhop(); emit(0xb4, op)
@vasm
def HALT():
    tryhop(); emit(0xb4, 0x80)
@vasm
def DEF(d):
    tryhop(); emit(0xcd, check_br(d))
@vasm
def CALLI(d):
    check_cpu(5); tryhop(); d=int(v(d)); emit(0x85, lo(d), hi(d))
@vasm
def CMPHS(d):
    check_cpu(5); tryhop(); emit(0x1f, check_zp(d))
@vasm
def CMPHU(d):
    check_cpu(5); tryhop(); emit(0x97, check_zp(d))

# some experimental instructions for cpu6 (opcodes to be checked)
@vasm
def DOKEA(d):
    check_cpu(6); tryhop(); emit(0x7d, check_zp(d))
@vasm
def POKEA(d):
    check_cpu(6); tryhop(); emit(0x69, check_zp(d))
@vasm
def DOKEI(d):
    check_cpu(6); tryhop(); d=int(v(d)); emit(0x37, lo(d), hi(d))
@vasm
def POKEI(d):
    check_cpu(6); tryhop(); emit(0x25, check_im8s(d))
@vasm
def DEEKA(d):
    check_cpu(6); tryhop(); emit(0x6f, check_zp(d))
@vasm
def PEEKA(d):
    check_cpu(6); tryhop(); emit(0x67, check_zp(d))
@vasm
def DEC(d):
    check_cpu(6); tryhop(); emit(0x14, check_zp(d))
@vasm
def INCW(d):
    check_cpu(6); tryhop(); emit(0x79, check_zp(d))
@vasm
def DECW(d):
    check_cpu(6); tryhop(); emit(0x7b, check_zp(d))
@vasm
def NEGW(d):
    check_cpu(6); tryhop(); emit(0xd3, check_zp(d))
@vasm
def NOTB(d):
    check_cpu(6); tryhop(); emit(0x48, check_zp(d))
@vasm
def NOTW(d):
    check_cpu(6); tryhop(); emit(0x8a, check_zp(d))
@vasm
def LSLV(d):
    check_cpu(6); tryhop();  emit(0x27, check_zp(d))
@vasm
def ADDBA(d):
    check_cpu(6); tryhop(); emit(0x29, check_zp(d))
@vasm
def SUBBA(d):
    check_cpu(6); tryhop(); emit(0x77, check_zp(d))
@vasm
def PEEKV(d):
    check_cpu(6); tryhop(); emit(0x39, check_zp(d))
@vasm
def DEEKV(d):
    check_cpu(6); tryhop(); emit(0x3b, check_zp(d))

@vasm
def _SP(n):
    '''Pseudo-instruction to compute SP relative addresses'''
    n = v(n)
    if is_zero(n):
        _LDW(SP);
    else:
        _LDI(n); ADDW(SP)
@vasm
def _LDI(d):
    '''Emit LDI or LDWI depending on the size of d.'''
    d = v(d)
    if is_zeropage(d):
        LDI(d)
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
    tryhop()
    d = v(d)
    if is_zeropage(d):
        LD(d)
    else:
        _LDI(d); PEEK()
@vasm
def _SHL(d):
    STW(T3); LDW(d); STW(T2)
    extern('_@_shl') 
    _CALLI('_@_shl')            # T3<<T2 -> vAC
@vasm
def _SHRS(d):
    STW(T3); LDW(d); STW(T2)
    extern('_@_shrs')
    _CALLI('_@_shrs')           # T3>>T2 --> vAC
@vasm
def _SHRU(d):
    STW(T3); LDW(d); STW(T2)
    extern('_@_shru')
    _CALLI('_@_shru')           # T3>>T2 --> vAC
@vasm
def _MUL(d):
    STW(T3); LDW(d); STW(T2)
    extern('_@_mul')
    _CALLI('_@_mul')            # T3*T2 --> vAC
@vasm
def _DIVS(d):
    STW(T3); LDW(d); STW(T2)
    extern('_@_divs')
    _CALLI('_@_divs')           # T3/T2 --> vAC
@vasm
def _DIVU(d):
    STW(T3); LDW(d); STW(T2)
    extern('_@_divu')
    _CALLI('_@_divu')           # T3/T2 --> vAC
@vasm
def _MODS(d):
    STW(T3); LDW(d); STW(T2)
    extern('_@_mods')
    _CALLI('_@_mods')           # T3%T2 --> vAC
@vasm
def _MODU(d):
    STW(T3); LDW(d); STW(T2)
    extern('_@_modu')
    _CALLI('_@_modu')           # T3%T2 --> vAC
@vasm
def _MOV(s,d):
    '''Move word from reg/addr s to d.
       Also accepts [vAC] for s or d.'''
    s = v(s)
    d = v(d)
    if s != d:
        if args.cpu > 5 and s == [vAC] and is_zeropage(d):
            DEEKA(d)
        elif args.cpu > 5 and is_zeropage(s) and d == [vAC]:
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
            STW(T3); _LDI(d)
            if args.cpu > 5:
                DOKEA(T3)
            else:
                STW(T2); LDW(T3); DOKE(T2)
        else:
            _LDI(d); STW(T2); _LDW(s); DOKE(T2)
@vasm
def _BRA(d, saveAC=False):
    emitjmp(v(d), saveAC=saveAC); tryhop(jump=False)
@vasm
def _BEQ(d, saveAC=False):
    emitjcc(BEQ, BNE, v(d), saveAC=saveAC)
@vasm
def _BNE(d, saveAC=False):
    emitjcc(BNE, BEQ, v(d), saveAC=saveAC)
@vasm
def _BLT(d, saveAC=False):
    emitjcc(BLT,_BGE, v(d), saveAC=saveAC)
@vasm
def _BGT(d, saveAC=False):
    emitjcc(BGT,_BLE, v(d), saveAC=saveAC)
@vasm
def _BLE(d, saveAC=False):
    emitjcc(BLE, BGT, v(d), saveAC=saveAC)
@vasm
def _BGE(d, saveAC=False):
    emitjcc(BGE, BLT, v(d), saveAC=saveAC)
@vasm
def _CMPIS(d):
    '''Compare vAC (signed) with immediate in range 0..255'''
    if args.cpu >= 5:
        CMPHS(0); SUBI(d)
    else:
        lbl = genlabel()
        BLT(lbl)
        SUBI(d)
        label(lbl)
@vasm
def _CMPIU(d):
    '''Compare vAC (unsigned) with immediate in range 0..255'''
    if args.cpu >= 5:
        CMPHU(0); SUBI(d)
    else:
        lbl = genlabel()
        BGE(lbl)
        LDWI(0x100)
        label(lbl)
        SUBI(d)
@vasm
def _CMPWS(d):
    '''Compare vAC (signed) with register.'''
    if args.cpu >= 5:
        CMPHS(d+1); SUBW(d)
    else:
        lbl1 = genlabel()
        lbl2 = genlabel()
        STW(T3); XORW(d)
        BGE(lbl1)
        LDW(T3); ORI(1)
        BRA(lbl2)
        label(lbl1)
        LDW(T3); SUBW(d)
        label(lbl2)
@vasm
def _CMPWU(d):
    '''Compare vAC (unsigned) with register.'''
    if args.cpu >= 5:
        CMPHU(d+1); SUBW(d)
    else:
        lbl1 = genlabel()
        lbl2 = genlabel()
        STW(T3); XORW(d)
        BGE(lbl1)
        LDW(d); ORI(1)
        BRA(lbl2)
        label(lbl1)
        LDW(T3); SUBW(d)
        label(lbl2)
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
        if s != [vAC] and s != [T3]:
            _LDI(s); STW(T3)
        _LDI(n);
        extern('_@_memcpy')
        _CALLI('_@_memcpy', storeAC=T1)         # [T3..T3+AC) --> [T2..T2+AC)
@vasm
def _LMOV(s,d):
    '''Move long from reg/addr s to d.
       Also accepts [vAC] as s, and [vAC] or [T2] as d.'''
    s = v(s)
    d = v(d)
    if s != d:
        if is_zeropage(d, 3):
            if is_zeropage(s, 3):
                _LDW(s); STW(d); _LDW(s+2); STW(d+2)      # 8 bytes
            elif args.cpu > 5:
                if s != [vAC]:
                    _LDI(s)
                DEEKA(d); ADDI(2); DEEKA(d+2)             # 6-9 bytes
            elif s != [vAC]:
                _LDW(s); STW(d); _LDW(s+2); STW(d+2)      # 12 bytes
            else:
                STW(T3); DEEK(); STW(d)
                _LDW(T3); ADDI(2); DEEK(); STW(d+2);      # 12 bytes
        elif is_zeropage(s, 3) and args.cpu > 5:
            if d == [T2]:
                _LDW(T2)
            elif s != [vAC]:
                _LDI(s)
            DOKEA(s); ADDI(2); DOKEA(s+2)                 # 6-9 bytes
        else:
            if d == [vAC]:
                STW(T2)
            if s == [vAC]:
                STW(T3)
            if d != [vAC] and d != [T2]:
                _LDI(d); STW(T2)
            if s != [vAC] and s != [T3]:               # call sequence
                _LDI(s); STW(T3)                      # 5-13 bytes
            extern('_@_lcopy')
            _CALLI('_@_lcopy')  #   [T3..T3+4) --> [T2..T2+4)
@vasm
def _LADD():
    extern('_@_ladd')              # [vAC/T3] means [vAC] for cpu>=5, [T3] for cpu<5
    _CALLI('_@_ladd', storeAC=T3)  # LAC+[vAC/T3] --> LAC
@vasm
def _LSUB():
    extern('_@_lsub') 
    _CALLI('_@_lsub', storeAC=T3)  # LAC-[vAC/T3] --> LAC
@vasm
def _LMUL():
    extern('_@_lmul')
    _CALLI('_@_lmul', storeAC=T3)  # LAC*[vAC/T3] --> LAC
@vasm
def _LDIVS():
    extern('_@_ldivs')
    _CALLI('_@_ldivs', storeAC=T3)  # LAC/[vAC/T3] --> LAC
@vasm
def _LDIVU():
    extern('_@_ldivu')
    _CALLI('_@_ldivu', storeAC=T3)  # LAC/[vAC/T3] --> LAC
@vasm
def _LMODS():
    extern('_@_lmods')
    _CALLI('_@_lmods', storeAC=T3)  # LAC%[vAC/T3] --> LAC
@vasm
def _LMODU():
    extern('_@_lmodu')
    _CALLI('_@_lmodu', storeAC=T3)  # LAC%[vAC/T3] --> LAC
@vasm
def _LSHL():
    extern('_@_lshl')
    _CALLI('_@_lshl', storeAC=T3)  # LAC<<[vAC/T3] --> LAC
@vasm
def _LSHRS():
    extern('_@_lshrs')
    _CALLI('_@_lshrs', storeAC=T3)  # LAC>>[vAC/T3] --> LAC
@vasm
def _LSHRU():
    extern('_@_lshru')
    _CALLI('_@_lshru', storeAC=T3)  # LAC>>[vAC/T3] --> LAC
@vasm
def _LNEG():
    extern('_@_lneg')
    _CALLI('_@_lneg')               # -LAC --> LAC
@vasm
def _LCOM():
    extern('_@_lcom')
    _CALLI('_@_lcom')               # ~LAC --> LAC
@vasm
def _LAND():
    extern('_@_land')
    _CALLI('_@_land', storeAC=T3)   # LAC&[vAC/T3] --> LAC
@vasm
def _LOR():
    extern('_@_lor')
    _CALLI('_@_lor', storeAC=T3)    # LAC|[vAC/T3] --> LAC
@vasm
def _LXOR():
    extern('_@_lxor')
    _CALLI('_@_lxor', storeAC=T3)   # LAC^[vAC/T3] --> LAC
@vasm
def _LCMPS():
    extern('_@_lcmps')
    _CALLI('_@_lcmps', storeAC=T3)  # SGN(LAC-[vAC/T3]) --> vAC
@vasm
def _LCMPU():
    extern('_@_lcmpu')
    _CALLI('_@_lcmpu', storeAC=T3)  # SGN(LAC-[vAC/T3]) --> vAC
@vasm
def _LCMPX():
    extern('_@_lcmpx')
    _CALLI('_@_lcmpx', storeAC=T3)  # TST(LAC-[vAC/T3]) --> vAC
@vasm
def _FMOV(s,d):
    '''Move float from reg s to d with special cases when s or d is FAC.
       Also accepts [vAC] or [T3] for s and [vAC] or [T2] for d.'''
    s = v(s)
    d = v(d)
    if s != d:
        if d == FAC:
            if s == [vAC]:
                STW(T3)
            elif s != [T3]:
                _LDI(s); STW(T3)
            extern('_@_fstorefac') 
            _CALLI('_@_fstorefac')   # [T3..T3+5) --> FAC
        elif s == FAC:
            if d == [vAC]:
                STW(T2)
            elif d != [T2]:
                _LDI(d); STW(T2)
            extern('_@_floadfac') 
            _CALLI('_@_floadfac')   # FAC --> [T2..T2+5)
        elif is_zeropage(d, 4) and is_zeropage(s, 4):
            _LDW(s); STW(d); _LDW(s+2); STW(d+2); _LD(s+4); ST(d+4)
        else:
            if d == [vAC]:
                STW(T2)
            if s == [vAC]:
                STW(T3)
            if d != [vAC] and d != [T2]:
                _LDI(d); STW(T2)
            if s != [vAC] and s != [T3]:
                _LDI(s); STW(T3)
            extern('_@_fcopy')       # [T3..T3+5) --> [T2..T2+5)
            _CALLI('_@_fcopy')
@vasm
def _FADD():
    extern('_@_fadd')
    _CALLI('_@_fadd', storeAC=T3)   # FAC+[vAC/T3] --> FAC
@vasm
def _FSUB():
    extern('_@_fsub')
    _CALLI('_@_fsub', storeAC=T3)   # FAC-[vAC/T3] --> FAC
@vasm
def _FMUL():
    extern('_@_fmul')
    _CALLI('_@_fmul', storeAC=T3)   # FAC*[vAC/T3] --> FAC
@vasm
def _FDIV():
    extern('_@_fdiv')
    _CALLI('_@_fdiv', storeAC=T3)   # FAC/[vAC/T3] --> FAC
@vasm
def _FNEG():
    extern('_@_fneg')
    _CALLI('_@_fneg')               # -FAC --> FAC
@vasm
def _FCMP():
    extern('_@_fcmp')
    _CALLI('_@_fcmp', storeAC=T3)   # SGN(FAC-[vAC/T3]) --> vAC
@vasm
def _FTOU():
    extern('_@_ftou')
    _CALLI('_@_ftou')
@vasm
def _FTOI():
    extern('_@_ftoi')
    _CALLI('_@_ftoi')
@vasm
def _FCVI():
    extern('_@_fcvi')
    _CALLI('_@_fcvi')
@vasm
def _FCVU():
    extern('_@_fcvu')
    _CALLI('_@_fcvu')
@vasm
def _CALLI(d, saveAC=False, storeAC=None):
    '''Call subroutine at far location d.
       When cpu<5, option saveAC=True ensures vAC is preserved, 
       and option storeAC=reg stores vAC into a register before jumping.
       When cpu>=5, this just calls CALLI. '''
    if args.cpu >= 5:
        CALLI(d)
    elif saveAC:
        STSW(-2)
        LDWI(d)
        STW('sysFn')
        LDSW(-2)
        CALL('sysFn')
    elif storeAC:
        STW(storeAC)
        LDWI(d)
        STW('sysFn')
        CALL('sysFn')
    else:
        LDWI(d)
        STW('sysFn')
        CALL('sysFn')
@vasm
def _SAVE(offset, mask):
    '''Save all registers specified by mask at [SP+offset],
       Use runtime helpers to save code bytes.'''
    def save1(r, postincr=False):
        '''Save one register'''
        if (args.cpu < 6):
            STW(T3);LDW(r);DOKE(T3)
            if (postincr):
                LDW(T3);ADDI(2)
        else:
            DOKEA(r)
            if (postincr):
                ADDI(2)
    i = 0
    while i < 32:
        m = 1 << i
        if mask & m:
            if i < 8 and ((0xff << i) & 0xff) == (mask & 0xff):
                # we can call a runtime helper
                rt = "_@_saveR%dto7" % i
                extern(rt)
                if args.cpu < 5:
                    _LDI(rt);STW('sysFn');_SP(offset);CALL('sysFn')
                else:
                    _SP(offset);CALLI(rt)
                i = 7
            else:
                if not mask & (m-1): _SP(offset)
                save1(R0+i+i, postincr=(mask & ~(m+m-1)))
        i += 1
        
@vasm
def _RESTORE(offset, mask):
    '''Restore all registers specified by mask from [SP+offset}
       Use runtime helpers to save code bytes.'''
    def restore1(r,postincr=False):
        '''Restore one register'''
        if (args.cpu < 6):
            if (postincr):
                STW(T3)
            DEEK();STW(r)
            if (postincr):
                LDW(T3);ADDI(2)
        else:
            DEEKA(r)
            if (postincr):
                ADDI(2)
    i = 0
    while i < 32:
        m = 1 << i
        if mask & m:
            if i < 8 and ((0xff << i) & 0xff) == (mask & 0xff):
                # we can call a runtime helper
                rt = "_@_restoreR%dto7" % i
                extern(rt)
                if args.cpu < 5:
                    _LDI(rt);STW('sysFn');_SP(offset);CALL('sysFn')
                else:
                    _SP(offset);CALLI(rt)
                i = 7
            else:
                if not mask & (m-1): _SP(offset)
                restore1(R0+i+i, postincr=(mask & ~(m+m-1)))
            first = False
        i += 1

    
        
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
        warning(f"File {f} did not define any module")
    if len(new_modules) == 1 and not f.endswith(".a"):
        new_modules[0].library = False
    for m in new_modules:
        if m.library:
            m.fname = f"{os.path.basename(f)}({m.name})"
        else:
            m.fname = m.name
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
        fatal(f"Cannot find linker map '{m}'")
    with open(fn, 'r') as fd:
        exec(compile(fd.read(), fn, 'exec'), globals())
    if not map_segments:
        fatal(f"Map '{m}' does not define 'map_segments'")

def read_interface():
    '''Read `interface.json' as known symbols.'''
    global symdefs
    with open(os.path.join(lccdir,'interface.json')) as file:
        for (name, value) in json.load(file).items():
            symdefs[name] = value if isinstance(value, int) else int(value, base=0)

def read_rominfo(rom):
    '''Read `rom.jsom' to translate rom names into romType byte and cpu version.'''
    global romtype, romcpu
    with open(os.path.join(lccdir,'roms.json')) as file:
        d = json.load(file)
        if rom in d:
            rominfo = d[args.rom]
    if rominfo:
        romtype = rominfo['romType']
        romcpu = rominfo['cpu']
    if not rominfo:
        print(f"glink: warning: rom '{args.rom}' is not recognized", file=sys.stderr)
    if romcpu and args.cpu and args.cpu > romcpu:
        print(f"glink: warning: rom '{args.rom}' does not implement cpu{args.cpu}", file=sys.stderr)
    


# ------------- compute code closure from import/export information

def find_exporters(sym):
    elist = []
    for m in module_list:
        if sym in m.exports:
            elist.append(m)
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
    global lbranch_counter
    the_module = m
    the_fragment = frag
    the_pc = 0
    lbranch_counter = 0
    try:
        frag[2]()
    except Exception as err:
        fatal(str(err), exc=True)
    debug(f"Function '{frag[1]}' is {the_pc}(-{lbranch_counter}) bytes long")
    frag = frag + (the_pc, lbranch_counter)
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
                if m.library:                      # rules for selecting one of the library modules 
                    if e and not e.library:        # that export a required symbol:
                        pass                       # -- cannot override a non-library module
                    elif m.cpu > args.cpu:         # -- ignore exports when module targets too high a cpu.
                        pass                       # -- prefer exports from module targeting a higher cpu. 
                    elif not e or m.cpu > e.cpu:
                        e = m
                else:                              # complain when a required symbol is exported
                    if e and not e.library:        # by multiple non-library files.
                        error(f"Symbol '{sym}' is exported by both '{e.fname}' and '{m.fname}'", dedup=True)
                    e = m
            if e:
                debug(f"Including module '{e.fname}' for symbol '{sym}'")
                e.used = True
                for sym in e.exports:              # register all symbols exported by the selected module
                    if sym in exporters:           # -- warn about possible conflicts
                        error(f"Symbol '{sym}' is exported by both '{e.fname}' and '{exporters[sym].fname}'", dedup=True)
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
            warning(f"File '{m.fname}' was not used")
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
                    debug(f"Instatiating common '{sym}' in '{m.fname}'")
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
        error(f"Undefined symbol '{s}' imported by {comma.join(und[s])}", dedup=True)



# ------------- passes

def round_used_segments():
    '''Split all segments containing code or data into 
       a used segment and a free segment starting on 
       a page boundary. Marks used segment as non-BSS.'''
    for (i,s) in enumerate(segment_list):
        epage = (s.pc + 0xff) & ~0xff
        if s.pc > s.saddr and s.eaddr > epage:
            segment_list.insert(i+1, Segment(epage, s.eaddr, s.dataonly))
            s.eaddr = epage
            if args.d >= 2:
                debug(f"Rounding {segment_list[i:i+2]}")
        if s.pc > s.saddr:
            s.nbss = True
 
def find_data_segment(size, align=None):
    for s in segment_list:
        pc = s.pc
        if align and align > 1:
            pc = align * ((pc + align - 1) // align)
        if s.eaddr - pc > size:
            return s

def find_code_segment(size):
    # Since code segments cannot cross page boundaries
    # it is sometimes necessary to carve a code segment from a larger one
    size = min(256, size)
    for (i,s) in enumerate(segment_list):
        if s.dataonly:
            continue
        if s.pc > s.saddr and s.pc + size <= s.eaddr:  # segment has enough free size and does not cross
            return s                                   # a page boundary because it already contains code
        if (s.saddr ^ (s.eaddr-1)) & 0xff00:
            epage = (s.saddr | 0xff) + 1               # segment crosses a page boundary:
            ns = Segment(s.saddr, epage)               # carve a non-crossing one and insert it in the list
            s.saddr = epage
            segment_list.insert(i, ns)
            s = ns
        if s.pc + size <= s.eaddr:                     # is it large enough?
            return s
    return None
    
def assemble_code_fragments(m):
    global the_module, the_fragment, the_segment, hops_enabled, the_pc
    the_module = m
    for frag in m.code:
        the_fragment = frag
        if frag[0] == 'CODE':
            shortsize = frag[3] - frag[4]
            the_segment = None
            sfst = args.sfst or 92
            if shortsize < sfst and shortsize < 256:
                hops_enabled = False
                the_segment = find_code_segment(shortsize)
                if the_segment and args.d >= 2:
                    debug(f"Pass {the_pass}: Assembling short function '{frag[1]}' at {hex(the_segment.pc)} in {the_segment} .")
            if not the_segment:
                hops_enabled = True
                lfss = args.lfss or 16
                the_segment = find_code_segment(min(lfss, 256))
                if not the_segment:
                    fatal(f"Map memory exhausted while fitting function '{frag[1]}'.")
                if the_segment and args.d >= 2:
                    debug(f"Pass {the_pass}: Assembling function '{frag[1]}' at {hex(the_segment.pc)} in {the_segment}")
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
                fatal(f"Map memory exhausted while fitting datum '{frag[1]}'.")
            elif args.d >= 2:
                debug(f"Pass {the_pass}: Assembling {cseg} item '{frag[1]}' at {hex(the_segment.pc)} in {the_segment}")
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
    if args.start_from_0x200:
        reserve_jump_in_0x200()
    debug(f"Pass {the_pass}.")
    # code segments
    for m in module_list:
        assemble_code_fragments(m)
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

def reserve_jump_in_0x200():
    if args.start_from_0x200:
        for seg in segment_list:
            if seg.saddr == 0x200:
                seg.pc += 6
                seg.buffer = bytearray(6)
                return
    error(f"cannot find a segment starting in 0x200 to insert a jump")

def write_jump_in_0x200():
    if args.start_from_0x200:
        seg = find_segment_for_address(0x200)
        start = resolve(args.e)
        if start and seg and seg.saddr == 0x200:
            seg.buffer[0:6] = builtins.bytes((0x11, lo(start), hi(start), # LDWI(start)
                                              0x2b, 0x1a, 0xff))          # STW(vLR); RET()

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
        if a1 - a0 >= 24:
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
                    return warning(f"Ignoring magic symbol '{s}' in {m.fname} (wrong type)")
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
                    return warning(f"Ignoring magic symbol '{s}' (list head not a pointer)")
                if deek_gt1(head_addr) != 0xBEEF:
                    return warning(f"Ignoring magic symbol '{s}' (list head not 0xBEEF)")
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
    for s in syms:
        pp="public " if s[2] else "private"
        print(f"{s[0]:04x}\t{s[1]:<22s}\t{pp}\t{s[3]:<24s}")

    
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
        parser.add_argument('files', type=str, nargs='+',
                            help='input files')
        parser.add_argument('-o', type=str, default='a.gt1', metavar='GT1FILE',
                            help='select the output filename (default: a.gt1)')
        parser.add_argument('-cpu', "--cpu", type=int, action='store',
                            help='select the target cpu version: 4, 5, 6 (default: 5).')
        parser.add_argument('-rom', "--rom", type=str, action='store', default='v5a',
                            help='select the target rom version: v4, v5a (default: v5a).')
        parser.add_argument('-map', "--map", type=str, action='store', 
                            help='select a linker map (default: 64k)')
        parser.add_argument('-l', type=str, action='append', metavar='LIB',
                            help='library files. -lxxx searches for libxxx.a')
        parser.add_argument('-L', type=str, action='append', metavar='LIBDIR',
                            help='specify an additional directory to search for libraries')
        parser.add_argument('--symbols', action='store_const', dest='symbols', const=1,
                            help='outputs a sorted list of symbols')
        parser.add_argument('--all-symbols', action='store_const', dest='symbols', const=2,
                            help='outputs a sorted list of all symbols, including generated ones')
        parser.add_argument('--entry', '-e', dest='e', metavar='START',
                            type=str, action='store', default='_start',
                            help='select the entry point symbol (default _start)')
        parser.add_argument('--start-from-0x200', action='store_true',
                            help='writes a jump to the entry point at address 0x200.')
        parser.add_argument('--short-function-size-threshold', dest='sfst',
                            metavar='SIZE', type=int, action='store',
                            help='attempts to fit functions smaller than this threshold into a single page.')
        parser.add_argument('--long-functions-segment-size', dest='lfss',
                            metavar='SIZE', type=int, action='store',
                            help='minimal segment size for functions split across segments.')
        parser.add_argument('--no-runtime-bss-initialization', action='store_true',
                            help='cause all bss segments to go as zeroes in the gt1 file')
        parser.add_argument('--debug-messages', '-d', dest='d', action='count', default=0,
                            help='enable debugging output. repeat for more.')
        args = parser.parse_args(argv)

        # set defaults
        if False:
            if args.map == None:
                args.map = '64k'
            if args.rom == None:
                args.rom = 'v5a'
        read_rominfo(args.rom)
        args.cpu = args.cpu or romcpu or 5
        args.files = args.files or []
        args.e = args.e or "_start"
        args.l = args.l or []
        args.L = args.L or []
        read_interface()

        # process map
        read_map(args.map)
        args.L.append(os.path.join(lccdir,f"map{args.map}"))
        args.L.append(os.path.join(lccdir,f"cpu{args.cpu}"))
        args.L.append(lccdir)

        # load all .s/.o/.a files
        for f in args.files:
            read_file(f)
        for m in module_list:
            if m.cpu > args.cpu:
                warning(f"Module '{m.name}' was compiled for cpu {m.cpu} > {args.cpu}")

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
        if args.start_from_0x200:
            write_jump_in_0x200()

        # output
        save_gt1(args.o, v(args.e))
        if (args.symbols):
            print_symbols(allsymbols=args.symbols>1)
        return 0
    
    except FileNotFoundError as err:
        fatal(str(err), exc=True)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
