    .code16                 # Using BIOS functions, hence in real mode
    .global himem           # Allow ld to see this label
    .section .text

# Enables the A20 gate using various methods.
# arg: n/a
# ret: 0 on failure
himem:
    push    %bp             # Save base pointer
    mov     %sp, %bp        # Re-base stack

    # Method 0: Maybe it just works?
    call    check           # Some BIOSes enable A20 for you
    jnz     return          # Don't do anything!
    
    # Method 1: BIOS service
    mov     $0x2403, %ax    # Query A20 support
    int     $0x15           # Call BIOS
    jc      next            # BIOS error (try the other methods)
    test    $3, %bl         # Test status (bit 0: kbd, bit 1: port 92)
    jz      fail            # ...neither supported

    mov     $0x2402, %ax    # Query A20 status
    int     $0x15
    jc      next            # Couldn't read status (assume can't set it either)
    cmp     $0, %al         # Check if A20 enabled (%al = 1)
    jnz     return

    mov     $0x2401, %ax    # Enable A20
    int     $0x15
    jc      next

    call    check
    jnz     return

next:
    # Method 2: PS/2 controller
    call    waitin          # Wait for PS/2 controller to accept input
    mov     $0xD0, %al      # Read controller output port
    out     %al, $0x64      # ...give command

    call    waitout         # Wait for data returned
    in      $0x60, %al      # Read data into %al

    push    %ax             # Caller save %ax
    call    waitin
    mov     $0xD1, %al      # Write byte to controller output port
    out     %al, $0x64      # ...give command

    call    waitin
    pop     %ax             # Restore %ax
    or      $2, %al         # Set 2nd bit (A20 gate)
    out     %al, $0x60      # Write to data port

    call    waitin          # Wait for controller to process
    call    check           # Test if enabled now
    jnz     return          # Enabled A20!

    # Method 3: System Control Port A (a.k.a. fast A20)
    inb     $0x92, %al      # Read control port status
    test    $2, %al         # Test 2nd bit (A20 enable)
    jnz     return          # Already enabled!

    orb     $2, %al         # Set enable A20 bit
    andb    $0xFE, %al      # Make sure bit 0 is 0
    outb    %al, $0x92      # Write to control port
    call    check
    jnz     return

fail:
    xor     %ax, %ax        # %ax = 0 (failure)
return:
    pop     %bp             # Restore old base pointer
    ret                     # Return to caller

# Busy-wait until PS/2 controller is ready to accept input
# arg: n/a
# ret: n/a
waitin:
    in      $0x64, %al      # Read PS/2 status register
    test    $2, %al         # Test 2nd bit (input buffer status)
    jnz     waitin          # Try again if bit is set
    ret                     # ...otherwise return

# Busy-wait until PS/2 controller has data output ready
# arg: n/a
# ret: n/a
waitout:
    in      $0x64, %al
    test    $1, %al         # Test 1st bit (output buffer status)
    jz      waitout         # Try again if bit is not set
    ret

# Checks if the A20 gate is enabled.
# arg: n/a
# ret: %ax = 0 if not enabled (ZF = 1)
check:
    push    %bp
    mov     %sp, %bp
    push    %di             # Save callee-saved register(s)
    push    %si
    push    %es
    push    %ds

    xor     %ax, %ax        # %ax = 0
    mov     %ax, %es        # %es:%di points to bootsector identifier
    mov     $0x7DFE, %di    # ...at 0000:7DFE
    not     %ax             # %ax = 0xFFFF
    mov     %ax, %ds        # %ds:%si points to 1M above identifier
    mov     $0x7E0E, %si    # ...at FFFF:7E0E

    mov     %es:(%di), %ax  # Retrieve word from %es:%di
    push    %ax             # ...and save it
    mov     %ds:(%si), %ax  # Ditto
    push    %ax

    movb    $0, %es:(%di)   # Write 0 to lower address
    movb    $-1, %ds:(%si)  # Write 0xFF to upper address
    cmpb    $-1, %es:(%di)  # Compare lower address byte to 0xFF

    pop     %ax
    mov     %ax, %ds:(%si)  # Restore word to %ds:%si
    pop     %ax
    mov     %ax, %es:(%di)  # Ditto

    mov     $0, %ax         # Can't use xor b/c it affects status register
    je      exit            # Lower and upper memory were equal, not enabled
    not     %ax             # Otherwise %ax != 0, A20 is enabled

exit:
    pop     %ds             # Restore callee-saved register(s)
    pop     %es
    pop     %si
    pop     %di
    pop     %bp             # Restore old base pointer
    ret                     # Return to caller
