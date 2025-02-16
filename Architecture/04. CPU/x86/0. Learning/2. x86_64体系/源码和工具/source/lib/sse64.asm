; sse64.asm
; Copyright (c) 2009-2012 邓志
; All rights reserved.


;
; 64-bit 模式下的 SSE 系列指令环境库

;-----------------------------------
; store_xmm(image)
; input:
;       rsi: image
;-----------------------------------
store_xmm:
        movdqu [rsi], xmm0
        movdqu [rsi + 16], xmm1
        movdqu [rsi + 32], xmm2 
        movdqu [rsi + 48], xmm3 
        movdqu [rsi + 64], xmm4 
        movdqu [rsi + 80], xmm5 
        movdqu [rsi + 96], xmm6 
        movdqu [rsi + 112], xmm7 
        movdqu [rsi + 128], xmm8 
        movdqu [rsi + 144], xmm9 
        movdqu [rsi + 160], xmm10 
        movdqu [rsi + 176], xmm11 
        movdqu [rsi + 192], xmm12
        movdqu [rsi + 208], xmm13 
        movdqu [rsi + 224], xmm14 
        movdqu [rsi + 240], xmm15 
        ret
        
;-----------------------------------
; restore_xmm(image)
; input:
;       rsi: image
;-----------------------------------    
restore_xmm:
        movdqu xmm0, [rsi]
        movdqu xmm1, [rsi + 16]
        movdqu xmm2, [rsi + 32] 
        movdqu xmm3, [rsi + 48] 
        movdqu xmm4, [rsi + 64] 
        movdqu xmm5, [rsi + 80] 
        movdqu xmm6, [rsi + 96] 
        movdqu xmm7, [rsi + 112] 
        movdqu xmm8, [rsi + 128] 
        movdqu xmm9, [rsi + 144] 
        movdqu xmm10, [rsi + 160] 
        movdqu xmm11, [rsi + 176] 
        movdqu xmm12, [rsi + 192] 
        movdqu xmm13, [rsi + 208] 
        movdqu xmm14, [rsi + 224] 
        movdqu xmm15, [rsi + 240] 
        ret
        

;--------------------------------
; store_sse(image)
; input:
;       rsi: iamge
;-------------------------------
store_sse:
        call store_xmm
        stmxcsr [rsi + 256]
        ret
                
;-------------------------------
; restore_sse(image)
; input:
;       rsi: image
;-------------------------------         
restore_sse:
        call restore_xmm
        ldmxcsr [rsi + 256]
        ret
        
                        
;-------------------------------------
; 打印 MXCSR 寄存器
;-------------------------------------
dump_mxcsr:
        push rbx
        mov esi, mxcsr_msg
        LIB32_PUTS_CALL
        mov esi, rc
        LIB32_PUTS_CALL
        sub rsp, 8
        stmxcsr [rsp]
        pop rbx
        mov esi, ebx
        shr esi, 13
        and esi, 3
        LIB32_PRINT_DWORD_DECIMAL_CALL
        LIB32_PRINTBLANK_CALL
        bt rbx, 15              ; FZ 位
        setc al
        shl ebx, 19
        shrd ebx, eax, 1
        mov esi, ebx
        LIB32_REVERSE_CALL
        mov esi, eax
        mov edi, mxcsr_flags
        LIB32_DUMP_FLAGS_CALL
        LIB32_PRINTLN_CALL
        pop rbx
        ret

;----------------------------------------
; 打印 16 个 XMM 寄存器
;----------------------------------------
dump_xmm:
        push rcx
        sub rsp, 16*16
        mov rsi, rsp
        call store_xmm
        xor rcx, rcx
dump_xmm_loop:        
        mov esi, xmm_msg
        LIB32_PUTS_CALL
        mov esi, ecx
        LIB32_PRINT_DWORD_DECIMAL_CALL
        mov esi, ':'
        LIB32_PUTC_CALL
        LIB32_PRINTBLANK_CALL
        cmp rcx, 10
        jae dump_xmm_next
        LIB32_PRINTBLANK_CALL
dump_xmm_next:        
        mov esi, [rsp + 12]
        LIB32_PRINT_DWORD_VALUE_CALL
        mov esi, '_'
        LIB32_PUTC_CALL
        mov esi, [rsp + 8]
        LIB32_PRINT_DWORD_VALUE_CALL
        mov esi, '_'
        LIB32_PUTC_CALL
        mov esi, [rsp + 4]
        LIB32_PRINT_DWORD_VALUE_CALL
        mov esi, '_'
        LIB32_PUTC_CALL
        mov esi, [rsp]
        LIB32_PRINT_DWORD_VALUE_CALL
        LIB32_PRINTLN_CALL
        inc rcx
        add rsp, 16
        cmp rcx, 16
        jb dump_xmm_loop
        pop rcx
        ret

;-------------------------------
; 打印 sse 环境
;------------------------------
dump_sse:
        call dump_mxcsr
        call dump_xmm
        ret



;; 数据区

;; FXSAVE64/FXRSTOR64 image(512字节）
FXSAVE64_IMAGE  times 512 DB 0



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