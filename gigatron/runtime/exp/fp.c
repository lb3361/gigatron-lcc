
typedef unsigned int word;
typedef unsigned char byte;

#ifdef TEST
word regs[32];
#else
#define regs ((word*)0x80)
#endif

# define FAC (&regs[2])
# define FARG (&regs[5])
# define bFAC ((byte*)FAC)
# define bFARG ((byte*)FARG)


void __load_fac(byte *p)
{
	bFAC[0] = p[0];
	bFAC[5] = p[1];
	bFAC[1] = (p[1] & 0x80) | 0x01;
	bFAC[4] = p[2];
	bFAC[3] = p[3];
	bFAC[2] = p[4] & 0x7f;
}

void __load_farg(byte *p)
{
	bFARG[0] = p[0];
	bFARG[5] = p[1];
	bFARG[1] = p[1] & 0x80;
	bFARG[4] = p[2];
	bFARG[3] = p[3];
	bFARG[2] = p[4];
}

void __store_fac(byte *p)
{
	p[0] = bFAC[0];
	p[1] = bFAC[5] | (bFAC[1] & 0x80);
	p[2] = bFAC[4];
	p[3] = bFAC[3];
	p[4] = bFAC[2];
}
