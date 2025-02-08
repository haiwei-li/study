;*************************************************
; dump_sse.asm                                   *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************


;-------------------------------------
; 打印 MXCSR 寄存器
;-------------------------------------
dump_mxcsr:
        push ebx
        mov esi, mxcsr_msg
        call puts
        mov esi, rc
        call puts
        sub esp, 4
        stmxcsr [esp]
        pop ebx
        mov esi, ebx
        shr esi, 13
        and esi, 3
        call print_dword_decimal
        call printblank
        bt ebx, 15              ; FZ 位
        setc al
        shl ebx, 19
        shrd ebx, eax, 1
        mov esi, ebx
        call reverse
        mov esi, eax
        mov edi, mxcsr_flags
        call dump_flags
        call println
        pop ebx
        ret

;----------------------------------------
; dump_xmm(start, end): 打印 XMM 寄存器
; input:
;       esi: 起始寄存器, 　edi: 终止寄存器
;----------------------------------------
dump_xmm:
        push ecx
        push edx
        push ebx
        sub esp, 8*16
        mov ecx, esi
        mov esi, esp
        call store_xmm
        mov edx, 7
        cmp edi, edx
        cmovb edx, edi
dump_xmm_loop:        
        mov esi, xmm_msg
        call puts
        mov esi, ecx
        call print_dword_decimal
        mov esi, ':'
        call putc
        call printblank
        lea ebx, [ecx * 8]              
        add ebx, ebx                    ; ecx * 16
        mov esi, [esp + ebx + 12]
        call print_dword_value
        mov esi, '_'
        call putc
        mov esi, [esp + ebx + 8]
        call print_dword_value
        mov esi, '_'
        call putc
        mov esi, [esp + ebx + 4]
        call print_dword_value
        mov esi, '_'
        call putc
        mov esi, [esp + ebx]
        call print_dword_value
        call println
        inc ecx
        cmp ecx, edx
        jbe dump_xmm_loop
        add esp, 8*16
        pop ebx
        pop edx
        pop ecx
        ret

;-------------------------------
; 打印 sse 环境
;------------------------------
dump_sse:
        call dump_mxcsr
        mov esi, 0
        mov edi, 7
        call dump_xmm
        ret


        

mxcsr_msg       db '<MXCSR>: ', 0
xmm_msg         db 'XMM', 0

b0      db 'ie', 0
b1      db 'de', 0
b2      db 'ze', 0
b3      db 'oe', 0
b4      db 'ue', 0
b5      db 'pe', 0
b6      db 'daz', 0
b7      db 'im', 0
b8      db 'dm', 0
b9      db 'zm', 0
b10     db 'om', 0
b11     db 'um', 0
b12     db 'pm', 0
b15     db 'fz', 0
rc      db 'RC:', 0

mxcsr_flags     dd b15, b12, b11, b10, b9, b8, b7, b6, b5, b4, b3, b2, b1, b0, -1