    bits 16


;-----------------------------------
; int detect_memory_e820()
;-----------------------------------
detect_memory_e820:
    sub sp, 20
    mov di, sp
    mov ax, 0xe820
    mov cx, 20
    mov edx, 'SMAP'
    int 0x15
    jc .1
    cmp eax, 'SMAP'
    jne .1

.1: 
    xor ax, ax    
    ret
