; ----------------------------------------------------------------
; PROGRAM
; ----------------------------------------------------------------

[bits 16]
[org 0x7e00]

s2_begin:
    mov si, msg_s2_jumped
    mov bl, 10
    call print_string

    ; enable the a20 line the easy way
    mov ax, 0x2401
    int 0x15

    ; if the carry is set, it failed
    jc _a20_failed

    ; if ah is set, it failed
    test ah, ah
    jnz _a20_failed

    ; otherwise, it succeeded
    jmp _a20_succeeded

    ; if a20 failed, hang as there is no way to continue without it
_a20_failed:
    mov si, msg_a20_failed
    mov bl, 12
    call print_string

_a20_succeeded:
    mov si, msg_a20_succeeded
    mov bl, 10
    call print_string

    ; enter unreal mode
    cli
    cld

    ; load the lgdt
    lgdt [gdt_descriptor]

    ; set cr0 to enable protected mode
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ; load the data segment registers while in protected mode
    mov bx, 0x10
    mov ds, bx
    mov es, bx

    ; immediately return to real mode
    and al, 0xfe
    mov cr0, eax
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; test unreal mode
    mov ebx, 0x100000
    mov byte [ebx], 'U'
    mov al, [ebx]
    cmp al, 'U'
    jne _unreal_failed
    jmp _unreal_succeded

_unreal_failed:
    mov si, msg_unreal_failed
    mov bl, 12
    call print_string
    jmp $

_unreal_succeded:
    mov si, msg_unreal_succeeded
    mov bl, 10
    call print_string

    ; now we can access above 1mb, lets load the kernel
    mov edi, 0x100000
    mov bp, KERNEL_SECTORS

_load_kernel_loop:
    ; read one sector to 0x8000
    mov si, kernel_dap
    mov ah, 0x42
    mov dl, [0x7dfd]
    int 0x13
    jc _load_failed

    ; move that sector to edi (initally 1MB mark)
    push ds
    xor ax, ax
    mov ds, ax
    mov esi, 0x9000
    mov ecx, 128
    db 0x67
    rep movsd
    pop ds

    ; prepare for next sector
    inc dword [lba_low]
    dec bp
    jnz _load_kernel_loop
    jmp _load_succeeded

_load_failed:
    mov si, msg_kernel_load_failed
    mov bl, 12
    call print_string
    jmp $

_load_succeeded:
    mov si, msg_kernel_load_succeeded
    mov bl, 10
    call print_string

    ; begin trying to load protected mode
    mov si, msg_pm_attempt
    mov bl, 10
    call print_string

    ; just make sure interrupts are off
    cli

    ; set cr0 to enable protected mode
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ; far jump to refresh everything
    jmp 0x8:dword prepare_for_kernel

[bits 32]
prepare_for_kernel:
    ; reset the segments and stack for 32 bit
    mov ax, 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ebp, 0x90000
    mov esp, ebp

    ; zero out bss
    mov edi, BSS_START
    mov ecx, BSS_END
    sub ecx, edi
    xor eax, eax
    cld
    rep stosb

    ; jump to the kernel
    mov eax, 0x100000
    jmp eax

; ----------------------------------------------------------------
; FUNCTIONS
; ----------------------------------------------------------------

[bits 16]
%include "src/bootloader/print.asm"

; ----------------------------------------------------------------
; DATA
; ----------------------------------------------------------------

msg_s2_jumped:              db "Far jumped to stage two", 0xa, 0xd, 0x0
msg_a20_failed:             db "Failed to enable the A20 gate, hanging", 0xa, 0xd, 0x0
msg_a20_succeeded:          db "Enabled the A20 gate", 0xa, 0xd, 0x0
msg_gdt_loaded:             db "Loaded global descriptor table", 0xa, 0xd, 0x0
msg_unreal_failed:          db "Unreal mode failed, hanging", 0xa, 0xd, 0x0
msg_unreal_succeeded:       db "Unreal mode succeeded", 0xa, 0xd, 0x0
msg_kernel_load_failed:     db "Kernel loading failed, hanging", 0xa, 0xd, 0x0
msg_kernel_load_succeeded:  db "Kernel loading succeeded", 0xa, 0xd, 0x0
msg_pm_attempt:             db "Enabling protected mode, losing bios interrupts", 0xa, 0xd, 0x0

gdt_start:
                    dq 0x0
gdt_code:           dw 0xffff
                    dw 0x0
                    db 0x0
                    db 0b10011010
                    db 0b11001111
                    db 0x0
gdt_data:           dw 0xffff
                    dw 0x0
                    db 0x0
                    db 0b10010010
                    db 0b11001111
                    db 0x0
gdt_end:

gdt_descriptor:     dw gdt_end - gdt_start - 1
                    dd gdt_start

kernel_dap:         db 0x10
                    db 0x0
block_count:        dw 0x1
                    dw 0x9000
                    dw 0x0
lba_low:            dd 0x9
lba_high:           dd 0x0

times 4096 - ($ - $$) db 0x0