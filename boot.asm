; References & resources:
; - http://www.osdever.net/tutorials/view/the-world-of-protected-mode
; - http://www.osdever.net/tutorials/view/xosdev-chapter-1
; - https://wiki.osdev.org/A20_Line
; - https://wiki.osdev.org/GDT
	
	bits 16				; Starting in real mode, generate 16-bit code
	org 0x7C00			; BIOS loads the booloader at address 0x7C00
	jmp boot			; Jump to beginning

; This routine attempts to enable the A20 line using several methods:
; - BIOS interrupts
; - Keyboard controller
; - Fast A20
;
; Returns 0 on success, -1 otherwise
enable_A20:
	pushad				; Save the flag and segment registers
	pushfd

	call check_A20			; Test if A20 is already enabled by BIOS
	cmp ax, 0
	jz enable_A20_return		; Already done!

	; BIOS method
	mov ax, 0x2403			; Query A20 support
	int 0x15
	jb A20_NOBIOS			; INT15 not supported
	cmp ah, 0
	jnz A20_NOBIOS			; INT15 not supported

	mov ax, 0x2402			; Query A20 status
	int 0x15
	jb A20_NOBIOS			; Can't get status
	cmp ah, 0
	jnz A20_NOBIOS			; Can't get status

	cmp al, 1
	xor ax, ax			; Clear AX, doesn't affect flags
	jz enable_A20_return		; A20 enabled

	mov ax, 0x2401			; Activate A20 with BIOS
	int 0x15
	jb A20_NOBIOS			; Can't activate
	cmp ah, 0
	jnz A20_NOBIOS			; Can't activate

	xor ax, ax			; Set return value
	jmp enable_A20_return		; BIOS method success

	; Keyboard controller method
A20_NOBIOS:
	call A20_OUT_WAIT		; Wait for keyboard
        mov al, 0xAD			; Disable keyboard
        out 0x64, al

        mov al, 0xD0			; Read controller out port
        out 0x64, al
 
        call A20_IN_WAIT		; Wait...
        in al, 0x60			; Read data port
        push ax				; Save
 
        call A20_OUT_WAIT		; Wait...
        mov al, 0xD1			; Write controller output port
        out 0x64, al
 
        call A20_OUT_WAIT		; Wait...
        pop ax				; Restore port data
        or al, 2			; Bit 1 enables A20
        out 0x60, al			; Write to data port
 
        call A20_OUT_WAIT		; Wait...
        mov al, 0xAE			; Enable keyboard
        out 0x64, al
 
        call A20_OUT_WAIT		; Wait...
	call check_A20			; Confirm A20 is enabled
	jz enable_A20_return		; If yes, we're done!

	; Fast A20 method
	in al, 0x92			; Read system control port A
	test al, 2			; Test Fast A20 bit
	push ax				; Save AX
	mov ax, -1			; Indicate failure
	jnz enable_A20_return		; Failed to enable A20
	pop ax				; Restore AX
	or al, 2			; Bit 1 enables A20
	and al, 0xFE			; Clear bit 0 to avoid a reboot
	out 0x92, al			; Write to system control port A
	call check_A20			; Confirm A20 is enabled
	jmp enable_A20_return		; Return either way
	
A20_OUT_WAIT:
	in al, 0x64
	test al, 2
	jnz A20_OUT_WAIT
	ret

A20_IN_WAIT:
	in al, 0x64
	test al, 1
	jz A20_IN_WAIT
	ret
	
enable_A20_return:	
	popfd				; Restore flag and segment registers
	popad
	ret
	
; This routine checks if the A20 line is enabled by comparing the boot signature
; found at 0000:7DFE to the location 1MiB above at FFFF:7E0E. If the two are the
; same then A20 is disabled, if not then the line must be enabled.
;
; Returns: 0 if A20 is enabled, -1 otherwise
check_A20:
	pushad				; Save the flag and segment registers
	pushfd
	push ds
	push es

	xor ax, ax			; AX = 0 (first segment)
	mov es, ax
	not ax				; AX = 0xFFFF (second segment)
	mov ds, ax

	mov di, 0x7DFE			; Location of boot identifier
	mov si, 0x7E0E			; 1MiB above it

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

	mov ax, -1			; Assume failure
	je check_A20_return		; Exit if A20 disabled
	not ax				; A20 is enabled
	
check_A20_return:			; Restore registers and return
	pop es
	pop ds
	popfd
	popad
	ret

boot:					; Actual start of the bootloader
	cli				; Disable interrupts while we work!
	xor ax, ax			; Clear AX
	mov ds, ax			; Initialize DS
	call enable_A20			; Enable the A20 line (AX = 0 on success)
	jz cont				; Continue booting
	
	mov si, ERRA20			; Point to A20 error message
	mov ah, 0x0E			; BIOS character display function
	mov bh, 0x00			; Page #
	mov bl, 0x07			; Normal text attribute
	
perr:
	lodsb				; Load character at [SI] to AL
	cmp al, 0			; Check for null terminator
	jz end				; Quit
	int 0x10			; BIOS print interrupt
	jmp perr
	
cont:
	lgdt [gdt_desc]			; Give CPU the GDT
	mov eax, cr0			; Get CR0 into AX
	or eax, 1			; Set bit 0
	mov cr0, eax			; Enter 32-bit PMode!
	
	jmp 0x8:clear_pipe		; Jump using selector and clear pipe

	bits 32				; Now in PMode, generate 32-bit code
clear_pipe:
	mov ax, 0x8			; Place the selector in AX
	mov ds, ax			; Initialize DS
	mov ss, ax			; Initialize SS
	mov esp, 0x90000		; Point the stack to a free memory area

	;  Print a character on the screen as a test
	mov esi, 0xB8000
	mov [esi], byte 'P'
	mov [esi+1], byte 0x1B

end:	
	sti				; Re-enable interrupts
	hlt				; Halt execution, we're done!

ERRA20:	db "Couldn't enable A20",0 	; A20 enable error message
	
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
gdt_end					; End of GDT
gdt_desc:				; GDT descriptor for the LGDT instruction
	dw gdt_end - gdt		; Size of GDT
	dw gdt				; Address of GDT

	times 510-($-$$) db 0		; Fill bytes until boot identifier
	dw 0xAA55			; Boot identifier
