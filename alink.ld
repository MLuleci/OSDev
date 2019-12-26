ENTRY(boot);
OUTPUT_FORMAT(binary);
SECTIONS {
	 .text : AT(0x7C00) {
	       *(.text);
	 }
	 .method : {
	 	*(.method);
	 }
	 .data : {
	       *(.data);
	 }
	 .sig : AT(0x7DFE) {
	      SHORT(0xAA55);
	 }
}
