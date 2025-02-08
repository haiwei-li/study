;*************************************************
; sse.asm                                        *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************


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
; store_sse(image):  保存 SSEx 环境 state
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
        pxor xmm0, xmm0                 ; 清 XMM0 寄存器
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
;       -1: 找不到, 否则 eax = 返回 str2 在 str1 的位置
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
        
