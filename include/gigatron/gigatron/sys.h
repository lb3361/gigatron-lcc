#ifndef __GIGATRON_SYS
#define __GIGATRON_SYS


/* ---- Well known constants from interface.json ---- */

enum {
	romTypeValue_ROMv1  = 0x1c,
	romTypeValue_ROMv2  = 0x20,
	romTypeValue_ROMv3  = 0x28,
	romTypeValue_ROMv4  = 0x38,
	romTypeValue_ROMv5a = 0x40,
	romTypeValue_ROMv5  = 0x40, /* ??? */
	romTypeValue_DEVROM = 0xf8
};

enum {
	qqVgaWidth = 160,
	qqVgaHeigh = 120
};

enum {
	buttonRight  = 1,
	buttonLeft   = 2,
	buttonDown   = 4,
	buttonUp     = 8,
	buttonStart  = 16,
	buttonSelect = 32,
	buttonB      = 64,
	buttonA      = 128
};

/* ---- Well known rom locations from interface.json ---- */

enum {
	font32up = 0x0700,
	font82up = 0x0800,
	notesTable = 0x0900,
	invTable = 0x0a00
};

/* ---- Well known memory locations from interface.json ---- */

#ifdef __CHAR_UNSIGNED__
# define byte char
# define word unsigned int
#else
# define byte unsigned char
# define word unsigned int
#endif

extern __near byte zeroConst;
extern __near byte memSize;
extern __near byte entropy[3];
extern __near byte videoY;
extern __near byte frameCount;
extern __near byte serialRaw;
extern __near byte buttonState;
extern __near byte xoutMask;
extern __near word vPC;
extern __near byte vPCL;
extern __near byte vPCH;
extern __near word vAC;
extern __near byte vACL;
extern __near byte vACH;
extern __near word vLR;
extern __near byte vLRL;
extern __near byte vLRH;
extern __near byte vSP;
extern __near byte romType;
extern __near byte channelMask_v4;
extern __near word sysFn;
extern __near byte sysArgs0;
extern __near byte sysArgs1;
extern __near byte sysArgs2;
extern __near byte sysArgs3;
extern __near byte sysArgs4;
extern __near byte sysArgs5;
extern __near byte sysArgs6;
extern __near byte sysArgs7;
extern __near byte soundTimer;
extern __near byte ledState;
extern __near byte ledTempo;
extern __near byte userVars[];
extern __near byte oneConst;
extern __near byte userVars2[];
extern __near word v6502_PC;
extern __near byte v6502_PCL;
extern __near byte v6502_PCH;
extern __near byte v6502_A;
extern __near byte v6502_X;
extern __near byte v6502_Y;

extern byte videoTable[];
extern void vReset(void);
extern word vIRQ_c5;
extern byte videoTop_v5;
extern byte userCode[];
extern byte soundTable[];
extern byte screenMemory[][256];
extern byte ctrlBits_v5;          /* not in interface.json */

/* ---- Sound channels ---- */

typedef struct channel_s {
	char wavA, wavX;
#if STRUCT_CHANNEL_HAS_KEYW
	word keyW;
#else
	char keyL, keyH;
#endif
#if STRUCT_CHANNEL_HAS_OSC
	char oscL, oscH;
#endif
} channel_t;

extern channel_t channel1;
extern channel_t channel2;
extern channel_t channel3;
extern channel_t channel4;
extern channel_t *channel(int);


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

/* -- SYS_Exec */
void SYS_Exec(void *romptr, void *vlr);
#define has_SYS_Exec() 1

/* -- SYS_SetMode */
void SYS_SetMode(int);
#define has_SYS_SetMode 1

/* -- SYS_ReadRomDir
   Notes: the name is copied into buf8 */
void* SYS_ReadRomDir(void *romptr, char *buf8);
#define has_SYS_ReadRomDir() \
	((romType & 0xfc) >= romTypeValue_ROMv5)

/* -- SYS_ExpanderControl --
   Notes: Calling this from C is risky.
   Notes: This exists in v4 but overwrites 0x81 with ctrlBits. 
   Notes: We depend on ctrlBits being nonzero when an expansion card is present. */
int SYS_ExpanderControl(unsigned int ctrl);
#define has_SYS_ExpanderControl() \
	(((romType & 0xfc) >= romTypeValue_ROMv5) && (ctrlBits_v5 != 0))

/* -- SYS_SpiExchangeBytes --
   Notes: This exists in v4 but depends on 0x81 containing ctrlBits.
   Notes: only the high 8 bits of `dst` are used.
   Notes: only the low 8 bits of `srcend` are used. */
void SYS_SpiExchangeBytes(void *dst, void *src, void *srcend);
#define has_SYS_SpiExchangeBytes() \
	(((romType & 0xfc) >= romTypeValue_ROMv5) && (ctrlBits_v5 != 0))



#endif
