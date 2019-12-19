;; Taken from: http://www.osdever.net/tutorials/view/the-world-of-protected-mode
;; Useful reference: https://wiki.osdev.org/GDT
	
	bits 16				; Starting in real mode, generate 16-bit code
	org 0x7C00			; BIOS loads the booloader at address 0x7C00
	cli				; Disable interrupts while we work!
	xor ax, ax			; Clear AX
	mov ds, ax			; Initialize DS (used by LGDT)
	lgdt [gdt-desc]			; Give CPU the GDT
	mov eax, cr0			; Get CR0 into AX
	or eax, 1			; Set bit 0
	mov cr0, eax			; Enter 32-bit PMode!
	jmp 0x8:clear-pipe		; Jump using selector and clear pipe

	bits 32				; Now in PMode, generate 32-bit code
clear-pipe:
	mov ax, 0x8			; Place the selector in AX
	mov ds, ax			; Initialize DS
	mov ss, ax			; Initialize SS
	mov esp, 0x90000		; Point the stack to a free memory area

	;;  Print a character on the screen as a test
	mov 0xB8000, 'P'
	mov 0xB8001, 0x1B
	
	hlt				; Halt execution, we're done!
	
gdt:					; Start of the GDT for PMode
gdt-null:				; NULL segment
	dq 0
gdt-code:				; Code segment, encompassing the whole 4GB
	dw 0xFFFF			; Limit bits 0-15
	dw 0				; Base bits 16-31
	db 0				; Base bits 32-39
	db 0b10011010			; Access bits 40-47
	db 0b11001111			; Limit bits 48-51 & flag bits 52-55
	db 0				; Base bits 56-63
	
gdt-data:				; Data segment, overlapping code segment
	dw 0xFFFF
	dw 0
	db 0
	db 0b10010010			; Access bits for a system data segment
	db 0b11001111
	db 0
gdt-end					; End of GDT
gdt-desc:				; GDT descriptor for the LGDT instruction
	dw gdt-end - gdt		; Size of GDT
	dw gdt				; Address of GDT

	times 510-($-$$) db 0		; Fill bytes until boot identifier
	dw 0xAA55			; Boot identifier
