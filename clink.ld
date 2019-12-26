ENTRY(kmain);
OUTPUT_FORMAT(binary);
SECTIONS {
	 .text : AT(0x500) {
	       tmp/kmain.o(.text);
	       *(.text);
	 }
	 .data : { *(.data); }
	 .bss : { *(.bss); }
	 .rodata : { *(.rodata); }
}
