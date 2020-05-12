# OSDev
A toy OS consisting of a multi-stage bootloader and a kernel. This is purely an 
exercise in x86 OS development out of curiosity. Please be smart and don't brick
any real hardware using my code.

## Dependencies
In order to compile the project you'll need a cross-compiler and matching 
`binutils` for the generic `i686-elf` target platform. This *must* be your 
target as the OS is 32-bit and made for the x86 ISA. You may do as I have and 
follow the instructions here: https://wiki.osdev.org/GCC_Cross-Compiler

GNU `make` and `coreutils` are also required.

## Compiling
After aquiring the dependencies simply run `make` which will produce a file
named `floppy.img` that you can use with an emulator like `qemu` or `bochs`.

## Reading
The project book I followed can be found in the `doc` directory. The book also 
includes several links to other relevant documents you can download online, such
as the multiboot, BIOS, and IA-32 specifications.

Online copy of the project book: http://www.cs.cmu.edu/~410-s07/p4/p4-boot.pdf

## TODOS/FIXMES/NOTES
`boot0`:
- Does BIOS service to reset device controller (`int 0x13, %ah = 0`) only work 
  with floppies? If so, how to make it work with more types of storage?

`boot1`:
- BIOS service to query upper memory size (`INT 0x15, %ax = 0xE801`) is limited
  and the more advanced function (`ax = 0xE820`) should be used instead.
  See: https://wiki.osdev.org/Detecting_Memory_(x86)
- The boot loader complies with Multiboot v1 when improved v2 exists. Using the
  word "complies" very loosely here, it does bare minimum for the kernel.
- No support for any filesystems or object files. This is fine unless the kernel
  grows >576 KiB in size or the boot loader must be anything more than a toy.
- `himem.s` assumes the PS/2 controller exists and is properly configured.
  Ideally it would first do some setup and test those assumptions.