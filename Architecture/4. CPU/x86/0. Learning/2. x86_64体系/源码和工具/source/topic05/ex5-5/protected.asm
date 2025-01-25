; setup.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


%include "..\inc\support.inc"
%include "..\inc\protected.inc"

; 这是 protected 模块

	bits 32
	
	org PROTECTED_SEG - 2

PROTECTED_BEGIN:
protected_length	dw	PROTECTED_END - PROTECTED_BEGIN		; protected 模块长度

entry:
	
;; 设置 #GP handler
	mov esi, GP_HANDLER_VECTOR
	mov edi, GP_handler
	call set_interrupt_handler	

;; 设置 #DB handler
	mov esi, DB_HANDLER_VECTOR
	mov edi, DB_handler
	call set_interrupt_handler

;; 设置 #AC handler
	mov esi, AC_HANDLER_VECTOR
	mov edi, AC_handler
	call set_interrupt_handler
	
;; 设置 TSS 的 ESP0        
        mov esi, tss32_sel
        call get_tss_base
        mov DWORD [eax + 4], 9FFFh


;; 为了完成实验, 关闭时间中断和键盘中断
	call disable_timer

	
; 进入 ring 3 代码
	push DWORD user_data32_sel | 0x3
	push esp
	push DWORD user_code32_sel | 0x3	
	push DWORD user_entry
	retf
	
	
	jmp $


user_entry:
	mov ax, user_data32_sel | 0x3
	mov ds, ax
	mov es, ax

;;测试 popfd 指令	
	pushfd
	bts DWORD [esp], 9
	popfd

;; 测试 sti 指令
	sti

	mov esi, msg7
	call puts				;打印成功信息
	call println
	
	jmp $




msg1		db 'Now: CPL=0, eflags value is:', 0
msg2		db 'Now: test the #DB exception...', 10,0
msg3		db 'Now: modify the eflags.IOPL to level 2 from 0', 0
msg4		db 'Now: CPL=3, eflags value is:', 10, 0
msg5		db 'Now: try to read port 0x21', 10, 0
msg6		db 'Now: try to write port 0x21', 10, 0
msg7		db 'success!'
value_address	dq 0, 0


	
;----------------------------------------
; DB_handler():  #DB handler
;----------------------------------------
DB_handler:
	jmp do_DB_handler
db_msg1		db '-----< Single-Debug information >-----', 10, 0	
db_msg2		db '>>>>> END <<<<<', 10, 0
eax_message	db 'eax: 0x          ', 0
ebx_message	db 'ebx: 0x          ', 0
ecx_message	db 'ecx: 0x          ', 0
edx_message	db 'edx: 0x          ', 0
esp_message	db 'esp: 0x          ', 0
ebp_message	db 'ebp: 0x          ', 0
esi_message	db 'esi: 0x          ', 0
edi_message	db 'edi: 0x          ', 0
eip_message db 'eip: 0x          ', 0
return_address dq 0, 0

register_message_table	dd eax_message, ebx_message, ecx_message, edx_message  
			dd esp_message, ebp_message, esi_message, edi_message, 0

do_DB_handler:	
;; 得到寄存器值
	pushad
	
	mov esi, db_msg1
	call puts
	
	lea ebx, [esp + 4 * 7]
	xor ecx, ecx

;; 停止条件	
	mov esi, [esp + 4 * 8]
	cmp esi, [return_address]
	je clear_TF
	
do_DB_handler_loop:	
	lea eax, [ecx*4]
	neg eax
	mov esi, [ebx + eax]
	mov edx, [register_message_table + ecx *4]
	lea edi, [edx + 7]
	call get_dword_hex_string
	mov esi, edx
	call puts
	
	inc ecx	
	test ecx, 3
	jnz do_DB_handler_tab
	call println
	jmp do_DB_handler_next
do_DB_handler_tab:	
	mov esi, DWORD '  '
	call putc
do_DB_handler_next:	
	cmp ecx, 8
	jb do_DB_handler_loop
	
	mov esi, [esp + 4 * 8]
	mov edi, eip_message+7
	call get_dword_hex_string
	mov esi, eip_message
	call puts
	call println
	mov eax, [esp + 4 * 8]
	mov [return_address], eax
	jmp do_DB_handler_done
clear_TF:
	btr DWORD [esp + 4 * 8 + 8], 8					; 清 TF 标志
	mov esi, db_msg2
	call puts
do_DB_handler_done:	
	bts DWORD [esp + 4 * 8 + 8], 16					; 设置 eflags.RF 为 1, 以便中断返回时, 继续执行
	popad
	iret

;-------------------------------------------
; GP_handler():  #GP handler
;-------------------------------------------
GP_handler:
	jmp do_GP_handler
gp_msg1		db '---> Now, enter the #GP handler. '
gp_msg2		db 'return address: 0x'
ret_address	dq 0, 0 
gp_msg3		db 'skip STI instruction', 10, 0
do_GP_handler:	
	pop eax							;  忽略错误码
	mov esi, [esp]
	mov edi, ret_address
	call get_dword_hex_string
	mov esi, gp_msg1
	call puts
	call println
	mov eax, [esp]
	cmp BYTE [eax], 0xfb			; 检查是否因为 sti 指令而产生 #GP 异常
	jne do_GP_handler_done
	inc eax					; 如果是的话, 跳过产生 #GP 异常的 sti 指令, 执行下一条指令
	mov [esp], eax
	mov esi, gp_msg3
	call puts
do_GP_handler_done:	
	iret

;-----------------------------------------------
; AC_handler(): #AC handler
;-----------------------------------------------
AC_handler:
	jmp do_AC_handler
ac_msg1		db '---> Now, enter the #AC exception handler <---', 10
ac_msg2		db 'exception location at 0x'
ac_location	dq 0, 0
do_AC_handler:	
	pusha
	mov esi, [esp+4+4*8]			
	mov edi, ac_location
	call get_dword_hex_string
	mov esi, ac_msg1
	call puts
	call println
;; 现在 disable	AC 功能
	btr DWORD [esp+12+4*8], 18		; 清elfags image中的AC标志	
	popa
	add esp, 4				; 忽略 error code	
	iret



%include "..\lib\pic8259A.asm"

;; 函数导入表
%include "..\common\lib32_import_table.imt"

PROTECTED_END: