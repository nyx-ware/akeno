ENTRY(kernel_main)
OUTPUT_FORMAT(binary)

SECTIONS
{
    . = 0x100000;

    .text :
    {
        *(.text.kernel_main)
        *(.text)
    }

    .data :
    {
        *(.data)
    }

    .bss :
    {
        bss_start = .;
        *(.bss)
        *(COMMON)
        bss_end = .;
    }
}