; long.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.

;;
;; 这段代码将切换到 long mode 运行

%include "..\inc\support.inc"
%include "..\inc\long.inc"
	
	bits 32

LONG_LENGTH:	dw	LONG_END - $
	
	org LONG_SEG - 2
	
	NMI_DISABLE
	cli

; 关闭 PAE paging	
	mov eax,  cr0
	btr eax,  31
	mov cr0,  eax
	
	mov esp,  9FF0h

	call init_page

; 加载 GDT 表
	lgdt [__gdt_pointer]
	
; 设置 CR3 寄存器	
	mov eax,  PML4T_BASE
	mov cr3,  eax
	
; 设置 CR4 寄存器
	mov eax,  cr4
	bts eax,  5				; CR4.PAE = 1
	mov cr4,  eax

; 设置 EFER 寄存器
	mov ecx,  IA32_EFER
	rdmsr 
	bts eax,  8				; EFER.LME = 1
	wrmsr

; 激活 long mode
	mov eax,  cr0
	bts eax,  31
	mov cr0,  eax			; EFER.LMA = 1
	
; 转到 64 位代码
	jmp KERNEL_CS : entry64


; 下面是 64 位代码
	
	bits 64
		
entry64:
	mov ax,  KERNEL_SS
	mov ds,  ax
	mov es,  ax
	mov ss,  ax
	mov rsp,  PROCESSOR0_KERNEL_RSP

;; 下面将 GDT 表定位在 SYSTEM_DATA64_BASE 的线性地址空间上
	mov rdi,  SYSTEM_DATA64_BASE
	mov rsi,  __system_data64_entry
	mov rcx,  __system_data64_end - __system_data64_entry
	rep movsb

;; 下面重新加载 64-bit 环境下的 GDT 和 IDT 表
	mov rbx,  SYSTEM_DATA64_BASE + (__gdt_pointer - __system_data64_entry)
	mov rax,  SYSTEM_DATA64_BASE + (__global_descriptor_table - __system_data64_entry)
	mov [rbx + 2],  rax
	lgdt [rbx]
	
	mov rbx,  SYSTEM_DATA64_BASE + (__idt_pointer - __system_data64_entry)
	mov rax,  SYSTEM_DATA64_BASE + (__interrupt_descriptor_table - __system_data64_entry)
	mov [rbx + 2],  rax
	lidt [rbx]

;; 设置 TSS descriptor	
	mov rsi,  tss64_sel
	mov edi,  0x67
	mov r8, 	SYSTEM_DATA64_BASE + (__task_status_segment - __system_data64_entry)
	mov r9,  TSS64
	call set_system_descriptor

; 设置 LDT 描述符
	mov rsi,  ldt_sel
	mov edi,  __local_descriptor_table_end - __local_descriptor_table - 1
	mov r8,  SYSTEM_DATA64_BASE + (__local_descriptor_table - __system_data64_entry)
	mov r9,  LDT64
	call set_system_descriptor

;; 加载 TSS 与 LDT 表
	mov ax,  tss64_sel
	ltr ax
	mov ax,  ldt_sel
	lldt ax
		
;; 设置 call gate descriptor
	mov rsi,  call_gate_sel
	mov rdi,  __lib32_service					; call-gate 设在 __lib32_srvice() 函数上
	mov r8,  3									; call-gate 的 DPL = 3
	mov r9,  KERNEL_CS							; code selector = KERNEL_CS
	call set_call_gate

	mov rsi,  conforming_callgate_sel
	mov rdi,  __lib32_service					; call-gate 设在 __lib32_srvice() 函数上
	mov r8,  3									; call-gate 的 DPL = 0
	mov r9,  conforming_code_sel					; code selector = conforming_code_sel
	call set_call_gate

;; 设置 conforming code segment descriptor	
	MAKE_SEGMENT_ATTRIBUTE 13,  0,  1,  0			; type=conforming code segment,  DPL=0,  G=1,  D/B=0
	mov r9,  rax									; attribute
	mov rsi,  conforming_code_sel				; selector
	mov rdi,  0xFFFFF							; limit
	mov r8,  0									; base       
	call set_segment_descriptor	
        
        
; 设置 #GP handler
	mov rsi,  GP_HANDLER_VECTOR
	mov rdi,  GP_handler
	call set_interrupt_descriptor
			
; 设置 #DB handler
	mov rsi,  DB_HANDLER_VECTOR
	mov rdi,  DB_handler
	call set_interrupt_descriptor					

;; 设置 sysenter/sysexit 使用环境
	call set_sysenter
        
;; 设置 syscall/sysret 使用环境
	call set_syscall
        
;; 设置 int 40h 使用环境
        mov rsi,  40h
        mov rdi,  user_system_service_call
        call set_user_interrupt_handler
	
; 设 FS.base = 0xfffffff800000000	
	mov ecx,  IA32_FS_BASE
	mov eax,  0x0
	mov edx,  0xfffffff8
	wrmsr	
	
; 开启开断许可
	NMI_ENABLE
	sti
        
;======== long-mode 环境设置代码结束=============


; 1) 开启APIC
	call enable_xapic	

;
;* 实验 14-13: 统计 64-bit 模式下 PMI 中断 handler 调用的次数
;*
	mov rsi,  APIC_PERFMON_VECTOR
	mov rdi,  apic_perfmon_handler
	call set_interrupt_handler


; 设置 performance monitor 寄存器
	mov DWORD [APIC_BASE + LVT_PERFMON],  FIXED | APIC_PERFMON_VECTOR

	
	SET_INT_DS_AREA64			; 设置 64-bit 模式下的 DS 存储区域
	ENABLE_BTS_BTINT			; 开启 BTS,  使用中断型 BTS buffer

;; 下面打印测试信息,  统计这个打印产生了多少分支
	mov esi,  test_msg
	LIB32_PUTS_CALL

; 关闭 BTS
	DISABLE_BTS


; 打印结果
	mov esi,  pmi_msg
	LIB32_PUTS_CALL
	mov esi,  [pmi_counter]
	LIB32_PRINT_DWORD_DECIMAL_CALL
	LIB32_PRINTLN_CALL
	LIB32_PRINTLN_CALL


;; 打印 BTS buffer 信息
	DUMP_BTS64				

	
	jmp $

test_msg	db 'this is a test message...',  10,  0
pmi_msg		db 'call PMI handler count is: ',  0
pmi_counter	dq 0

	
	;call QWORD far [conforming_callgate_pointer]	; 测试 call-gate for conforming 段
	
	;call QWORD far [conforming_pointer]			; 测试conforimg 代码
	
;; 从 64 位切换到 compatibility mode(权限不改变,  0 级)　	
	;jmp QWORD far [compatibility_pointer]

;; 切换到 compatibility mode(进入 3 级)
;	push user_data32_sel | 3
;	push 0x10ff0
;	push user_code32_sel | 3
;	push compatibility_user_entry
;	db 0x48
;	retf	

;; 使用 iret 切换到 compatibility mode(进入 3 级)
;	mov rax,  KERNEL_RSP
;	push user_data32_sel | 3
;	push rax;USER_RSP
;	push 0x3000
;	push user_code32_sel | 3
;	push compatibility_user_entry
;	iretq

;; 使用 iret 切换到 conforming 段
;	mov rax,  KERNEL_RSP
;	push KERNEL_SS;user_data32_sel
;	push rax;USER_RSP
;	pushfq
;	push conforming_code_sel
;	push compatibility_user_entry
;	iretq

;	mov rsi,  USER_CS
;	call read_segment_descriptor
;	btr rax,  47				; p=0
;	btr rax,  43				; code/data=0
;	btr rax,  41				; R=0
;	btr rax,  42				; c=1
;	btr rax,  45
;	mov rsi,  0x78
;	mov rdi,  rax
;	call write_segment_descriptor
	
	


	
;; 切换到用户代码　
;	push USER_SS | 3
;	push USER_RSP
;	push USER_CS | 3
;	push user_entry
;	db 0x48
;	retf

;; 使用 iret 切换到用户代码　		
;	push USER_SS | 2;3
;	push USER_RSP
;	pushfq
;	push USER_CS | 2;3
;	push user_entry
;	iretq							; 返回到 3 级权限

;	mov rdi,  0x0000
;	mov rsi,  user_entry
;	mov rcx,  conforming_callgate_pointer-user_entry
;	rep movsb
	
;	mov DWORD [rsp],  user_entry
;	mov DWORD [rsp + 4],  KERNEL_CS;USER_CS | 2
;	mov DWORD [rsp + 8],  46
;	mov DWORD [rsp + 12],  USER_RSP
;	mov DWORD [rsp + 16],  KERNEL_SS;USER_SS | 2
;	iret

;	mov WORD [rsp],  0x0000;user_entry
;	mov WORD [rsp + 2],  KERNEL_CS;USER_CS | 2
;	mov WORD [rsp + 4],  46
;	mov WORD [rsp + 6],  0x8f0;USER_RSP
;	mov WORD [rsp + 8],  0xa0;KERNEL_SS;USER_SS | 2
;	db 0x66
;	iret
		
compatibility_pointer:
		dq compatibility_kernel_entry              ; 64 bit offset on Intel64
		dw code32_sel

		

;;; ##### 64-bit 用户代码 #########

	bits 64
	
user_entry:
	mov rbx,  lib32_service
;	mov rsi,  rsp
;	mov rdi,  rsi
;	shr rdi,  32
;	mov eax,  LIB32_PRINT_QWORD_VALUE
;	call rbx
	
	mov rsi,  rsp
	shl rsi,  16
	mov si,  ss
	mov rdi,  rsi
	shr rdi,  32
	mov eax,  LIB32_PRINT_QWORD_VALUE
	call rbx
	
	;call lib32_service
	jmp $
	
; 使用 Call-gate 调用
	mov esi,  msg1
	mov eax,  LIB32_PUTS
	call lib32_service

; 使用 sysenter 调用
	mov esi,  msg2
	mov eax,  LIB32_PUTS
	call sys_service_enter

; 使用 syscall 调用	
	mov esi,  msg3
	mov eax,  LIB32_PUTS
	call sys_service_call		
	
breakpoint:
	mov rax,  rbx			; 无用的指令,  在这此产生#DB异常
	
		
;	mov rsi,  msg1
;	mov eax,  LIB32_PUTS	

;	call QWORD far [conforming_callgate_pointer]	; 测试 call-gate for conforming 段		
;	call QWORD far [conforming_pointer]		; 测试 conforming 代码

	jmp $

conforming_callgate_pointer:
	dq 0
	dw conforming_callgate_sel

;	jmp $

msg		db '>>> now: test 64-bit LBR stack <<<',  10,  0
msg1	db '---> Now: call sys_service() with CALL-GATE',  10,  0
msg2	db '---> Now: call sys_service() with SYSENTER',  10,  0
msg3	db '---> Now: call sys_service() with SYSCALL',  10,  0


;;; ###### 下面是 32-bit compatibility 模块 ########		
	
	bits 32

;; 0 级的 compatibility 代码入口	
compatibility_kernel_entry:
	mov ax,  data32_sel
	mov ds,  ax
	mov es,  ax
	mov ss,  ax	
	mov esp,  COMPATIBILITY_USER_ESP
	jmp compatibility_entry

;; 3 级的 compatibility 代码入口	
compatibility_user_entry:
	mov ax,  user_data32_sel | 3
	mov ds,  ax
	mov es,  ax
	mov ss,  ax	
	mov esp,  COMPATIBILITY_USER_ESP
	
compatibility_entry:
;; 通过 stub 函数从compaitibility模式调用call gate 进入64位模式
	mov esi,  cmsg1
	mov eax,  LIB32_PUTS
	call compatibility_lib32_service			;; stub 函数形式


	mov esi,  cmsg1
	mov eax,  LIB32_PUTS
	call compatibility_sys_service_enter		; compatibility 模式下的 sys_service() stub 函数

;; 现在切换到 3级 64-bit 模式代码
	push USER_SS | 3
	push USER_ESP
	push USER_CS | 3				; 在 4G范围内
	push user_entry
	retf

;; 使用 iret指令从 compatibility 模式切换到 3 级 64-bit 模式
;	push USER_SS | 3
;	push USER_RSP
;	pushf
;	push USER_CS | 3				; 在 4G 范围内
;	push user_entry
;	iret							; 使用 32 位操作数
	
	jmp $
	
cmsg1	db '---> Now: call sys_service() from compatibility mode with sysenter instruction',  10,  0
		
compatibility_entry_end:






;; ###### 下面是 64 位例程: #######

	bits 64


;-------------------------------
; perfmon handler
;------------------------------
apic_perfmon_handler:
	jmp do_apic_perfmon_handler
ph_msg1	db '>>> now: enter PMI handler,  occur at 0x',  0
ph_msg2 db 'exit the PMI handler <<<',  10,  0	
ph_msg3 db '****** DS interrupt occur with BTS buffer full! *******',  10,  0
ph_msg4 db '****** PMI interrupt occur *******',  10,  0
ph_msg5 db '****** DS interrupt occur with PEBS buffer full! *******',  10,  0
ph_msg6 db '****** PEBS interrupt occur *******',  10,  0

do_apic_perfmon_handler:
	;; 保存处理器上下文
	STORE_CONTEXT64

;*
;* 下面在 handler 里关闭功能
;*

	;; 关闭 TR
	mov ecx,  IA32_DEBUGCTL
	rdmsr
	mov [debugctl_value],  eax	; 保存原 IA32_DEBUGCTL 寄存器值,  以便恢复
	mov [debugctl_value + 4],  edx
	btr eax,  6			; TR = 0
	wrmsr

	;; 关闭 pebs enable
	mov ecx,  IA32_PEBS_ENABLE
	rdmsr
	mov [pebs_enable_value],  eax
	mov [pebs_enable_value + 4],  edx
	mov eax,  0
	mov edx,  0
	wrmsr


	; 关闭 performance counter
	mov ecx,  IA32_PERF_GLOBAL_CTRL
	rdmsr
	mov [perf_global_ctrl_value],  eax
	mov [perf_global_ctrl_value + 4],  edx
	mov eax,  0
	mov edx,  0
	wrmsr


;*
;* 接下来判断 PMI 中断引发原因
;*
check_pebs_buffer_overflow:
	; 是否 PEBS buffer 满
	call test_pebs_buffer_overflow
	test eax,  eax
	jz check_counter_overflow

	; 清 OvfBuffer 位
        RESET_PEBS_BUFFER_OVERFLOW
        call reset_pebs_index

check_counter_overflow:
	; 是否 counter 产生溢出
	call test_counter_overflow	
	test eax,  eax
	jz check_bts_buffer_overflow

        ;; 清 overflow 标志
        RESET_COUNTER_OVERFLOW

check_bts_buffer_overflow:
        call test_bts_buffer_overflow
        test eax,  eax
        jz check_pebs_interrupt
	;
	; 增调用 PMI 中断 handler 的 count 值
	;
	mov rax,  pmi_counter
	inc QWORD [rax]

	; 重设 index 值
        call reset_bts_index

check_pebs_interrupt:
        call test_pebs_interrupt
        test eax,  eax
        jz apic_perfmon_handler_done

	call update_pebs_index_track

apic_perfmon_handler_done:

;*
;* 下面恢复功能原设置!
;* 
	; 恢复原 IA32_PERF_GLOBAL_CTRL 寄存器值
	mov ecx,  IA32_PERF_GLOBAL_CTRL
	mov eax,  [perf_global_ctrl_value]
	mov edx,  [perf_global_ctrl_value + 4]
	wrmsr

	; 恢复原 IA32_DEBUGCTL 设置　
	mov ecx,  IA32_DEBUGCTL
	mov eax,  [debugctl_value]
	mov edx,  [debugctl_value + 4]
	wrmsr

	;; 恢复 IA32_PEBS_ENABLE 寄存器
	mov ecx,  IA32_PEBS_ENABLE
	mov eax,  [pebs_enable_value]
	mov edx,  [pebs_enable_value + 4]
	wrmsr

	RESTORE_CONTEXT64		; 恢复 context

	btr DWORD [APIC_BASE + LVT_PERFMON],  16		; 清 LVT_PERFMON 寄存器 mask 位
	mov DWORD [APIC_BASE + EOI],  0			; 写 EOI 命令
	iret64




%define EX14_13


	
	bits 64

;*** include 64-bit 模式的 interrupt handler ****
%include "..\common\handler64.asm"


;*** include 64-bit 模式下的系统数据 *****
%include "..\lib\system_data64.asm"


;*** include 其它 64 位库 *****
%include "..\lib\lib64.asm"
%include "..\lib\page64.asm"
%include "..\lib\debug64.asm"
%include "..\lib\apic64.asm"
%include "..\lib\perfmon64.asm"




LONG_END:
		