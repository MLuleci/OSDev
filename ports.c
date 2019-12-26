#include "ports.h"

void out(unsigned short port, unsigned char data)
{
  __asm__ ("out %%al, %%dx"
	   : // no output
	   : "a" (data), "d" (port)
	   );
}

unsigned char in(unsigned short port)
{
  unsigned char data;
  __asm__ ("in %%dx, %%al"
	   : "=a" (data)
	   : "d" (port)
	   );
  return data;
}
