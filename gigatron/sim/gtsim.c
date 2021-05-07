#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>

typedef struct cpustate_s CpuState;

void sys_0x3b4(CpuState*);
void next_0x301(CpuState*);

char *rom = 0;
char *gt1 = 0;
int nogt1 = 0;
int trace = 0;
int verbose = 0;

void debug(const char *fmt, ...)
{
  if (verbose) {
    va_list ap;
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
  }
}

void fatal(const char *fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
  exit(EXIT_FAILURE);
}


/* ----------------------------------------------- */
/* MARCEL'S EMULATOR                               */
/* ----------------------------------------------- */


struct cpustate_s { // TTL state that the CPU controls
  uint16_t PC;
  uint8_t IR, D, AC, X, Y, OUT, undef;
};

uint8_t ROM[1<<16][2], RAM[1<<16], IN=0xff;

CpuState cpuCycle(const CpuState S)
{
  CpuState T = S; // New state is old state unless something changes

  T.IR = ROM[S.PC][0]; // Instruction Fetch
  T.D  = ROM[S.PC][1];

  int ins = S.IR >> 5;       // Instruction
  int mod = (S.IR >> 2) & 7; // Addressing mode (or condition)
  int bus = S.IR&3;          // Busmode
  int W = (ins == 6);        // Write instruction?
  int J = (ins == 7);        // Jump instruction?

  uint8_t lo=S.D, hi=0, *to=NULL; // Mode Decoder
  int incX=0;
  if (!J)
    switch (mod) {
      #define E(p) (W?0:p) // Disable AC and OUT loading during RAM write
      case 0: to=E(&T.AC);                          break;
      case 1: to=E(&T.AC); lo=S.X;                  break;
      case 2: to=E(&T.AC);         hi=S.Y;          break;
      case 3: to=E(&T.AC); lo=S.X; hi=S.Y;          break;
      case 4: to=  &T.X;                            break;
      case 5: to=  &T.Y;                            break;
      case 6: to=E(&T.OUT);                         break;
      case 7: to=E(&T.OUT); lo=S.X; hi=S.Y; incX=1; break;
    }
  uint16_t addr = (hi << 8) | lo;

  int B = S.undef; // Data Bus
  switch (bus) {
    case 0: B=S.D;                        break;
    case 1: if (!W) B = RAM[addr];        break;
    case 2: B=S.AC;                       break;
    case 3: B=IN;                         break;
  }

  if (W) RAM[addr] = B; // Random Access Memory

  uint8_t ALU; // Arithmetic and Logic Unit
  switch (ins) {
    case 0: ALU =        B; break; // LD
    case 1: ALU = S.AC & B; break; // ANDA
    case 2: ALU = S.AC | B; break; // ORA
    case 3: ALU = S.AC ^ B; break; // XORA
    case 4: ALU = S.AC + B; break; // ADDA
    case 5: ALU = S.AC - B; break; // SUBA
    case 6: ALU = S.AC;     break; // ST
    case 7: ALU = -S.AC;    break; // Bcc/JMP
  }

  if (to) *to = ALU; // Load value into register
  if (incX) T.X = S.X + 1; // Increment X

  T.PC = S.PC + 1; // Next instruction
  if (J) {
    if (mod != 0) { // Conditional branch within page
      int cond = (S.AC>>7) + 2*(S.AC==0);
      if (mod & (1 << cond)) // 74153
        T.PC = (S.PC & 0xff00) | B;
    } else
      T.PC = (S.Y << 8) | B; // Unconditional far jump
  }
  return T;
}

void sim(void)
{
  int vgaX = 0;
  int vgaY = 0;
  CpuState S;

  for(long long t = -2; ; t++)
    {
      // reset
      if (t < 0)
        S.PC = 0;

      // cycle
      CpuState T = cpuCycle(S); 

      // vga timing check
      int hSync = (T.OUT & 0x40) - (S.OUT & 0x40);
      int vSync = (T.OUT & 0x80) - (S.OUT & 0x80);
      if (vSync < 0) 
        vgaY = -36;
      vgaX++;
      if (hSync > 0) {
        if (vgaX != 200 && t >= 6250000)
          fprintf(stderr, "(gtsim) Horizontal timing error:"
                  "vgaY %-3d, vgaX %-3d, t=%0.3f\n", vgaY, vgaX, t/6.25e6);
        vgaX = 0;
        vgaY++;
      }

      // callbacks
      if (S.PC == 0x3b4)
        sys_0x3b4(&T);
      if (S.PC == 0x301)
        next_0x301(&T);
      // commit
      S = T;
    }
}



/* ----------------------------------------------- */
/* WELL-KNOWN LOCATIONS                            */
/* ----------------------------------------------- */


typedef uint16_t   word;
typedef uint8_t    byte;
typedef uint32_t   quad;

typedef int16_t   sword;
typedef int8_t    sbyte;
typedef int32_t   squad;

#define PEEK(a)     (RAM[a])
#define POKE(a,v)   (RAM[a]=v)
#define DEEK(a)     ((word)RAM[a]|(word)(RAM[(a)+1]<<8))
#define DOKE(a,v)   (RAM[a]=((v)&0xff),RAM[(a)+1]=(((v)>>8)&0xff))
#define QEEK(a)     ((quad)RAM[a]|((quad)RAM[(a)+1]<<8)|((quad)RAM[(a)+2]<<16)|((quad)RAM[(a)+3]<<24))


#define vPC_a       (0x16)
#define vAC_a       (0x18)
#define vLR_a       (0x1a)
#define vSP_a       (0x1b)
#define sysFn_a     (0x22)
#define sysArg_a(i) (0x24+(i))
#define LAC_a       (0x84)
#define T_a(i) 	    (0x88+2*(i))
#define R_a(i) 	    (0x90+2*(i))
#define SP_a        R_a(23)

#define vPC         DEEK(vPC_a)
#define vAC         DEEK(vAC_a)
#define vLR         DEEK(vLR_a)
#define vSP         PEEK(vSP_a)
#define sysFn       DEEK(sysFn_a)
#define sysArg(i)   PEEK(sysArg_a(i))
#define LAC         QEEK(LAC_a)
#define T(i)        DEEK(T_a(i))
#define R(i) 	    DEEK(R_a(i))
#define SP          R(23)

#define addlo(a,i)  (((a)&0xff00)|(((a)+i)&0xff))



/* ----------------------------------------------- */
/* CAPTURING SYS CALLS                             */
/* ----------------------------------------------- */

#define SYS_Exec 0x00ad

char *sysArgs(void)
{
  static char buffer[128];
  sprintf(buffer,"%02x %02x %02x %02x %02x %02x %02x %02x",
          sysArg(0),sysArg(1),sysArg(2),sysArg(3),
          sysArg(4),sysArg(5),sysArg(6),sysArg(7));
  return buffer;
}

word loadGt1(const char *gt1)
{
  int c;
  word addr;
  int len;
  FILE *fp = fopen(gt1, "rb");
  if (! fp)
    fatal("Cannot open file '%s'\n", gt1);
  c = getc(fp);
  do
    {
      // high address byte
      if (c < 0)
        goto eof;
      addr = (c & 0xff) << 8;
      // low address byte
      if ((c = getc(fp)) < 0)
        goto eof;
      addr |= (c & 0xff);
      // length
      if ((c = getc(fp)) < 0)
        goto eof;
      len = (c == 0) ? 256 : (c & 0xff);
      // segment
      while (--len >= 0)
        {
          if ((c = getc(fp)) < 0)
            goto eof;
          POKE(addr, c&0xff);
          addr = (addr & 0xff00) | ((addr+1) & 0xff);
        }
      // next high address byte
      if ((c = getc(fp)) < 0)
        goto eof;
    }
  while (c > 0);
  // high start byte
  if ((c = getc(fp)) < 0)
    goto eof;
  addr = (c & 0xff) << 8;
  // low start byte
  if ((c = getc(fp)) < 0)
    goto eof;
  addr |= (c & 0xff);
  // finished
  c = getc(fp);
  fclose(fp);
  if (c >= 0)
    fatal("Extra data in GT1 file '%s'\n", gt1);
  return addr;
 eof:
  fclose(fp);
  fatal("Premature EOF in GT1 file '%s'\n", gt1);
}



void sys_exit(void)
{
  exit((sword)R(8));
}

void sys_printf(void)
{
  printf("%s", (char*)&RAM[R(8)]);
}


void sys_0x3b4(CpuState *S)
{
  if ((sysFn & 0xff00) == 0xff00)
    {
      debug("vPC=%#x SYS(%d) sysFn=%#x sysArgs=%s\n", vPC, S->AC, sysFn, sysArgs()); 
      /* Pseudo SYS calls are captured here */
      switch(sysFn)
        {
        case 0xff00: sys_exit(); break;
        case 0xff01: sys_printf(); break;
        default: fprintf(stderr,"(gtsim) unimplemented SysFn=%#x\n", sysFn); break;
        }
      /* Return with no action and proper timing */
      S->IR = 0x00; S->D = 0xfa; /* LD(-12/2) */
      S->PC = 0x300;             /* NEXTY */
    }

  if (sysFn == SYS_Exec)
    {
      static int exec_count = 0;
      
      debug("vPC=%#x SYS(%d) sysFn=%#x (sys_Exec) sysArgs=%s\n",
            vPC, S->AC, sysFn, sysArgs());

      if (++exec_count == 2 && gt1)
        {
          // First exec is Reset.
          // Second exec is MainMenu.
          // Load GT1 instead
          int execaddr = loadGt1(gt1);
          debug("Loading file '%s' with start address %#x\n", gt1, execaddr);
          POKE(vPC_a, ((execaddr-2)) & 0xff);
          POKE(vPC_a+1, ((execaddr>>8) & 0xff));
          // And return from SYS_Exec
          S->IR = 0x00; S->D = 0xf8; /* LD(-16/2) */
          S->PC = 0x3cb;             /* REENTER */
          nogt1 = 1;
        }
    }
}



/* ----------------------------------------------- */
/* TRACING VCPU                                    */
/* ----------------------------------------------- */



int oper8(word addr, int i, char *operand)
{
  sprintf(operand, "$%02x", PEEK(addlo(addr,i)));
  return i+1;
}

int oper16(word addr, int i, char *operand)
{
  sprintf(operand, "$%04x", DEEK(addlo(addr,i)));
  return i+2;
}

int disasbcc(word addr, char **pm, char *operand)
{
  switch(PEEK(addlo(addr,1)))
    {
    case 0x3f:  *pm = "BEQ"; break;
    case 0x72:  *pm = "BNE"; break;
    case 0x50:  *pm = "BLT"; break;
    case 0x4d:  *pm = "BGT"; break;
    case 0x56:  *pm = "BLE"; break;
    case 0x53:  *pm = "BGE"; break;
    default:    *pm = "B??"; break;
    }
  sprintf(operand, "$%04x", (addr&0xff00)|((PEEK(addlo(addr,2))+2)&0xff));
  return 3;
}


int disassemble(word addr, char **pm, char *operand)
{
  switch(PEEK(addr))
    {
    case 0x5e:  *pm = "ST"; goto oper8;  
    case 0x2b:  *pm = "STW"; goto oper8;
    case 0xec:  *pm = "STLW"; goto oper8;
    case 0x1a:  *pm = "LD"; goto oper8;
    case 0x59:  *pm = "LDI"; goto oper8;
    case 0x11:  *pm = "LDWI"; goto oper16;
    case 0x21:  *pm = "LDW"; goto oper8;
    case 0xee:  *pm = "LDLW"; goto oper8;
    case 0x99:  *pm = "ADDW"; goto oper8;
    case 0xb8:  *pm = "SUBW"; goto oper8;
    case 0xe3:  *pm = "ADDI"; goto oper8;
    case 0xe6:  *pm = "SUBI"; goto oper8;
    case 0xe9:  *pm = "LSLW"; return 1;
    case 0x93:  *pm = "INC"; goto oper8;
    case 0x82:  *pm = "ANDI"; goto oper8;
    case 0xf8:  *pm = "ANDW"; goto oper8;
    case 0x88:  *pm = "ORI"; goto oper8;
    case 0xfa:  *pm = "ORW"; goto oper8;
    case 0x8c:  *pm = "XORI"; goto oper8;
    case 0xfc:  *pm = "XORW"; goto oper8;
    case 0xad:  *pm = "PEEK"; return 1;
    case 0xf6:  *pm = "DEEK"; return 1;
    case 0xf0:  *pm = "POKE"; goto oper8;
    case 0xf3:  *pm = "DOKE"; goto oper8;
    case 0x7f:  *pm = "LUP"; goto oper8;
    case 0x90:  *pm = "BRA"; goto operbr;
    case 0xcf:  *pm = "CALL"; goto oper8;
    case 0xff:  *pm = "RET"; return 1;
    case 0x75:  *pm = "PUSH"; return 1;
    case 0x63:  *pm = "POP"; return 1;
    case 0xdf:  *pm = "CALL"; goto oper8;
    case 0xcd:  *pm = "DEF"; goto oper8;
    case 0x85:  *pm = "CALLI"; goto oper16;
    case 0x1f:  *pm = "CMPHS"; goto oper8;
    case 0x97:  *pm = "CMPHU"; goto oper8;
    case 0x35: {
      switch(PEEK(addlo(addr,1)))
        {
        case 0x3f:  *pm = "BEQ"; break;
        case 0x72:  *pm = "BNE"; break;
        case 0x50:  *pm = "BLT"; break;
        case 0x4d:  *pm = "BGT"; break;
        case 0x56:  *pm = "BLE"; break;
        case 0x53:  *pm = "BGE"; break;
        default:    *pm = "B??"; break;
        }
      sprintf(operand, "$%04x", (addr&0xff00)|((PEEK(addlo(addr,2))+2)&0xff));
      return 3;
    }
    case 0xb4: {
      sbyte b = PEEK(addlo(addr,1));
      if (b > -128 && b <= 0) {
        *pm = "SYS"; sprintf(operand, "%d", 2*(14-b));
      } else 
        *pm = (b > 0) ? "S??" : "HALT";
      return 2;
    }
    default:
      return 2;
    oper8:
      sprintf(operand, "$%02x", PEEK(addlo(addr,1)));
      return 2;
    oper16:
      sprintf(operand, "$%04x", DEEK(addlo(addr,1)));
      return 3;
    operbr:
      sprintf(operand, "$%04x", (addr&0xff00)|((PEEK(addlo(addr,1))+2)&0xff));
      return 2;
    }
}

void print_trace(void)
{
  char operand[32];
  char *mnemonic = "???";
  word addr = addlo(vPC,2);
  operand[0] = 0;
  disassemble(addr, &mnemonic, operand);
  fprintf(stderr, "%04x:  [ vAC=$%04x vLR=$%04x ]  %-5s %-18s\n",
          addr, vAC, vLR, mnemonic, operand);
}

void next_0x301(CpuState *S)
{
  if (trace && nogt1)
    print_trace();
}



/* ----------------------------------------------- */
/* MAIN                                            */
/* ----------------------------------------------- */


void garble(uint8_t mem[], int len)
{
  for (int i=0; i<len; i++) mem[i] = rand();
}

void usage(int exitcode)
{
  fprintf(stderr,"Usage: gtsim [options] -rom romfile gt1file\n");
  if (exitcode == EXIT_SUCCESS) {
    fprintf(stderr,"\n"
            "Simulate the Gigatron executing <gt1file>\n"
            "The simulator captures the SYS_Exec calls to load <gt1file>\n"
            "instead of the main menu.\n"
            "\n"
            "Options:\n"
            "  -v: print debug messages\n"
            "  -t: trace VCPU execution\n"
            "  -nogt1: do not override main menu and run forever\n" );
  }
  exit(exitcode);
}

int main(int argc, char *argv[])
{
  // Initialize with randomized data
  srand(time(NULL));
  garble((void*)ROM, sizeof ROM);
  garble((void*)RAM, sizeof RAM);
  // Parse options
  for (int i=1; i<argc; i++)
    {
      if (!strcmp(argv[i],"-h"))
        {
          usage(EXIT_SUCCESS);
        }
      else if (! strcmp(argv[i],"-nogt1"))
        {
          nogt1 = 1;
        }
      else if (! strcmp(argv[i],"-v"))
        {
          verbose = 1;
        }
      else if (! strcmp(argv[i],"-t"))
        {
          trace = 1;
        }
      else if (! strcmp(argv[i],"-rom"))
        {
          if (i+1 >= argc)
            fatal("Missing argument for option -rom\n");
          if (rom)
            fatal("Duplicate option -rom\n");
          rom = argv[++i];
        }
      else if (argv[i][0] == '-')
        {
          fatal("Unrecognized option %s\n", argv[i]);
        }
      else
        {
          if (gt1)
            usage(EXIT_FAILURE);
          gt1 = argv[i];
        }
    }
  if (! gt1 && ! nogt1)
    usage(EXIT_FAILURE);
  
  // Read rom
  if (! rom)
    rom = "../gigatron-rom/dev.rom";
  FILE *fp = fopen(rom, "rb");
  if (!fp)
    fatal("Failed to open rom file '%s'\n", rom);
  if (fread(ROM, 1, sizeof(ROM), fp) != sizeof(ROM))
    fatal("Failed to read enough data from rom file '%s'\n", rom);
  fclose(fp);
  
  // Simulate
  sim();
  return 0;
}
