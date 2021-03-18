#ifndef __STDIO
#define __STDIO

/* interface.json with types */
/* to be refined */

#define romTypeValue_ROMv1  0x1c
#define romTypeValue_ROMv2  0x20
#define romTypeValue_ROMv3  0x28
#define romTypeValue_ROMv4  0x38
#define romTypeValue_ROMv5  0x40
#define romTypeValue_DEVROM 0xf8

#define __BYTEAT(addr) (*(unsigned char*)(addr))
#define __WORDAT(addr) (*(unsigned int*)(addr))

#define zeroConst       __BYTEAT(0x0000)
#define memSize         __BYTEAT(0x0001)
#define entropy         __BYTEAT(0x0006)
#define videoY          __BYTEAT(0x0009)
#define frameCount      __BYTEAT(0x000e)
#define serialRaw       __BYTEAT(0x000f)
#define buttonState     __BYTEAT(0x0011)
#define xoutMask        __BYTEAT(0x0014)
#define vPC             __WORDAT(0x0016)
#define vPCL            __BYTEAT(0x0016)
#define vPCH            __BYTEAT(0x0017)
#define vAC             __WORDAT(0x0018)
#define vACL            __BYTEAT(0x0018)
#define vACH            __BYTEAT(0x0019)
#define vLR             __WORDAT(0x001a)
#define vLRL            __BYTEAT(0x001a)
#define vLRH            __BYTEAT(0x001b)
#define vSP             __BYTEAT(0x001c)
#define romType         __BYTEAT(0x0021)
#define channelMask_v4  __BYTEAT(0x0021)
#define sysFn           __WORDAT(0x0022)
#define sysArgs0        __BYTEAT(0x0024)
#define sysArgs1        __BYTEAT(0x0025)
#define sysArgs2        __BYTEAT(0x0026)
#define sysArgs3        __BYTEAT(0x0027)
#define sysArgs4        __BYTEAT(0x0028)
#define sysArgs5        __BYTEAT(0x0029)
#define sysArgs6        __BYTEAT(0x002a)
#define sysArgs7        __BYTEAT(0x002b)
#define soundTimer      __BYTEAT(0x002c)
#define ledState_v2     __BYTEAT(0x002e)
#define ledTempo        __BYTEAT(0x002f)
#define oneConst        __BYTEAT(0x0080)

#define userVars        ((unsigned char*)0x0030)
#define userVars2       ((unsigned char*)0x0081)

#define v6502_PC        __WORDAT(0x001a)
#define v6502_PCL       __BYTEAT(0x001a)
#define v6502_PCH       __BYTEAT(0x001b)
#define v6502_A         __BYTEAT(0x0018)
#define v6502_X         __BYTEAT(0x002a)
#define v6502_Y         __BYTEAT(0x002b)

#define videoTable      ((unsigned int*)0x100)
#define vReset          ((void*)0x1f0)
#define vIRQ_v5         ((void*)0x1f6)
#define videoTop_v5     __BYTEAT(0x01f9)
#define userCode        ((void*)0x200)  
#define sountTable      ((unsigned char*)0x0700)
#define screenMemory"   ((unsigned char*)0x0800)

#define qqVgaWidth  160
#define qqVgaHeight 120

#define channel1 ((unsigned char*)0x0100)
#define channel2 ((unsigned char*)0x0200)
#define channel3 ((unsigned char*)0x0300)
#define channel4 ((unsigned char*)0x0400)
#define wavA     250
#define wavX     251
#define keyL     252
#define keyH     253
#define oscL     254
#define oscH     255

#define buttonRight  1
#define buttonLeft   2
#define buttonDown   4
#define buttonUp     8
#define buttonStart  16
#define buttonSelect 32
#define buttonB      64
#define buttonA      128

#define maxTicks     14

#define __PROGADDR(x) ((unsigned int)x)

#define LDWI          __PROGADDR(0x0311)
#define LD            __PROGADDR(0x031a)
#define CMPHS_v5      __PROGADDR(0x031f)
#define LDW           __PROGADDR(0x0321)
#define STW           __PROGADDR(0x032b)
#define BCC           __PROGADDR(0x0335)
#define EQ            __PROGADDR(0x033f)
#define GT            __PROGADDR(0x034d)
#define LT            __PROGADDR(0x0350)
#define GE            __PROGADDR(0x0353)
#define LE            __PROGADDR(0x0356)
#define LDI           __PROGADDR(0x0359)
#define ST            __PROGADDR(0x035e)
#define POP           __PROGADDR(0x0363)
#define NE            __PROGADDR(0x0372)
#define PUSH          __PROGADDR(0x0375)
#define LUP           __PROGADDR(0x037f)
#define ANDI          __PROGADDR(0x0382)
#define CALLI_v5      __PROGADDR(0x0385)
#define ORI           __PROGADDR(0x0388)
#define XORI          __PROGADDR(0x038c)
#define BRA           __PROGADDR(0x0390)
#define INC           __PROGADDR(0x0393)
#define CMPHU_v5      __PROGADDR(0x0397)
#define ADDW          __PROGADDR(0x0399)
#define PEEK          __PROGADDR(0x03ad)
#define SYS           __PROGADDR(0x03b4)
#define SUBW          __PROGADDR(0x03b8)
#define DEF           __PROGADDR(0x03cd)
#define CALL          __PROGADDR(0x03cf)
#define ALLOC         __PROGADDR(0x03df)
#define ADDI          __PROGADDR(0x03e3)
#define SUBI          __PROGADDR(0x03e6)
#define LSLW          __PROGADDR(0x03e9)
#define STLW          __PROGADDR(0x03ec)
#define LDLW          __PROGADDR(0x03ee)
#define POKE          __PROGADDR(0x03f0)
#define DOKE          __PROGADDR(0x03f3)
#define DEEK          __PROGADDR(0x03f6)
#define ANDW          __PROGADDR(0x03f8)
#define ORW           __PROGADDR(0x03fa)
#define XORW          __PROGADDR(0x03fc)
#define RET           __PROGADDR(0x03ff)
#define HALT          __PROGADDR(0x80b4)
#define vIRQ_Return   __PROGADDR(0x0400)

#define SYS_Exec_88                     __PROGADDR(0x00ad)
#define SYS_ReadRomDir_v5_80            __PROGADDR(0x00ef)
#define SYS_Out_22                      __PROGADDR(0x00f4)
#define SYS_In_24                       __PROGADDR(0x00f9)
#define SYS_Random_34                   __PROGADDR(0x04a7)
#define SYS_LSRW7_30                    __PROGADDR(0x04b9)
#define SYS_LSRW8_24                    __PROGADDR(0x04c6)
#define SYS_LSLW8_24                    __PROGADDR(0x04cd)
#define SYS_Draw4_30                    __PROGADDR(0x04d4)
#define SYS_VDrawBits_134               __PROGADDR(0x04e1)
#define SYS_LSRW1_48                    __PROGADDR(0x0600)
#define SYS_LSRW2_52                    __PROGADDR(0x0619)
#define SYS_LSRW3_52                    __PROGADDR(0x0636)
#define SYS_LSRW4_50                    __PROGADDR(0x0652)
#define SYS_LSRW5_50                    __PROGADDR(0x066d)
#define SYS_LSRW6_48                    __PROGADDR(0x0687)
#define SYS_LSLW4_46                    __PROGADDR(0x06a0)
#define SYS_Read3_40                    __PROGADDR(0x06b9)
#define SYS_Unpack_56                   __PROGADDR(0x06c0)
#define SYS_SetMode_v2_80               __PROGADDR(0x0b00)
#define SYS_SetMemory_v2_54             __PROGADDR(0x0b03)
#define SYS_SendSerial1_v3_80           __PROGADDR(0x0b06)
#define SYS_ExpanderControl_v4_40       __PROGADDR(0x0b09)
#define SYS_Run6502_v4_80               __PROGADDR(0x0b0c)
#define SYS_ResetWaveforms_v4_50        __PROGADDR(0x0b0f)
#define SYS_ShuffleNoise_v4_46          __PROGADDR(0x0b12)
#define SYS_SpiExchangeBytes_v4_134     __PROGADDR(0x0b15)
#define SYS_Sprite6_v3_64               __PROGADDR(0x0c00)
#define SYS_Sprite6x_v3_64              __PROGADDR(0x0c40)
#define SYS_Sprite6y_v3_64              __PROGADDR(0x0c80)
#define SYS_Sprite6xy_v3_64             __PROGADDR(0x0cc0)

#define font32up                    __PROGADDR(0x0700)
#define font82up                    __PROGADDR(0x0800)
#define notesTable                  __PROGADDR(0x0900)
#define invTable                    __PROGADDR(0x0a00)

extern __builtin_syscall(int);


#endif

