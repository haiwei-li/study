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
        
; 2)设置 PMI handler
        mov esi, APIC_PERFMON_VECTOR
        mov edi, perfmon_handler
        call set_interrupt_handler
        
        
; 3) 设置 LVT perfmon 寄存器
        mov DWORD [APIC_BASE + LVT_PERFMON], FIXED | APIC_PERFMON_VECTOR



;;; 实验 ex15-4: 测试在 PMI 中冻结 counter 机制


; 设置 IA32_PERF_GLOBAL_CTRL
        mov ecx, IA32_PERF_GLOBAL_CTRL
        rdmsr
        bts eax, 0                              ; PMC0 enable
        wrmsr


; 写入 IA32_PMC0 计数器为最大值
        mov esi, IA32_PMC0                      
        call write_counter_maximum              ; 写入计数器的最大值


; 设置 IA32_PERFEVTSEL0 寄存器, 开启计数器
        mov ecx, IA32_PERFEVTSEL0
        mov eax, 5300c0H                        ; EN=1, INT=1, USR=OS=1, umask=0, event select = c0
        mov edx, 0
        wrmsr


; 下面引发 PMI 中断产生
        call println


; 设置 FREEZE_PERFMON_ON_PMI 位
        mov ecx, IA32_DEBUGCTL
        rdmsr
        bts eax, 12                             ; FREEZE_PERFMON_ON_PMI = 1
        wrmsr

; 再次写入 IA32_PMC0 计数器最大值
        mov esi, IA32_PMC0                      
        call write_counter_maximum 

;*** 下面再次触发 PMI 中断 ****     

; 关闭计数器        
        mov ecx, IA32_PERFEVTSEL0
        rdmsr
        btr eax, 22                              ; 关闭 counter
        wrmsr

        jmp $

        
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
                
next:
        jmp $



;;; 测试函数
foo:
        mov esi, msg
        call puts                        ; 打印一条信息
        ret

msg     db 10, 'hi, this is test function !!!', 10, 10,0



;-------------------------------
; perfmon handler
;------------------------------
perfmon_handler:
        jmp do_perfmon_handler
pfh_msg1 db '>>> now: enter PMI handler', 10, 0
pfh_msg2 db 'exit the PMI handler <<<', 10, 0       
pfh_msg3 db '**** test message ****', 10, 0
do_perfmon_handler:        
        STORE_CONTEXT                                   ; 保存 context

        mov esi, pfh_msg1
        call puts

        ;* 第 1 次打印 PMC 值
        call dump_pmc

        ;** 测试执行一些指令 ****
        mov esi, pfh_msg3
        call puts

        ;* 再次打印 PMC 值
        call dump_pmc


        RESET_COUNTER_OVERFLOW                          ; 清出标志
        mov esi, pfh_msg2
        call puts
do_perfmon_handler_done:
        RESTORE_CONTEXT                                 ; 恢复 context
        btr DWORD [APIC_BASE + LVT_PERFMON], 16         ; 清 mask 位
        mov DWORD [APIC_BASE + EOI], 0                  ; 发送 EOI 命令
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