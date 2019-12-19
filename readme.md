# OSDev
A small "OS" consisting of a bootloader and a bit of C code. This is purely an exercise in x86 OS development out of curiosity. Please be smart and don't brick any real hardware using my code.

# Compiling
The makefile will compile the `boot.bin` and `kernel.bin` binaries and combine them within the `floppy.img` which you can use. Using an emulator like `qemu` or `bochs` is recommended over real hardware. Compilation requires you install `gcc` and `nasm` unless you want to use another compiler/assembler combination.

TL;DR - First `make` then `qemu-system-x86_64 -fda floppy.img`
