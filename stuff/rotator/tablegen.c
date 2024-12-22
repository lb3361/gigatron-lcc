
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef RADIUS
# ifdef ROMdev7
#  define RADIUS 59
# else
#  define RADIUS 31
# endif
#endif

#ifndef ZOOM
# define ZOOM 1.15
#endif

#ifndef ANGLE
# define ANGLE (-M_PI/43.0)
#endif



#define CENTERX 80
#define CENTERY 60
#define ADDR(x,y) (((x) + CENTERX) | (((y) + CENTERY + 8)<<8))
#define X(a) ((unsigned char)(a)-CENTERX)
#define Y(a) ((unsigned char)((a)>>8)-CENTERY-8)


unsigned short map[1+2*RADIUS][1+2*RADIUS];
signed short use[1+2*RADIUS][1+2*RADIUS];
char done[1+2*RADIUS][1+2*RADIUS];

void makemap()
{
  int x, y;
  double mr = cos(ANGLE) / ZOOM;
  double mi = sin(ANGLE) / ZOOM;

  for (y = -RADIUS; y <= RADIUS; y++)
    for (x = -RADIUS; x <= RADIUS; x++)
      {
        double x2f = mr * x + mi * y;
        double y2f = mr * y - mi * x;
        int x2 = (int)floor(x2f+0.5);
        int y2 = (int)floor(y2f+0.5);
        map[RADIUS+y][RADIUS+x] = ADDR(x2,y2);
        if (x2 >= -RADIUS && x2 <= RADIUS &&
            y2 >= -RADIUS && y2 <= RADIUS )
          if (x2 != x || y2 != y)
            use[RADIUS+y2][RADIUS+x2] += 1;
      }
}


int lastt2 = -1;
int lastt3 = -1;

int update(char *reg, int last, int t)
{
  if (last == t)
    {
      return 0;
    }
  else if (! ((last ^ t) & 0xff00))
    {
      if ((t & 0xff) == (last & 0xff) + 1)
        printf("INC(%s);", reg);
      else
#if defined(ROMdev7) || defined(ROMvx0)
        printf("MOVQB(0x%02x, %s);", t & 0xff, reg);
#else
      printf("LDI(0x%02x);ST(%s);", t & 0xff, reg);
#endif
    }
  else if (! ((last ^ t) & 0xff))
    {
      if ((t & 0xff00) == (last & 0xff00) + 256)
        {
          printf("INC(%s+1);", reg);
        }
      else
        {
#if defined(ROMdev7) || defined(ROMvx0)
          printf("MOVQB(0x%02x, %s+1);", (t >> 8) & 0xff, reg);
#else
          printf("LDWI(0x%04x);STW(%s);", t, reg);
          return 1;
#endif
        }
    }
  else
    {
#if defined(ROMdev7) || defined(ROMvx0)
      printf("_MOVIW(0x%04x, %s);", t, reg);
#else
      printf("LDWI(0x%04x);STW(%s);", t, reg);
      return 1;
#endif
    }
  return 0;
}

int point(int x, int y)
{
  int t;
  int n = 0;
  int t2 = ADDR(x,y);
  int t3 = map[RADIUS+y][RADIUS+x];

  printf("\t");
  printf("# (%d,%d)->(%d,%d) [%d]\n\t",
         Y(t3),X(t3),y,x,n);

  update("T2", lastt2, t2);

  if (x == X(t3) && y == Y(t3))
    {
      printf("_CALLJ('gen');POKE(T2)\n");
      use[RADIUS+Y(t3)][RADIUS+X(t3)] -= 1;
      done[RADIUS+y][RADIUS+x] = -1;
      lastt2 = t2;
      return x + 1;
    }

  if (X(t3) < -RADIUS || X(t3) > RADIUS ||
      Y(t3) < -RADIUS || Y(t3) > RADIUS )
    {
      printf("LDI(0);POKE(T2)\n");
      done[RADIUS+y][RADIUS+x] = -1;
      lastt2 = t2;
      return x + 1;
    }

  t = update("T3", lastt3, t3);

#if defined(ROMdev7)

  for (n=0; n <= RADIUS - x; n++)
    if (t3 + n == map[RADIUS+y][RADIUS+x+n] &&
        use[RADIUS+y][RADIUS+x+n] <= 0 &&
        done[RADIUS+y][RADIUS+x+n] == 0 )
      {
        use[RADIUS+Y(t3)][RADIUS+X(t3)+n] -= 1;
        done[RADIUS+y][RADIUS+x+n] = -1;
      }
    else
      break;
  printf("COPYN(%d)\n", n);
  lastt2 = t2 + n;
  lastt3 = t3 + n;
  return x + n;

#else
  if (t3 + 1 == map[RADIUS+y][RADIUS+x+1] &&
      use[RADIUS+y][RADIUS+x+1] <= 0 &&
      done[RADIUS+y][RADIUS+x+1] == 0 )
    {
      printf(t ? "DEEK();" : "_DEEKV(T3);");
      printf("DOKE(T2)\n");
      use[RADIUS+Y(t3)][RADIUS+X(t3)] -= 1;
      done[RADIUS+y][RADIUS+x] = 1;
      use[RADIUS+Y(t3)][RADIUS+X(t3)+1] -= 1;
      done[RADIUS+y][RADIUS+x+1] = 1;
      lastt2 = t2;
      lastt3 = t3;
      return x + 2;
    }
  printf(t ? "PEEK();" : "_PEEKV(T3);");
  printf("POKE(T2)\n");
  use[RADIUS+Y(t3)][RADIUS+X(t3)] -= 1;
  done[RADIUS+y][RADIUS+x] = 1;
  lastt2 = t2;
  lastt3 = t3;
  return x + 1;
#endif
}



int main()
{
  int r, x, y;

  makemap();

  printf("def code0():\n"
         "\tlabel('gen')\n"
         "\tSYS(34);LD(vACH);SUBI(7);_BGE('.g1')\n"
         "\tLD('entropy');ANDI(19);ADDW('rnd');ST('rnd')\n"
         "\tlabel('.g1');LD('rnd');RET()\n"
         "\n");
  
  printf("def code1():\n"
         "\tlabel('table')\n"
         "\tif args.cpu >= 6:\n"
         "\t\tdef _MOVQB(i,v): MOVQB(i,v)\n"
         "\telse:\n"
         "\t\tdef _MOVQB(i,v): LDI(i);ST(v)\n"
         "\tPUSH();LDI(0);STW(T2);STW(T3)\n");

  do {
    r = 0;
    for (y = -RADIUS; y <= RADIUS; y++)
      for (x = -RADIUS; x <= RADIUS; x++)
        {
          if (done[RADIUS+y][RADIUS+x])
            continue;
          else
            r += 1;
          if (use[RADIUS+y][RADIUS+x] <= 0)
            point(x,y);
        }
  } while (r);
  
  printf("\ttryhop(2);POP();RET()\n%s\n",
         "\n"
         "module(name='table.s',\n"
         "       code=[('EXPORT', 'table'),\n"
         "             ('CODE', 'gen', code0),\n"
         "             ('CODE', 'table', code1),\n"
         "             ('PLACE', 'table', 0x8000, 0xffff) ] )\n"
         "\n"
         "# Local Variables" ":\n"
         "# mode: python\n"
         "# indent-tabs-mode: ()\n"
         "# End:\n");
  return 0;
}


/* Local Variables: */
/* mode: c */
/* c-basic-offset: 2 */
/* indent-tabs-mode: () */
/* End: */
