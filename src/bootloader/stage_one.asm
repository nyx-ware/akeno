; ----------------------------------------------------------------
; PROGRAM
; ----------------------------------------------------------------

[bits 16]
[org 0x7c00]

; ensure proper cs setup by far jumping
jmp 0x0:s1_begin

s1_begin:
    ; disable interrupts and clear screen
    cli

    ; setup the stack and segment registers
    xor ax, ax
    mov ss, ax
    mov sp, 0x7c00

    mov ds, ax
    mov es, ax

    ; clear screen before printing for the first time
    mov ah, 0x0
    mov al, 0x3
    int 0x10

    mov si, msg_seg_setup
    mov bl, 10
    call print_string

    ; store the boot drive
    mov [boot_drive], dl

    mov si, msg_boot_stored
    mov bl, 10
    call print_string

    ; check if the drive supports the required extension
    mov ah, 0x41
    mov bx, 0x55aa
    mov dl, [boot_drive]
    int 0x13

    ; if carry is set, no extensions are supported
    jc _lba_not_supported
    
    ; if bx didnt swap then the check failed
    cmp bx, 0xaa55
    jne _lba_not_supported

    ; if the lba support bit is not set, lba is not supported
    test cx, 0x1
    jz _lba_not_supported

    ; otherwise the drive supports lba
    jmp _lba_supported

    ; if lba is not supported, hang as there is no support for CHS
_lba_not_supported:
    mov si, msg_ext_failed
    mov bl, 12
    call print_string
    jmp $

    ; if lba is supported, move on
_lba_supported:
    mov si, msg_ext_success
    mov bl, 10
    call print_string

    mov cx, 3
_s2_attempt_load:
    ; load stage two using lba
    mov dl, [boot_drive]
    mov si, s2_dap
    mov ah, 0x42
    int 0x13

    ; if carry flag is set, load failed
    jc _s2_load_failed

    ; otherwise it was loaded successfully
    jmp _s2_load_succeeded

_s2_load_failed:
    ; ensure we try three times and reset the drive between attempts
    mov ah, 0x0
    int 0x13
    dec cx
    jnz _s2_attempt_load
    ; and after three attempts fail properly
    mov si, msg_s2_failed
    mov bl, 12
    call print_string
    jmp $

_s2_load_succeeded:
    mov si, msg_s2_succeeded
    mov bl, 10
    call print_string

    ; far jump to stage two (loaded to 0x0:0x7e00)
    jmp 0x0:0x7e00

; ----------------------------------------------------------------
; FUNCTIONS
; ----------------------------------------------------------------

%include "src/bootloader/print.asm"

; ----------------------------------------------------------------
; DATA
; ----------------------------------------------------------------

msg_seg_setup:      db "Setup stack and segment registers", 0xa, 0xd, 0x0
msg_boot_stored:    db "Stored boot drive", 0xa, 0xd, 0x0
msg_ext_failed:     db "LBA extension not supported, hanging", 0xa, 0xd, 0x0
msg_ext_success:    db "LBA extension supported", 0xa, 0xd, 0x0
msg_s2_failed:      db "Failed to load stage two, hanging", 0xa, 0xd, 0x0
msg_s2_succeeded:   db "Loaded stage two", 0xa, 0xd, 0x0

s2_dap:             db 0x10
                    db 0x0
                    dw 0x8
                    dw 0x7e00
                    dw 0x0
                    dq 0x1

times 509 - ($ - $$) db 0x0

; this is placed right before the magic bytes so we know where it is, so it
; can be used in stage two
boot_drive: db 0x0

dw 0xaa55