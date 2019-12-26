ODIR = obj
OBJ = $(patsubst %.c,$(ODIR)/%.o,$(wildcard *.c))
OUT = floppy.img
LDFLAGS = -e kmain -Ttext 0x0500

run : $(OUT)
	qemu-system-x86_64 -fda $^

$(OUT) : $(ODIR)/kernel.bin $(ODIR)/boot.bin
	dd if=/dev/zero      of=$@ status=none conv=sparse count=2048
	dd if=$(ODIR)/boot.bin   of=$@ status=none conv=notrunc
	dd if=$(ODIR)/kernel.bin of=$@ status=none conv=notrunc seek=1

$(ODIR)/kernel.bin : $(ODIR)/kernel.o
	objcopy -R .note -R .comment -S -O binary $^ $@

$(ODIR)/kernel.o : $(OBJ)
	ld    $(LDFLAGS) -o $@ $^
	ld -i $(LDFLAGS) -o $@ $^

$(ODIR)/%.o : %.c
	gcc -c -o $@ $^

$(ODIR)/kmain.o : kmain.c
	gcc -ffreestanding -c -o $@ $^

$(ODIR)/boot.bin : boot.asm
	nasm -f bin -o $@ $^

clean :
	rm -f $(ODIR)/* *.img
