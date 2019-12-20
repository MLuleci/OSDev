floppy.img : boot.bin
	dd if=/dev/zero of=$@ count=2048
	dd if=$^ of=$@ conv=notrunc

boot.bin : boot.asm
	nasm -f bin -o $@ $^

clean :
	rm -f *.o *.bin *.img
