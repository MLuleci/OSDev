#include "video.h"
#include "ports.h"
#define halt() while(1)

void kmain()
{
  clear();
  print("Hello from the kernel!");
  halt();
}
