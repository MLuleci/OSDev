    .code16             # Using BIOS functions, hence in real mode
    .global print       # Allow ld to see this label
    .section .text

# Prints an argument string onto the screen.
# Changes BIOS video mode to 40x25 Teletype!
# arg: Pointer to a null-terminated string
# ret: 0
print:
    push    %bp         # Save base pointer
    mov     %sp, %bp    # Re-base stack
    push    %bx         # Save callee-saved register(s)
    push    %si

    xor     %ax, %ax    # %ax = 0
    int     $0x10       # Use text mode, 40x25. Resets cursor to (0, 0).

    mov     $0x0E, %ah  # Select BIOS teletype write function
    xor     %bx, %bx    # Use first video page
    mov     4(%bp), %si # Load address of argument string to %si

loop:
    lodsb               # Load next character to %al (increments %si)
    cmp     $0, %al     # Check for null terminator
    jz      return      # Exit loop
    int     $0x10       # Print character
    jmp     loop

return:
    xor     %ax, %ax    # %ax = 0 (return value)
    pop     %si         # Restore callee-saved register(s)
    pop     %bx
    pop     %bp         # Restore old base pointer
    ret                 # Return to caller
