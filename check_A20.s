	[BITS 16]
	SECTION .method
	GLOBAL check_A20		; Export function
	
; This routine checks if the A20 line is enabled by comparing the memory at 0000:0500
; to the location 1MiB above at FFFF:0510. If the two are the same then A20 is disabled,
; if not then the line must be enabled. 
;
; Returns: 0 if A20 is enabled, -1 otherwise
check_A20:
	pusha				; Save registers
	pushf
	push ds
	push es

	xor ax, ax			; AX = 0 (first segment)
	mov es, ax
	not ax				; AX = 0xFFFF (second segment)
	mov ds, ax
	
	mov di, 0x500			; Free memory 
	mov si, 0x510			; 1MiB above it

	; Get a byte from the boot identifier and from 1MiB above it
	mov al, byte [es:di]
	push ax
	mov al, byte [ds:si]
	push ax

	; Change the bytes
	mov byte [es:di], 0x00
	mov byte [ds:si], 0xFF
	cmp byte [es:di], 0xFF		; Compare the changes

	; Restore changed bytes
	pop ax
	mov byte [ds:si], al
	pop ax
	mov byte [es:di], al

	mov ax, 0			; Assume success
	jne .check_A20_return		; Exit if A20 enabled
	not ax				; Failure!
	
.check_A20_return:			; Restore registers and return
	pop es
	pop ds
	popf
	popa
	ret
