%{
/*---- BEGIN HEADER --*/
  
#include "c.h"
#include "math.h"
  
#define NODEPTR_TYPE Node
#define OP_LABEL(p) ((p)->op)
#define LEFT_CHILD(p) ((p)->kids[0])
#define RIGHT_CHILD(p) ((p)->kids[1])
#define STATE_LABEL(p) ((p)->x.state)

static void address(Symbol, Symbol, long);
static void blkfetch(int, int, int, int);
static void blkloop(int, int, int, int, int, int[]);
static void blkstore(int, int, int, int);
static void defaddress(Symbol);
static void defconst(int, int, Value);
static void defstring(int, char *);
static void defsymbol(Symbol);
static void doarg(Node);
static void emit2(Node);
static void export(Symbol);
static void clobber(Node);
static void function(Symbol, Symbol [], Symbol [], int);
static void global(Symbol);
static void import(Symbol);
static void local(Symbol);
static void progbeg(int, char **);
static void progend(void);
static void segment(int);
static void space(int);
static void target(Node);

static int  if_cv_from_size(Node,int,int);
static int  if_cpu(int,int);
 
static Symbol ireg[32], lreg[32], freg[32];
static Symbol iregw, lregw, fregw;

#define REG_SP   31
#define REG_LR   30
#define REG_SR    1
#define REG_AC    0
#define REG_LAC   3
#define REG_LARG  6
#define REG_FAC   2
#define REG_FARG  5
 
#define REGMASK_VARS            0x00fff000
#define REGMASK_ARGS            0x0000ff00
#define REGMASK_TEMPS           0x3f000f00
#define REGMASK_SAVED           0x00ff0000
 
static int cseg;
static int cpu = 5;

 
/*---- END HEADER --*/
%}
# /*-- BEGIN TERMINALS --/

%start stmt

# From ./ops c=1 s=2 i=2 l=4 h=4 f=5 d=5 x=5 p=2
   
%term CNSTF5=5137
%term CNSTI1=1045 CNSTI2=2069 CNSTI4=4117
%term CNSTP2=2071
%term CNSTU1=1046 CNSTU2=2070 CNSTU4=4118

%term ARGB=41
%term ARGF5=5153
%term ARGI2=2085 ARGI4=4133
%term ARGP2=2087
%term ARGU2=2086 ARGU4=4134

%term ASGNB=57
%term ASGNF5=5169
%term ASGNI1=1077 ASGNI2=2101 ASGNI4=4149
%term ASGNP2=2103
%term ASGNU1=1078 ASGNU2=2102 ASGNU4=4150

%term INDIRB=73
%term INDIRF5=5185
%term INDIRI1=1093 INDIRI2=2117 INDIRI4=4165
%term INDIRP2=2119
%term INDIRU1=1094 INDIRU2=2118 INDIRU4=4166

%term CVFF5=5233
%term CVFI2=2165 CVFI4=4213

%term CVIF5=5249
%term CVII1=1157 CVII2=2181 CVII4=4229
%term CVIU1=1158 CVIU2=2182 CVIU4=4230

%term CVPU2=2198

%term CVUI1=1205 CVUI2=2229 CVUI4=4277
%term CVUP2=2231
%term CVUU1=1206 CVUU2=2230 CVUU4=4278

%term NEGF5=5313
%term NEGI2=2245 NEGI4=4293

%term CALLB=217
%term CALLF5=5329
%term CALLI2=2261 CALLI4=4309
%term CALLP2=2263
%term CALLU2=2262 CALLU4=4310
%term CALLV=216

%term RETF5=5361
%term RETI2=2293 RETI4=4341
%term RETP2=2295
%term RETU2=2294 RETU4=4342
%term RETV=248

%term ADDRGP2=2311

%term ADDRFP2=2327

%term ADDRLP2=2343

%term ADDF5=5425
%term ADDI2=2357 ADDI4=4405
%term ADDP2=2359
%term ADDU2=2358 ADDU4=4406

%term SUBF5=5441
%term SUBI2=2373 SUBI4=4421
%term SUBP2=2375
%term SUBU2=2374 SUBU4=4422

%term LSHI2=2389 LSHI4=4437
%term LSHU2=2390 LSHU4=4438

%term MODI2=2405 MODI4=4453
%term MODU2=2406 MODU4=4454

%term RSHI2=2421 RSHI4=4469
%term RSHU2=2422 RSHU4=4470

%term BANDI2=2437 BANDI4=4485
%term BANDU2=2438 BANDU4=4486

%term BCOMI2=2453 BCOMI4=4501
%term BCOMU2=2454 BCOMU4=4502

%term BORI2=2469 BORI4=4517
%term BORU2=2470 BORU4=4518

%term BXORI2=2485 BXORI4=4533
%term BXORU2=2486 BXORU4=4534

%term DIVF5=5569
%term DIVI2=2501 DIVI4=4549
%term DIVU2=2502 DIVU4=4550

%term MULF5=5585
%term MULI2=2517 MULI4=4565
%term MULU2=2518 MULU4=4566

%term EQF5=5601
%term EQI2=2533 EQI4=4581
%term EQU2=2534 EQU4=4582

%term GEF5=5617
%term GEI2=2549 GEI4=4597
%term GEU2=2550 GEU4=4598

%term GTF5=5633
%term GTI2=2565 GTI4=4613
%term GTU2=2566 GTU4=4614

%term LEF5=5649
%term LEI2=2581 LEI4=4629
%term LEU2=2582 LEU4=4630

%term LTF5=5665
%term LTI2=2597 LTI4=4645
%term LTU2=2598 LTU4=4646

%term NEF5=5681
%term NEI2=2613 NEI4=4661
%term NEU2=2614 NEU4=4662

%term JUMPV=584

%term LABELV=600

%term LOADB=233
%term LOADF5=5345
%term LOADI1=1253 LOADI2=2277 LOADI4=4325
%term LOADP2=2279
%term LOADU1=1254 LOADU2=2278 LOADU4=4326

%term VREGP=711


# /*-- END TERMINALS --/
%%
# /*-- BEGIN RULES --/

reg:  INDIRI1(VREGP)     "# read register\n"
reg:  INDIRU1(VREGP)     "# read register\n"
reg:  INDIRI2(VREGP)     "# read register\n"
reg:  INDIRU2(VREGP)     "# read register\n"
reg:  INDIRP2(VREGP)     "# read register\n"
reg:  INDIRI4(VREGP)     "# read register\n"
reg:  INDIRU4(VREGP)     "# read register\n"
reg:  INDIRF5(VREGP)     "# read register\n"

stmt: ASGNI1(VREGP,reg)  "# write register\n"
stmt: ASGNU1(VREGP,reg)  "# write register\n"
stmt: ASGNI2(VREGP,reg)  "# write register\n"
stmt: ASGNU2(VREGP,reg)  "# write register\n"
stmt: ASGNP2(VREGP,reg)  "# write register\n"
stmt: ASGNI4(VREGP,reg)  "# write register\n"
stmt: ASGNU4(VREGP,reg)  "# write register\n"
stmt: ASGNF5(VREGP,reg)  "# write register\n"

stmt: RETF5(reg)  "# ret\n"  1
stmt: RETI4(reg)  "# ret\n"  1
stmt: RETU4(reg)  "# ret\n"  1
stmt: RETI2(reg)  "# ret\n"  1
stmt: RETU2(reg)  "# ret\n"  1
stmt: RETP2(reg)  "# ret\n"  1
stmt: RETV(reg)   "# ret\n"  1

con8: CNSTI1  "%a"
con8: CNSTU1  "%a"  range(a,0,255)
con8: CNSTI2  "%a"  range(a,0,255)
con8: CNSTU2  "%a"  range(a,0,255)
con8: CNSTP2  "%a"  range(a,0,255)

stmt: ac ""
stmt: reg  ""

ac: reg "LDW(%0);" 20
ac: ADDRGP2 "LDWI(%a);" 20
ac: ADDRLP2 "LDWI(%a+%F);ADDW(SP);" 48
ac: ADDRFP2 "LDWI(%a+%F);ADDW(SP);" 48

reg: ac "\t%0STW(%c)\n" 20
zpv: reg "%0" 

ac: ADDI2(ac,zpv)  "%0ADDW(%1);" 28 
ac: ADDI2(zpv,ac)  "%1ADDW(%0);" 28 
ac: ADDI2(ac,con8) "%0ADDI(%1);" 28
ac: ADDU2(ac,zpv)  "%0ADDW(%1);" 28 
ac: ADDP2(zpv,ac)  "%1ADDW(%0);" 28 
ac: ADDP2(ac,con8) "%0ADDI(%1);" 28

ac: SUBI2(ac,zpv)  "%0SUBW(%1);" 28 
ac: SUBI2(ac,con8) "%0SUBI(%1);" 28
ac: SUBU2(ac,zpv)  "%0SUBW(%1);" 28 
ac: SUBU2(ac,con8) "%0SUBI(%1);" 28
ac: SUBP2(ac,zpv)  "%0SUBW(%1);" 28 
ac: SUBP2(ac,con8) "%0SUBI(%1);" 28

ac: NEGI2(ac) "%0ST(SR);LDI(0);SUBW(SR);" 68
ac: BCOMI2(ac) "%0ST(SR);LDWI(-0);XORW(SR);" 68
ac: BCOMU2(ac) "%0ST(SR);LDWI(-0);XORW(SR);" 68

ac: BANDI2(ac,zpv)  "%0ANDW(%1);" 28
ac: BANDI2(ac,con8)  "%0ANDI(%1);" 16 
ac: BANDU2(ac,zpv)  "%0ANDW(%1);" 28
ac: BANDU2(ac,con8)  "%0ANDI(%1);" 16 

ac: BORI2(ac,zpv)  "%0ORW(%1);" 28
ac: BORI2(ac,con8)  "%0ORI(%1);" 16 
ac: BORU2(ac,zpv)  "%0ORW(%1);" 28
ac: BORU2(ac,con8)  "%0ORI(%1);" 16 

ac: BXORI2(ac,zpv)  "%0XORW(%1);" 28
ac: BXORI2(ac,con8)  "%0XORI(%1);" 16 
ac: BXORU2(ac,zpv)  "%0XORW(%1);" 28
ac: BXORU2(ac,con8)  "%0XORI(%1);" 16

ac: INDIRP2(con8) "LDW(%0)" 20
ac: INDIRP2(ac) "%0DEEK();" 28
ac: INDIRU2(con8) "LDW(%0)" 20
ac: INDIRU2(ac) "%0DEEK();" 28
ac: INDIRI2(con8) "LDW(%0)" 20
ac: INDIRI2(ac) "%0DEEK();" 28
ac: INDIRI1(con8) "LD(%0)" 18
ac: INDIRI1(ac) "%0PEEK();" 26
ac: INDIRU1(con8) "LD(%0)" 18
ac: INDIRU1(ac) "%0PEEK();" 26

stmt: ASGNP2(con8,ac) "\t%1STW(%0)\n" 20
stmt: ASGNP2(zpv,ac) "\t%1DOKE(%0)\n" 28
stmt: ASGNI2(con8,ac) "\t%1STW(%0)\n" 20
stmt: ASGNI2(zpv,ac) "\t%1DOKE(%0)\n" 28
stmt: ASGNU2(con8,ac) "\t%1STW(%0)\n" 20
stmt: ASGNU2(zpv,ac) "\t%1DOKE(%0)\n" 28
stmt: ASGNI1(con8,ac) "\t%1ST(%0)\n" 20
stmt: ASGNI1(zpv,ac) "\t%1POKE(%0)\n" 28
stmt: ASGNU1(con8,ac) "\t%1ST(%0)\n" 20
stmt: ASGNU1(zpv,ac) "\t%1POKE(%0)\n" 28

reg: LOADI1(ac)  "\t%0ST(%c)\n" move(a)
reg: LOADU1(ac)  "\t%0ST(%c)\n" move(a)
reg: LOADI2(ac)  "\t%0STW(%c)\n" move(a)
reg: LOADU2(ac)  "\t%0STW(%c)\n" move(a)
reg: LOADP2(ac)  "\t%0STW(%c)\n" move(a)


# More opcodes for cpu=5


# More opcodes for cpu=6
stmt: ASGNP2(ac,con8) "\t%0DOKEI(%1)\n" if_cpu(6,28)
stmt: ASGNP2(ac,reg) "\t%0DOKEA(%1)\n" if_cpu(6,30)
stmt: ASGNI2(ac,con8) "\t%0DOKEI(%1)\n" if_cpu(6,28)
stmt: ASGNI2(ac,reg) "\t%0DOKEA(%1)\n" if_cpu(6,30)
stmt: ASGNU2(ac,con8) "\t%0DOKEI(%1)\n" if_cpu(6,28)
stmt: ASGNU2(ac,reg) "\t%0DOKEA(%1)\n" if_cpu(6,30)
stmt: ASGNI1(ac,con8) "\t%0POKEI(%1)\n" if_cpu(6,28)
stmt: ASGNI1(ac,reg) "\t%0POKEA(%1)\n" if_cpu(6,30)
stmt: ASGNU1(ac,con8) "\t%0POKEI(%1)\n" if_cpu(6,20)
stmt: ASGNU1(ac,reg) "\t%0POKEA(%1)\n" if_cpu(6,28)

# Long int support
lac: reg "LDW(%0);STW(LAC);LDW(%0+2);STW(LAC+2);" 40
larg: reg "LDW(%0);STW(LARG);LDW(%0+2);STW(LARG+2);" 40
reg: lac "%0LDW(LAC);STW(%c);LDW(LAC+2);STW(%c+2);" 40
lac: INDIRI4(ac) "%0CALLI('@.load_lac');" 256
larg: INDIRI4(ac) "%0CALLI('@.load_larg');" 256
lac: INDIRU4(ac) "%0CALLI('@.load_lac');" 256
larg: INDIRU4(ac) "%0CALLI('@.load_larg');" 256
lac: ADDI4(lac,larg) "%0%1CALLI('@.ladd');" 256
lac: ADDU4(lac,larg) "%0%1CALLI('@.ladd');" 256
lac: SUBI4(lac,larg) "%0%1CALLI('@.lsub');" 256
lac: SUBU4(lac,larg) "%0%1CALLI('@.lsub');" 256
lac: MULI4(lac,larg) "%0%1CALLI('@.lmul');" 256
lac: MULU4(lac,larg) "%0%1CALLI('@.lmul');" 256
lac: DIVI4(lac,larg) "%0%1CALLI('@.ldivs');" 256
lac: DIVU4(lac,larg) "%0%1CALLI('@.ldivu');" 256
lac: NEGI4(lac) "%0CALLI('@.lneg');" 50
lac: BCOMU4(lac) "%0CALLI('@.lcom');" 50
lac: BANDU4(lac,larg) "%0%1CALLI('@.land');"  50
lac: BORU4(lac,larg) "%0%1CALLI('@.lor');"  50
lac: BXORU4(lac,larg) "%0%1CALLI('@.lxor');"  50
lac: BCOMI4(lac) "%0CALLI('@.lcom');" 50
lac: BANDI4(lac,larg) "%0%1CALLI('@.land');"  50
lac: BORI4(lac,larg) "%0%1CALLI('@.lor');"  50
lac: BXORI4(lac,larg) "%0%1CALLI('@.lxor');"  50

reg: LOADI4(reg) "\tLDW(%0);STW(%c);LDW(%0+2);STW(%c+2)\n" move(a)
reg: LOADU4(reg) "\tLDW(%0);STW(%c);LDW(%0+2);STW(%c+2)\n" move(a)
stmt: ASGNI4(ac,lac) "\t%1%0CALLI('@.store_lac')\n" 256
stmt: ASGNU4(ac,lac) "\t%1%0CALLI('@.store_lac')\n" 256

# Floating point support
fac: reg "LDW(%0);STW(FAC);LDW(%0+2);STW(FAC+2);LDW(%0+4);STW(FAC+4);" 60
farg: reg "LDW(%0);STW(FARG);LDW(%0+2);STW(FARG+2);LDW(%0+4);STW(FARG+4);" 60
reg: fac "%0LDW(FAC);STW(%c);LDW(FAC+2);STW(%c+2);LDW(FAC+4);STW(%c+4);" 60
fac: INDIRF5(ac) "%0CALLI('@.load_fac');" 256
farg: INDIRF5(ac) "%0CALLI('@.load_farg');" 256
fac: ADDF5(fac,farg) "%0%1CALLI('@.fadd');" 256
fac: SUBF5(fac,farg) "%0%1CALLI('@.fsub');" 256
fac: MULF5(fac,farg) "%0%1CALLI('@.fmul');" 256
fac: DIVF5(fac,farg) "%0%1CALLI('@.fdiv');" 256
fac: NEGF5(fac) "%0CALLI('@.fneg');" 50
reg: LOADF5(reg) "LDW(%0);STW(%c);LDW(%0+2);STW(%c+2);LDW(%0+4);STW(%c+4)\n" move(a)
stmt: ASGNF5(ac,fac) "\t%1%0CALLI('@.store_fac')\n" 256

# Conversions
ac: CVFI2(fac) "%0CALLI('@.cv_fac_to_lac');LDW(LAC);" 256
lac: CVFI4(fac) "%0CALLI('@.cv_fac_to_lac');" 256
fac: CVIF5(ac) "%0STW(LAC);LDI(0);STW(LAC+2);CALLI('@.cv_lac_to_fac');" if_cv_from_size(a,2,120)
fac: CVIF5(lac) "%0CALLI('@.cv_lac_to_fac');" if_cv_from_size(a,4,256)
ac: CVII2(ac) "%0XORI(128);SUBI(128);" if_cv_from_size(a,1,48)
ac: CVIU2(ac) "%0" if_cv_from_size(a,1,48)
ac: CVUI2(ac) "%0" if_cv_from_size(a,1,48)
ac: CVUU2(ac) "%0" if_cv_from_size(a,1,48)
ac: CVII2(lac) "%0LDW(LAC);" if_cv_from_size(a,4,20)
ac: CVIU2(lac) "%0LDW(LAC);" if_cv_from_size(a,4,20)
ac: CVUI2(lac) "%0LDW(LAC);" if_cv_from_size(a,4,20)
ac: CVUU2(lac) "%0LDW(LAC);" if_cv_from_size(a,4,20)
lac: CVIU4(ac) "%0STW(LAC);LDI(0);STW(LAC+2);" if_cv_from_size(a,2,50)
lac: CVII4(ac) "%0STW(LAC);LD(LAC+1);XORI(128);SUBI(128);LD('vAH');ST(LAC+2);ST(LAC+3);" if_cv_from_size(a,2,120)
lac: CVUU4(ac) "%0STW(LAC);LDI(0);STW(LAC+2);" if_cv_from_size(a,2,50)
lac: CVUI4(ac) "%0STW(LAC);LDI(0);STW(LAC+2);" if_cv_from_size(a,2,50)

# Labels and jumps
stmt: LABELV "label(%a)\n"


# /*-- END RULES --/
%%
/*---- BEGIN CODE --*/


static void comment(const char *fmt, ...) {
  va_list ap;
  print("-- ");
  va_start(ap, fmt);
  vfprint(stdout, NULL, fmt, ap);
  va_end(ap);
}

static int if_cv_from_size(Node p, int sz, int cost)
{
  assert(p->syms[0]);
  assert(p->syms[0]->scope == CONSTANTS);
  assert(p->syms[0]->type = inttype);
  if (p->syms[0]->u.c.v.i == sz)
    return cost;
  return LBURG_MAX;
}

static int  if_cpu(int mincpu, int cost)
{
  return (cpu >= mincpu) ? cost : LBURG_MAX;
}

static void progend(void)
{
  print("endmodule();\n");
}

static void progbeg(int argc, char *argv[])
{
  int i;
  /* Parse flags */
  parseflags(argc, argv);
  for (i=0; i<argc; i++)
    if (!strcmp(argv[i],"-cpu=5"))
      cpu = 5;
    else if (!strcmp(argv[i],"-cpu=6"))
      cpu = 6;
    else if (!strncmp(argv[i],"-cpu=",5))
      error("invalid cpu %s\n", argv[i]+5);
  /* Print header */
  print("module('@@modulename@@',%d)\n", cpu); /* more here */
  /* Prepare registers */
  ireg[0] = mkreg("AC", 0, 1, IREG);
  ireg[1] = mkreg("SR", 0, 1, IREG);
  for (i=2; i<30; i++)
    ireg[i] = mkreg("R%d", i, 1, IREG);
  ireg[30] = mkreg("LR", 0, 1, IREG);
  ireg[31] = mkreg("SP", 0, 1, IREG);
  /* Register pairs for longs */
  lreg[3] = mkreg("LAC", 3, 3, IREG);
  lreg[6] = mkreg("LARG", 6, 3, IREG);
  for (i=8; i<29; i++)
    lreg[i] = mkreg("L%d", i, 3, IREG);
  /* Register triple for floats */
  freg[2] = mkreg("FAC", 2, 7, IREG);
  freg[5] = mkreg("FARG", 2, 7, IREG);  
  for (i=8; i<28; i++)
    freg[i] = mkreg("F%d", i, 7, IREG);
  /* Prepare wildcards */
  iregw = mkwildcard(ireg);
  lregw = mkwildcard(lreg);
  fregw = mkwildcard(freg);
  tmask[IREG] = REGMASK_TEMPS;
  vmask[IREG] = REGMASK_VARS;
  tmask[FREG] = vmask[FREG] = 0;
  /* No segment */
  cseg = -1;
}

static Symbol rmap(int opk)
{
  switch(optype(opk)) {
  case I: case U:
    return (opsize(opk)==4) ? lregw : iregw;
  case P: case B:
    return iregw;
  case F:
    return fregw;
  default:
    return 0;
  }
}
  
static Symbol argreg(int argno, int ty, int sz, int *roffset)
{
  Symbol r;
  if (argno == 0)
    *roffset = 8; /* First register is R8 */
  if (*roffset >= 16)
    return 0;
  if (ty == I || ty == U || ty == P)
    if (sz <= 2)
      r = ireg[*roffset];
    else
      r = lreg[*roffset];
  else if (ty == F)
    r = freg[*roffset];
  if (r == 0 || r->x.regnode->mask & ~REGMASK_ARGS)
    return 0;
  *roffset += roundup(sz,2)/2;
  return r;
}

static void target(Node p)
{
  assert(p);
  switch (specific(p->op)) {
  case RET+I: case RET+U: case RET+P:
    rtarget(p, 0, (opsize(p->op)==4) ? lreg[3]: ireg[3]);
    break;
  case RET+F:
    rtarget(p, 0, freg[2]);
    break;
  }
}

static void clobber(Node p)
{
}

static void emit2(Node p)
{
}

static void doarg(Node p)
{
}

static void local(Symbol p)
{
  if (askregvar(p, rmap(ttob(p->type))) == 0)
    mkauto(p);
}

static int bitcount(unsigned mask) {
  unsigned i, n = 0;
  for (i = 1; i; i <<= 1)
    if (mask&i)
      n++;
  return n;
}

static void ld_sp_plus_offset(int offset)
{
  if (offset >= 256 || offset <= -256)
    print("LDWI(%s);ADDW(SP);",offset);
  else if (offset > 0)
    print("LDW(SP);ADDI(%d);",offset);
  else if (offset < 0)
    print("LDW(SP);SUBI(%d);",-offset);
  else
    print("LDW(SP);");
}

static void function(Symbol f, Symbol caller[], Symbol callee[], int ncalls)
{
  int i, roffset, sizesave, varargs, noret, first;
  Symbol r, argregs[8];
  usedmask[0] = usedmask[1] = 0;
  freemask[0] = freemask[1] = ~(unsigned)0;
  offset = maxoffset = maxargoffset = 0;
  /* does it return */
  assert(f->type && f->type->type);
  noret = (optype(ttob(f->type->type)) == VOID);
  /* is it variadic? */
  for (i = 0; callee[i]; i++) {}
  varargs = variadic(f->type) || i > 0 && strcmp(callee[i-1]->name, "va_alist") == 0;
  /* locate incoming arguments */
  roffset = 0;
  for (i = 0; callee[i]; i++) {
    Symbol p = callee[i];
    Symbol q = caller[i];
    assert(q);
    p->x.offset = q->x.offset = offset;
    p->x.name = q->x.name = stringd(offset);
    r = argreg(i, optype(ttob(q->type)), q->type->size, &roffset);
    if (i < 8)
      argregs[i] = r;
    offset += q->type->size;
    if (varargs)
      p->sclass = AUTO;
    else if (r && ncalls == 0 && !isstruct(q->type) && !p->addressed)
      {
        p->sclass = q->sclass = REGISTER;
        askregvar(p, r);
        assert(p->x.regnode && p->x.regnode->vbl == p);
        q->x = p->x;
        q->type = p->type;
      }
    else if (askregvar(p, rmap(ttob(p->type))) && r != NULL
             && (isint(p->type) || p->type == q->type))
      {
        assert(q->sclass != REGISTER);
        p->sclass = q->sclass = REGISTER;
        q->type = p->type;
      }
  }
  /* gen code */
  assert(!caller[i]);
  offset = 0;
  gencode(caller, callee);
  /* prologue */
  comment("begin function %s\n", f->x.name);
  segment(CODE);
  global(f);
  print("\tLDW('vLR');STW(LR)\n");
  if (ncalls)
    usedmask[IREG] |= (1 << REG_LR);
  usedmask[IREG] &= REGMASK_SAVED;
  sizesave = 2 * bitcount(usedmask[IREG]);
  framesize = maxargoffset + sizesave + maxoffset;
  print("\t");
  ld_sp_plus_offset(-framesize);
  print("STW(SP)\n");
  /* save callee saved registers */
  first = 1;
  for (i=0; i<=31; i++)
    if (usedmask[IREG]&(1<<i)) {
      print("\t");
      if (first) {
        ld_sp_plus_offset(maxargoffset);
        print((cpu >= 6) ? "" : "STW(SR);");
      } else {
        print((cpu >= 6) ? "ADDI(2);" : "LDW(SR);ADDI(2);STW(SR);");
      }
      print((cpu >= 6) ? "DOKEA(R%d)\n" : "LDW(R%d);DOKE(SR)\n", i);
      first = 0;
    }
  /* save args into new registers */
  for (i = 0; i < 8 && callee[i]; i++) {
    r = argregs[i];
    if (r && r->x.regnode != callee[i]->x.regnode) {
      Symbol out = callee[i];
      Symbol in  = caller[i];
      int rn = r->x.regnode->number;
      int sz = in->type->size;
      assert(out && in && r && r->x.regnode);
      assert(out->sclass != REGISTER || out->x.regnode);
      if (out->sclass == REGISTER && (isint(out->type) || out->type == in->type)) {
        int outn = out->x.regnode->number;
        print("\tLDW(R%d);STW(R%d)", outn, rn);
        if (sz > 2)
          print(";LDW(R%d);STW(R%d)", outn+1, rn+1);
        if (sz > 4)
          print(";LDW(R%d);STW(R%d)", outn+2, rn+2);
        print("\n");
      } else {
        int off = in->x.offset + framesize;
        print("\t");
        if (isfloat(in->type))
          print("LDW(R%d);STW(R2);LDW(R%d);STW(R3);LDW(R%d);STW(R4);", rn, rn+1, rn+2);
        else if (sz == 4)
          print("LDW(R%d);STW(R3);LDW(R%d);STW(R4);", rn, rn+1);
        if (off >= 256)
          print("LDWI(%d);ADDW(SP);",off);
        else if (off > 0)
          print("LDW(SP);ADDI(%d);",off);
        else
          print("LDW(SP);");
        if (isfloat(in->type))
          print("CALLI('@.store_fac')\n");
        else if (sz == 4)
          print("CALLI('@.store_lac')\n");
        else if (sz == 2)
          print((cpu >= 6) ? "DOKEA(R%d)\n" : "STW(SR);LDW(R%d);DOKE(SR)\n", rn);
        else if (sz == 1)
          print((cpu >= 6) ? "POKEA(R%d)\n" : "STW(SR);LD(R%d);POKE(SR)\n", rn);
        else
          assert(0);
      }
    }
  }
  /* Emit actual code */
  print("\t");
  comment("code\n");
  emitcode();
  print("\t");
  comment("epilogue\n");
  /* Restore callee saved registers */
  first = 1;
  for (i=0; i<=31; i++)
    if (usedmask[IREG]&(1<<i)) {
      print("\t");
      if (first) {
        ld_sp_plus_offset(maxargoffset);
        print((cpu >= 6) ? "" : "STW(SR);");
      } else {
        print((cpu >= 6) ? "ADDI(2);" : "LDW(SR);ADDI(2);STW(SR);");
      }
      print((cpu >= 6) ? "DEEKA(R%d)\n" : "DEEK(SR);STW(R%d)\n", i);
      first = 0;
    }
  print("\t");
  ld_sp_plus_offset(framesize);
  print("STW(SP)\n");
  print("\tLDW(LR);STW('vLR');RET()\n");
  comment("end function %s\n", f->x.name);
}

static void defconst(int suffix, int size, Value v)
{
  if (suffix == F) {
    double d = v.d;
    int exp;
    unsigned long mantissa;
    assert(size == 5);
    assert(isnormal(d));
    mantissa = (unsigned long)(frexp(d,&exp) * pow(2.0, 32));
    if (mantissa == 0 || exp < -128)
      print("\tbytes(0,0,0,0,0) ");
    else
      print("\tbytes(%d,%d,%d,%d,%d) ",
            exp+128, ((mantissa>>24)&0x7f)|((d<0.0)?0x80:0x00),
            (mantissa>>16)&0xff, (mantissa>>8)&0xff, (mantissa&0xff) );
    comment("%f\n", d);
  } else {
    long x = (suffix == P) ? (unsigned)(size_t)v.p : (suffix == I) ? v.i : v.u;
      if (size == 1)
      print("\tbytes(%d)\n", x&0xff);
    else if (size == 2)
      print("\twords(%d)\n", x&0xffff);
    else if (size == 4)
      print("\twords(%d,%d)\n", x&0xffff, (x>>16)&0xffff);
  }
}

static void defaddress(Symbol p)
{
  print("\twords(%s)\n", p->x.name);
}

static void defstring(int n, char *str)
{
  int i;
  for (i=0; i<n; i++)
    print( (i&7==0) ? "\tbytes(%d" : (i&7==7) ? ",%d)\n" : ",%d", (int)str[i]&0xff );
  if (i&7)
    print(")\n");
}

static void export(Symbol p)
{
  if (isfunc(p->type))
    print("\texport(%s)\n", p->x.name);
  else
    print("\texport(%s,%d)\n", p->x.name, p->type->size);
}

static void import(Symbol p)
{
  if (isfunc(p->type))
    print("\timport(%s)\n", p->x.name);
  else
    print("\timport(%s,%d)\n", p->x.name, p->type->size);
}

static void defsymbol(Symbol p)
{
  if (p->scope >= LOCAL && p->sclass == STATIC)
    p->x.name = stringf("'.%d'", genlabel(1));
  else if (p->generated)
    p->x.name = stringf("'.%s'", p->name);
  else if (p->scope == GLOBAL || p->sclass == EXTERN)
    p->x.name = stringf("'%s'", p->name);
  else
    p->x.name = p->name;
}

static void address(Symbol q, Symbol p, long n)
{
  if (p->scope == GLOBAL || p->sclass == STATIC || p->sclass == EXTERN)
    q->x.name = stringf("val(%s)%s%D", p->x.name, n >= 0 ? "+" : "", n);
  else {
    assert(n <= INT_MAX && n >= INT_MIN);
    q->x.offset = p->x.offset + n;
    q->x.name = stringd(q->x.offset);
  }
}

static void global(Symbol p)
{
  print("label(%s)\n", p->x.name);
}

static void segment(int n)
{
  if (n == cseg)
    return;
  switch (n) {
  case CODE: print("\tsegment('CODE')\n"); break;
  case BSS:  print("\tsegment('BSS')\n");  break;
  case DATA: print("\tsegment('DATA')\n"); break;
  case LIT:  print("\tsegment('LIT')\n"); break;
  }
  cseg = n;
}

static void space(int n)
{
  print("\tspace(%d)\n", n);
}

static void blkloop(int dreg, int doff, int sreg,
                    int soff, int size, int tmps[])
{
}

static void blkfetch(int size, int off, int reg, int tmp)
{
}

static void blkstore(int size, int off, int reg, int tmp)
{
}


Interface gigatronIR = {
        1, 1, 0,  /* char */
        2, 1, 0,  /* short */
        2, 1, 0,  /* int */
        4, 1, 1,  /* long */
        4, 1, 1,  /* long long */
        5, 1, 1,  /* float */
        5, 1, 1,  /* double */
        5, 1, 1,  /* long double */
        2, 2, 0,  /* T * */
        0, 1, 0,  /* struct */
        0,        /* little_endian */
        0,        /* mulops_calls */
        0,        /* wants_callb */
        0,        /* wants_argb */
        1,        /* left_to_right */
        0,        /* wants_dag */
        0,        /* unsigned_char */
        address,
        blockbeg,
        blockend,
        defaddress,
        defconst,
        defstring,
        defsymbol,
        emit,
        export,
        function,
        gen,
        global,
        import,
        local,
        progbeg,
        progend,
        segment,
        space,
        /* stabblock, stabend, 0, stabinit, stabline, stabsym, stabtype */
        0, 0, 0, 0, 0, 0, 0,
        /* Xinterface */
        { 1,
          rmap,
          blkfetch, blkstore, blkloop,
          _label,
          _rule,
          _nts,
          _kids,
          _string,
          _templates,
          _isinstruction,
          _ntname,
          emit2,
          doarg,
          target,
          clobber,
        }
};

/*---- END CODE --*/

/* Local Variables:  */
/* mode: c           */
/* End:              */
