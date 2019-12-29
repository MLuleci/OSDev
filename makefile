DIR = tmp
CSRC = $(wildcard *.c)
COBJ = $(patsubst %.c,$(DIR)/%.o,$(CSRC))
BIN = $(addprefix $(DIR)/,$(addsuffix .bin,boot kernel))
TARGET = floppy.img

$(TARGET) : $(DIR)/kernel.bin $(DIR)/boot.bin
	dd if=/dev/zero of=$@ status=none conv=sparse count=2048
	dd if=$(word 1,$(BIN)) of=$@ status=none conv=notrunc
	dd if=$(word 2,$(BIN)) of=$@ status=none conv=notrunc seek=1

$(word 2,$(BIN)) : $(COBJ)
	ld -T clink.ld -o $@ $^

$(COBJ) : $(DIR)/%.o : %.c
	gcc -ffreestanding -c -o $@ $^

$(word 1,$(BIN)) : boot.s
	nasm -f bin -o $@ $^

clean :
	rm -f $(DIR)/* $(TARGET)
