; protected.asm
; Copyright (c) 2009-2012 mik
; All rights reserved.


%define NON_PAGING
%include "..\inc\support.inc"
%include "..\inc\protected.inc"

; 这是 protected 模块

        bits 32

        org PROTECTED_SEG - 2

PROTECTED_BEGIN:
protected_length        dw        PROTECTED_END - PROTECTED_BEGIN                                ; protected 模块长度

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

;; 设置 #UD handler
        mov esi, UD_HANDLER_VECTOR
        mov edi, UD_handler
        call set_interrupt_handler

;; 设置 #NM handler
        mov esi, NM_HANDLER_VECTOR
        mov edi, NM_handler
        call set_interrupt_handler

;; 设置 #TS handler
        mov esi, TS_HANDLER_VECTOR
        mov edi, TS_handler
        call set_interrupt_handler

;; 设置 TSS 的 ESP0
        mov esi, tss32_sel
        call get_tss_base
        mov DWORD [eax + 4], KERNEL_ESP

;; 关闭所有 8259中断
        call disable_8259

;======================================================



;; 设置新 TSS 区域
        mov esi, tss_sel
        call get_tss_base
        mov DWORD [eax + 32], tss_task_handler                ; 设置 EIP 值为 tss_task_handler
        mov DWORD [eax + 36], 0                               ; eflags = 0
        mov DWORD [eax + 56], KERNEL_ESP                      ; esp
        mov WORD [eax + 76], KERNEL_CS                        ; cs
        mov WORD [eax + 80], KERNEL_SS                        ; ss
        mov WORD [eax + 84], KERNEL_SS                        ; ds
        mov WORD [eax + 72], KERNEL_SS                        ; es


;; 设置 Task-gate 描述符
        mov esi, taskgate_sel                                 ; Task-gate selector
        mov eax, tss_sel << 16
        mov edx, 0E500h                                       ; DPL=3, type=Task-gate
        call write_gdt_descriptor



; 转到 long 模块
        ;jmp LONG_SEG


; 进入 ring 3 代码
        push DWORD user_data32_sel | 0x3
        push esp
        push DWORD user_code32_sel | 0x3
        push DWORD user_entry
        retf


;; 用户代码

user_entry:
        mov ax, user_data32_sel
        mov ds, ax
        mov es, ax

;; 使用 Task-gate进行任务切换
        call taskgate_sel : 0

        mov esi, msg1
        call puts                        ; 在用户代码里打印信息

        jmp $
msg1                db '---> now, switch back to old task', 10, '---> now, enter user code', 10, 0





;-----------------------------------------
; tss_task_handler()
;-----------------------------------------
tss_task_handler:
        jmp do_tss_task
tmsg1        db '---> now, switch to new Task with Task-gate', 10, 0
do_tss_task:
        mov esi, tmsg1
        call puts

        clts                                                ; 清 CR0.TS 标志位


; 使用 iret 指令切换回原 task
        iret







;******** include 中断 handler 代码 ********
%include "..\common\handler32.asm"


;********* include 模块 ********************
%include "..\lib\creg.asm"
%include "..\lib\cpuid.asm"
%include "..\lib\msr.asm"
%include "..\lib\pci.asm"
%include "..\lib\debug.asm"
%include "..\lib\page32.asm"
%include "..\lib\apic.asm"
%include "..\lib\pic8259A.asm"


;;************* 函数导入表  *****************

; 这个 lib32 库导入表放在 common\ 目录下,
; 供所有实验的 protected.asm 模块使用

%include "..\common\lib32_import_table.imt"



PROTECTED_END: