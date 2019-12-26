DIR = tmp

CSRC = $(wildcard *.c)
COBJ = $(patsubst %.c,$(DIR)/%.o,$(CSRC))

ASRC = $(wildcard *.s)
AOBJ = $(patsubst %.s,$(DIR)/%.o,$(ASRC))

BIN = $(addprefix $(DIR)/,$(addsuffix .bin,kernel boot))
IMG = $(addsuffix .img,floppy)

$(IMG) : $(BIN)
	dd if=/dev/zero of=$@ status=none conv=sparse count=2048
	dd if=$(word 2,$(BIN)) of=$@ status=none conv=notrunc
	dd if=$(word 1,$(BIN)) of=$@ status=none conv=notrunc seek=1

$(word 1,$(BIN)) : $(COBJ)
	ld -T clink.ld -o $@ $^

$(COBJ) : $(DIR)/%.o : %.c
	gcc -ffreestanding -c -o $@ $^

$(word 2,$(BIN)) : $(AOBJ)
	ld -T alink.ld -o $@ $^

$(AOBJ) : $(DIR)/%.o : %.s
	nasm -f elf64 -o $@ $^

clean :
	rm -f $(DIR)/* $(IMG)
