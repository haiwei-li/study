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

;; 设置系统服务例程入口
        mov esi, SYSTEM_SERVICE_VECTOR
        mov edi, system_service
        call set_user_interrupt_handler


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

        mov esi, msg1
        mov eax, SYS_PUTS        ; 系统服务例程号
        int 0x40                 ; 调用系统服务

        jmp $

msg1    db '---> now, call system service routine with int 0x40',10, 0







;

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