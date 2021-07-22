#include <stdio.h>
#include <limits.h>




int main()
{
  // Demo printf and varargs
  fprintf(stdout,"%d %d %u\n",          1972, -327, UINT_MAX);
  fprintf(stdout,"%07d %07d %07u\n",    1972, -327, UINT_MAX);
  fprintf(stdout,"%+7d %+7d %+7u\n",    1972, -327, UINT_MAX);
  fprintf(stdout,"%+07d %+07d %+07u\n", 1972, -327, UINT_MAX);

  puts("Ready");
}
