    bits 16


%define MBR_SECTION         0x600
%define DPT1_OFFSET         446
%define DPT2_OFFSET         462
%define DPT3_OFFSET         478
%define DPT4_OFFSET         494
%define SIGN_OFFSET         510






    org 0x7c00

init_start:

    ;;
    ;; ss:sp = 0:7c00h
    ;; ds = es = 0
    ;;
    xor ax, ax
    mov ss, ax
    mov sp, 0x7c00
    mov es, ax
    mov ds, ax

    ;;
    ;; 复制 mbr 代码到 0:0600h
    ;;
    mov si, init_start
    mov di, MBR_SECTION
    mov cx, 512
    cld
    rep movsb

    ;;
    ;; 
    ;;
    push ax
    push WORD (MBR_SECTION + main - init_start)
    retf

;------------------------
; MBR 主要代码
;------------------------
main:
    sti

    ;;
    ;; 在 4 个分区表里查找可启动分区
    ;;
    mov cx, 4
    mov bp, MBR_SETCION + DPT1_OFFSET
@0:
    cmp BYTE [bp], 0
    jl @1
    jnz 
    add bp, 16
    loop @0


@1:
    mov [bp], dl
    push bp
    mov BYTE [bp+17], 5
    mov BYTE [bp+16], 0
    mov ah, 0x41
    mov bx, 0x55aa
    int 0x13
    pop bp
    jc next
    cmp bx, 0xaa55
    jne next
    test cx, 1
    jz next

    inc BYTE [bp+16]
    
next:
    pushad
    cmp BYTE [bp+16], 0
    je not_support
    

ext_read:
    push DWORD 0
    push DWORD [bp+8]
    push WORD 0
    push WORD 0x7c00
    push WORD 1
    push WORD 16
    mov ah, 0x42
    mov dl, [bp]
    mov si, sp
    int 13
    lahf
    add sp, 16
    sahf
    jmp read_done

legacy_read:
    mov ax, 0x0201
    mov bx, 0x7c00
    mov dl, [bp]
    mov dh, [bp+1] 
    mov cl, [bp+2]
    mov ch, [bp+3]
    int 0x13

read_done:
    popad
    jnc success


failure:
    dec BYTE [bp+17]
    jnz again
    
    cmp BYTE [bp], 0x80
    je
    mov dl, 0x80
    jmp @1


again:
    push bp
    xor ah, ah
    mov dl, [bp+0]
    int 0x13
    pop bp
    jmp next


success:
    cmp WORD [0x7c00+SIGN_OFFSET], 0xaa55
    jne

    push WORD [bp]
    


times 446-($-$$) db 0


        dw 0AA55h




