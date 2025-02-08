;*************************************************
;* dump_debug.asm                                *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************



;-----------------------------------------------------------
; dump_lbr_stack()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 打印 LBR stack 内所有 LBR 记录
;-----------------------------------------------------------
dump_lbr_stack:
	push ecx
	push ebx
	push edx
	push ebp
        
	xor ebx, ebx
	mov ebp, print_dword_decimal

	mov esi, Lbr.Msg0
	call puts

; 打印信息
dump_lbr_stack.loop:

	mov esi, Lbr.FromIp
	call puts
	mov esi, ebx
	mov eax, print_byte_value
	cmp ebx, 10
	cmovae eax, ebp
	call eax
	mov esi, Lbr.Msg1
	call puts

; 打印 from ip
	lea ecx, [ebx + MSR_LASTBRANCH_0_FROM_IP]
	rdmsr
        
%ifdef __X64
        mov edi, edx
        mov esi, eax
        call print_qword_value
%else      
	mov esi, eax
	call print_dword_value
%endif

	mov ecx, MSR_LASTBRANCH_TOS
	rdmsr
	cmp eax, ebx
	jne dump_lbr_from_stack.next
	mov esi, Lbr.Top
	call puts
        
	jmp dump_lbr_stack.ToIp
        
dump_lbr_from_stack.next:
	mov esi, Lbr.Msg2
	call puts

;; 打印 to ip
dump_lbr_stack.ToIp:
	mov esi, Lbr.ToIp
	call puts
	mov esi, ebx
	mov eax, print_byte_value
	cmp ebx, 10
	cmovae eax, ebp
	call eax
	mov esi, Lbr.Msg1
	call puts

	lea ecx, [ebx + MSR_LASTBRANCH_0_TO_IP]
	rdmsr
        
%ifdef __X64
        mov edi, edx
        mov esi, eax
        call print_qword_value
%else      
	mov esi, eax
	call print_dword_value
%endif

	call println
	INCv ebx
	cmp ebx, 16
	jb dump_lbr_stack.loop
	call println

	pop ebp
	pop edx
	pop ebx
	pop ecx
	ret

