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
        
;; 为了完成实验, 关闭时间中断和键盘中断
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
        call disable_keyboard
        call disable_timer
        sti
        
;========= 初始化设置完毕 =================


;*
;* 实验 ex14-11: 测试BTS buffer的过滤功能
;*

; 1) 开启APIC
        call enable_xapic        
        
; 2) 设置 APIC performance monitor counter handler
        mov esi, APIC_PERFMON_VECTOR
        mov edi, apic_perfmon_handler
        call set_interrupt_handler
        
        
; 设置 LVT performance monitor counter
        mov DWORD [APIC_BASE + LVT_PERFMON], FIXED_DELIVERY | APIC_PERFMON_VECTOR
        
        call available_bts                                ; 测试 bts 是否可用
        test eax, eax
        jz next                                           ; 不可用


; 设置完整 DS 区域(环形 BTS buffer)
        SET_DS_AREA

        
; * 注册用户中断服务例程
; * 挂接在 system_service_table 表上

        mov esi, USER_ENABLE_BTS                        ; 功能号
        mov edi, user_enable_bts                        ; 自定义例程
        call set_system_service_table

        mov esi, USER_DISABLE_BTS                        ; 功能号
        mov edi, user_disable_bts                        ; 自定义例程 
        call set_system_service_table
                
        mov esi, USER_DUMP_BTS                           ; 功能号
        mov edi, user_dump_bts                           ; 自定义例程
        call set_system_service_table
        
; 进入 ring 3 代码
        push DWORD user_data32_sel | 0x3
        push DWORD USER_ESP
        push DWORD user_code32_sel | 0x3        
        push DWORD user_entry
        retf


;; **********************************        
;; 下面是用户代码(CPL = 3)
;; **********************************

user_entry:
        mov ax, user_data32_sel
        mov ds, ax
        mov es, ax

user_start:
        
        ; 开启 BTS
        mov eax, USER_ENABLE_BTS
        int SYSTEM_SERVICE_VECTOR

        ; 打印测试信息
        mov esi, msg
        mov eax, SYS_PUTS
        int SYSTEM_SERVICE_VECTOR
        
        ; 关闭 BTS
        mov eax, USER_DISABLE_BTS
        int SYSTEM_SERVICE_VECTOR

        ; 打印 BTS
        mov eax, USER_DUMP_BTS
        int SYSTEM_SERVICE_VECTOR

        
next:
        jmp $


;; 定义 3 个用户中断服务例程号
;; 对应于 user_enable_bts(), user_dislable_bts() 以及 user_dump_bts()

USER_ENABLE_BTS         equ SYSTEM_SERVICE_USER0
USER_DISABLE_BTS        equ SYSTEM_SERVICE_USER1
USER_DUMP_BTS           equ SYSTEM_SERVICE_USER2


;------------------------
; 在用户层里开启 BTS 功能
;-------------------------
user_enable_bts:
        ;*
        ;* 关闭在 OS kernel 层的 BTS 记录
        ;* 使用环形 BTS buffer
        ;*
        mov ecx, IA32_DEBUGCTL
        mov edx, 0
        mov eax, 2C0h                ; TR=1, BTS=1, BTS_OFF_OS=1
        wrmsr
        ret

;--------------------------
; 在用户层里关闭 BTS 功能
;-------------------------
user_disable_bts:
        mov ecx, IA32_DEBUGCTL
        rdmsr
        btr eax, TR_BIT                ; TR = 0
        wrmsr
        ret

;--------------------------
; 在用户层打印 BTS buffer
;--------------------------
user_dump_bts:
        call dump_ds_management
        call dump_bts_record
        ret



;;; 测试函数
foo:
        mov esi, msg
        call puts                        ; 打印一条信息
        ret


msg        db 'hi, message from User...', 10, 10, 0




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