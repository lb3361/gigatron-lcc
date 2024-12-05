
#include <math.h>
#include <stdio.h>


#define RADIUS 19

#define ZOOM 1.1
#define ANGLE (-M_PI/20.0)

#define CENTERX 80
#define CENTERY 60


int main()
{
	int r, x, y, x2, y2;
	double mat[2][2];

	mat[0][0] = cos(ANGLE) / ZOOM;
	mat[0][1] = sin(ANGLE) / ZOOM;
	mat[1][0] = - mat[0][1];
	mat[1][1] = mat[0][0];

	
	int i = 0;
	printf("unsigned int table[] = {\n\t");
	for (r = RADIUS; r; r--) {
		x = y = -r;
		do {
			x2 = (int)trunc( x * mat[0][0] + y * mat[0][1] );
			y2 = (int)trunc( x * mat[1][0] + y * mat[1][1] );
			printf("0x%04x,0x%04x, ",
			       (x  + CENTERX) | ((y  + CENTERY + 8)<<8),
			       (x2 + CENTERX) | ((y2 + CENTERY + 8)<<8) );
			if (! (++i & 3))
				printf(" /* r=%d x=%d y=%d */\n\t", r, x, y);
			if (y == -r && x < r)
				x++;
			else if (x == r && y < r)
				y++;
			else if (y == r && x > -r)
				x--;
			else if (x == -r && y > -r)
				y--;
		} while (x > -r || y > -r);
	}
	printf("0 };\n");
	fprintf(stderr, "tablesize=%d\n", ++i);
	return 0;
}
