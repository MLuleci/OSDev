	[BITS 16]
	SECTION .method	
	GLOBAL print			; Export function
	
; Method to print the message (null-terminated string) pointed to by the first argument.
; The method uses BIOS interrupts to work, so only 16-bit addresses can be used.
; Has no return value.
print:
	push bp				; Push BP onto the stack
	mov bp, sp			; Copy SP into BP
	push bx				; Push callee-saved registers
	push si

	mov si, [bp + 4]		; Get address of message
	mov ah, 0x0E			; BIOS character display function
	mov bh, 0x00			; Page #
	mov bl, 0x07			; Normal text attribute

.print_lp:
	lodsb				; Load character at [SI] to AL
	cmp al, 0			; Check for null terminator
	jz .print_return		; Quit
	int 0x10			; BIOS print interrupt
	jmp .print_lp

.print_return:	
	pop si				; Restore registers
	pop bx
	pop bp				; Restore BP
	ret
