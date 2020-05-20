#if !defined(_FIX_GLIBC)
#define _FIX_GLIBC

int oldglibc_sscanf(const char *, const char *, ...);
asm(".symver oldglibc_sscanf, sscanf@GLIBC_2.2.5");

#endif

