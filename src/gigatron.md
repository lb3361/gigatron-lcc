# /* 
%{
/*---- BEGIN HEADER --*/

#include "c.h"
#include <ctype.h>
#include <math.h>

#define NODEPTR_TYPE Node
#define OP_LABEL(p) ((p)->op)
#define LEFT_CHILD(p) ((p)->kids[0])
#define RIGHT_CHILD(p) ((p)->kids[1])
#define STATE_LABEL(p) ((p)->x.state)

static void address(Symbol, Symbol, long);
static void blkfetch(/* int, int, int, int */) {}
static void blkloop(/* int, int, int, int, int, int[] */) {}
static void blkstore(/* int, int, int, int */) {}
static void defaddress(Symbol);
static void defconst(int, int, Value);
static void defstring(int, char *);
static void defsymbol(Symbol);
static void doarg(Node);
static void emit2(/* Node */) {}
static void emit3(const char*, Node, Node*, short*);
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


/* Cost functions */
static int  if_zpconst(Node);
static int  if_zpglobal(Node);
static int  if_rmw1(Node,int);
static int  if_rmw2(Node,int);
static int  if_cv_from(Node,int,int);
static int  if_arg_reg(Node);
static int  if_arg_stk(Node);
 
/* Registers */
static Symbol ireg[32], lreg[32], freg[32];
static Symbol iregw, lregw, fregw;

#define REGMASK_VARS            0x00ffc000
#define REGMASK_ARGS            0x00003f00
#define REGMASK_TEMPS           0x3f003f00
#define REGMASK_LR              0x40000000
#define REGMASK_LAC_LARG        0x000000d8
#define REGMASK_FAC_FARG        0x000000fc

/* Misc */ 
static int cseg;
static int cpu = 5;

#define MINCPU5(cost) ((cpu<5)?LBURG_MAX:(cost))
#define MINCPU6(cost) ((cpu<6)?LBURG_MAX:(cost))
 
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
%term CVFU2=2166 CVFU4=4214

%term CVIF5=5249
%term CVII1=1157 CVII2=2181 CVII4=4229
%term CVIU1=1158 CVIU2=2182 CVIU4=4230

%term CVPU2=2198

%term CVUF5=5297
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

# -- common rules
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

# -- constants
con0: CNSTI1  "%a"  range(a,0,0)
con0: CNSTU1  "%a"  range(a,0,0)
con0: CNSTI2  "%a"  range(a,0,0)
con0: CNSTU2  "%a"  range(a,0,0)
con1: CNSTI1  "%a"  range(a,1,1)
con1: CNSTU1  "%a"  range(a,1,1)
con1: CNSTI2  "%a"  range(a,1,1)
con1: CNSTU2  "%a"  range(a,1,1)
con8: CNSTI1  "%a"  range(a,0,255)
con8: CNSTU1  "%a"  range(a,0,255)
con8: CNSTI2  "%a"  range(a,0,255)
con8: CNSTU2  "%a"  range(a,0,255)
con8: CNSTP2  "%a"  if_zpconst(a)
co8n: CNSTI2  "%a"  range(a,-255,-1)
con: CNSTI1  "%a"
con: CNSTU1  "%a"
con: CNSTI2  "%a"
con: CNSTU2  "%a"
con: CNSTP2  "%a"
con: addr "%0"

# -- lddr represent a frame offset
# -- addr represent a simple address
# -- zddr represent a zero page address
lddr: ADDRLP2 "%a+%F"
lddr: ADDRFP2 "%a+%F"
addr: ADDRGP2 "%a" 
addr: con "%0" 1
addr: zddr "%0"
zddr: VREGP "%a"
zddr: ADDRGP2 "%a" if_zpglobal(a)
zddr: con8 "%0"

# -- eac when ac represents a simple address, that is,
#        provably computed without trashing anything but AC.
eac: zddr "LDI(%0);" 16
eac: addr "LDWI(%0);" 20
eac: lddr "_SP(%0);" 40

# -- stmt & reg
stmt: reg ""
stmt: ac1 "\t%0\n"
reg: ac "\t%0%{%c!=AC:STW(%c);}\n" 20
 
# -- loada when using simple addresses (not trashing SR)
# -- loadx when complex address calculation is needed
loada: INDIRI2(eac) "%0DEEK();" 20 
loada: INDIRU2(eac) "%0DEEK();" 20 
loada: INDIRP2(eac) "%0DEEK();" 20 
loada: INDIRI1(eac) "%0PEEK();" 16 
loada: INDIRU1(eac) "%0PEEK();" 16 
loada: INDIRI2(zddr) "LDW(%0);" 20 
loada: INDIRU2(zddr) "LDW(%0);" 20 
loada: INDIRP2(zddr) "LDW(%0);" 20 
loada: INDIRI1(zddr) "LD(%0);" 16 
loada: INDIRU1(zddr) "LD(%0);" 16 
loadx: INDIRI2(ac) "%0DEEK();" 20
loadx: INDIRU2(ac) "%0DEEK();" 20
loadx: INDIRP2(ac) "%0DEEK();" 20
loadx: INDIRI1(ac) "%0PEEK();" 16
loadx: INDIRU1(ac) "%0PEEK();" 16

# -- ac when result left in AC
# -- ac1 indicates unclean high byte for I1/U1
ac: reg "%{%0!=AC:LDW(%0);}" 20
ac: con8 "LDI(%0);" 16
ac: con "LDWI(%0);" 20
ac: eac "%0" 
ac: loada "%0"
ac: loadx "%0"
ac: ac1 "%0LD('vAC');" 16
ac1: ac "%0"

# genreload() can use the iarg:loada rule to reload without allocating a register. 
# This depends on code using the %{iargX} macro to insert the reloading code when needed.
# Note that the loada clause is only useful when reloading a spilled register.
iarg: reg "%0"
iarg: INDIRI2(zddr) "%0"
iarg: INDIRU2(zddr) "%0"
iarg: INDIRP2(zddr) "%0"
iarg: loada "%{alt:SR:STLW(-2);%0STW(SR);LDLW(-2);}" 60

ac: ADDI2(ac,iarg)  "%0%{iarg1}ADDW(%1);" 28
ac: ADDU2(ac,iarg)  "%0%{iarg1}ADDW(%1);" 28
ac: ADDP2(ac,iarg)  "%0%{iarg1}ADDW(%1);" 28
ac: ADDI2(iarg,ac)  "%1%{iarg0}ADDW(%0);" 28
ac: ADDU2(iarg,ac)  "%1%{iarg0}ADDW(%0);" 28
ac: ADDP2(iarg,ac)  "%1%{iarg0}ADDW(%0);" 28
ac: ADDI2(ac,con8) "%0ADDI(%1);" 28
ac: ADDU2(ac,con8) "%0ADDI(%1);" 28
ac: ADDP2(ac,con8) "%0ADDI(%1);" 28
ac: ADDI2(ac,co8n) "%0SUBI(-(%1));" 28
ac: ADDU2(ac,co8n) "%0SUBI(-(%1));" 28
ac: ADDP2(ac,co8n) "%0SUBI(-(%1));" 28

ac: SUBI2(ac,iarg)  "%0%{iarg1}SUBW(%1);" 28
ac: SUBU2(ac,iarg)  "%0%{iarg1}SUBW(%1);" 28
ac: SUBP2(ac,iarg)  "%0%{iarg1}SUBW(%1);" 28
ac: SUBI2(ac,con8) "%0SUBI(%1);" 28
ac: SUBU2(ac,con8) "%0SUBI(%1);" 28
ac: SUBP2(ac,con8) "%0SUBI(%1);" 28
ac: SUBI2(ac,co8n) "%0ADDI(-(%1));" 28
ac: SUBU2(ac,co8n) "%0ADDI(-(%1));" 28
ac: SUBP2(ac,co8n) "%0ADDI(-(%1));" 28

ac: NEGI2(ac) "%0ST(SR);LDI(0);SUBW(SR);" 68
ac: NEGI2(iarg) "LDI(0);%{iarg0}SUBW(%0);" 48

ac: LSHI2(ac, con8) "%0%{shl1}" 100
ac: LSHI2(ac, iarg) "%0%{iarg1}_SHL(%1);" 200
ac: RSHI2(ac, iarg) "%0%{iarg1}_SHRS(%1);" 200
ac: LSHU2(ac, con8) "%0%{shl1}" 100
ac: LSHU2(ac, iarg) "%0%{iarg1}_SHL(%1);" 200
ac: RSHU2(ac, iarg) "%0%{iarg1}_SHRU(%1);" 200

ac: MULI2(con8, ac) "%1%{mul0}" 110
ac: MULI2(co8n, ac) "%1%{mul0}" 110
ac: MULI2(con8, reg) "%{mul0%1}" 100
ac: MULI2(co8n, reg) "%{mul0%1}" 100
ac: MULI2(ac, iarg) "%0%{iarg1}_MUL(%1);" 200
ac: MULI2(iarg, ac) "%1%{iarg0}_MUL(%0);" 200
ac: MULU2(con8, ac) "%1%{mul0}" 100
ac: MULU2(con8, reg) "%1%{mul0%1}" 100
ac: MULU2(ac, iarg) "%0%{iarg1}_MUL(%1);" 200
ac: MULU2(iarg, ac) "%1%{iarg0}_MUL(%0);" 200

ac: DIVI2(ac, iarg) "%0%{iarg1}_DIVS(%1);" 200
ac: DIVU2(ac, iarg) "%0%{iarg1}_DIVU(%1);" 200
ac: MODI2(ac, iarg) "%0%{iarg1}_MODS(%1);" 200
ac: MODU2(ac, iarg) "%0%{iarg1}_MODU(%1);" 200

ac: BCOMI2(ac) "%0ST(SR);LDWI(-1);XORW(SR);" 68
ac: BCOMU2(ac) "%0ST(SR);LDWI(-1);XORW(SR);" 68

ac: BANDI2(ac,iarg)  "%0%{iarg1}ANDW(%1);" 28
ac: BANDU2(ac,iarg)  "%0%{iarg1}ANDW(%1);" 28
ac: BANDI2(iarg,ac)  "%1%{iarg0}ANDW(%0);" 28
ac: BANDU2(iarg,ac)  "%1%{iarg0}ANDW(%0);" 28
ac: BANDI2(ac,con8)  "%0ANDI(%1);" 16 
ac: BANDU2(ac,con8)  "%0ANDI(%1);" 16 

ac: BORI2(ac,iarg)  "%0%{iarg1}ORW(%1);" 28
ac: BORU2(ac,iarg)  "%0%{iarg1}ORW(%1);" 28
ac: BORI2(iarg,ac)  "%1%{iarg0}ORW(%0);" 28
ac: BORU2(iarg,ac)  "%1%{iarg0}ORW(%0);" 28
ac: BORI2(ac,con8)  "%0ORI(%1);" 16 
ac: BORU2(ac,con8)  "%0ORI(%1);" 16 

ac: BXORI2(ac,iarg)  "%0%{iarg1}XORW(%1);" 28
ac: BXORU2(ac,iarg)  "%0%{iarg1}XORW(%1);" 28
ac: BXORI2(iarg,ac)  "%1%{iarg0}XORW(%0);" 28
ac: BXORU2(iarg,ac)  "%1%{iarg0}XORW(%0);" 28
ac: BXORI2(ac,con8)  "%0XORI(%1);" 16 
ac: BXORU2(ac,con8)  "%0XORI(%1);" 

stmt: ASGNP2(zddr,ac)  "\t%1STW(%0);\n" 20
stmt: ASGNP2(iarg,ac)  "\t%1%{iarg0}DOKE(%0);\n" 28
stmt: ASGNP2(ac,iarg)  "\t%0%{iarg1}_DOKEA(%1);\n" 28+20
stmt: ASGNI2(zddr,ac)  "\t%1STW(%0);\n" 20
stmt: ASGNI2(iarg,ac)  "\t%1%{iarg0}DOKE(%0);\n" 28
stmt: ASGNI2(ac,iarg)  "\t%0%{iarg1}_DOKEA(%1);\n" 28+20
stmt: ASGNU2(zddr,ac)  "\t%1STW(%0);\n" 20
stmt: ASGNU2(iarg,ac)  "\t%1%{iarg0}DOKE(%0);\n" 28
stmt: ASGNU2(ac,iarg)  "\t%0%{iarg1}_DOKEA(%1);\n" 28+20
stmt: ASGNI1(zddr,ac1) "\t%1ST(%0);\n" 20
stmt: ASGNI1(iarg,ac1) "\t%1%{iarg0}POKE(%0);\n" 28
stmt: ASGNI1(ac,iarg)  "\t%0%{iarg1}_POKEA(%1);\n" 28+20
stmt: ASGNU1(zddr,ac1) "\t%1ST(%0);\n" 20
stmt: ASGNU1(iarg,ac1) "\t%1%{iarg0}POKE(%0);\n" 28
stmt: ASGNI1(ac,iarg)  "\t%0%{iarg1}_POKEA(%1);\n" 28+20

stmt: EQI2(ac,con0)  "\t%0_BEQ(%a);\n" 28
stmt: EQI2(ac,con8)  "\t%0XORI(con8);_BEQ(%a);\n" 42
stmt: EQI2(ac,iarg)  "\t%0%{iarg1}XORW(%1);_BEQ(%a);\n" 54
stmt: EQI2(iarg,ac)  "\t%1%{iarg0}XORW(%0);_BEQ(%a);\n" 54
stmt: NEI2(ac,con0)  "\t%0_BNE(%a);\n" 28
stmt: NEI2(ac,con8)  "\t%0XORI(con8);_BNE(%a);\n" 42
stmt: NEI2(ac,iarg)  "\t%0%{iarg1}XORW(%1);_BNE(%a);\n" 54
stmt: NEI2(iarg,ac)  "\t%1%{iarg0}XORW(%0);_BNE(%a);\n" 54
stmt: EQU2(ac,con0)  "\t%0_BEQ(%a);\n" 28
stmt: EQU2(ac,con8)  "\t%0XORI(con8);_BEQ(%a);\n" 42
stmt: EQU2(ac,iarg)  "\t%0%{iarg1}XORW(%1);_BEQ(%a);\n" 54
stmt: EQU2(iarg,ac)  "\t%1%{iarg0}XORW(%0);_BEQ(%a);\n" 54
stmt: NEU2(ac,con0)  "\t%0_BNE(%a);\n" 28
stmt: NEU2(ac,con8)  "\t%0XORI(con8);_BNE(%a);\n" 42
stmt: NEU2(ac,iarg)  "\t%0%{iarg1}XORW(%1);_BNE(%a);\n" 54
stmt: NEU2(iarg,ac)  "\t%1%{iarg0}XORW(%0);_BNE(%a);\n" 54
stmt: LTI2(ac,con0) "\t%0_BLT(%a);\n" 28
stmt: LEI2(ac,con0) "\t%0_BLE(%a);\n" 28
stmt: GTI2(ac,con0) "\t%0_BGT(%a);\n" 28
stmt: GEI2(ac,con0) "\t%0_BGE(%a);\n" 28
stmt: GTU2(ac,con0) "\t%0_BNE(%a);\n" 28
stmt: LEU2(ac,con0) "\t%0_BEQ(%a);\n" 28
stmt: LTI2(ac,con8) "\t%0_CMPIS(%1);_BLT(%a);\n" 80
stmt: LEI2(ac,con8) "\t%0_CMPIS(%1);_BLE(%a);\n" 80
stmt: GTI2(ac,con8) "\t%0_CMPIS(%1);_BGT(%a);\n" 80
stmt: GEI2(ac,con8) "\t%0_CMPIS(%1);_BGE(%a);\n" 80
stmt: LTU2(ac,con8) "\t%0_CMPIU(%1);_BLT(%a);\n" 80
stmt: LEU2(ac,con8) "\t%0_CMPIU(%1);_BLE(%a);\n" 80
stmt: GTU2(ac,con8) "\t%0_CMPIU(%1);_BGT(%a);\n" 80
stmt: GEU2(ac,con8) "\t%0_CMPIU(%1);_BGE(%a);\n" 80
stmt: LTI2(ac,iarg) "\t%0%{iarg1}_CMPWS(%1);_BLT(%a);\n" 100
stmt: LEI2(ac,iarg) "\t%0%{iarg1}_CMPWS(%1);_BLE(%a);\n" 100
stmt: GTI2(ac,iarg) "\t%0%{iarg1}_CMPWS(%1);_BGT(%a);\n" 100
stmt: GEI2(ac,iarg) "\t%0%{iarg1}_CMPWS(%1);_BGE(%a);\n" 100
stmt: LTU2(ac,iarg) "\t%0%{iarg1}_CMPWU(%1);_BLT(%a);\n" 100
stmt: LEU2(ac,iarg) "\t%0%{iarg1}_CMPWU(%1);_BLE(%a);\n" 100
stmt: GTU2(ac,iarg) "\t%0%{iarg1}_CMPWU(%1);_BGT(%a);\n" 100
stmt: GEU2(ac,iarg) "\t%0%{iarg1}_CMPWU(%1);_BGE(%a);\n" 100

# Structs
stmt: ARGB(INDIRB(reg))       "\t_SP(%c);_MEMCPY(AC,%0,%a);\n"   200
stmt: ASGNB(reg,INDIRB(ac))   "\t%1_MEMCPY(%0,AC,%a);\n"   200
stmt: ASGNB(ac,INDIRB(reg))   "\t%0_MEMCPY(AC,%1,%a);\n"   200
stmt: ASGNB(reg,INDIRB(reg))  "\t_MEMCPY(%0,%1,%a);\n"   200

# Longs
stmt: lac "\t%0\n"
reg: lac "\t%0%{%c!=LAC:_LMOV(LAC,%c);}\n" 80
reg: INDIRI4(ac) "\t%0_LPEEKA(%c);\n" 150
reg: INDIRU4(ac) "\t%0_LPEEKA(%c);\n" 150
lac: reg "%{%0!=LAC:_LMOV(%0,LAC);}" 80
lac: INDIRI4(ac) "%0_LPEEKA(LAC);" 150
lac: INDIRU4(ac) "%0_LPEEKA(LAC);" 150
lac: INDIRI4(zddr) "_LMOV(%0,LAC);" 150
lac: INDIRU4(zddr) "_LMOV(%0,LAC);" 150
larg: reg "%{%0!=LARG:_LMOV(%0,LARG);}" 80
larg: INDIRI4(eac) "%0_LPEEKA(LARG);" 150
larg: INDIRU4(eac) "%0_LPEEKA(LARG);" 150
larg: INDIRI4(zddr) "_LMOV(%0,LARG);" 150
larg: INDIRU4(zddr) "_LMOV(%0,LARG);" 150
lac: ADDI4(lac,larg) "%0%1_LADD();" 200
lac: ADDU4(lac,larg) "%0%1_LADD();" 200
lac: ADDI4(larg,lac) "%1%0_LADD();" 200
lac: ADDU4(larg,lac) "%1%0_LADD();" 200
lac: SUBI4(lac,larg) "%0%1_LSUB();" 200
lac: SUBU4(lac,larg) "%0%1_LSUB();" 200
lac: MULI4(lac,larg) "%0%1_LMUL();" 200
lac: MULU4(lac,larg) "%0%1_LMUL();" 200
lac: MULI4(larg,lac) "%1%0_LMUL();" 200
lac: MULU4(larg,lac) "%1%0_LMUL();" 200
lac: DIVI4(lac,larg) "%0%1_LDIVS();" 200
lac: DIVU4(lac,larg) "%0%1_LDIVU();" 200
lac: MODI4(lac,larg) "%0%1_LMODS();" 200
lac: MODU4(lac,larg) "%0%1_LMODU();" 200
lac: LSHI4(lac,iarg) "%0%{iarg1}_LSHL(%1);" 200
lac: LSHI4(lac,con8) "%0LDI(%1);_LSHL(AC);" 1
lac: LSHU4(lac,iarg) "%0%{iarg1}_LSHL(%1);" 200
lac: LSHU4(lac,con8) "%0LDI(%1);_LSHL(AC);" 1
lac: RSHI4(lac,iarg) "%0%{iarg1}_LASR(%1);" 200
lac: RSHU4(lac,iarg) "%0%{iarg1}_LLSR(%1);" 200
lac: NEGI4(lac) "%0_LNEG();" 200
lac: BCOMU4(lac) "%0_LCOM();" 200
lac: BANDU4(lac,larg) "%0%1_LAND();" 200
lac: BANDU4(larg,lac) "%1%0_LAND();" 200
lac: BORU4(lac,larg) "%0%1_LOR();" 200
lac: BORU4(larg,lac) "%1%0_LOR();" 200
lac: BXORU4(lac,larg) "%0%1_LXOR();" 200
lac: BXORU4(larg,lac) "%1%0_LXOR();" 200
lac: BCOMI4(lac) "%0_LCOM();" 200
lac: BANDI4(lac,larg) "%0%1_LAND();" 200
lac: BANDI4(larg,lac) "%1%0_LAND();" 200
lac: BORI4(lac,larg) "%0%1_LOR();" 200
lac: BORI4(larg,lac) "%1%0_LOR();" 200
lac: BXORI4(lac,larg) "%0%1_LXOR();" 200
lac: BXORI4(larg,lac) "%1%0_LXOR();" 200
stmt: ASGNI4(eac,lac) "\t%1%0_LPOKEA(LAC);\n" 200
stmt: ASGNU4(eac,lac) "\t%1%0_LPOKEA(LAC);\n" 200
stmt: ASGNI4(reg,lac) "\t%1LDW(%0);_LPOKEA(LAC);\n" 180
stmt: ASGNU4(reg,lac) "\t%1LDW(%0);_LPOKEA(LAC);\n" 180
stmt: ASGNI4(ac,reg) "\t%0_LPOKEA(%1);\n" 160
stmt: ASGNU4(ac,reg) "\t%0_LPOKEA(%1);\n" 160
stmt: LTI4(lac,larg) "\t%0%1_LCMPS();_BLT(%a);\n" 200
stmt: LEI4(lac,larg) "\t%0%1_LCMPS();_BLE(%a);\n" 200
stmt: GTI4(lac,larg) "\t%0%1_LCMPS();_BGT(%a);\n" 200
stmt: GEI4(lac,larg) "\t%0%1_LCMPS();_BGE(%a);\n" 200
stmt: LTU4(lac,larg) "\t%0%1_LCMPU();_BLT(%a);\n" 200
stmt: LEU4(lac,larg) "\t%0%1_LCMPU();_BLE(%a);\n" 200
stmt: GTU4(lac,larg) "\t%0%1_LCMPU();_BGT(%a);\n" 200
stmt: GEU4(lac,larg) "\t%0%1_LCMPU();_BGE(%a);\n" 200
stmt: NEI4(lac,larg) "\t%0%1_LDW(LAC);XORW(LARG);STW(SR);LDW(LAC+2);XORW(LARG+2);ORW(SR);_BNE(%a);\n" 100
stmt: EQI4(lac,larg) "\t%0%1_LDW(LAC);XORW(LARG);STW(SR);LDW(LAC+2);XORW(LARG+2);ORW(SR);_BEQ(%a);\n" 100
stmt: NEI4(lac,reg) "\t%0_LDW(LAC);XORW(%1);STW(SR);LDW(LAC+2);XORW(%1+2);ORW(SR);_BNE(%a);\n" 100
stmt: EQI4(lac,reg) "\t%0_LDW(LAC);XORW(%1);STW(SR);LDW(LAC+2);XORW(%1+2);ORW(SR);_BEQ(%a);\n" 100
stmt: NEU4(lac,larg) "\t%0%1_LDW(LAC);XORW(LARG);STW(SR);LDW(LAC+2);XORW(LARG+2);ORW(SR);_BNE(%a);\n" 100
stmt: EQU4(lac,larg) "\t%0%1_LDW(LAC);XORW(LARG);STW(SR);LDW(LAC+2);XORW(LARG+2);ORW(SR);_BEQ(%a);\n" 100
stmt: NEU4(lac,reg) "\t%0_LDW(LAC);XORW(%1);STW(SR);LDW(LAC+2);XORW(%1+2);ORW(SR);_BNE(%a);\n" 100
stmt: EQU4(lac,reg) "\t%0_LDW(LAC);XORW(%1);STW(SR);LDW(LAC+2);XORW(%1+2);ORW(SR);_BEQ(%a);\n" 100

# Floats
stmt: fac "\t%0\n"
reg: fac "\t%0%{%c!=FAC:_FMOV(FAC,%c);}\n" 100
reg: INDIRF5(ac) "\t%0_FPEEKA(%c);\n" 200
fac: reg "%{%0!=FAC:_FMOV(%0,FAC);}" 100
fac: INDIRF5(ac) "%0_FPEEKA(FAC);" 200
farg: reg "%{%0!=FARG:_FMOV(%0,FARG);}" 60
farg: INDIRF5(eac) "%0_FPEEKA(FARG);" 200
fac: ADDF5(fac,farg) "%0%1_FADD();" 200
fac: ADDF5(farg,fac) "%1%0_FADD();" 200
fac: SUBF5(fac,farg) "%0%1_FSUB();" 200
fac: SUBF5(farg,fac) "%1_FNEG();%0_FADD();" 200+50
fac: MULF5(fac,farg) "%0%1_FMUL();" 200
fac: MULF5(farg,fac) "%1%0_FMUL();" 200
fac: DIVF5(fac,farg) "%0%1_FDIV();" 200
fac: NEGF5(fac) "%0_FNEG();" 50
stmt: ASGNF5(eac,fac) "\t%1%0_FPOKEA(FAC);\n" 200
stmt: ASGNF5(reg,fac) "\t%1LDW(%0);_FPOKEA(FAC);\n" 200
stmt: ASGNF5(ac,reg) "\t%0_FPOKEA(%1);\n" 200
stmt: EQF5(fac,farg) "\t%0%1_FCMP();_BEQ(%a);\n" 200
stmt: NEF5(fac,farg) "\t%0%1_FCMP();_BNE(%a);\n" 200
stmt: LTF5(fac,farg) "\t%0%1_FCMP();_BLT(%a);\n" 200
stmt: LEF5(fac,farg) "\t%0%1_FCMP();_BLE(%a);\n" 200
stmt: GTF5(fac,farg) "\t%0%1_FCMP();_BGT(%a);\n" 200
stmt: GEF5(fac,farg) "\t%0%1_FCMP();_BGE(%a);\n" 200

# Calls
fac: CALLF5(addr) "CALLI(%0);" MINCPU5(28)
fac: CALLF5(reg) "CALL(%0);" 26
lac: CALLI4(addr) "CALLI(%0);" MINCPU5(28)
lac: CALLI4(reg) "CALL(%0);" 26
lac: CALLU4(addr) "CALLI(%0);" MINCPU5(28)
lac: CALLU4(reg) "CALL(%0);" 26
ac: CALLI2(addr) "CALLI(%0);" MINCPU5(28)
ac: CALLI2(reg) "CALL(%0);" 26
ac: CALLU2(addr) "CALLI(%0);" MINCPU5(28)
ac: CALLU2(reg) "CALL(%0);" 26
ac: CALLP2(addr) "CALLI(%0);" MINCPU5(28)
ac: CALLP2(reg) "CALL(%0);" 26
stmt: CALLV(addr) "\tCALLI(%0);\n" MINCPU5(28)
stmt: CALLV(reg) "\tCALL(%0);\n" 26
stmt: ARGF5(fac)  "\t%0_SP(%c);_FPOKEA(FAC);\n"  if_arg_stk(a)
stmt: ARGI4(lac)  "\t%0_SP(%c);_LPOKEA(FAC);\n"  if_arg_stk(a)
stmt: ARGU4(lac)  "\t%0_SP(%c);_LPOKEA(FAC);\n"  if_arg_stk(a)
stmt: ARGF5(reg)  "\t_SP(%c);_FPOKEA(%0);\n"     if_arg_stk(a)
stmt: ARGI4(reg)  "\t_SP(%c);_LPOKEA(%0);\n"     if_arg_stk(a)
stmt: ARGU4(reg)  "\t_SP(%c);_LPOKEA(%0);\n"     if_arg_stk(a)
stmt: ARGI2(reg)  "\t_SP(%c);_DOKEA(%0);\n"      if_arg_stk(a)
stmt: ARGU2(reg)  "\t_SP(%c);_DOKEA(%0);\n"      if_arg_stk(a)
stmt: ARGP2(reg)  "\t_SP(%c);_DOKEA(%0);\n"      if_arg_stk(a)
stmt: ARGF5(reg)  "# arg\n"  if_arg_reg(a)
stmt: ARGI4(reg)  "# arg\n"  if_arg_reg(a)
stmt: ARGU4(reg)  "# arg\n"  if_arg_reg(a)
stmt: ARGI2(reg)  "# arg\n"  if_arg_reg(a)
stmt: ARGU2(reg)  "# arg\n"  if_arg_reg(a)
stmt: ARGP2(reg)  "# arg\n"  if_arg_reg(a)
stmt: RETF5(fac)  "\t%0\n"  1
stmt: RETI4(lac)  "\t%0\n"  1
stmt: RETU4(lac)  "\t%0\n"  1
stmt: RETI2(ac)   "\t%0STW(R3);\n"  1
stmt: RETU2(ac)   "\t%0STW(R3);\n"  1
stmt: RETP2(ac)   "\t%0STW(R3);\n"  1

# Conversions
#            I1   U1
#              \ /
#              I2 - U2 - P
#            /  | X |
#         F5 - I4 - U4
# 1) prelabel changes all truncations into LOADs
ac1: LOADI1(ac) "%0"
ac1: LOADU1(ac) "%0"
ac: LOADI2(ac) "%0"
ac: LOADU2(ac) "%0"
ac: LOADP2(ac) "%0"
ac: LOADI2(lac) "%0LDW(LAC);" 28
ac: LOADU2(lac) "%0LDW(LAC);" 28
lac: LOADI4(lac) "%0"
lac: LOADU4(lac) "%0"
fac: LOADF5(fac) "%0"

# 2) extensions
ac: CVII2(ac) "%0XORI(128);SUBI(128);" if_cv_from(a,1,48)
ac: CVUI2(ac) "%0" if_cv_from(a,1,0)
lac: CVIU4(ac) "%0STW(LAC);LDI(0);STW(LAC+2);" 50
lac: CVII4(ac) "%0STW(LAC);LD(vAH);XORI(128);SUBI(128);LD(vAH);ST(LAC+2);ST(LAC+3);" if_cv_from(a,2,120)
lac: CVUU4(ac) "%0STW(LAC);LDI(0);STW(LAC+2);"
lac: CVUI4(ac) "%0STW(LAC);LDI(0);STW(LAC+2);"
# 3) floating point conversions
ac: CVFU2(fac)  "%0_FTOU();LDW(LAC);" 200
lac: CVFU4(fac) "%0_FTOU();" 200
fac: CVUF5(ac)  "%0_FCVU(AC);" if_cv_from(a,2,120)
fac: CVUF5(lac) "%0_FCVU(LAC);" if_cv_from(a,4,200)
ac: CVFI2(fac)  "%0_FTOI();LDW(LAC);" 200
lac: CVFI4(fac) "%0_FTOI();" 200
fac: CVIF5(ac)  "%0_FCVI(AC);" if_cv_from(a,2,120)
fac: CVIF5(lac) "%0_FCVI(LAC);" if_cv_from(a,4,200)

# Labels and jumps
stmt: LABELV       "\tlabel(%a);\n"
stmt: JUMPV(addr)  "\t_BRA(%0);\n"  14
stmt: JUMPV(reg)   "\tCALL(%0);\n"  14


# More opcodes for cpu=5
stmt: ASGNU1(zddr, LOADU1(ADDI2(CVUI2(INDIRU1(zddr)), con1)))  "\tINC(%1);\n" if_rmw1(a,16)
stmt: ASGNI1(zddr, LOADI1(ADDI2(CVII2(INDIRI1(zddr)), con1)))  "\tINC(%1);\n" if_rmw1(a,16)

# More opcodes for cpu=6
stmt: ASGNP2(zddr, ADDP2(INDIRP2(zddr), con1)) "\tINCW(%1);\n" MINCPU6(if_rmw2(a, 26))
stmt: ASGNU2(zddr, ADDU2(INDIRU2(zddr), con1)) "\tINCW(%1);\n" MINCPU6(if_rmw2(a, 26))
stmt: ASGNI2(zddr, ADDI2(INDIRI2(zddr), con1)) "\tINCW(%1);\n" MINCPU6(if_rmw2(a, 26))
stmt: ASGNP2(zddr, ADDP2(INDIRP2(zddr), con1)) "\tINCW(%1);\n" MINCPU6(if_rmw2(a, 26))
stmt: ASGNU2(zddr, ADDU2(INDIRU2(zddr), con1)) "\tINCW(%1);\n" MINCPU6(if_rmw2(a, 26))
stmt: ASGNI2(zddr, ADDI2(INDIRI2(zddr), con1)) "\tINCW(%1);\n" MINCPU6(if_rmw2(a, 26))

# /*-- END RULES --/
%%
/*---- BEGIN CODE --*/


static void comment(const char *fmt, ...) {
  va_list ap;
  print("# ");
  va_start(ap, fmt);
  vfprint(stdout, NULL, fmt, ap);
  va_end(ap);
}

static int if_cpu(int mincpu, int cost)
{
  return (cpu < mincpu) ? LBURG_MAX : cost;
}

static int if_arg_reg(Node p)
{
  return p->syms[1] ? 1 : LBURG_MAX;
}

static int if_arg_stk(Node p)
{
  return p->syms[1] ? LBURG_MAX : 1;
}

static int if_zpconst(Node p)
{
  Symbol s = p->syms[0];
  assert(specific(p->op) == CNST+P);
  if ((size_t)s->u.c.v.p == ((size_t)s->u.c.v.p & 0xff))
    return 0;
  return LBURG_MAX;
}

static int if_zpglobal(Node p)
{
  /* TODO */
  return LBURG_MAX;
}

static int if_rmw1(Node p, int cost)
{
  Node n0 = p->kids[0];
  Node n1 = p->kids[1]->kids[0]->kids[0]->kids[0]->kids[0];
  assert(n0 && n1);
  if (generic(n0->op) == INDIR && n0->kids[0]->op == VREG+P
      && n0->x.mayrecalc && n0->syms[RX]->u.t.cse)
    n0 = n0->syms[RX]->u.t.cse;
  if (generic(n1->op) == INDIR && n1->kids[0]->op == VREG+P
      && n1->x.mayrecalc && n1->syms[RX]->u.t.cse)
    n1 = n1->syms[RX]->u.t.cse;
  if (n0->syms[RX] && n1->syms[RX] && n0->syms[RX] == n1->syms[RX])
    return cost;
  return LBURG_MAX;
}

static int if_rmw2(Node p, int cost)
{
  Node n0 = p->kids[0];
  Node n1 = p->kids[1]->kids[0]->kids[0];
  assert(n0 && n1);
  if (generic(n0->op) == INDIR && n0->kids[0]->op == VREG+P
      && n0->x.mayrecalc && n0->syms[RX]->u.t.cse)
    n0 = n0->syms[RX]->u.t.cse;
  if (generic(n1->op) == INDIR && n1->kids[0]->op == VREG+P
      && n1->x.mayrecalc && n1->syms[RX]->u.t.cse)
    n1 = n1->syms[RX]->u.t.cse;
  if (n0->syms[RX] && n1->syms[RX] && n0->syms[RX] == n1->syms[RX])
    return cost;
  return LBURG_MAX;
}

static int if_cv_from(Node p, int sz, int cost)
{
  assert(p->syms[0]);
  assert(p->syms[0]->scope == CONSTANTS);
  assert(p->syms[0]->type = inttype);
  if (p->syms[0]->u.c.v.i == sz)
    return cost;
  return LBURG_MAX;
}

static void progend(void)
{
  extern char *firstfile; /* From input.c */
  print("\nmodule(code=code, ");
  if (firstfile)
    print("name='%s', ", firstfile);
  print("cpu=%d);\n", cpu);
}

static void progbeg(int argc, char *argv[])
{
  int i;
  /* Parse flags */
  parseflags(argc, argv);
  for (i=0; i<argc; i++)
    if (!strcmp(argv[i],"-cpu=4"))
      cpu = 4; /* Asm should replace CALLIs */
    else if (!strcmp(argv[i],"-cpu=5"))
      cpu = 5; /* Has CALLI. Ignore CMPHI,CMPHS. */
    else if (!strcmp(argv[i],"-cpu=6"))
      cpu = 6; /* TBD */
    else if (!strncmp(argv[i],"-cpu=",5))
      warning("invalid cpu %s\n", argv[i]+5);
  /* Print header */
  comment("VCPUv%d\n",cpu);
  print("def code():\n");
  /* Prepare registers */
  ireg[0] = mkreg("AC", 0, 1, IREG);
  ireg[1] = mkreg("SR", 1, 1, IREG);
  ireg[30] = mkreg("LR", 30, 1, IREG);
  ireg[31] = mkreg("SP", 31, 1, IREG);
  for (i=2; i<30; i++)
    ireg[i] = mkreg("R%d", i, 1, IREG);
  /* Register pairs for longs */
  lreg[3] = mkreg("LAC", 3, 3, IREG);
  lreg[6] = mkreg("LARG", 6, 3, IREG);
  for (i=8; i<29; i++)
    lreg[i] = mkreg("L%d", i, 3, IREG);
  /* Register triple for floats */
  freg[2] = mkreg("FAC", 2, 7, IREG);
  freg[5] = mkreg("FARG", 5, 7, IREG);  
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
  Symbol r = 0;
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
  switch (specific(p->op))
    {
    case ARG+F: case ARG+I: case ARG+P: case ARG+U:
      if (p->syms[1])
        rtarget(p, 0, p->syms[1]);
      break;
    }
}

static void clobber_helper(Node p, unsigned *pmask)
{
  int ty = optype(p->op);
  int sz = opsize(p->op);
  if (ty == F)
    *pmask |= REGMASK_FAC_FARG;
  else if (sz > 2 && (ty == I || ty == P))
    *pmask |= REGMASK_LAC_LARG;
  else if (opkind(p->op) == CALL)
    *pmask |= REGMASK_TEMPS;
  if (p->kids[0] && ! p->kids[0]->x.inst)
    clobber_helper(p->kids[0], pmask);
  if (p->kids[1] && ! p->kids[1]->x.inst)
    clobber_helper(p->kids[1], pmask);
}

static void clobber(Node p)
{
  int mask = 0;
  assert(p);
  clobber_helper(p, &mask);
  if (p->x.registered && p->syms[2])
    if (p->syms[2]->x.regnode && p->syms[2]->x.regnode->set == IREG)
      mask &= ~p->syms[2]->x.regnode->mask;
  if (mask)
    spill(mask, IREG, p);
}


static Node alt_p = 0;
static int alt_s;

static void emit3(const char *fmt, Node p, Node *kids, short *nts)
{
  /* %{iargX} -- see iarg rule for an explanation */
  if (!strncmp(fmt,"iarg",4) && fmt[4]>='0' && fmt[4]<='9' && !fmt[5])
    {
      static short iarg_nt, loada_nt;
      int i, rn1;
      short *nts1;

      if (!loada_nt || !iarg_nt)
        for(i=1; _ntname[i]; i++)
          if (!strcmp("loada", _ntname[i]))
            loada_nt = i;
          else if (!strcmp("iarg", _ntname[i]))
            iarg_nt = i;
      i = fmt[4] - '0';
      assert(kids[i]);
      assert(iarg_nt == nts[i]);
      rn1 = (*IR->x._rule)(kids[i]->x.state, nts[i]);
      nts1 = IR->x._nts[rn1];
      if (loada_nt == nts1[0]) {
        alt_p = kids[i];
        alt_s = 1;
        emitasm(kids[i], nts[i]);
      }
      alt_p = kids[i];
      alt_s = 0;
      return;
    }
  /* %{alt:A1:A2} -- alternate expansions selectable from the parent rule
     %{XY} -- selects alternate expansion Y in child rule X */
  if (!strncmp(fmt,"alt:", 4))
    {
      const char *s;
      assert(alt_p == p);
      alt_p = 0;
      for (s = fmt = fmt + 4; *s; s++)
        if (*s == ':') {
          if (alt_s == 0)
            break;
          alt_s -= 1;
          fmt = s + 1;
        }
      if (alt_s == 0)
        emitfmt(stringn(fmt,s-fmt), p, kids, nts);
      return;
    }
  if (isdigit(fmt[0]) && isdigit(fmt[1]) && !fmt[2])
    {
      int i = fmt[0] - '0';
      alt_s = fmt[1] - '1';
      alt_p = kids[i];
      emitasm(kids[i], nts[i]);
      return;
    }
  /* %{%X==S:fmt} %{%X!=S:fmt} -- conditional expansion of S
     Argument X can be %0..%9 for a register input, %a..%c for a symbol name */
  if (fmt[0]=='%' && fmt[1] && (fmt[2]=='=' || fmt[2]=='!') && fmt[3]=='=')
    {
      const char *x, *v, *s = fmt+4;
      assert(isdigit(fmt[1]) || fmt[1] >= 'a' && fmt[1] < 'a' + NELEMS(p->syms));
      for (v = s = fmt+4; *v && *v != ':'; v++) { }
      assert(*v == ':');
      s = stringn(s, v-s);
      x = 0;
      if (isdigit(fmt[1]) && kids[fmt[1]-'0'] && kids[fmt[1]-'0']->syms[RX])
        x = kids[fmt[1]-'0']->syms[RX]->x.name;
      else if (isalpha(fmt[1]) && p->syms[fmt[1]-'a'])
        x = p->syms[fmt[1]-'a']->x.name;
      if ((fmt[2] == '=' && x && x == s) || (fmt[2] == '!' && x && x != s))
        emitfmt(v + 1, p, kids, nts);
      return;
    }
  /* %{shlC} -- left shift AC by a constant */
  if (!strncmp(fmt,"shl", 3) && fmt[3] >= '0' && fmt[3] <= '9' && ! fmt[4])
    {
      int i,c,m;
      Node k;
      i = fmt[3] - '0';
      k = kids[i];
      assert(k);
      if (k->syms[0] == 0 || k->syms[0]->scope != CONSTANTS)
        if (generic(k->op) == INDIR && k->syms[2] && k->syms[2]->u.t.cse)
          k = k->syms[2]->u.t.cse;
      assert(k->syms[0] && k->syms[0]->scope == CONSTANTS);
      c = k->syms[0]->u.c.v.i;
      assert(c>=0 && c<256);
      if (c >= 16) {
        print("LDI(0);");
        return;
      }
      if (c >= 8) {
        print("ST(v('vAH'));ORI(255);XORI(255);");
        c -= 8;
      }
      while (c > 0) {
        print("LSLW();");
        c -= 1;
      }
      return;
    }
  /* ${mulC[:R]} -- multiplication by a small constant */
  if (!strncmp(fmt,"mul", 3) && fmt[3] >= '0' && fmt[3] <= '9')
    {
      int i, c,m,x;
      const char *r;
      Node k;
      r = "SR";
      i = fmt[3] - '0';
      k = kids[i];
      assert(k);
      if (! (k->syms[0] && k->syms[0]->scope == CONSTANTS))
        if (generic(k->op) == INDIR && k->syms[2] && k->syms[2]->u.t.cse)
          k = k->syms[2]->u.t.cse;
      assert(k->syms[0] && k->syms[0]->scope == CONSTANTS);
      c = k->syms[0]->u.c.v.i;
      if (fmt[4]) {
        assert(fmt[4]=='%' && fmt[5]>='0' && fmt[5]<='9' && !fmt[6]);
        assert(kids[fmt[5]-'0'] && kids[fmt[5]-'0']->syms[RX]);
        r = kids[fmt[5]-'0']->syms[RX]->x.name;
      }
      if(c == 0) {
        print("LDI(0);");
        return;
      }
      x = (c >= 0) ? c : -c;
      assert(x>=0 && x<256);
      m = 0x80;
      while (m && !(m & x))
        m >>= 1;
      if (fmt[4] && c < 0)
        print("LDI(0);SUBW(%s);", r);
      else if (fmt[4])
        print("LDW(%s);", r);
      else if (c < 0)
        print("STW(SR);LDI(0);SUBW(SR);");
      else if (x & (m-1))
        print("STW(SR);");
      for (m >>= 1; m; m >>= 1) {
        print("LSLW();");
        if (m & x)
          print("x.%s(%s);", (c > 0) ? "ADDW" : "SUBW", r);
      }
      return;
    }
  /* otherwise complain */
  assert(0);
}

static void doarg(Node p)
{
  static int argno;
  static int roffset;
  Symbol r;
  if (argoffset == 0)
    argno = 0;
  r  = argreg(argno, optype(p->op), opsize(p->op), &roffset);
  p->x.argno = argno++;
  p->syms[1] = r;
  p->syms[2] = intconst(mkactual(1, p->syms[0]->u.c.v.i));
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

static void function(Symbol f, Symbol caller[], Symbol callee[], int ncalls)
{
  int i, roffset, soffset, sizesave, varargs, ty;
  Symbol r, argregs[8];
  usedmask[0] = usedmask[1] = 0;
  freemask[0] = freemask[1] = ~(unsigned)0;
  offset = maxoffset = maxargoffset = 0;
  assert(f->type && f->type->type);
  ty = ttob(f->type->type);
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
    if (varargs) {
      p->sclass = AUTO;
    } else if (r && ncalls == 0 && !p->addressed) {
      p->sclass = q->sclass = REGISTER;
      askregvar(p, r);
      assert(p->x.regnode && p->x.regnode->vbl == p);
      q->x = p->x;
      q->type = p->type;
    } else if (askregvar(p, rmap(ttob(p->type))) && r) {
      assert(q->sclass != REGISTER);
      p->sclass = q->sclass = REGISTER;
      q->type = p->type;
    }
  }
  /* gen code */
  assert(!caller[i]);
  soffset = offset;
  offset = 0;
  gencode(caller, callee);
  /* prologue */
  segment(CODE);
  print("\tfunction(%s);\n", f->x.name);
  print("\tLDW('vLR');STW(LR);");
  if (ncalls)
    usedmask[IREG] |= REGMASK_LR;
  i = bitcount(REGMASK_ARGS);
  if (ncalls & maxargoffset < i)
    maxargoffset = i;
  usedmask[IREG] &= REGMASK_VARS;
  sizesave = 2 * bitcount(usedmask[IREG]);
  framesize = maxargoffset + sizesave + maxoffset;
  if (framesize > 0)
    print("_SP(%d);STW(SP);",-framesize);
  /* save callee saved registers */
  offset = maxargoffset;
  for (i=0; i<=31; i++)
    if (usedmask[IREG]&(1<<i)) {
      print("_SP(%d);_DOKEA(R%d);", offset, i);
      offset += 2;
    }
  /* save args into new registers or vars */
  for (i = 0; i < 8 && callee[i]; i++) {
    r = argregs[i];
    if (r && r->x.regnode != callee[i]->x.regnode) {
      Symbol out = callee[i];
      Symbol in  = caller[i];
      const char *rn = r->x.name;
      assert(out && in && r && r->x.regnode);
      assert(out->sclass != REGISTER || out->x.regnode);
      if (out->sclass == REGISTER) {
        if (isfloat(in->type))
          print("_FMOV(%s,%s);", rn, out->x.name);
        else if (in->type->size > 2)
          print("_LMOV(%s,%s);", rn, out->x.name);
        else 
          print("LDW(%s);STW(%s);", rn, out->x.name);
      } else {
        if (isfloat(in->type))
          print("_FMOV(%s,FAC);_SP(%s+%d);_FPOKEA(FAC);", rn, out->x.name, framesize);
        else if (in->type->size == 4)
          print("_SP(%s+%d);_LPOKEA(%s);", out->x.name, framesize, rn);
        else if (in->type->size == 2)
          print("_SP(%s+%d);_DOKEA(%s);", out->x.name, framesize, rn); 
        else if (in->type->size == 1)
          print("_SP(%s+%d);_POKEA(%s);", out->x.name, framesize, rn); 
      }
    }
  }
  /* for variadic functions, save remaining registers */
  if (varargs)
    while (! ((r=ireg[roffset])->x.regnode->mask & ~REGMASK_ARGS)) {
      print("_SP(%d+%d);_DOKEA(%s);", soffset, framesize, r->x.name);
      roffset += 1;
      soffset += 2;
    }
  print("\n");
  /* Emit actual code */
  emitcode();
  /* Restore callee saved registers */
  print("\t");
  offset = maxargoffset;
  for (i=0; i<=31; i++)
    if (usedmask[IREG]&(1<<i)) {
      print("_SP(%d);DEEK();STW(R%d);", offset, i);
      offset += 2;
    }
  if (framesize > 0)
    print("_SP(%d);STW(SP);", framesize);
  print("LDW(LR);STW('vLR');");
  if (ty == I+sizeop(2) || ty == U+sizeop(2) || ty == P+sizeop(2))
    print("LDW(R3);");
  print("RET();\n");
}

static void defconst(int suffix, int size, Value v)
{
  if (suffix == F) {
    double d = v.d;
    int exp;
    unsigned long mantissa;
    assert(size == 5);
    assert(isfinite(d));
    mantissa = (unsigned long)(frexp(d,&exp) * pow(2.0, 32));
    if (mantissa == 0 || exp < -128)
      print("\tbytes(0,0,0,0,0); ");
    else
      print("\tbytes(%d,%d,%d,%d,%d); ",
            exp+128, ((mantissa>>24)&0x7f)|((d<0.0)?0x80:0x00),
            (mantissa>>16)&0xff, (mantissa>>8)&0xff, (mantissa&0xff) );
    comment("%f\n", d);
  } else {
    unsigned long x = (suffix == P) ? (unsigned)(size_t)v.p : (suffix == I) ? v.i : v.u;
    if (size == 1) 
      print("\tbytes(%d); ", x&0xff);
    else if (size == 2)
      print("\twords(%d); ", x&0xffff);
    else if (size == 4)
      print("\twords(%d,%d); ", x&0xffff, (x>>16)&0xffff);
    if (suffix == I)
      comment("%D", (long)x);
    else if (suffix == U)
      comment("%U", x);
  print("\n");
  }
}

static void defaddress(Symbol p)
{
  print("\twords(%s);\n", p->x.name);
}

static void defstring(int n, char *str)
{
  int i;
  for (i=0; i<n; i++)
    print( ((i&7)==0) ? "\tbytes(%d" : ((i&7)==7) ? ",%d);\n" : ",%d", (int)str[i]&0xff );
  if (i&7)
    print(");\n");
}

static void export(Symbol p)
{
  if (isfunc(p->type))
    print("\texport(%s);\n", p->x.name);
  else if (p->u.seg != BSS)
    print("\texport(%s,%d);\n", p->x.name, p->type->size);
  else
    print("\tcommon(%s,%d);\n", p->x.name, p->type->size);
}

static void import(Symbol p)
{
  if (isfunc(p->type))
    print("\textern(%s);\n", p->x.name);
  else
    print("\textern(%s,%d);\n", p->x.name, p->type->size);
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
    q->x.name = stringf("v(%s)%s%D", p->x.name, n >= 0 ? "+" : "", n);
  else {
    assert(n <= INT_MAX && n >= INT_MIN);
    q->x.offset = p->x.offset + n;
    q->x.name = stringd(q->x.offset);
  }
}

static void global(Symbol p)
{
  if (p->u.seg == BSS && p->sclass == STATIC) {
    print("\tglobl(%s,%d);\n", p->x.name, p->type->size);
    print("\tspace(%d);\n", p->type->size);
  } else if (p->u.seg != BSS) {
    print("\tgloblv(%s,%d);\n", p->x.name, p->type->size);
  }
}

static void segment(int n)
{
  if (n == cseg)
    return;
  switch (n) {
  case CODE: print("\tsegment('CODE');\n"); break;
  case BSS:  print("\tsegment('BSS');\n");  break;
  case DATA: print("\tsegment('DATA');\n"); break;
  case LIT:  print("\tsegment('LIT');\n"); break;
  }
  cseg = n;
}

static void space(int n)
{
  if (cseg != BSS)
    print("\tspace(%d);\n", n);
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
        1,        /* wants_argb */
        1,        /* left_to_right */
        0,        /* wants_dag */
        1,        /* unsigned_char !!!! */
        1,        /* wants_cvfu_cvuf */
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
          emit3,
          doarg,
          target,
          clobber,
        }
};

/*---- END CODE --*/

/* Local Variables: */
/* mode: c */
/* c-basic-offset: 2 */
/* indent-tabs-mode: () */
/* End: */
