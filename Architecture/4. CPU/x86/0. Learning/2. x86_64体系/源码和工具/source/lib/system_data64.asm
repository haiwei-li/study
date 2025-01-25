; system_data64.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


;*
;* 定义 long-mode 模式下的系统数据
;*

        bits 64


;----------------------------------------------
; BSP 处理器初始化 long-mode 系统表
;----------------------------------------------
bsp_init_system_struct:
init_system_struct:
;*
;* 测试是否 BSP 处理器
;*
        mov ecx, IA32_APIC_BASE
        rdmsr
        bt eax, 8
        jnc bsp_init_system_struct_done


; 设置 LDT 描述符                       
        mov rbx, ldt_sel + __global_descriptor_table                                            ; LDT descriptor
        mov rsi, SYSTEM_DATA64_BASE + (__local_descriptor_table - __system_data64_entry)        ; base
        mov rdi, __local_descriptor_table_end - __local_descriptor_table - 1                    ; limit
        mov [rbx], di                   ; limit[15:0]
        mov [rbx + 4], rsi              ; base[63:24]
        mov [rbx + 2], esi              ; base[23:0]
        mov BYTE [rbx + 5], 82h         ; type
        mov BYTE [rbx + 6], 0           ; limit[19:16]

;; 下面将系统数据结构定位在 SYSTEM_DATA64_BASE 的线性地址空间上
        mov rdi, SYSTEM_DATA64_BASE
        mov rsi, __system_data64_entry
        mov rcx, __system_data64_end - __system_data64_entry
        rep movsb

;; 下面重新设置 64-bit 环境下的 GDT 和 IDT 表指针
        mov rbx, SYSTEM_DATA64_BASE + (__gdt_pointer - __system_data64_entry)
        mov rax, SYSTEM_DATA64_BASE + (__global_descriptor_table - __system_data64_entry)
        mov [rbx + 2], rax

        mov rbx, SYSTEM_DATA64_BASE + (__idt_pointer - __system_data64_entry)
        mov rax, SYSTEM_DATA64_BASE + (__interrupt_descriptor_table - __system_data64_entry)
        mov [rbx + 2], rax

bsp_init_system_struct_done:
        ret



; 下面定义所有 system 数据的入口

__system_data64_entry:

;-----------------------------------------
; 下面定义 long-mode 的 GDT 表
;-----------------------------------------
__global_descriptor_table:


null_desc			dq 0                            ; NULL descriptor

code16_desc			dq 0x00009a000000ffff           ; for real mode code segment
data16_desc			dq 0x000092000000ffff           ; for real mode data segment
code32_desc			dq 0x00cf9a000000ffff           ; for protected mode code segment
								 ; or for compatibility mode code segmnt
data32_desc			dq 0x00cf92000000ffff           ; for protected mode data segment
								 ; or for compatibility mode data segment

kernel_code64_desc		dq 0x0020980000000000		; 64-bit code segment
kernel_data64_desc		dq 0x0000920000000001		; 64-bit data segment

;;; 也为 sysexit 指令使用而组织
user_code32_desc		dq 0x00cffa000000ffff           ; for protected mode code segment
								 ; or for compatibility mode code segmnt
user_data32_desc		dq 0x00cff2000000ffff           ; for protected mode data segment
								; or for compatibility mode data segment	
;; 也为 sysexit 指令使用而组织                                                 
user_code64_desc		dq 0x0020f80000000000		; 64-bit non-conforming
user_data64_desc		dq 0x0000f20000000000		; 64-bit data segment

tss64_desc			dw 0x67                         ; 64bit TSS
				dd 0
				dw 0
				dq 0

call_gate_desc			dq 0, 0

conforming_code64_desc		dq 0

;; 下面为 syscall/sysret 环境准备					
				dq 0				; reserved
sysret_stack64_desc		dq 0x0000f20000000000
sysret_code64_desc		dq 0x0020f80000000000

data64_desc			dq 0x0000f00000000000		; 64-bit data segment

;test_kernel_data64_desc		dq 0x0000920000000001		; 64-bit data segment
                                                 				
	times	40 dq 0						; 保留 40 个 descriptor 位置


__global_descriptor_table_end:




;--------------------------------------
; 下面定义 long-mode 的 LDT 表
;--------------------------------------

__local_descriptor_table:

				dq 0
ldt_kernel_code64_desc		dq 0x0020980000000000		; 64-bit code segment
ldt_kernel_data64_desc		dq 0x0000920000000000		; 64-bit data segment
ldt_user_code32_desc		dq 0x00cffa000000ffff           ; for protected mode code segment
				                                 ; or for compatibility mode code segmnt
ldt_user_data32_desc		dq 0x00cff2000000ffff           ; for protected mode data segment	
ldt_user_code64_desc		dq 0x0020f80000000000		; 64-bit non-conforming
ldt_user_data64_desc		dq 0x0000f20000000000		; 64-bit data segment

			times 5 dq 0

__local_descriptor_table_end:



;-------------------------------------------
; 下面定义 long-mode 的 IDT 表
;-------------------------------------------
__interrupt_descriptor_table:

times 0x50 dq 0, 0			; 保留 0x50 个 vector

__interrupt_descriptor_table_end:



;-------------------------------------------
; TSS64 for long mode
;-------------------------------------------
__processor0_task_status_segment:
__task_status_segment:
	dd 0							; reserved
	dq PROCESSOR0_IDT_RSP					; rsp0
	dq 0							; rsp1
	dq 0							; rsp2
	dq 0							; reserved
	dq PROCESSOR0_IST1_RSP       				; IST1
times 0x3c db 0
__task_status_segment_end:
__processor0_task_status_segment_end:


;*
;* 为 7 个处理器定义 7 个 TSS 区域
;*
__processor_task_status_segment:
        times 104 * 8 db 0                                      ; 保留 8 个 TSS 空间
        

;--------------------------------------------
; TEST_TSS SEGMENT
;-------------------------------------------
__test_tss:
	dd 0							; reserved
	dq PROCESSOR0_IDT_RSP					; rsp0
	dq 0							; rsp1
	dq 0							; rsp2
	dq 0							; reserved
	dq PROCESSOR0_IST1_RSP       				; IST1
times 0x3c db 0
__test_tss_end:


;----------------------------------------
; 下面定义 descriptor table pointer 变量
;----------------------------------------

__gdt_pointer:
gdt_limit	dw (__global_descriptor_table_end - __global_descriptor_table) - 1
gdt_base:	dq __global_descriptor_table


__idt_pointer:
idt_limit	dw (__interrupt_descriptor_table_end - __interrupt_descriptor_table)- 1 
idt_base	dq __interrupt_descriptor_table



;; system 数据区域的结束
__system_data64_end:


