#if defined linux
#include <limits.h>
#include <sched.h>

#define OLDGLIBC_CPU_COUNT(cpusetp) __oldglibc_sched_cpucount (sizeof (cpu_set_t), cpusetp)

int
__oldglibc_sched_cpucount (size_t setsize, cpu_set_t *setp)
{
  int s = 0;
  for (unsigned int j = 0; j < setsize / sizeof (__cpu_mask); ++j)
    {
      __cpu_mask l = setp->__bits[j];
      if (l == 0)
	continue;

#if LONG_BIT > 32
      l = (l & 0x5555555555555555ul) + ((l >> 1) & 0x5555555555555555ul);
      l = (l & 0x3333333333333333ul) + ((l >> 2) & 0x3333333333333333ul);
      l = (l & 0x0f0f0f0f0f0f0f0ful) + ((l >> 4) & 0x0f0f0f0f0f0f0f0ful);
      l = (l & 0x00ff00ff00ff00fful) + ((l >> 8) & 0x00ff00ff00ff00fful);
      l = (l & 0x0000ffff0000fffful) + ((l >> 16) & 0x0000ffff0000fffful);
      l = (l & 0x00000000fffffffful) + ((l >> 32) & 0x00000000fffffffful);
#else
      l = (l & 0x55555555ul) + ((l >> 1) & 0x55555555ul);
      l = (l & 0x33333333ul) + ((l >> 2) & 0x33333333ul);
      l = (l & 0x0f0f0f0ful) + ((l >> 4) & 0x0f0f0f0ful);
      l = (l & 0x00ff00fful) + ((l >> 8) & 0x00ff00fful);
      l = (l & 0x0000fffful) + ((l >> 16) & 0x0000fffful);
#endif

      s += l;
    }

  return s;
}
#endif
