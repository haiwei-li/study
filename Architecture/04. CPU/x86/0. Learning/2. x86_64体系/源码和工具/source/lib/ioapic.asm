; ioapic.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.




;------------------------------------
; enable_ioapic(): 开启 ioapic
;------------------------------------
enable_ioapic:
        ; 开启 ioapic
        call get_root_complex_base_address
        mov esi, [eax + 31FEh]
        bts esi, 8                      ; IOAPIC enable 位
        and esi, 0FFFFFF00h             ; IOAPIC range select
        mov [eax + 31FEh], esi          ; enable ioapic

        ; 设置 IOAPIC ID
        mov DWORD [IOAPIC_INDEX_REG], IOAPIC_ID_INDEX
        mov DWORD [IOAPIC_DATA_REG], 0F000000h          ; IOAPIC ID = 0Fh
        ret


;-----------------------------------
; ioapic_keyboard_handler()
;-----------------------------------
ioapic_keyboard_handler:
        in al, I8408_DATA_PORT                  ; 读键盘扫描码
        movzx eax, al
        cmp eax, key_map_end - key_map
        jg ioapic_keyboard_handler_done
        mov esi, [key_map + eax]
        call putc
ioapic_keyboard_handler_done:
        mov DWORD [APIC_BASE + EOI], 0          ; 发送 EOI 命令
        iret


;---------------------------------------------
; dump_ioapic(): 打印 ioapic 寄存器信息
;---------------------------------------------
dump_ioapic:
        push ecx
        
; 打印 ID, Version
        mov esi, id_msg
        call puts
        mov DWORD [IOAPIC_INDEX_REG], IOAPIC_ID_INDEX
        mov esi, [IOAPIC_DATA_REG]                              ; 读 ioapic ID
        call print_dword_value
        mov esi, ver_msg
        call puts
        mov DWORD [IOAPIC_INDEX_REG], IOAPIC_VER_INDEX
        mov esi, [IOAPIC_DATA_REG]                              ; 读 version
        call print_dword_value
        call println

; 打印 IOAPIC redirection table
        xor ecx, ecx
        mov esi, redirection
        call puts        
        
dump_ioapic_loop:        
        mov esi, ecx
        cmp ecx, 10
        jae print_decimal
        call print_byte_value
        jmp dump_next
print_decimal:
        call print_dword_decimal
dump_next:                
        mov esi, dump_msg
        call puts

        lea eax, [ecx * 2 + 10h]                        ; index
        mov [IOAPIC_INDEX_REG], eax                     ; 写入 index
        mov esi, [IOAPIC_DATA_REG]
        lea eax, [ecx * 2 + 11h]                        ; index
        mov [IOAPIC_INDEX_REG], eax                     ; 写入 index
        mov edi, [IOAPIC_DATA_REG]
        call print_qword_value
        mov esi, ' '
        mov eax, 10
        bt ecx, 0
        cmovc esi, eax
        call putc
        inc ecx
        cmp ecx, 24
        jb dump_ioapic_loop

        pop ecx
        ret



;****** ioapic 数据区 **********

id_msg          db 'ID: ', 0
ver_msg         db '        Ver: ', 0
redirection     db '-------- Redirection Table ----------', 10, 0
dump_msg        db ': ', 0


;*** 键盘扫描码 *****
key_map:
        db KEY_NULL, KEY_ESC, "1234567890-=", KEY_BS
        db KEY_TAB, "qwertyuiop[]", KEY_ENTER, KEY_CTRL
        db "asdfghjkl;'`", KEY_SHIFT, "\zxcvbnm,./"
        db KEY_SHIFT, KEY_PRINTSCREEN, KEY_ALT, KEY_SPACE, KEY_CAPS
        db KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10
        db KEY_NUM, KEY_SCROLL, KEY_HOME, KEY_UP, KEY_PAGEUP, KEY_SUB, KEY_LEFT, KEY_ENTER
        db KEY_RIGHT, KEY_ADD, KEY_END, KEY_DOWN, KEY_PAGEDOWN, KEY_INSERT, KEY_DEL
        db 0, 0, 0, KEY_F11, KEY_F12, 0, 0, 0
key_map_end:
