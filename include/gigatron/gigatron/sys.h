#ifndef __GIGATRON_SYS
#define __GIGATRON_SYS


/* ---- Well known constants from interface.json ---- */

#define romTypeValue_ROMv1    0x1c
#define romTypeValue_ROMv2    0x20
#define romTypeValue_ROMv3    0x28
#define romTypeValue_ROMv4    0x38
#define romTypeValue_ROMv5    0x40
#define romTypeValue_DEVROM   0xf8

#define qqVgaWidth            160
#define qqVgaHeight           120

#define buttonRight           1
#define buttonLeft            2
#define buttonDown            4
#define buttonUp              8
#define buttonStart           16
#define buttonSelect          32
#define buttonB               64
#define buttonA               128

#define wavA                  250
#define wavX                  251
#define keyL                  252
#define keyH                  253
#define oscL                  254
#define oscH                  255

/* ---- Well known rom locations from interface.json ---- */

#define font32up              0x0700
#define font82up              0x0800
#define notesTable            0x0900
#define invTable              0x0a00

/* ---- Well known memory locations from interface.json ---- */

#define zeroConst             (*(unsigned char*)(0x0000)) // unsigned char zeroConst;
#define memSize               (*(unsigned char*)(0x0001)) // unsigned char memSize;
#define entropy               ( (unsigned char*)(0x0006)) // unsigned char entropy[3];
#define videoY                (*(unsigned char*)(0x0009)) // unsigned char videoY;
#define frameCount            (*(unsigned char*)(0x000e)) // unsigned char frameCount;
#define serialRaw             (*(unsigned char*)(0x000f)) // unsigned char serialRaw;
#define buttonState           (*(unsigned char*)(0x0011)) // unsigned char buttonState;
#define xoutMask              (*(unsigned char*)(0x0014)) // unsigned char xoutMask;
#define vPC                   (*(unsigned int* )(0x0016)) // unsigned int  vPC;
#define vPCL                  (*(unsigned char*)(0x0016)) // unsigned char vPCL;
#define vPCH                  (*(unsigned char*)(0x0017)) // unsigned char vPCH;
#define vAC                   (*(unsigned int* )(0x0018)) // unsigned int  vAC;
#define vACL                  (*(unsigned char*)(0x0018)) // unsigned char vACL;
#define vACH                  (*(unsigned char*)(0x0019)) // unsigned char vACH;
#define vLR                   (*(unsigned int* )(0x001a)) // unsigned int  vLR;
#define vLRL                  (*(unsigned char*)(0x001a)) // unsigned char vLRL;
#define vLRH                  (*(unsigned char*)(0x001b)) // unsigned char vLRH;
#define vSP                   (*(unsigned char*)(0x001c)) // unsigned char vSP;
#define romType               (*(unsigned char*)(0x0021)) // unsigned char romType;
#define channelMask_v4        (*(unsigned char*)(0x0021)) // unsigned char channelMask_v4;
#define sysFn                 (*(unsigned int *)(0x0022)) // unsigned int  sysFn;
#define sysArgs0              (*(unsigned char*)(0x0024)) // unsigned char sysArgs0;
#define sysArgs1              (*(unsigned char*)(0x0025)) // unsigned char sysArgs1;
#define sysArgs2              (*(unsigned char*)(0x0026)) // unsigned char sysArgs2;
#define sysArgs3              (*(unsigned char*)(0x0027)) // unsigned char sysArgs3;
#define sysArgs4              (*(unsigned char*)(0x0028)) // unsigned char sysArgs4;
#define sysArgs5              (*(unsigned char*)(0x0029)) // unsigned char sysArgs5;
#define sysArgs6              (*(unsigned char*)(0x002a)) // unsigned char sysArgs6;
#define sysArgs7              (*(unsigned char*)(0x002b)) // unsigned char sysArgs7;
#define soundTimer            (*(unsigned char*)(0x002c)) // unsigned char soundTimer;
#define ledState_v2           (*(unsigned char*)(0x002e)) // unsigned char ledState;
#define ledTempo              (*(unsigned char*)(0x002f)) // unsigned char ledTempo;
#define userVars              ( (unsigned char*)(0x0030)) // unsigned char *userVars;
#define oneConst              (*(unsigned char*)(0x0080)) // unsigned char oneConst;
#define userVars2             ( (unsigned char*)(0x0081)) // unsigned char *userVars2;
#define v6502_PC              (*(unsigned int *)(0x001a)) // unsigned int  v6502_PC;
#define v6502_PCL             (*(unsigned char*)(0x001a)) // unsigned char v6502_PCL;
#define v6502_PCH             (*(unsigned char*)(0x001b)) // unsigned char v6502_PCH;
#define v6502_A               (*(unsigned char*)(0x0018)) // unsigned char v6502_A;
#define v6502_X               (*(unsigned char*)(0x002a)) // unsigned char v6502_X;
#define v6502_Y               (*(unsigned char*)(0x002b)) // unsigned char v6502_Y;

#define videoTable            ( (unsigned char*)(0x0100))  // unsigned char *videoTable;
#define vReset                ( (void (*)(void))(0x01f0))  // void           vReset(void);
#define vIRQ_v5               (*(unsigned int *)(0x01f6))  // unsigned int  *vIRQ_v5;
#define videoTop_v5           (*(unsigned char*)(0x01f9))  // unsigned char  videoTop_v5;
#define userCode              ( (unsigned char*)(0x0200))  // unsigned char *userCode;
#define soundTable            ( (unsigned char*)(0x0700))  // unsigned char  soundTable[]
#define screenMemory          ( (unsigned char*)(0x0800))  // unsigned char  screenMemory[]

#define channel1              ( (unsigned char*)(0x0100))  // unsigned char  channel1[]
#define channel2              ( (unsigned char*)(0x0200))  // unsigned char  channel2[]
#define channel3              ( (unsigned char*)(0x0300))  // unsigned char  channel3[]
#define channel4              ( (unsigned char*)(0x0400))  // unsigned char  channel4[]


/* ---- Unofficial memory locations ---- */

#define ctrlBits_v5           (*(unsigned char*)(0x01f8))  // unsigned char  ctrlBits_v5;


/* ---- Calling SYS functions ---- */

/* All stubs are in gigatron/libc/gigatron.s */

/* -- SYS_Lup -- */
int SYS_Lup(unsigned int addr);
#define has_SYS_Lup() 1

/* -- SYS_Random -- */
unsigned int SYS_Random(void);
#define has_SYS_Random() 1

/* -- SYS_VDrawBits -- */
void SYS_VDrawBits(int fgbg, char bits, char *address);
#define has_SYS_VDrawBits() 1

/* -- SYS_ExpanderControl --
   Notes: Calling this from C is risky.
   Notes: This exists in v4 but overwrites 0x81 with ctrlBits. 
   Notes: We depend on ctrlBits being nonzero when an expansion card is present. */
void SYS_ExpanderControl(unsigned int ctrl);
#define has_SYS_ExpanderControl()					\
	(((romType & 0xfc) >= romTypeValue_ROMv5) && (ctrlBits_v5 != 0))

/* -- SYS_SpiExchangeBytes --
   Notes: This exists in v4 but depends on 0x81 containing ctrlBits.
   Notes: only the high 8 bits of `dst` are used.
   Notes: only the low 8 bits of `srcend` are used. */
void SYS_SpiExchangeBytes(void *dst, void *src, void *srcend);
#define has_SYS_SpiExchangeBytes() \
	(((romType & 0xfc) >= romTypeValue_ROMv5) && (ctrlBits_v5 != 0))


#endif
