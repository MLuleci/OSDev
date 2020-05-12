ENTRY(_start);
OUTPUT_FORMAT(binary);

SECTIONS {
    .text 0x7C00 : {
        *(.text);
    }
    .data : {
        *(.data);
        . += 510 - (. - ADDR(.text));
        SHORT(0xAA55);
    }
}
