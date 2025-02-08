; lib16.asm
; Copyright (c) 2009-2012 mik
; All rights reserved.


%include "..\inc\lib.inc"
%include "..\inc\support.inc"

; 这是 16位实模式下使用的库.
; 使用了 bios 的中断, So 这个库是依赖于 bios 的.
; 这个库会被加载到内存 0x8c00 的位置上

	bits 16


	org LIB16_SEG - 2					; 加载到 LIB16_SEG 段, 去除掉模块 size

begin	dw (end - begin)				; 模块 size


; 以下是函数的跳转表
; 当其它模块调用 lib16 里的函数时, 先获取这个的跳转表地址

LIB16_FUNCTION_TABLE:

putc:					jmp 		WORD __putc
puts:					jmp 		WORD __puts
hex_to_char:			jmp			WORD __hex_to_char
get_hex_string:			jmp			WORD __get_hex_string
test_CPUID:				jmp			WORD __test_CPUID
get_dword_hex_string:	jmp			WORD __get_dword_hex_string
println:				jmp			WORD __println
get_DisplayFamily_DisplayModel:	jmp WORD __get_DisplayFamily_DisplayModel
clear_screen:			jmp			WORD __clear_screen




;------------------------------------------------------
; clear_screen()
; description:
;		clear the screen & set cursor position at (0,0)
;------------------------------------------------------
__clear_screen:
	pusha
	mov ax, 0x0600
	xor cx, cx
	xor bh, 0x0f						; white
	mov dh,	24
	mov dl, 79
	int 0x10

set_cursor_position:
	mov ah, 02
	mov bh, 0
	mov dx, 0
	int 0x10
	popa
	ret


;--------------------------------
; putc(): 打印一个字符
; input:
;		si: char
;--------------------------------
__putc:
	push bx
	xor bh, bh
	mov ax, si
	mov ah, 0x0e
	int 0x10
	pop bx
	ret

;--------------------------------
; println(): 打印换行
;--------------------------------
__println:
	mov si, 13
	call __putc
	mov si, 10
	call __putc
	ret

;--------------------------------
; puts(): 打印字符串信息
; input:
;		si: message
;--------------------------------
__puts:
	pusha
	mov ah, 0x0e
	xor bh, bh

do_puts_loop:
	lodsb
	test al,al
	jz do_puts_done
	int 0x10
	jmp do_puts_loop

do_puts_done:
	popa
	ret


;-----------------------------------------
; hex_to_char(): 将 Hex 数字转换为 Char 字符
; input:
;		si: Hex number
; ouput:
;		ax: Char
;----------------------------------------
__hex_to_char:
	jmp do_hex_to_char
@char	db '0123456789ABCDEF', 0

do_hex_to_char:
	push si
	and si, 0x0f
	mov ax, [@char+si]
	pop si
	ret

;---------------------------------------------------
; get_hex_string(): 将数(WORD)转换为字符串
; input:
;		si: 需转换的数(word size)
;		di: 目标串 buffer(最短需要 5 bytes, 包括 0)
;---------------------------------------------------
__get_hex_string:
	push cx
	push si
	mov cx, 4					; 4 个 half-byte
do_get_hex_string_loop:
	rol si, 4					; 高4位 --> 低 4位
	call __hex_to_char
	mov byte [di], al
	inc di
	dec cx
	jnz do_get_hex_string_loop
	mov byte [di], 0
	pop si
	pop cx
	ret

;---------------------------------------------------
; get_dword_hex_string(): 将数 (DWORD) 转换为字符串
; input:
;		esi: 需转换的数(dword size)
;		di: 目标串 buffer(最短需要 9 bytes, 包括 0)
;---------------------------------------------------
__get_dword_hex_string:
	push cx
	push esi
	mov cx, 8					; 8 个 half-byte
do_get_dword_hex_string_loop:
	rol esi, 4					; 高4位 --> 低 4位
	call __hex_to_char
	mov byte [di], al
	inc di
	dec cx
	jnz do_get_dword_hex_string_loop
	mov byte [di], 0
	pop esi
	pop cx
	ret

;---------------------------------------------------
; test_CPUID(): 测试是否支持 CPUID 指令
; output:
;		1 - support,  0 - no support
;---------------------------------------------------
__test_CPUID:
	pushfd								; save eflags DWORD size
	mov eax, dword [esp]				; get old eflags
	xor dword [esp], 0x200000			; xor the eflags.ID bit
	popfd								; set eflags register
	pushfd								; save eflags again
	pop ebx								; get new eflags
	cmp eax, ebx						; test eflags.ID has been modify
	setnz al							; OK! support CPUID instruction
	movzx eax, al
	ret

;---------------------------------------------------------------------
; get_DisplayFamily_DisplayModel():	获得 DisplayFamily 与 DisplayModel
; output:
;		ah: DisplayFamily,  al: DisplayModel
;--------------------------------------------------------------------
__get_DisplayFamily_DisplayModel:
	push ebx
	push edx
	push ecx
	mov eax, 01H
	cpuid
	mov ebx, eax
	mov edx, eax
	mov ecx, eax
	shr eax, 4
	and eax, 0x0f			; 得到 model 值
	shr edx, 8
	and edx, 0x0f			; 得到 family 值

	cmp edx, 0FH
	jnz test_family_06
	shr ebx, 20
	add edx, ebx			; 得到 DisplayFamily
	jmp get_displaymodel
test_family_06:
	cmp edx, 06H
	jnz get_DisplayFamily_DisplayModel_done
get_displaymodel:
	shr ecx, 12
	and ecx, 0xf0
	add eax, ecx			; 得到 DisplayModel
get_DisplayFamily_DisplayModel_done:
	mov ah, dl
	pop ecx
	pop edx
	pop ebx
	ret

end: