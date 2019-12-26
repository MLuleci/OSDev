#include "video.h"
#include "ports.h"

void clear()
{
  // Video memory location
  unsigned char *vidmem = (unsigned char *) 0xB8000;
  
  // Write null bytes to video memory
  const long size = 80 * 25;
  for (long i = 0; i < size; ++i) {
    *vidmem++ = 0; // Null character
    *vidmem++ = 0xF; // White color
  }

  // Reset cursor position to (0,0)
  move(0, 0);
}

void print(const char *ptr)
{
  // Video memory location
  unsigned char *vidmem = (unsigned char *) 0xB8000;

  // Get cursor offset
  unsigned short offset;
  out(0x3D4, 14);
  offset = in(0x3D5) << 8; // High byte
  out(0x3D4, 15);
  offset |= in(0x3D5); // Low byte

  // Goto cursor (x2 skips color attribs)
  vidmem += offset * 2;

  // Loop over string & print
  long i;
  for (i = 0; ptr[i]; ++i) {
    *vidmem = ptr[i];
    vidmem += 2;
  }

  // Place cursor after the string
  offset += i;
  out(0x3D4, 14);
  out(0x3D5, (unsigned char) (offset >> 8)); // High byte
  out(0x3D4, 15);
  out(0x3D5, (unsigned char) offset); // Low byte
}

void move(unsigned char x, unsigned char y)
{
  // Screen is 80 chars. wide
  unsigned short pos = y * 80 + x;
  
  // Access high cursor byte
  out(0x3D4, 14);
  out(0x3D5, (unsigned char) (pos >> 8));

  // Access low cursor byte
  out(0x3D4, 15);
  out(0x3D5, (unsigned char) pos);
}
