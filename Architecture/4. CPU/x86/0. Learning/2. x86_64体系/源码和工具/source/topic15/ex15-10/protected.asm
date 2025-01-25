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
;* 实验 ex15-10: 测试 load latency 机制
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


; 设置完整的 DS 区域
        SET_DS_AREA
        ENABLE_BTS                                     ; TR=1, BTS=1

; 设置 counter 计数值        
        mov esi, IA32_PMC0
        call write_counter_maximum

; 写入 load latency 监控值
        mov ecx, MSR_PEBS_LD_LAT
        mov eax, 03h                                    ; 监控值为 3
        mov edx, 0
        wrmsr

; 设置监控事件, 开启计数器
        mov ecx, IA32_PERFEVTSEL0
        mov eax, PEBS_MEM_INST_COUNT_EVENT              ; 使用 MEM load 事件
        mov edx, 0
        wrmsr     

; 开启 IA32_PMC0 计数器的 PEBS 机制,并使用 load latency 功能
        ENABLE_PEBS_WITH_LL_PMC0
        ENABLE_IA32_PMC0
        

; 测试函数 
        call test_func


; 关闭 IA32_PMC0 计数器
        DISABLE_IA32_PMC0
        DISABLE_PEBS_PMC0
        DISABLE_BTS

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



test_func:
        jmp do_test_func
test_msg db 'this is a test message', 10, 0
do_test_func:
        mov esi, test_msg
        call puts
        ret

pebs_count dd 0


;-------------------------------
; perfmon handler
;------------------------------
apic_perfmon_handler:
        jmp do_apic_perfmon_handler
ph_msg1 db '>>> now: enter PMI handler, occur at 0x', 0
ph_msg2 db 'exit the PMI handler <<<', 10, 0        
ph_msg3 db '****** DS interrupt occur with BTS buffer full! *******', 10, 0
ph_msg4 db '****** PMI interrupt occur *******', 10, 0
ph_msg5 db '****** DS interrupt occur with PEBS buffer full! *******', 10, 0
ph_msg6 db '****** PEBS interrupt occur *******', 10, 0

do_apic_perfmon_handler:
        ;; 保存处理器上下文
        STORE_CONTEXT

;*
;* 下面在 handler 里关闭功能
;*

        ;; 当 TR 开启时,就关闭 TR
        mov ecx, IA32_DEBUGCTL
        rdmsr
        mov [debugctl_value], eax        ; 保存原 IA32_DEBUGCTL 寄存器值,以便恢复
        mov [debugctl_value + 4], edx
        mov eax, 0
        mov edx, 0
        wrmsr

        ;; 关闭 pebs enable
        mov ecx, IA32_PEBS_ENABLE
        rdmsr
        mov [pebs_enable_value], eax
        mov [pebs_enable_value + 4], edx
        mov eax, 0
        mov edx, 0
        wrmsr


        ; 关闭 performance counter
        mov ecx, IA32_PERF_GLOBAL_CTRL
        rdmsr
        mov [perf_global_ctrl_value], eax
        mov [perf_global_ctrl_value + 4], edx
        mov eax, 0
        mov edx, 0
        wrmsr

        mov esi, ph_msg1
        call puts
        mov esi, [esp]
        call print_dword_value
        call println

        call dump_pmc
;*
;* 接下来判断 PMI 中断引发原因
;*

checK_pebs_interrupt:
        ; 是否 PEBS 中断
        call test_pebs_interrupt
        test eax, eax
        jz check_counter_overflow
        ; 打印信息
        mov esi, ph_msg6
        call puts
        call dump_pebs_record
        call update_pebs_index_track            ; 更新 PEBS index 的轨迹,保持对 PEBS 中断的检测

check_counter_overflow:
        ; 检测是否发生 PMI 中断
        call test_counter_overflow
        test eax, eax
        jz check_pebs_buffer_overflow
        ; 打印信息
        mov esi, ph_msg4
        call puts
        call dump_perf_global_status
        RESET_COUNTER_OVERFLOW                  ; 清溢出标志

check_pebs_buffer_overflow:
        ; 检测是否发生 PEBS buffer 溢出中断
        call test_pebs_buffer_overflow
        test eax, eax
        jz check_bts_buffer_overflow
        ; 打印信息
        mov esi, ph_msg5
        call puts
        call dump_perf_global_status
        RESET_PEBS_BUFFER_OVERFLOW              ; 清 OvfBuffer 溢出标志
        call reset_pebs_index                   ; 重置 PEBS 值

check_bts_buffer_overflow:
        ; 检则是否发生 BTS buffer 溢出中断
        call test_bts_buffer_overflow
        test eax, eax
        jz apic_perfmon_handler_done
        ; 打印信息
        mov esi, ph_msg3
        call puts
        call reset_bts_index                    ; 重置 BTS index 值

apic_perfmon_handler_done:
        mov esi, ph_msg2
        call puts

;*
;* 下面恢复功能原设置!
;* 
        ; 恢复原 IA32_PERF_GLOBAL_CTRL 寄存器值
        mov ecx, IA32_PERF_GLOBAL_CTRL
        mov eax, [perf_global_ctrl_value]
        mov edx, [perf_global_ctrl_value + 4]
        wrmsr

        ; 恢复原 IA32_DEBUGCTL 设置　
        mov ecx, IA32_DEBUGCTL
        mov eax, [debugctl_value]
        mov edx, [debugctl_value + 4]
        wrmsr

        ;; 恢复 IA32_PEBS_ENABLE 寄存器
        mov ecx, IA32_PEBS_ENABLE
        mov eax, [pebs_enable_value]
        mov edx, [pebs_enable_value + 4]
        wrmsr

        RESTORE_CONTEXT                                 ; 恢复 context
        btr DWORD [APIC_BASE + LVT_PERFMON], 16         ; 清 LVT_PERFMON 寄存器 mask 位
        mov DWORD [APIC_BASE + EOI], 0                  ; 写 EOI 命令
        iret




        
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