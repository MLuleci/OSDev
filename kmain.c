#include "video.h"
#include "ports.h"
#define halt() while(1)
const char *str;

void kmain()
{
  clear();
  print(str);
  halt();
}
const char *str = "Hello from the kernel!";
