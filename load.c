#include "multiboot.h"

/**
 * Parse the Multiboot header located within the first 8192 bytes of the pre-
 * loaded kernel image @ 0000:F000 - 9000:F000, fill the Multiboot information 
 * structure as requested, and load the kernel into the high memory area.
 * 
 * Given parameters:
 * - `mem_lo` lower memory size (in KiB)
 * - `mem_hi` upper memory size (in KiB)
 * - `drive` drive number that was booted from, understood by BIOS INT 0x13
 * 
 * Returns 0 on failure, entry_addr on success
 */
multiboot_uint32_t load(multiboot_uint16_t mem_lo, multiboot_uint16_t mem_hi, multiboot_uint8_t drive)
{
    // Search for the multiboot header w/in kernel image
    struct multiboot_header* mbh = (struct multiboot_header*) 0xF000;
    multiboot_uint32_t i;
    for (i = 0; i < MULTIBOOT_SEARCH; ++i) {
        if ((mbh + i)->magic == MULTIBOOT_HEADER_MAGIC)
            break;
    }
    if (i >= MULTIBOOT_SEARCH)
        return 0; // Header not found
    mbh += i;

    // Verify header
    if (mbh->magic + mbh->flags + mbh->checksum)
        return 0; // Header not valid

    // "Allocate" multiboot information structure, just past boot1
    // w/in 0000:3200 - 0000:7FFF (19.4 KiB)
    multiboot_info_t* mbi = (multiboot_info_t*) 0x3200;
    mbi->flags = 0;

    // Flag 0: Align boot modules
    if (mbh->flags & MULTIBOOT_PAGE_ALIGN)
        return 0; // Not supported

    // Flag 1: Include memory information
    if (mbh->flags & MULTIBOOT_MEMORY_INFO) {
        mbi->flags |= MULTIBOOT_INFO_MEMORY;
        mbi->mem_lower = mem_lo;
        mbi->mem_upper = mem_hi;

        // For mmap_* fields see "0xE820" section:
        // https://wiki.osdev.org/Detecting_Memory_(x86)
        // Not possible here since interrupts are disabled by boot1
    }

    // Flag 2: Include video information
    if (mbh->flags & MULTIBOOT_VIDEO_MODE)
        return 0; // Not supported

    // Flag 16: Use header's address fields
    if (mbh->flags & MULTIBOOT_AOUT_KLUDGE) {
        // Multiboot spec. demands any compliant bootloader to support ELF,
        // however our project book specifically says to ignore this.

        multiboot_uint8_t* img = (multiboot_uint8_t*) (0xF000 + mbh->header_addr - mbh->load_addr);
        multiboot_uint8_t* ptr = (multiboot_uint8_t*) 0x100000;
        multiboot_uint32_t siz = 0x90000; // Pre-load area 0x9F000 - 0xF000
        if (!mbh->bss_end_addr) {
            siz = mbh->bss_end_addr - mbh->load_addr;
        } else if (mbh->load_end_addr) {
            siz = mbh->load_end_addr - mbh->load_addr;
        }

        for (i = 0; i < siz; ++i) {
            if (i > mbh->load_end_addr - mbh->load_addr) {
                *(ptr++) = 0; // Above .text & .data, zero-fill .bss
            } else {
                *(ptr++) = *(img + i);
            }
        }
    } else {
        return 0; // Not supported
    }

    // Include boot device information
    mbi->flags |= MULTIBOOT_INFO_BOOTDEV;
    mbi->boot_device = (drive << 24) | 0xFFFFFF;

    return mbh->entry_addr;
}