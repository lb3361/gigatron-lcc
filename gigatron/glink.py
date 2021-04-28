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
import os, sys, traceback, functools

args = None
rominfo = None
lccdir = '/usr/local/lib/gigatron-lcc'
safe_dict = {}
module_list = []
new_modules = []

symdefs = {}
exporters = {}

the_module = None
the_segment = None
the_fragment = None
the_pc = 0
the_pass = 0

final_pass = False
lbranch_counter = 0
error_counter = 0
warning_counter = 0
genlabel_counter = 0
labelchange_counter = 0

map_extra_modules = None
map_extra_libs = None
map_sp = None
map_ram = None

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
            return f"{s[0]}:{s[1]}"
    return None

class __metaUnk(type):
    wrapped = ''' 
      __abs__ __add__ __and__ __floordiv__ __ge__ __gt__ __invert__
      __le__  __lshift__ __lt__ __mod__ __mul__ __neg__ __or__ 
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
        return int(x) & 0xff00 == 0
    return False

def is_pcpage(x):
    if isinstance(x,int) and not isinstance(x,Unk):
        return int(x) & 0xff00 == pc() & 0xff00
    return False

def is_not_pcpage(x):
    if isinstance(x,int) and not isinstance(x,Unk):
        return int(x) & 0xff00 == pc() & 0xff00
    return False

def genlabel():
    global genlabel_counter
    genlabel_counter += 1
    return f".LL{genlabel_counter}"

def check_zp(x):
    x = v(x)
    if is_not_zeropage(x) and final_pass:
        warning(f"zero page argument overflow")
    return x

def check_br(x):
    x = v(x)
    if is_not_pcpage(x) and final_pass:
        warning(f"short branch overflow")
    return (int(x)-2) & 0xff

def check_cpu(op, v):
    if args.cpu < v and final_pass:
        warning(f"opcode '{op}' not implemented by cpu={arg.cpu}")

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
        self.used = False
        for tp in self.code:
            if tp[0] == 'EXPORT':
                self.exports.append(tp[1])
            elif tp[0] == 'IMPORT':
                self.imports.append(tp[1])
    def __repr__(self):
        return f"Module('{self.fname or self.name}',...)"
    def v(self, s):
        global exporters
        if not isinstance(s, str):
            return s
        elif s in self.symdefs:
            return self.symdefs[s]
        elif s in exporters:
            exporter = exporters[s]
            if exporter != self:
                return exporter.v(s)
        elif s in symdefs:
            return symdefs[s]
        return Unk(0x1234)
    def label(self, sym, val):
        if the_pass > 0:
            if sym in self.symdefs:
                if val != self.symdefs[sym]:
                    labelchange_counter += 1
                    if self.sympass[sym] == the_pass:
                        error(f"Multiple definitions of label '{sym}'")
                self.symdefs[sym] = v
                self.sympass[sym] = the_pass
    def tryhop(self, jump=True):
        global hops
        if the_pass == 0 and isinstance(hops,list):
            hops.append(the_pc)
        else:
            pass ## TODO: check segment, hop if necessary

def final_emit(*args):
    fatal("not yet implemented")
        
def emit(*args):
    global final_pass, the_pc
    if final_pass:
        final_emit(*args)
    else:
        the_pc += len(args)

def emitjmp(d, saveAC=False):
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
    lbl = genlabel()
    if is_pcpage(d):
        BCC(d)
    elif args.cpu > 5:
        JCC(d)
    else:
        BNCC(lbl);
        emitjmp(int(d), saveAC=saveAC)
        label(lbl)
    
        
# ------------- usable vocabulary for .s/.o/.a files

def register_names():
    d = { "vPC":  0x0016, "vAC":  0x0018, "vACL": 0x0018, "vACH": 0x0019,
          "vLR":  0x001a, "vSP":  0x001c, 
          "AC":   0x0018, "LAC":  0x0084, "FAC":  0x0081,
          "FACS": 0x0081, "FACE": 0x0082, "FACX": 0x0083, "FACM": 0x0084 }
    for i in range(0,4): d[f'T{i}'] = 0x88+i+i
    for i in range(8,32): d[f'R{i}'] = 0x80+i+i
    for i in range(8,29): d[f'L{i}'] = d[f'R{i}']
    for i in range(8,28): d[f'F{i}'] = d[f'R{i}']
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
    global the_pass, final_pass, error_counter
    if the_pass == 0 or final_pass:
        error_counter += 1
        w = where()
        w = "" if w == None else w + ": "
        print(f"glink: {w}error: {s}", file=sys.stderr)
@vasm
def warning(s):
    global the_pass, final_pass, warning_counter
    if the_pass == 0 or final_pass:
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
def extern(sym):
    ### TODO
    pass
@vasm
def module(code=None,name=None,cpu=None):
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
    if isinstance(x,str):
        return the_module.v(x)
    return x
@vasm
def lo(x):
    return v(x) & 0xff
@vasm
def hi(x):
    return (v(x) >> 8) & 0xff

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
def label(sym, val=None):
    if the_pass > 0:
        the_module.label(sym, v(val) if val else the_pc)
@vasm
def tryhop(jump=True):
    the_module.tryhop(jump)

@vasm
def ST(d):
    emit(0x5e, check_zp(d))
@vasm
def STW(d):
    emit(0x2b, check_zp(d))
@vasm
def STLW(d):
    emit(0xec, check_zp(d))
@vasm
def LD(d):
    tryhop(); emit(0x1a, check_zp(d))
@vasm
def LDI(d, hop=True):
    tryhop(); emit(0x59, check_zp(d))
@vasm
def LDWI(d):
    tryhop(); d=int(v(d)); emit(0x11, lo(d), hi(d))
@vasm
def LDW(d):
    tryhop(); emit(0x21, check_zp(d))
@vasm
def LDLW(d):
    emit(0xee, check_zp(d))
@vasm
def ADDW(d):
    emit(0x99, check_zp(d))
@vasm
def SUBW(d):
    emit(0xb8, check_zp(d))
@vasm
def ADDI(d):
    emit(0xe3, check_zp(d))
@vasm
def SUBI(d):
    emit(0x36, check_zp(d))
@vasm
def LSLW():
    emit(0xe9)
@vasm
def INC(d):
    emit(0x93, check_zp(d))
@vasm
def ANDI(d):
    emit(0x82, check_zp(d))
@vasm
def ANDW(d):
    emit(0xf8, check_zp(d))
@vasm
def ORI(d):
    emit(0x88, check_zp(d))
@vasm
def ORW(d):
    emit(0xfa, check_zp(d))
@vasm
def XORI(d):
    emit(0x8c, check_zp(d))
@vasm
def XORW(d):
    emit(0xfc, check_zp(d))
@vasm
def PEEK():
    emit(0xad)
@vasm
def DEEK():
    emit(0xf6)
@vasm
def POKE(d):
    emit(0xf0, check_zp(d))
@vasm
def DOKE(d):
    emit(0xf3, check_zp(d))
@vasm
def LUP(d):
    emit(0x7f, check_zp(d))
@vasm
def BRA(d):
    emit(0x90, check_br(d)); tryhop(jump=False);
@vasm
def BEQ(d):
    emit(0x35, 0x3f, check_br(d))
@vasm
def BNE(d):
    emit(0x35, 0x72, check_br(d))
@vasm
def BLT(d):
    emit(0x35, 0x50, check_br(d))
@vasm
def BGT(d):
    emit(0x35, 0x4d, check_br(d))
@vasm
def BLE(d):
    emit(0x35, 0x56, check_br(d))
@vasm
def BGE(d):
    emit(0x35, 0x53, check_br(d))
@vasm
def CALL(d):
    emit(0xcf, check_zp(d))
@vasm
def RET():
    emit(0xff); tryhop(jump=False)
@vasm
def PUSH():
    emit(0x75)
@vasm
def POP():
    emit(0x63)
@vasm
def ALLOC(d):
    emit(0xdf, check_zp(d))
@vasm
def SYS(op):
    t = 270-op//2 if op>28 else 0
    if not isinstance(t,Unk):
        if t <= 128 or t > 255:
            error(f"argument overflow in SYS opcode");
    emit(0xb4, t)
@vasm
def HALT():
    emit(0xb4, 0x80); tryhop(jump=False)
@vasm
def DEF(d):
    emit(0xcd, check_br(d))
@vasm
def CALLI(d):
    check_cpu('CALLI', 5); d=int(v(d)); emit(0x85, lo(d-2), hi(d))
@vasm
def CMPHS(d):
    check_cpu('CMPHS', 5); emit(0x1f, check_zp(d))
@vasm
def CMPHU(d):
    check_cpu('CMPHU', 5); emit(0x97, check_zp(d))

@vasm
def _SP(n):
    n = v(n)
    if is_zero(n):
        LDW(SP);
    elif is_zeropage(n):
        LDW(SP); ADDI(n)
    elif is_zeropage(-n):
        LDW(SP); SUBI(n)
    else:
        LDWI(n); ADDW(SP)
@vasm
def _LDI(d):
    '''Emit LDI or LDWI depending on the size of d. No hops.'''
    d = v(d)
    if is_zeropage(d):
        emit(0x59, d)
    else:
        emit(0x11, lo(d), hi(d))
@vasm
def _LDW(d):
    '''Emit LDW or LDWI+DEEK depending on the size of d. No hops.'''
    d = v(d)
    if is_zeropage(d):
        emit(0x21, d)
    else:
        _LDI(d); DEEK()
@vasm
def _LD(d):
    '''Emit LD or LDWI+PEEK depending on the size of d. No hops.'''
    d = v(d)
    if is_zeropage(d):
        emit(0x21, d)
    else:
        _LDI(d); PEEK()
@vasm
def _SHL(d):
    STW(T3); LDW(d); STW(T2)
    extern('_@_shl16')
    _CALLI('_@_shl')            # T3<<T2 -> AC
@vasm
def _SHRS(d):
    STW(T3); LDW(d); STW(T2)
    extern('_@_shrs16')
    _CALLI('_@_shrs16')         # T3>>T2 --> AC
@vasm
def _SHRU(d):
    STW(T3); LDW(d); STW(T2)
    extern('_@_shru16')
    _CALLI('_@_shru16')         # T3>>T2 --> AC
@vasm
def _MUL(d):
    STW(T3); LDW(d); STW(T2)
    extern('_@_mul16')
    _CALLI('_@_mul16')          # T3*T2 --> AC
@vasm
def _DIVS(d):
    STW(T3); LDW(d); STW(T2)
    extern('_@_divs16')
    _CALLI('_@_divs16')         # T3/T2 --> AC
@vasm
def _DIVU(d):
    STW(T3); LDW(d); STW(T2)
    extern('_@_divu16')
    _CALLI('_@_divu16')         # T3/T2 --> AC
@vasm
def _MODS(d):
    STW(T3); LDW(d); STW(T2)
    extern('_@_mods16')
    _CALLI('_@_mods16')         # T3%T2 --> AC
@vasm
def _MODU(d):
    STW(T3); LDW(d); STW(T2)
    extern('_@_modu16')
    _CALLI('_@_modu16')         # T3%T2 --> AC
@vasm
def _MOV(s,d):
    '''Move word from reg/addr s to d.
       Also accepts [AC] for s or d.'''
    s = v(s)
    d = v(d)
    if s != d:
        if args.cpu > 5 and s == [AC] and is_zeropage(d):
            DEEKA(d)
        elif args.cpu > 5 and is_zeropage(s) and d == [AC]:
            DOKEA(s)
        elif d == [AC]:
            STW(T3)
            if s != AC:
                _LDW(s)
            DOKE(T3)
        elif is_zeropage(d):
            if s == [AC]:
                DEEK()
            elif s != AC:
                _LDW(s)
            if d != AC:
                STW(d)
        elif s == AC or s == [AC]:
            if s == [AC]:
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
    emitjmp(v(d), saveAC=saveAC)
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
    if args.cpu >= 5:
        CMPHS(0); SUBI(d)
    else:
        lbl = genlabel()
        BLT(lbl)
        SUBI(d)
        label(lbl)
@vasm
def _CMPIU(d):
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
       Also accepts [AC] as s and [AC] or [T2] as d.'''
    dr = v(dr)
    sr = v(sr)
    n = v(n)
    if s != d:
        if d == [AC]:
            STW(T2)
        if s == [AC]:
            STW(T3)
        if d != [AC] and d != [T2]:
            _LDI(d); STW(T2)
        if s != [AC] and s != [T3]:
            _LDI(s); STW(T3)
        _LDI(n);
        extern('_@_memcpy')
        _CALLI('_@_memcpy', storeAC=T1)         # [T3..T3+AC) --> [T2..T2+AC)
@vasm
def _LMOV(s,d):
    '''Move long from reg/addr s to d.
       Also accepts [AC] as s, and [AC] or [T2] as d.'''
    s = v(s)
    d = v(d)
    if s != d:
        if is_zeropage(d, 3):
            if is_zeropage(s, 3):
                _LDW(s); STW(d); _LDW(s+2); STW(d+2)      # 8 bytes
            elif args.cpu > 5:
                if s != [AC]:
                    _LDI(s)
                DEEKA(d); ADDI(2); DEEKA(d+2)             # 6-9 bytes
            elif s != [AC]:
                _LDW(s); STW(d); _LDW(s+2); STW(d+2)      # 12 bytes
            else:
                STW(T3); DEEK(); STW(d)
                _LDW(T3); ADDI(2); DEEK(); STW(d+2);      # 12 bytes
        elif is_zeropage(s, 3) and args.cpu > 5:
            if d == [T2]:
                _LDW(T2)
            elif s != [AC]:
                _LDI(s)
            DOKEA(s); ADDI(2); DOKEA(s+2)                 # 6-9 bytes
        else:
            if d == [AC]:
                STW(T2)
            if s == [AC]:
                STW(T3)
            if d != [AC] and d != [T2]:
                _LDI(d); STW(T2)
            if s != [AC] and s != [T3]:               # call sequence
                _LDI(s); STW(T3)                      # 5-13 bytes
            extern('_@_lcopy')
            _CALLI('_@_lcopy')  #   [T3..T3+4) --> [T2..T2+4)
@vasm
def _LADD():
    extern('_@_ladd')              # [AC/T3] means [AC] for cpu>=5, [T3] for cpu<5
    _CALLI('_@_ladd', storeAC=T3)  # LAC+[AC/T3] --> LAC
@vasm
def _LSUB():
    extern('_@_lsub') 
    _CALLI('_@_lsub', storeAC=T3)  # LAC-[AC/T3] --> LAC
@vasm
def _LMUL():
    extern('_@_lmul')
    _CALLI('_@_lmul', storeAC=T3)  # LAC*[AC/T3] --> LAC
@vasm
def _LDIVS():
    extern('_@_ldivs')
    _CALLI('_@_ldivs', storeAC=T3)  # LAC/[AC/T3] --> LAC
@vasm
def _LDIVU():
    extern('_@_ldivu')
    _CALLI('_@_ldivu', storeAC=T3)  # LAC/[AC/T3] --> LAC
@vasm
def _LMODS():
    extern('_@_lmods')
    _CALLI('_@_lmods', storeAC=T3)  # LAC%[AC/T3] --> LAC
@vasm
def _LMODU():
    extern('_@_lmodu')
    _CALLI('_@_lmodu', storeAC=T3)  # LAC%[AC/T3] --> LAC
@vasm
def _LSHL():
    extern('_@_lshl')
    _CALLI('_@_lshl', storeAC=T3)  # LAC<<[AC/T3] --> LAC
@vasm
def _LSHRS():
    extern('_@_lshrs')
    _CALLI('_@_lshrs', storeAC=T3)  # LAC>>[AC/T3] --> LAC
@vasm
def _LSHRU():
    extern('_@_lshru')
    _CALLI('_@_lshru', storeAC=T3)  # LAC>>[AC/T3] --> LAC
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
    _CALLI('_@_land', storeAC=T3)   # LAC&[AC/T3] --> LAC
@vasm
def _LOR():
    extern('_@_lor')
    _CALLI('_@_lor', storeAC=T3)    # LAC|[AC/T3] --> LAC
@vasm
def _LXOR():
    extern('_@_lxor')
    _CALLI('_@_lxor', storeAC=T3)   # LAC^[AC/T3] --> LAC
@vasm
def _LCMPS():
    extern('_@_lcmps')
    _CALLI('_@_lcmps', storeAC=T3)  # SGN(LAC-[AC/T3]) --> AC
@vasm
def _LCMPU():
    extern('_@_lcmpu')
    _CALLI('_@_lcmpu', storeAC=T3)  # SGN(LAC-[AC/T3]) --> AC
@vasm
def _LCMPX():
    extern('_@_lcmpx')
    _CALLI('_@_lcmpx', storeAC=T3)  # TST(LAC-[AC/T3]) --> AC
@vasm
def _FMOV(s,d):
    '''Move float from reg s to d with special cases when s or d is FAC.
       Also accepts [AC] or [T3] for s and [AC] or [T2] for d.'''
    s = v(s)
    d = v(d)
    if s != d:
        if d == FAC:
            if s == [AC]:
                STW(T3)
            elif s != [T3]:
                _LDI(s); STW(T3)
            extern('_@_fstorefac') 
            _CALLI('_@_fstorefac')   # [T3..T3+5) --> FAC
        elif s == FAC:
            if d == [AC]:
                STW(T2)
            elif d != [T2]:
                _LDI(d); STW(T2)
            extern('_@_floadfac') 
            _CALLI('_@_floadfac')   # FAC --> [T2..T2+5)
        elif is_zeropage(d, 4) and is_zeropage(s, 4):
            _LDW(s); STW(d); _LDW(s+2); STW(d+2); _LD(s+4); ST(d+4)
        else:
            if d == [AC]:
                STW(T2)
            if s == [AC]:
                STW(T3)
            if d != [AC] and d != [T2]:
                _LDI(d); STW(T2)
            if s != [AC] and s != [T3]:
                _LDI(s); STW(T3)
            extern('_@_fcopy')       # [T3..T3+5) --> [T2..T2+5)
            _CALLI('_@_fcopy')
@vasm
def _FADD():
    extern('_@_fadd')
    _CALLI('_@_fadd', storeAC=T3)   # FAC+[AC/T3] --> FAC
@vasm
def _FSUB():
    extern('_@_fsub')
    _CALLI('_@_fsub', storeAC=T3)   # FAC-[AC/T3] --> FAC
@vasm
def _FMUL():
    extern('_@_fmul')
    _CALLI('_@_fmul', storeAC=T3)   # FAC*[AC/T3] --> FAC
@vasm
def _FDIV():
    extern('_@_fdiv')
    _CALLI('_@_fdiv', storeAC=T3)   # FAC/[AC/T3] --> FAC
@vasm
def _FNEG():
    extern('_@_fneg')
    _CALLI('_@_fneg')               # -FAC --> FAC
@vasm
def _FCMP():
    extern('_@_fcmp')
    _CALLI('_@_fcmp', storeAC=T3)   # SGN(FAC-[AC/T3]) --> AC
@vasm
def _CALLI(d, saveAC=False, storeAC=None):
    '''Call subroutine at far location d.
       When cpu<5, option saveAC=True ensures AC is preserved, 
       and option storeAC=reg stores AC into a register before jumping.
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
    dn = os.path.dirname(__file__)
    fn = os.path.join(dn, f"map{m}", "map.py")
    if not os.access(fn, os.R_OK):
        fatal(f"Cannot find linker map '{m}'")
    with open(fn, 'r') as fd:
        exec(compile(fd.read(), fn, 'exec'), globals())
    if not map_sp:
        fatal(f"Map '{m}' does not define 'map_sp'")

def read_interface():
    global symdefs
    with open(os.path.join(lccdir,'interface.json')) as file:
        for (name, value) in json.load(file).items():
            symdefs[name] = value if isinstance(value, int) else int(value, base=0)

def read_rominfo(rom):
    global rominfo
    with open(os.path.join(lccdir,'roms.json')) as file:
        d = json.load(file)
        if rom in d:
            rominfo = d[args.rom]
    if not rominfo:
        print(f"glink: warning: rom '{args.rom}' is not recognized", file=sys.stderr)



# ------------- prepare link

def find_exporters(sym):
    elist = []
    for m in module_list:
        if sym in m.exports:
            elist.append(m)
    return elist

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
                if m.library:
                    if e and not e.library:
                        pass
                    elif m.cpu > args.cpu:
                        pass
                    elif not e or m.cpu > e.cpu:
                        e = m
                else:
                    if e and not e.library:
                        error(f"Symbol '{sym}' is exported by both '{e.fname}' and '{m.fname}'")
                    e = m
            if e:
                debug(f"Including module '{e.fname}' for symbol '{sym}'")
                e.used = True
                for sym in e.imports:
                    implist.append(sym)
                for sym in e.exports:
                    if sym in exporters:
                        error(f"Symbol '{sym}' is exported by both '{e.fname}' and '{exporters[sym].fname}'")
                    if sym not in exporters or exporters[sym].library:
                        exporters[sym] = e
    # only keep used modules
    nml = []
    for m in module_list:
        if m.used:
            nml.append(m)
        elif not m.library:
            warning(f"File '{m.fname}' was not used")
    return nml

def convert_common_symbols():
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
        error(f"Undefined symbol '{s}' imported by {comma.join(und[s])}")

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
    global the_module, the_fragment, the_pc, lbranch_counter, hops
    hops = []
    the_module = m
    the_fragment = frag
    the_pc = 0
    lbranch_counter = 0
#    try:
    frag[2]()
#    except Exception as err:
#        fatal(str(err), exc=True)
    nhops = len(hops)
    for i in range(0, nhops):
        next = hops[i+1] if i+1 < nhops else the_pc
        hops[i] = next - hops[i]
    debug(f"Function '{frag[1]}' is {the_pc}-{lbranch_counter} bytes long")
    return frag + (the_pc, lbranch_counter, hops)

def measure_fragments():
    for m in module_list:
        for (i,frag) in enumerate(m.code):
            fragtype = frag[0]
            if fragtype in ('DATA', 'BSS') and frag[3] == 0:
                m.code[i] = measure_data_fragment(m, frag)
            elif fragtype in ('CODE'):
                m.code[i] = measure_code_fragment(m, frag)


                
# ------------- main function


def main(argv):
    '''Main entry point'''
    global lccdir, args, rominfo, symdefs, module_list
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
        parser.add_argument('-cpu', type=int, action='store',
                            help='select the target cpu version')
        parser.add_argument('-rom', type=str, action='store',
                            help='select the target rom version')
        parser.add_argument('-map', type=str, action='store',
                            help='select a linker map')
        parser.add_argument('-d', action='count',
                            help='enable verbose output')
        parser.add_argument('-e', type=str, action='store', default='_start',
                            help='select the entry point symbol (default _start)')
        parser.add_argument('files', type=str, nargs='+',
                            help='input files')
        parser.add_argument('-l', type=str, action='append',
                            help='library files. -lxxx searches for libxxx.a')
        parser.add_argument('-L', type=str, action='append',
                            help='additional library directories')
        args = parser.parse_args(argv)

        # set defaults
        if args.map == None:
            args.map = '64k'
        if args.rom == None:
            args.rom = 'v5a'
        read_rominfo(args.rom)
        if rominfo and args.cpu and args.cpu > rominfo['cpu']:
            print(f"glink: warning: rom '{args.rom}' does not implement cpu{args.cpu}", file=sys.stderr)
        if rominfo and not args.cpu:
            args.cpu = rominfo['cpu']
        args.cpu = args.cpu or 5
        args.files = args.files or []
        args.e = args.e or "_start"
        args.l = args.l or []
        args.L = args.L or []
        read_interface()

        # process map
        read_map(args.map)
        args.L.append(os.path.join(lccdir,f"map{args.map}"))
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
            map_extra_modules()
            module_list += new_modules

        # load libraries requested by the map
        global map_extra_libs
        if map_extra_libs:
            for n in map_extra_libs():
                read_lib(n)

        # load libraries
        for f in args.l:
            read_lib(f)

        # symdefs
        symdefs['_etext'] = 0x0
        symdefs['_edata'] = 0x0
        symdefs['_ebss'] = 0x0
        symdefs['_initsp'] = map_sp()
        symdefs['_minrom'] = rominfo['romType'] if rominfo else 0
        symdefs['_minram'] = map_ram() if map_ram else 1

        # resolve import/exports/common and prune unused modules
        module_list = compute_closure()
        convert_common_symbols()
        check_undefined_symbols()
        if error_counter > 0:
            return 1

        # measure fragments whose length is unknown
        measure_fragments()
        
        return 0
    
    except FileNotFoundError as err:
        fatal(str(err), exc=True)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
