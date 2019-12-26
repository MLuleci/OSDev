	[BITS 16]
	SECTION .method
	GLOBAL enable_A20		; Export function
	EXTERN check_A20		; Define external symbol(s)
	
; This routine attempts to enable the A20 line using BIOS functions, the keyboard
; controller and the fast A20 gate methods.
; 
; Returns 0 on success, -1 otherwise
enable_A20:
	cli				; Disable interrupts while we work!
	pusha				; Save registers
	pushf

	call check_A20			; Test if A20 is already enabled by BIOS
	cmp ax, 0
	jz .enable_A20_return		; Already done!
	
	; BIOS method
	mov ax, 0x2403			; Query A20 support
	int 0x15
	jb .A20_NOBIOS			; INT15 not supported
	cmp ah, 0
	jnz .A20_NOBIOS			; INT15 not supported

	mov ax, 0x2402			; Query A20 status
	int 0x15
	jb .A20_NOBIOS			; Can't get status
	cmp ah, 0
	jnz .A20_NOBIOS			; Can't get status

	cmp al, 1
	xor ax, ax			; Clear AX, doesn't affect flags
	jz .enable_A20_return		; A20 enabled

	mov ax, 0x2401			; Activate A20 with BIOS
	int 0x15
	jb .A20_NOBIOS			; Can't activate
	cmp ah, 0
	jnz .A20_NOBIOS			; Can't activate

	xor ax, ax			; Set return value
	jmp .enable_A20_return		; BIOS method success
	
	; Keyboard method
.A20_NOBIOS:	
	call .A20_OUT_WAIT		; Wait for keyboard inputs to become available
	mov al, 0xAD			; Disable keyboard
        out 0x64, al
	
	call .A20_OUT_WAIT		; Wait for input...
	mov al, 0xD0			; Tell it we want to read from output port
	out 0x64, al
	
	call .A20_IN_WAIT		; Wait for the controller to return output
	in al, 0x60			; Read current controller status
	push ax				; Save status

	call .A20_OUT_WAIT		; Wait for input...
	mov al, 0xD1			; Tell it we want to write to output port
	out 0x64, al

	call .A20_OUT_WAIT		; Wait for input...
	pop ax				; Restore status
	or al, 2			; Set A20 enable bit
	out 0x60, al			; Write status back to controller

	call .A20_OUT_WAIT		; Wait for input...
	mov al, 0xAE			; Re-enable keyboard
	out 0x64, al

	call .A20_OUT_WAIT		; Clear input buffer
	call check_A20			; Check if A20 was set
	jz .enable_A20_return		; If yes, we're done!

	; Fast A20 method
	in al, 0x92			; Read system control port A
	test al, 2			; Test Fast A20 bit
	
	push ax				; Save AX
	mov ax, -1			; Indicate failure
	jnz .enable_A20_return		; Failed to enable A20
	pop ax				; Restore AX
	
	or al, 2			; Bit 1 enables A20
	and al, 0xFE			; Clear bit 0 to avoid a reboot
	out 0x92, al			; Write to system control port A
	call check_A20			; Confirm A20 is enabled
	jmp .enable_A20_return		; Return either way
	
; Spin until the output buffer is full
.A20_IN_WAIT:
	in al, 0x64
	test al, 1
	jz .A20_IN_WAIT
	ret

; Spin until the input buffer is empty
.A20_OUT_WAIT:
	in al, 0x64
	test al, 2
	jnz .A20_OUT_WAIT
	ret

.enable_A20_return:
	popf				; Restore registers
	popa
	sti				; Re-enable interrupts
	ret
