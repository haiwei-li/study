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
        call disable_keyboard
        call disable_timer
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
;* 实验 ex15-8: 测试 PMI 中断与 PEBS 中断同时触发
;*
        
        call available_pebs                             ; 测试 pebs 是否可用
        test eax, eax
        jz next                                         ; 不可用

        ;*
        ;* perfmon 初始设置
        ;* 关闭所有 counter 和 PEBS 
        ;* 清 overflow 标志位
        ;*
        DISABLE_GLOBAL_COUNTER
        DISABLE_PEBS
        RESET_COUNTER_OVERFLOW


; 设置完整的 DS 区域,BTS buffer 满时中断
        SET_DS_AREA


; 开启 BTS 并使用 PMI 冻结功能
        ENABLE_BTS_FREEZE_PERFMON_ON_PMI                ; TR=1, BTS=1, BTINT=1


; 设置两个 counter 计数值        
        mov esi, IA32_PMC0                              ; 设置 IA32_PMC0
        call write_counter_maximum
        mov esi, IA32_PMC1                              ; 设置 IA32_PMC1
        call write_counter_maximum
        

; 设置两个 IA32_PERFEVTSEL0 寄存器, 开启计数
        mov ecx, IA32_PERFEVTSEL0                       ; counter 0                       
        mov eax, INST_COUNT_EVENT
        mov edx, 0
        wrmsr
        mov ecx, IA32_PERFEVTSEL1                       ; counter 1
        mov eax, PEBS_INST_COUNT_EVENT
        mov edx, 0
        wrmsr
 
; 开启 PEBS
        ;*
        ;* 测试一: IA32_PMC0 使用 PMI 计数,IA32_PMC1 使用 PEBS 计数
        ;*
;        ENABLE_PEBS_PMC1

        ;*
        ;* 测试二: IA32_PMC0 使用 PEBS 计数,IA32_PMC1 使用 PMI 计数
        ;*
        ENABLE_PEBS_PMC0

; 同时开启两个计数器,开始计数
        ENABLE_COUNTER (IA32_PMC0_EN | IA32_PMC1_EN), 0

        jmp l1
l1:     jmp l2
l2:     jmp l3
l3:     jmp l4
l4:     jmp l5
l5:     jmp l6
l6:     jmp l7
l7:     jmp l8
l8:     jmp l9
l9:     jmp l10
l10:    jmp l11
l11:


; 关闭两个计数器
        DISABLE_COUNTER (IA32_PMC0_EN | IA32_PMC1_EN), 0

; 关闭 PEBS 机制
        DISABLE_PEBS_PMC1

; 关闭 BTS
        DISABLE_BTS_FREEZE_PERFMON_ON_PMI                ; TR=0, BTS=0

next:        
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



;* 使用 ..\common\handler32.asm 里面的 apic_perfmon_handler 例程 *
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