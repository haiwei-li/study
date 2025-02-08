; sse.asm
; Copyright (c) 2009-2012 邓志
; All rights reserved.


;
; SSE 系列指令环境库

init_sse:
        
        ret


;--------------------------------
; store_xmm(image): 保存 xmm 寄存器
; input:
;       esi: address of image
;-------------------------------
store_xmm:
        movdqu [esi], xmm0
        movdqu [esi + 16], xmm1
        movdqu [esi + 32], xmm2
        movdqu [esi + 48], xmm3
        movdqu [esi + 64], xmm4
        movdqu [esi + 80], xmm5
        movdqu [esi + 96], xmm6
        movdqu [esi + 112], xmm7
        ret

;-----------------------------------
; restore_xmm(image): 恢复 xmm 寄存器
; input:
;       esi: address of image
;----------------------------------
restore_xmm:
        movdqu xmm0, [esi]
        movdqu xmm1, [esi + 16]
        movdqu xmm2, [esi + 32] 
        movdqu xmm3, [esi + 48] 
        movdqu xmm4, [esi + 64] 
        movdqu xmm5, [esi + 80] 
        movdqu xmm6, [esi + 96] 
        movdqu xmm7, [esi + 112] 
        ret

;---------------------------------------
; store_sse(image)： 保存 SSEx 环境 state
; input:
;       esi: image
;---------------------------------------
store_sse:
        call store_xmm
        stmxcsr [esi + 128]
        ret

;----------------------------------------
; restore_sse(image): 恢复 SSEx 环境 state
; input:
;       esi: image
;----------------------------------------
restore_sse:
        call restore_xmm
        ldmxcsr [esi + 128]
        ret

;-----------------------------
; sse4_strlen(): 得到字符串长度
; input:
;       esi: string
; output:
;       eax: length of string
;-----------------------------
sse4_strlen:
        push ecx
        pxor xmm0, xmm0         ; 清 XMM0 寄存器
        mov eax, esi
        sub eax, 16
sse4_strlen_loop:        
        add eax, 16
        pcmpistri xmm0, [eax], 8        ; unsigned byte, equal each, IntRes2=IntRes1, lsb index
        jnz sse4_strlen_loop
        add eax, ecx
        sub eax, esi
        pop ecx
        ret


;----------------------------------------------------------
; substr_search(str1, str2): 查找串str2 在 str1串出现的位置
; input:
;       esi: str1, edi: str2
; outpu:
;       -1: 找不到，否则 eax = 返回 str2 在 str1 的位置
;----------------------------------------------------------
substr_search:
        push ecx
        push ebx
        lea eax, [esi - 16]
        movdqu xmm0, [edi]              ; str2 串
	mov ecx, 16
        mov ebx, -1
substr_search_loop:
	add eax, ecx                     ; str1 串
        test ecx, ecx
        jz found
	pcmpistri xmm0, [eax], 0x0c     ; unsigned byte, substring search, LSB index
	jnz substr_search_loop   
found:        
        add eax, ecx
	sub eax, esi                    ; eax = 位置
        cmp ecx, 16
        cmovz eax, ebx
        pop ebx
        pop ecx
	ret
        
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
; dump_xmm(start, end)：打印 XMM 寄存器
; input:
;       esi: 起始寄存器，　edi: 终止寄存器
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


;; 数据区

;; FXSAVE/FXRSTOR 内存image（512字节）
FXSAVE_IMAGE    times 512 DB 0

        

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