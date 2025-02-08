;*************************************************
;* ioapic.asm                                    *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************


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
        jae process_decimal
        call print_byte_value
        jmp dump_next
process_decimal:
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