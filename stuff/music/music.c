#include <stdio.h>
#include <conio.h>
#include <gigatron/sys.h>
#include <gigatron/libc.h>
#include <gigatron/sound.h>

#pragma glcc option("PRINTF_SIMPLE")
#pragma glcc segment(0x8000,0x8100,"")
#pragma glcc segment(0x8240,0xfe00,"CDH")

extern const byte* agony[];
extern const byte* bath[];
extern const byte* escape[];
extern const byte* f1[];
extern const byte* freedom[];
extern const byte* fzero[];
extern const byte* ik[];
extern const byte* ment[];
extern const byte* virus[];

struct {
  const byte **midi;
  const char *name;
} midis[] = {
  { agony, "agony" },
  { bath, "bath" },
  { escape, "escape" },
  { f1, "f1" },
  { freedom, "freedom" },
  { fzero, "fzero" },
  { ik, "ik" },
  { ment, "ment" },
  { virus, "virus" }
};

#define NMIDIS (sizeof(midis)/sizeof(midis[0]))

int mindex = 1;
unsigned int startclk;


/* HEADER */

void header_name(void)
{
  gotoxy(1,2);
  cprintf("Name: %-10s",midis[mindex].name);
  startclk = _clock();
}

void header_time(void)
{
  static unsigned int lastclk;
  register unsigned int clk = (_clock()-startclk)/60;
  if (lastclk != clk) {
    gotoxy(1,3);
    cprintf("Time: %03ds", clk);
    lastclk = clk;
  }
}

/* SAMPLE WINDOW */

/* This locates the buffers in an area that we
   avoid loading because we do not want to
   crash 32k machines. */
extern byte sample1[128] __at(0x8000);
extern byte sample2[128] __at(0x8080);
byte * __near sb1 = sample1;
byte * __near sb2 = sample2;

#define SAMPLEY 32+64

void clear_sample_display(void)
{
  register int i;
  register byte *s = &screenMemory[SAMPLEY-63][16];
  for(i=0; i!=64; i++) {
    SYS_SetMemory(128, 0, s);
    s += 256;
  }
}

void sample_display(void)
{
  register int i;
  register byte *s;
  register byte *p = sb1;
  register byte *e = sb1 + 128;
  do { *p = *(volatile byte*)0x13; } while (++p != e);
    s = &screenMemory[SAMPLEY][16];
  p = sb2; e = sb2 + 128;
  do { *(s - ((*p & 0xf0) << 6)) = 0; s++; } while (++p != e);
  s = &screenMemory[SAMPLEY][16];
  p = sb1; e = sb1 + 128;
  do { *(s - ((*p & 0xf0) << 6)) = 0x2f; s++; } while (++p != e);
  p = sb1; sb1 = sb2; sb2 = p;
}

/* KEYS */

void handle_keys()
{
  int nindex = mindex;
  byte chr = serialRaw;
  byte btn = buttonState;
  if (chr >= '1' && chr < '1' + NMIDIS) {
    nindex = chr - '1';
  } else if ((btn & (buttonUp|buttonLeft)) != (buttonUp|buttonLeft)) {
    buttonState |= buttonLeft | buttonUp;
    nindex -= 1;
  } else if ((btn & (buttonDown|buttonRight)) != (buttonDown|buttonRight)) {
    buttonState |= buttonDown | buttonRight;
    nindex += 1;
  }
  if (nindex < 0)
    nindex = NMIDIS-1;
  else if (nindex >= NMIDIS)
    nindex = 0;
  if (nindex != mindex) {
    midi_play(0);
    mindex = nindex - 1; /* because the main loop adds one */
  }
}

/* MAIN */

void main()
{
  sound_sine_waveform(2);
  sound_reset(2);
  clear_sample_display();
  gotoxy(1,14);
  cprintf("Use digits or arrows");

  for(;;) {
    header_name();
    midi_play(midis[mindex].midi);
    while(midi_playing()) {
      header_time();
      sample_display();
      handle_keys();
    }
    mindex = mindex + 1;
    if (mindex >= NMIDIS)
      mindex = 0;
    _wait(30);
  }
}

/* Local Variables: */
/* mode: c */
/* c-basic-offset: 2 */
/* indent-tabs-mode: () */
/* End: */
