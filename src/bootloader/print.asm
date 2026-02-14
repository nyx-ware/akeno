; Print a null terminated string with an optional prefix
;
; si - start of a null terminated string
; bl - bios colour attribute for prefix
;
; Registers are preserved
print_string:
    pusha
    ; query current page
    mov ah, 0x0f
    int 0x10
    ; print the correctly coloured star
    mov ah, 0x09
    mov al, '*'
    mov cx, 1
    int 0x10
    ; query current cursor position
    mov ah, 0x03
    int 0x10
    ; shift cursor right by two
    add dl, 2
    mov ah, 0x02
    int 0x10
    
    ; standard print loop
_print_loop:
    ; set output type
    mov ah, 0x0e
    ; nice instruction to mov al, [si] then inc si
    lodsb
    ; check if the character is null
    cmp al, 0x0
    ; if so we are done
    je _print_done
    ; if not print and repeat
    int 0x10
    jmp _print_loop
_print_done:
    popa
    ret