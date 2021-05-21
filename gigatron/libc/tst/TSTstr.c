#include <stdio.h>
#include <string.h>

const char *str1 = "The quick brown fox jumps over the lazy dog";
char str2[512];
char str3[512];



void fill_str2()
{
	int i;
	for (i=0; i<sizeof(str2);i++)
		str2[i] = '0' + (i % 10);
	str2[489] = 0;
	str2[123] = 'A';
	str2[258] = 'B';
	str2[358] = 'A';
}



int main()
{
	fill_str2();
	
	printf("str1=[%s] len=%d\n", str1, strlen(str1));
	printf("str2=[%s] len=%d\n", str2, strlen(str2));
	printf("strlen(str1+3)=%d\n", strlen(str1+3));
	printf("strlen(str2+255)=%d\n", strlen(str2+255));

	printf("strchr(str2,'A')=str2+%d\n", strchr(str2,'A')-str2);
	printf("strchr(str2,'B')=str2+%d\n", strchr(str2,'B')-str2);
	printf("strchr(str2,'C')=%p\n", strchr(str2,'C'));

	return 0;
}
