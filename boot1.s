# boot1.s - Setup protected mode environment, load & pass execution to kernel
    .code16                    # Starting in real mode, generate 16-bit code
    .global _start             # Allow ld to see this label (used as entry)
    .extern print              # Declare external symbol for print subroutine
    .extern himem              # Declare external symbol for himem subroutine
    .extern load               # Declare external symbol for multiboot loader
    .section .text

# Execution enviornment inherited from boot0 ensures:
# - boot1 is loaded at 0000:1000 - 0000:31FF
# - All segment registers are set to the first 64kB page (i.e. 0)
# - Interrupts are enabled
# - Stack (%sp) points to free memory 0000:31FF - 0000:7000 
_start:
    pushl   %ebp                # Save base pointer
    movl    %esp, %ebp          # Re-base stack
    subl    $8, %esp            # Allocate two 4-byte local variables

    int     $0x12               # Query lower memory size
    cmp     $636, %ax           # If available lower memory is < 636kB
    jl      fail                # ...not enough space for bootloader
    movl    %eax, -4(%ebp)      # Store lower memory size

    xor     %cx, %cx            # %cx = 0
    xor     %dx, %dx            # %dx = 0
    mov     $0xE801, %ax        # Get upper memory size
    int     $0x15               # Call BIOS
    jc      fail                # Check for BIOS error (CF = 1)
    jcxz    useax               # if %cx = 0 then %ax has return value
    mov     %cx, %ax            # ...otherwise TX value to %ax
    mov     %dx, %bx            # ...and %bx (%dx is coupled w/ %cx)

# %ax = # of cont. Kb from 1M to 16M
# %bx = cont. 64Kb pages above 16M
useax:
    cmp     $576, %ax           # If avalable upper memory is < 576kB
    jl      fail                # ...kernel can't be loaded
    movl    %eax, -8(%ebp)      # Store upper memory size

    mov     $0x0101, %cx        # Start from track #1, sector #1 (TTttssS)
    xor     %dh, %dh            # Start at head #0
    mov     $0xF000, %bx        # Place bytes at %es:%bx (0000:F000 start)

loop:
    cmp     $0xDC00, %bx        # If %bx < 0xDC00 read a full track (18 sectors)
    jnc     else                # ...otherwise calculate max readable amount
    mov     $18, %al            # %al = # sectors to read
    jmp     endif

else:
    push    %bx                 # Save %bx before clobbering
    shr     $4, %bx             # %bx >> 4 (as if doing memory addressing)
    mov     $0x1000, %ax
    sub     %bx, %ax            # (0x1000 - (%bx >> 4)) >> 5 = # sectors to read
    shr     $5, %ax             # ...total SHR = 9 i.e. %bx / 512 (bytes per sector)
    pop     %bx                 # Restore %bx

endif:
    mov     $2, %ah             # Read sectors function (%ah = 0x02)
    push    %cx                 # Caller-saved register
    int     $0x13
    jc      fail
    pop     %cx                 # Restore %cx
    add     %al, %cl            # %cl = starting sector + sectors read

    shl     $9, %ax             # %ax * 512 = bytes read
    add     %ax, %bx            # Move buffer pointer by %ax
    jnz     keepseg             # Test if %bx = 0x10000 (page boundary) & continue
    mov     %es, %ax
    add     $0x1000, %ax
    mov     %ax, %es            # Select next segment

keepseg:
    cmpb    $18, %cl
    jle     loop                # If %cl <= 18 keep reading from this track
    mov     $1, %cl             # ...otherwise reset starting sector
    xor     $1, %dh             # ...and move to other head
    jnz     loop                # If not using head #0 keep reading this cylinder
    inc     %ch                 # ...otherwise advance track #
    cmp     $33, %ch            # Check if we're done
    jne     loop                # ...otherwise loop

exit:
    call    himem               # Enable the A20 gate
    cmp     $0, %ax             # Check if the routine failed
    jz      fail

    cli                         # Disable interrupts (b/c we won't set an IDT)
    lgdt    gdt_desc            # Load GDT register

    mov     %cr0, %eax          # Read system control flags
    or      $1, %eax            # Set protection enable (PE) bit
    and     $0x7FFFFFFF, %eax   # Disable paging (PE) bit
    mov     %eax, %cr0          # Enter protected mode (BIOS services no more)
    ljmpl   $0x8, $pmode        # Jump using code selector and clear pipeline

    .code32                     # 32-bit code for protected mode
pmode:
    mov     $0x10, %ax          # Load the data segment selector into
    mov     %ax, %ds            # ...data segment register
    mov     %ax, %ss            # ...and the stack segment register
    xor     %ax, %ax            # Load the null segment selector into
    mov     %ax, %es            # ...extended segment register
    mov     %ax, %fs            # ...f-segment register
    mov     %ax, %gs            # ...and the g-segment register
    mov     $0x0000F000, %esp   # Use 0x8000 - 0xF000 as protected mode stack

    pushl   %edx                # Push drive # parameter
    pushl   -8(%ebp)            # Push upper memory size parameter
    pushl   -4(%ebp)            # Push lower memory size parameter
    call    load                # Invoke the multiboot loader
    add     $12, %esp           # Remove parameters from stack
    cmp     $0, %eax            # Check for errors
    je      fail

    mov     %eax, %edx          # Save entry_addr
    movl    $0x3200, %ebx       # Address of Multiboot info. structure
    mov     $0x2BADB002, %eax   # Magic # indicates to kernel we use Multiboot
    jmpl    *%edx               # Jump to kernel entry!

halt:
    cli                         # Disable interrupts which may wake us
    hlt
    jmp halt                    # In case of spurious wakeups, halt again

    .code16                     # 16-bit code for data and fail routine
fail:
    push    $failmsg            # Push &failmsg onto stack as argument
    call    print               # Print error message
    add     $2, %sp
    jmp     halt                # Halt execution

    .section .data              # Read-only data values
failmsg:
    .asciz "Boot1 failed, halting..."

# Start of GDT
# Segment descriptor layout:
#  31        24  23   22   21   20  19              16  15 14 13  12 11   8 7          0
# ---------------------------------------------------------------------------------------
# | Base 31:24 | G | D/B | 0 | AVL | Seg. Limit 19:16 | P | DPL | S | Type | Base 23:16 | 4
# ---------------------------------------------------------------------------------------
# | Base Address 15:00                                | Segment Limit 15:00             | 0
# ---------------------------------------------------------------------------------------
# AVL - Available for use by system software (that's us!)
# BASE - Segment base address
# D/B - Default operation size (0 = 16-bit, 1 = 32-bit)
# DPL - Descriptor privilege level (ring level)
# G - Granularity (0 = limit is interpreted in bytes, 1 = in 4KB units)
# LIMIT - Segment limit
# P - Segment present (when 0 causes trap if segment is accessed)
# S - Descriptor type (0 = system, 1 = code or data)
# TYPE - Segment type (meaning changes depending on value of 'S')
gdt:

# Null segment (required)
gdt_null:
    .quad 0

# Code segment (4 GB, 32-bit, DPL 0, “non-conforming” type)
# NOTES: 
# - Readable code segment may be accessed using %cs override or loading the
#   code segment selector into a data segment register (e.g. %es, %ds, ...)
# - Non-conforming code segment causes the CPU will trap if a lower privilege 
#   segment transfers control to it unless a call gate or task gate is used
# - Bit 20 in the second quadword (see "skip" below) is reserved for kernel use
gdt_code:
    .hword 0xFFFF               # Limit 15:00
    .hword 0                    # Base 15:00
    .byte 0                     # Base 23:16
    .byte 0b10011010            # Present, DPL 0, code, non-conforming, execute/read
    .byte 0b11001111            # 4KB granularity, 32-bit, skip (21,20), limit 19:16
    .byte 0                     # Base 31:23

# Data segment (4 GB, 32-bit, DPL 0, “expand-up” type)
# NOTES:
# - Stack segments are data segments which are read/write segments.
gdt_data:
    .hword 0xFFFF
    .hword 0
    .byte 0
    .byte 0b10010010            # Present, DPL 0, data, expand-up, read/write
    .byte 0b11001111
    .byte 0

# End of GDT
gdt_end:

# GDT descriptor
gdt_desc:
    .hword gdt_end - gdt        # GDT size (16 bits)
    .word gdt                   # GDT start address (32 bits)
