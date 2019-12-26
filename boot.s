; References & resources:
; - http://www.osdever.net/tutorials/view/the-world-of-protected-mode
; - http://www.osdever.net/tutorials/view/xosdev-chapter-12
; - https://wiki.osdev.org/A20_Line
; - https://wiki.osdev.org/GDT
; - https://wiki.osdev.org/%228042%22_PS/2_Controller#PS.2F2_Controller_IO_Ports

	[BITS 16]			; Starting in real mode, generate 16-bit code
	SECTION .text
	GLOBAL boot			; Export entry
	EXTERN print, enable_A20	; Define external symbol(s)
boot:
	xor ax, ax
	mov ds, ax			; Initialize DS
	call enable_A20			; Enable the A20 line (AX = 0 on success)
	or ax, ax			; Check for errors
	jnz boot			; Try again

	push A20OK			; Print status message
	call print
	add sp, 2
	
reset_drive:
	mov ah, 0     			; BIOS reset drive function
	int 0x13
	or ah, ah     			; Check for errors
	jnz reset_drive			; Try again

	mov es, ax    			; Segment of memory buffer = 0
	mov bx, 0x0500			; Offset of memory buffer
					; 0x500-0x7BFF is guaranteed free memory (30KiB)
	mov ah, 0x02			; Read floppy in CHS mode (cylndr, head, sector)
	mov al, 0x02			; # of sectors to read (512 bytes each)
	mov ch, 0			; Cylinder #
	mov cl,	0x02			; Starting sector
	mov dh,	0			; Head #
					; DL = Drive to use, already set by BIOS 
	int 0x13			; Load the kernel into ES:BX from floppy
	or ah, ah			; Check for errors	
	jnz reset_drive			; Try again

	push LDOK			; Print status message
	call print
	add sp, 2
	
	cli				; Disable interrupts
	xor ax, ax
	mov ds, ax			; Set DS = 0 to find DS:gdt_desc
	lgdt [gdt_desc]			; Give CPU the GDT
	
	mov eax, cr0			; Get CR0 into EAX
	or eax, 1			; Set bit 0
	mov cr0, eax			; Enter 32-bit PMode! (BIOS services are no more)
	jmp 0x08:clear_pipe		; Jump using selector and clear pipe

	[BITS 32]			; Now in PMode, generate 32-bit code
clear_pipe:
	mov ax, 0x10			; Place the selector in AX
	mov ds, ax			; Initialize DS
	mov ss, ax			; Initialize SS
	mov esp, 0x7E00			; Point the stack to a free memory area
					; 0x7E00-0x7FFFF guaranteed free memory (480KiB)
	jmp 0x08:0x0500			; Jump to kernel entry
	hlt				; Halt execution, we're done!

	SECTION .data
A20OK:					; A20 enable message
	db "Enabled A20... ",0

LDOK:					; Kernel load message
	db "Loaded kernel... ",0
	
gdt:					; Start of the GDT for PMode
gdt_null:				; NULL segment
	dq 0
gdt_code:				; Code segment, encompassing the whole 4GB
	dw 0xFFFF			; Limit bits 0-15
	dw 0				; Base bits 16-31
	db 0				; Base bits 32-39
	db 0b10011010			; Access bits 40-47
	db 0b11001111			; Limit bits 48-51 & flag bits 52-55
	db 0				; Base bits 56-63
	
gdt_data:				; Data segment, overlapping code segment
	dw 0xFFFF
	dw 0
	db 0
	db 0b10010010			; Access bits for a system data segment
	db 0b11001111
	db 0
gdt_end:				; End of GDT
gdt_desc:				; GDT descriptor for the LGDT instruction
	dw gdt_end - gdt		; Size of GDT
	dw gdt				; Address of GDT
