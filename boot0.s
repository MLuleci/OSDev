# boot0.s - Setup realmode environment, load & pass execution to boot1
    .code16                 # Starting in real mode, generate 16-bit code
    .global _start          # Allow ld to see this label (used as entry)
    .extern print           # Declare external symbol for print subroutine
    .section .text
_start:
    cli                     # Disable interrupts
    ljmpl   $0, $canon      # Canoniclize %cs:%ip

canon:
    xor     %ax, %ax        # %ax = 0
    mov     %ax, %ds        # Use first 64 Kib page for data...
    mov     %ax, %ss        # ...and stack
    mov     %ax, %fs        # ...and f-segment
    mov     %ax, %gs        # ...and g-segment
    mov     %ax, %es        # ...and extended segment (for now)
    mov     $0x7000, %sp    # Use free memory 0000:31FF - 0000:7000 for stack
    sti                     # Re-enable interrupts

    int     $0x13           # Reset floppy controller (%ah = 0)
    jc      fail            # Check for BIOS error (CF = 1)

    mov     $0x0211, %ax    # Read (%ah = 0x02) 17 (%al = 0x11) sectors
    mov     $0x0002, %cx    # Start from track #0, sector #2 (TTttssS)
    xor     %dh, %dh        # Head #0
    mov     $0x1000, %bx    # Place bytes at %es:%bx (0000:1000)
    
    int     $0x13           # Call BIOS
    jc      fail            # Check for BIOS error
    jmp     *%bx            # Jump to boot1 code

fail:
    push    $failmsg        # Push &failmsg onto stack as argument
    call    print           # Print error message
    add     $2, %sp         # Remove parameter from stack
halt:
    cli                     # Disable interrupts which may wake us
    hlt
    jmp halt                # In case of spurious wakeups, halt again

    .section .data          # Read-only data values
failmsg:
    .asciz "Boot0 failed, halting..."
