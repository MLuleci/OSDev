TARGET = i686-elf
LD = $(TARGET)-ld
AS = $(TARGET)-as
CC = $(TARGET)-gcc
OCPY = $(TARGET)-objcopy

# boot0 is max 512 bytes -- CHS: (0,0,1), LBA: 0
# boot1 is max 8.5 KiB -- CHS: (0,0,2) - (0,0,18), LBA: 1 - 17
# kernel is max 576 KiB -- CHS: (1,0,1) - (32,1,18), LBA: 36 - 1187
# Final floppy is 1.44 MiB in size
floppy.img : boot0.img boot1.img kernel.o
	dd if=/dev/zero of=$@ status=none conv=sparse count=2880
	dd if=boot0.img of=$@ status=none conv=notrunc count=1
	dd if=boot1.img of=$@ status=none conv=notrunc seek=1 count=17
	dd if=kernel.o of=$@ status=none conv=notrunc seek=36 count=1152

# Generate 576KiB of placeholder data instead of the kernel for debugging
kernel.o :
	./gen -c 1152 kernel.o

boot1.img : boot1.ld boot1.o print.o himem.o load.o
	$(LD) -T $^ -o $@

boot0.img : boot0.ld boot0.o print.o
	$(LD) -T $^ -o $@

%.o : %.s
	$(AS) $< -o $@

%.o : %.c
	$(CC) -std=gnu99 -ffreestanding -O2 -Wall -Wextra -c $< -o $@

clean : 
	rm -f *.o *.img
