; protected.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


%include "..\inc\support.inc"
%include "..\inc\protected.inc"

; 这是 protected 模块

        bits 32
        
        org PROTECTED_SEG - 2

PROTECTED_BEGIN:
protected_length        dw        PROTECTED_END - PROTECTED_BEGIN       ; protected 模块长度

entry:
        
;; 为了完成实验,关闭时间中断和键盘中断
        call disable_timer
        
;; 设置 #PF handler
        mov esi, PF_HANDLER_VECTOR
        mov edi, PF_handler
        call set_interrupt_handler        

;; 设置 #GP handler
        mov esi, GP_HANDLER_VECTOR
        mov edi, GP_handler
        call set_interrupt_handler

; 设置 #DB handler
        mov esi, DB_HANDLER_VECTOR
        mov edi, DB_handler
        call set_interrupt_handler


;; 设置 sysenter/sysexit 使用环境
        call set_sysenter

;; 设置 system_service handler
        mov esi, SYSTEM_SERVICE_VECTOR
        mov edi, system_service
        call set_user_interrupt_handler 

; 允许执行 SSE 指令        
        mov eax, cr4
        bts eax, 9                                ; CR4.OSFXSR = 1
        mov cr4, eax
        
        
;设置 CR4.PAE
        call pae_enable
        
; 开启 XD 功能
        call execution_disable_enable
                
; 初始化 paging 环境
        call init_pae_paging
        
;设置 PDPT 表地址        
        mov eax, PDPT_BASE
        mov cr3, eax
                                
; 打开　paging
        mov eax, cr0
        bts eax, 31
        mov cr0, eax                                 

        mov esi, PIC8259A_TIMER_VECTOR
        mov edi, timer_handler
        call set_interrupt_handler        

        mov esi, KEYBOARD_VECTOR
        mov edi, keyboard_handler
        call set_interrupt_handler                
        
        call init_8259A
        call init_8253        
        call disable_8259
        
        sti
        
;========= 初始化设置完毕 =================


; 1) 开启 APIC
        call enable_xapic        
        
; 2) 设置 APIC performance monitor counter handler
        mov esi, APIC_PERFMON_VECTOR
        mov edi, apic_perfmon_handler
        call set_interrupt_handler
        
        
; 设置 LVT performance monitor counter
        mov DWORD [APIC_BASE + LVT_PERFMON], FIXED_DELIVERY | APIC_PERFMON_VECTOR
        

;*
;* 实验 ex15-13: 测量 CPI 值
;*
        ;*
        ;* perfmon 初始设置
        ;* 关闭所有 counter 和 PEBS 
        ;* 清 overflow 标志位
        ;*
        DISABLE_GLOBAL_COUNTER
        DISABLE_PEBS
        RESET_COUNTER_OVERFLOW


; 1) 得到 non-halted CPI 值
        mov esi, test_func                      ; 被测量的函数
        call get_unhalted_cpi                   ; 得到 CPI 值
        mov ebx, eax
        mov esi, msg1
        call puts
        mov esi, ebx
        call print_dword_decimal                ; 打印 CPI 值
        call println
        call println

; 2)得到 nominal CPI 值
        mov esi, test_func
        call get_nominal_cpi
        mov ebx, eax
        mov esi, msg2
        call puts
        mov esi, ebx
        call print_dword_decimal
        call println
        call println

; 3)得到 non-halted CPI 值
        mov esi, test_print_float
        call get_unhalted_cpi
        mov ebx, eax
        mov esi, msg1
        call puts
        mov esi, ebx
        call print_dword_decimal
        call println
        call println

; 4)得到 nomial CPI 值
        mov esi, test_print_float
        call get_nominal_cpi
        mov ebx, eax
        mov esi, msg2
        call puts
        mov esi, ebx
        call print_dword_decimal
        call println
        call println
        
        jmp $
     
    

        
; 转到 long 模块
        ;jmp LONG_SEG
                                
                                
; 进入 ring 3 代码
        push DWORD user_data32_sel | 0x3
        push DWORD USER_ESP
        push DWORD user_code32_sel | 0x3        
        push DWORD user_entry
        retf

        
;; 用户代码

user_entry:
        mov ax, user_data32_sel
        mov ds, ax
        mov es, ax

user_start:

        jmp $

msg1    db '<non-halted CPI>: ', 0
msg2    db '<nominal CPI>: ', 0


;*
;* 测试 float 单元
;*
test_print_float:
        jmp do_test_print_float
f1      dd 1.3333
tpf_msg db 'the float is: ', 0
do_test_print_float:
        finit
        mov esi, tpf_msg
        call puts
        mov esi, f1
        call print_dword_float
        call println
        ret 


;*
;* 测试字符串
;*
test_func:
        jmp do_test_func
test_msg db 'this is a test message', 10, 0
do_test_func:
        mov esi, test_msg
        mov eax, SYS_PUTS
        int SYSTEM_SERVICE_VECTOR
        ret
        








%define APIC_PERFMON_HANDLER

;******** include 中断 handler 代码 ********
%include "..\common\handler32.asm"


;********* include 模块 ********************
%include "..\lib\creg.asm"
%include "..\lib\cpuid.asm"
%include "..\lib\msr.asm"
%include "..\lib\pci.asm"
%include "..\lib\apic.asm"
%include "..\lib\debug.asm"
%include "..\lib\perfmon.asm"
%include "..\lib\page32.asm"
%include "..\lib\pic8259A.asm"


;;************* 函数导入表  *****************

; 这个 lib32 库导入表放在 common\ 目录下,
; 供所有实验的 protected.asm 模块使用

%include "..\common\lib32_import_table.imt"


PROTECTED_END: