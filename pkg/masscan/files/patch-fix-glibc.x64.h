#if !defined(_FIX_GLIBC)
#define _FIX_GLIBC
#include <stdio.h>

int oldglibc_sscanf(const char *, const char *, ...);
asm(".symver oldglibc_sscanf, sscanf@GLIBC_2.2.5");

int oldglibc_fscanf(FILE *stream, const char *format, ...);
asm(".symver oldglibc_fscanf, fscanf@GLIBC_2.2.5");
#endif

