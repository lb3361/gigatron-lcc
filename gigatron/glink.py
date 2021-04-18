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
emit_counter = 0
lbranch_counter = 0

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
        self.genlabelcounter = 0
    def __repr__(self):
        return f"Module('{self.name}',...)"
    def genlabel():
        self.genlabelcounter += 1
        return f".LL{self.genlabelcounter}"
    def run(self,proc):
        '''Execute the module code with the specified delegate''' 
        global current_proc, current_module
        current_proc = proc
        current_module = self
        self.genlabelcounter = 0
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

def is_zero(x):
    if isinstance(x,int) and not isinstance(x,Unk):
        return int(x) == 0
    return False

def is_zeropage(x):
    if isinstance(x,int) and not isinstance(x,Unk):
        return int(x) & 0xff00 == 0
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

def check_zp(x):
    x = v(x)
    if is_not_zeropage(x):
        warning(f"zero page argument overflow")
    return x

def check_br(x):
    x = v(x)
    if is_not_pcpage(x):
        warning(f"short branch overflow")
    return (int(x)-2) & 0xff

def check_cpu(op, v):
    if args.cpu < v:
        warning(f"opcode not implemented for cpu={arg.cpu}")

def emit(*args):
    global emit_counter
    emit_counter += len(args)
    current_proc.emit(*args)

def emitjmp(d, saveac=False):
    if is_pcpage(d): # 2 bytes
        BRA(d)
        return
    global lbranch_counter
    if args.cpu >= 5: # 3 bytes
        lbranch_counter += 3
        CALLI(d)
    elif not saveac:  # 5 bytes
        lbranch_counter += 5
        emit(0x11, lo(int(d)-2), hi(int(d))) # LDWI (nohop)
        STW('vPC')
    else:             # 10 bytes (sigh!)
        lbranch_counter += 10
        STLW(-2)
        emit(0x11, lo(int(d)), hi(int(d)))   # LDWI (nohop)
        STW('vLR')
        LDLW(-2)
        RET()
    
def emitjcc(BCC, BNCC, d, saveac=False):
    lbl = current_module.genlabel()
    if is_pcpage(d):
        BCC(d)
    else:
        BNCC(lbl);
        emitjmp(int(d), saveac=saveac)
        label(lbl)
    
        
# ------------- usable vocabulary for .s/.o/.a files

def register_names():
    d = {}
    d['AC'] = 0x18
    d['FACEXT'] = 0x81
    d['FACEXP'] = 0x82
    d['FACSGN'] = 0x83
    d['FACM'] = 0x84
    d['LAC'] = 0x84
    for i in range(0,4): d[f'T{i}'] = 0x8e-i-i
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
    check_cpu(5); d=int(v(d)); emit(0x85, lo(d-2), hi(d))
@vasm
def CMPHS(d):
    check_cpu(5); emit(0x1f, check_zp(d))
@vasm
def CMPHU(d):
    check_cpu(5); emit(0x97, check_zp(d))

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
    d = v(d)
    if is_zeropage(d):
        emit(0x59, d)             # LDI  (nohop)
    else:
        emit(0x11, lo(d), hi(d))  # LDWI (nohop)
@vasm
def _LDW(d):
    emit(0x21, v(d))              # LDW (nohop)
@vasm
def _SHL(d):
    STW(T0); LDW(d); STW(T1)
    extern('_@_shl16')
    _CALLI('_@_shl')            # T0<<T1 -> AC
@vasm
def _SHRS(d):
    STW(T0); LDW(d); STW(T1)
    extern('_@_shrs16')
    _CALLI('_@_shrs16')         # T0>>T1 --> AC
@vasm
def _SHRU(d):
    STW(T0); LDW(d); STW(T1)
    extern('_@_shru16')
    _CALLI('_@_shru16')         # T0>>T1 --> AC
@vasm
def _MUL(d):
    STW(T0); LDW(d); STW(T1)
    extern('_@_mul16')
    _CALLI('_@_mul16')          # T0*T1 --> AC
@vasm
def _DIVS(d):
    STW(T0); LDW(d); STW(T1)
    extern('_@_divs16')
    _CALLI('_@_divs16')         # T0/T1 --> AC
@vasm
def _DIVU(d):
    STW(T0); LDW(d); STW(T1)
    extern('_@_divu16')
    _CALLI('_@_divu16')         # T0/T1 --> AC
@vasm
def _MODS(d):
    STW(T0); LDW(d); STW(T1)
    extern('_@_mods16')
    _CALLI('_@_mods16')         # T0%T1 --> AC
@vasm
def _MODU(d):
    STW(T0); LDW(d); STW(T1)
    extern('_@_modu16')
    _CALLI('_@_modu16')         # T0%T1 --> AC
@vasm
def _MOV(s,d):
    '''Move word from s to d.
       Also accepts [AC] for s or d.'''
    if s != d:
        if d == [AC] and is_zeropage(s) and args.cpu > 5:
            DOKEA(s)
            return
        if s == [AC] and is_zeropage(d) and args.cpu > 5:
            DEEKA(d)
            return
        if d == [AC]:
            STW(T0)
        if s == AC:
            pass
        elif s == [AC]:
            DEEK()
        elif is_zeropage(s):
            _LDW(s)
        else:
            _LDI(s); DEEK()
        if d == AC:
            pass
        elif is_zeropage(d):
            STW(d)
        elif d == [AC]:
            DOKE(T0)
        else:
            STW(T1); _LDI(d); STW(T0); _LDW(T1); DOKE(T0)
    
@vasm
def _BRA(d, saveac=False):
    emitjmp(v(d), saveac=saveac)
@vasm
def _BEQ(d, saveac=False):
    emitjcc(BEQ, BNE, v(d), saveac=saveac)
@vasm
def _BNE(d, saveac=False):
    emitjcc(BNE, BEQ, v(d), saveac=saveac)
@vasm
def _BLT(d, saveac=False):
    emitjcc(BLT,_BGE, v(d), saveac=saveac)
@vasm
def _BGT(d, saveac=False):
    emitjcc(BGT,_BLE, v(d), saveac=saveac)
@vasm
def _BLE(d, saveac=False):
    emitjcc(BLE, BGT, v(d), saveac=saveac)
@vasm
def _BGE(d, saveac=False):
    emitjcc(BGE, BLT, v(d), saveac=saveac)
@vasm
def _CMPIS(d):
    if args.cpu >= 5:
        CMPHS(0); SUBI(d)
    else:
        lbl = current_module.genlabel()
        BLT(lbl)
        SUBI(d)
        label(lbl)
@vasm
def _CMPIU(d):
    if args.cpu >= 5:
        CMPHU(0); SUBI(d)
    else:
        lbl = current_module.genlabel()
        BGE(lbl)
        LDWI(0x100)
        label(lbl)
        SUBI(d)
@vasm
def _CMPWS(d):
    if args.cpu >= 5:
        CMPHS(d+1); SUBW(d)
    else:
        lbl1 = current_module.genlabel()
        lbl2 = current_module.genlabel()
        STW(T0); XORW(d)
        BGE(lbl1)
        LDW(T0); ORI(1)
        BRA(lbl2)
        label(lbl1)
        LDW(T0); SUBW(d)
        label(lbl2)
@vasm
def _CMPWU(d):
    if args.cpu >= 5:
        CMPHU(d+1); SUBW(d)
    else:
        lbl1 = current_module.genlabel()
        lbl2 = current_module.genlabel()
        STW(T0); XORW(d)
        BGE(lbl1)
        LDW(d); ORI(1)
        BRA(lbl2)
        label(lbl1)
        LDW(T0); SUBW(d)
        label(lbl2)
@vasm
def _BMOV(s,d,n):
    '''Move memory block of size n from s to d.
       Also accepts [AC] or [T0] for s and [AC] or [T1] for d.'''
    dr = v(dr)
    sr = v(sr)
    n = v(n)
    if s != d:
        if d == [AC]:
            STW(T1)
        if s == [AC]:
            STW(T0)
        if d != [AC] and d != [T1]:
            _LDI(d); STW(T1)
        if s != [AC] and s != [T0]:
            _LDI(s); STW(T0)
        _LDI(n); STW(T2)
        extern('_@_memcpy')
        _CALLI('_@_memcpy')         # [T1..T1+T2) --> [T0..T0+T2)
@vasm
def _LMOV(s,d):
    '''Move long from reg s to d.
       Also accepts [AC] or [T0] for s and [AC] or [T1] for d.'''
    s = v(s)
    d = v(d)
    if s != d:
        if is_zeropage(s) and is_zeropage(d):
            LDW(s); STW(d); LDW(s+2); STW(d+2)
        elif is_zeropage(d) and args.cpu  > 5:
            if s == [T0]:
                LDW(T0)
            elif s != [AC]:
                _LDI(s)
            DEEKA(d); ADDI(2); DEEKA(d+2)
        elif is_zeropage(s) and args.cpu  > 5:
            if d == [T1]:
                LDW(T1)
            elif d != [AC]:
                _LDI(s)
            DOKEA(s); ADDI(2); DOKEA(d+2)
        elif is_zeropage(d):
            if s == [AC]:
                STW(T0)
            elif s != [T0]:
                _LDI(s); STW(T0)
            DEEK(); STW(d); LDW(T0); ADDI(2); DEEK(); STW(d+2)
        else:
            if d == [AC]:
                STW(T1)
            if s == [AC]:
                STW(T0)
            if d != [AC] and d != [T1]:
                _LDI(d); STW(T1)
            if s != [AC] and s != [T0]:
                _LDI(s); STW(T0)
            else:
                LDW(T0)
            DEEK(); DOKE(T1)
            LDW(T1); ADDI(2); STW(T1);
            LDW(T0); ADDI(2);
            DEEK(); DOKE(T0)
@vasm
def _LADD():
    extern('_@_ladd')              # [AC/T0] means [AC] for cpu>=5, [T0] for cpu<5
    _CALLI('_@_ladd', storeac=T0)  # LAC+[AC/T0] --> LAC
@vasm
def _LSUB():
    extern('_@_lsub') 
    _CALLI('_@_lsub', storeac=T0)  # LAC-[AC/T0] --> LAC
@vasm
def _LMUL():
    extern('_@_lmul')
    _CALLI('_@_lmul', storeac=T0)  # LAC*[AC/T0] --> LAC
@vasm
def _LDIVS():
    extern('_@_ldivs')
    _CALLI('_@_ldivs', storeac=T0)  # LAC/[AC/T0] --> LAC
@vasm
def _LDIVU():
    extern('_@_ldivu')
    _CALLI('_@_ldivu', storeac=T0)  # LAC/[AC/T0] --> LAC
@vasm
def _LMODS():
    extern('_@_lmods')
    _CALLI('_@_lmods', storeac=T0)  # LAC%[AC/T0] --> LAC
@vasm
def _LMODU():
    extern('_@_lmodu')
    _CALLI('_@_lmodu', storeac=T0)  # LAC%[AC/T0] --> LAC
@vasm
def _LSHL(d):
    extern('_@_lshl')
    _CALLI('_@_lshl', storeac=T0)  # LAC<<[AC/T0] --> LAC
@vasm
def _LSHRS(d):
    extern('_@_lshrs')
    _CALLI('_@_lshrs', storeac=T0)  # LAC>>[AC/T0] --> LAC
@vasm
def _LSHRU(d):
    extern('_@_lshru')
    _CALLI('_@_lshru', storeac=T0)  # LAC>>[AC/T0] --> LAC
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
    _CALLI('_@_land', storeac=T0)   # LAC&[AC/T0] --> LAC
@vasm
def _LOR():
    extern('_@_lor')
    _CALLI('_@_lor', storeac=T0)    # LAC|[AC/T0] --> LAC
@vasm
def _LXOR():
    extern('_@_lxor')
    _CALLI('_@_lxor', storeac=T0)   # LAC^[AC/T0] --> LAC
@vasm
def _LCMPS():
    extern('_@_lcmps')
    _CALLI('_@_lcmps', storeac=T0)  # SGN(LAC-[AC/T0]) --> AC
@vasm
def _LCMPU():
    extern('_@_lcmpu')
    _CALLI('_@_lcmpu', storeac=T0)  # SGN(LAC-[AC/T0]) --> AC
@vasm
def _LCMPX():
    extern('_@_lcmpx')
    _CALLI('_@_lcmpx', storeac=T0)  # TST(LAC-[AC/T0]) --> AC
@vasm
def _FMOV(s,d):
    '''Move float from reg s to d with special cases when s or d is FAC.
       Also accepts [AC] or [T0] for s and [AC] or [T1] for d.'''
    s = v(s)
    d = v(d)
    if s != d:
        if d == [AC]:
            STW(T1)
        if s == [AC]:
            STW(T0)
        if d != [AC] and d != [T1]:
            _LDI(d); STW(T1)
        if s != [AC] and s != [T0]:
            _LDI(s); STW(T0)
        if s == FAC:
            extern('_@_fstorefac') 
            _CALLI('_@_fstorefac')   # [T0] --> FAC
        elif d == FAC:
            extern('_@_floadfac')
            _CALLI('_@_floadfac')    #  FAC --> [T1]
        else:
            extern('_@_fcopy')       # [T0] --> [T1]
            _CALLI('_@_fcopy')
@vasm
def _FADD():
    extern('_@_fadd')
    _CALLI('_@_fadd', storeac=T0)   # FAC+[AC/T0] --> FAC
@vasm
def _FSUB():
    extern('_@_fsub')
    _CALLI('_@_fsub', storeac=T0)   # FAC-[AC/T0] --> FAC
@vasm
def _FMUL():
    extern('_@_fmul')
    _CALLI('_@_fmul', storeac=T0)   # FAC*[AC/T0] --> FAC
@vasm
def _FDIV():
    extern('_@_fdiv')
    _CALLI('_@_fdiv', storeac=T0)   # FAC/[AC/T0] --> FAC
@vasm
def _FNEG():
    extern('_@_fneg')
    _CALLI('_@_fneg')               # -FAC --> FAC
@vasm
def _FCMP():
    extern('_@_fcmp')
    _CALLI('_@_fcmp', storeac=T0)   # SGN(FAC-[AC/T0]) --> AC
@vasm
def _CALLI(d, saveac=False, storeac=None):
    '''Call subroutine at far location d.
       When cpu<5, option saveac=True ensures AC is preserved, 
       and option storeac=reg stores AC into a register before jumping.
       When cpu>=5, this just calls CALLI. '''
    if args.cpu >= 5:
        CALLI(d)
    elif saveac:
        STSW(-2)
        LDWI(d)
        STW('sysFn')
        LDSW(-2)
        CALL('sysFn')
    elif storeac:
        STW(storeac)
        LDWI(d)
        STW('sysFn')
        CALL('sysFn')
    else:
        LDWI(d)
        STW('sysFn')
        CALL('sysFn')

# export(sym):
# extern(sym)
# common(sym,size,align)
# segment(seg)
# function(sym)
# globvar(sym)
# label(sym,[def])
# sethop(n)
# tryhop(jump=True)
# align(d)
# bytes(*args)
# words(*args)
# space(d)




    
        
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
