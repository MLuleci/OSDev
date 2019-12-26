ODIR = obj
OBJ = $(patsubst %.c,$(ODIR)/%.o,$(wildcard *.c))
OUT = floppy.img
LDFLAGS = -e kmain -Ttext 0x500

$(OUT) : $(ODIR)/boot.bin $(ODIR)/kernel.bin
	dd if=/dev/zero of=$@ count=2048
	dd if=$< of=$@ conv=notrunc
	dd if=$(ODIR)/kernel.bin of=$@ conv=notrunc seek=1

$(ODIR)/kernel.bin : $(ODIR)/kernel.o
	objcopy -R .note -R .comment -S -O binary $^ $@

$(ODIR)/kernel.o : $(OBJ)
	ld $(LDFLAGS) -o $@ $^
	ld -i $(LDFLAGS) -o $@ $^

$(ODIR)/%.o : %.c
	gcc -ffreestanding -c -o $@ $^

$(ODIR)/boot.bin : boot.asm
	nasm -f bin -o $@ $^

clean:
	rm -f $(ODIR)/* *.img
