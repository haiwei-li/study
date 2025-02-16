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
protected_length        dw        PROTECTED_END - PROTECTED_BEGIN     ; protected 模块长度

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

        mov esi, call_gate_sel
        mov edi, call_gate_handler
        mov eax, 0
        call set_call_gate



;; 设置新 TSS 区域
        mov esi, tss_sel
        call get_tss_base
        mov DWORD [eax + 32], tss_task_handler                ; 设置 EIP 值为 tss_task_handler
        mov DWORD [eax + 36], 0                               ; eflags = 0
        mov DWORD [eax + 56], KERNEL_ESP                       ; esp
        mov WORD [eax + 76], KERNEL_CS                        ; cs
        mov WORD [eax + 80], KERNEL_SS                        ; ss
        mov WORD [eax + 84], KERNEL_SS                        ; ds
        mov WORD [eax + 72], KERNEL_SS                        ; es


;; 设置嵌套环境1: 在当前的 TSS 段里写入 Link 域 (目标任务的TSS selector) 
        call get_tr_base
        mov WORD [eax], tss_sel                               ; 设当前的 TSS.link

;; 设置嵌套环境2: 置目标 TSS descriptor 为 Busy 状态
        mov esi, tss_sel
        call read_gdt_descriptor
        bts edx, 9                                            ; TSS.busy = 1
        mov esi, tss_sel
        call write_gdt_descriptor

;; 设置嵌套环境3: 置 Eflags.NT 标志位
        pushf
        bts DWORD [esp], 14                                   ; eflags.NT = 1
        popf


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

;; 在 3 级里发起任务切换到 0 级
        iret

        mov esi, msg1
        call puts                        ; 在用户代码里打印信息

        jmp $
msg1                db '---> now, switch back to old task with IRET instruction', 10, '---> now, enter user code', 10, 0

callgate_pointer:       dd        call_gate_handler
                        dw        call_gate_sel








;-----------------------------------------
; tss_task_handler()
;-----------------------------------------
tss_task_handler:
        jmp do_tss_task
tmsg1        db '---> now, switch to new Task with IRET instruction!', 10, 0
do_tss_task:
        mov esi, tmsg1
        call puts

        clts                                            ; 清 CR0.TS 标志位

;;; 再伪造一个嵌套环境: 从0级返回到3级, tss32_sel 是原 TSS selector

        call get_tr_base
        mov WORD [eax], tss32_sel                        ; 写入原 TSS selector
;;
        mov esi, tss32_sel
        call read_gdt_descriptor
        bts edx, 9                                      ; TSS.busy = 1
        mov esi, tss32_sel
        call write_gdt_descriptor

;; 设置嵌套环境3: 置 Eflags.NT 标志位
        pushf
        bts DWORD [esp], 14                                                        ; eflags.NT = 1
        popf

; 使用 iret 指令切换回原 task
        iret


;------------------------------------------
; sys_service():  system service entery
;-----------------------------------------
sys_service:
        jmp do_syservice
smsg1        db '---> Now, enter the system service', 10, 0
do_syservice:
        mov esi, smsg1
        call puts
        sysexit

;-----------------------------------------
; call_gate_handler()
;----------------------------------------
call_gate_handler:
        jmp do_callgate
cgmsg1        db '---> Now, enter the call gate', 10, 0
do_callgate:
        mov esi, cgmsg1
        call puts
        ret




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