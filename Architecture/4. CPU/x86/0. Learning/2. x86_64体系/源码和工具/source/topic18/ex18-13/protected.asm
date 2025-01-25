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
        cli
        NMI_DISABLE

; 允许执行 SSE 指令        
        mov eax, cr4
        bts eax, 9                                ; CR4.OSFXSR = 1
        mov cr4, eax
        call pae_enable
        call execution_disable_enable

;; 设置 sysenter/sysexit 使用环境
        call set_sysenter
 
        ;*
        ;* perfmon 初始设置
        ;* 关闭所有 counter 和 PEBS 
        ;* 清 overflow 标志位
        ;*
        DISABLE_GLOBAL_COUNTER
        DISABLE_PEBS
        RESET_COUNTER_OVERFLOW       
        RESET_PMC
        
       
;;; 测试 bootstrap processor 还是 application processor ?
        mov ecx, IA32_APIC_BASE
        rdmsr
        bt eax, 8
        jnc application_processor_enter


;------------------------------------------------
; 下面是 bootstrap processor 执行代码
;-----------------------------------------------
bsp_processor_enter:
        call init_pae_paging
        mov eax, PDPT_BASE
        mov cr3, eax
        mov eax, cr0
        bts eax, 31
        mov cr0, eax  

        ;*
        ;* 复制 startup routine 代码到 20000h                
        ;* 以便于 AP processor 运行
        ;*
        mov esi, startup_routine
        mov edi, 20000h
        mov ecx, startup_routine_end - startup_routine
        rep movsb


; 设置 IRQ0 和 IRQ1 中断
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

;; 设置 system_service handler
        mov esi, SYSTEM_SERVICE_VECTOR
        mov edi, system_service
        call set_user_interrupt_handler 

;设置 APIC performance monitor counter handler
        mov esi, APIC_PERFMON_VECTOR
        mov edi, apic_perfmon_handler
        call set_interrupt_handler

; 设置 APIC timer handler
        mov esi, APIC_TIMER_VECTOR
        mov edi, apic_timer_handler
        call set_interrupt_handler      

;开启APIC
        call enable_apic        

; 设置 LVT 寄存器
        mov DWORD [APIC_BASE + LVT_PERFMON], FIXED_DELIVERY | APIC_PERFMON_VECTOR
        mov DWORD [APIC_BASE + LVT_TIMER], TIMER_ONE_SHOT | APIC_TIMER_VECTOR
        mov DWORD [APIC_BASE + LVT_ERROR], APIC_ERROR_VECTOR

; 设置 BSP IPI handler
        mov esi, BP_IPI_VECTOR
        mov edi, bp_ipi_handler
        call set_interrupt_handler             
        
;===============================================

        inc DWORD [processor_index]                             ; 增加 index 值
        inc DWORD [processor_count]                             ; 增加 logical processor 数量
        mov ecx, [processor_index]                              ; 取 index 值
        mov edx, [APIC_BASE + APIC_ID]                          ; 读 APIC ID
        mov [apic_id + ecx * 4], edx                            ; 保存 APIC ID 
;*
;* 分配 stack 空间
;*
        mov eax, PROCESSOR_STACK_SIZE                           ; 每个处理器的 stack 空间大小
        mul ecx                                                 ; stack_offset = STACK_SIZE * index
        mov esp, PROCESSOR_KERNEL_ESP                           ; stack 基值
        add esp, eax  

; 设置 logical ID
        mov eax, 01000000h
        shl eax, cl
        mov [APIC_BASE + LDR], eax
 
        call extrac_x2apic_id 
        
; 开放 lock 
        mov DWORD [20100h], 0

        ;*
        ;* 下面发送 IPIs, 使用 INIT-SIPI-SIPI 序列
        ;* 发送 SIPI 时, 发送 startup routine 地址位于 200000h
        ;*
        mov DWORD [APIC_BASE + ICR0], 000c4500h                ; 发送 INIT IPI, 使所有 processor 执行 INIT
        DELAY
        DELAY
        mov DWORD [APIC_BASE + ICR0], 000C4620H               ; 发送 Start-up IPI
        DELAY
        mov DWORD [APIC_BASE + ICR0], 000C4620H                ; 再次发送 Start-up IPI
     
        ; 打开中断
        sti
        NMI_ENABLE


        ;*
        ;* 等待 AP 处理器完成初始化
        ;*
wait_for_done:
        cmp DWORD [ap_init_done], 1
        je next
        nop
        pause
        jmp wait_for_done 

next:  

;============== 初始化设置完毕 ======================


; 实验 18-13: 通过 LINT0 屏蔽来自 8259 中断控制器的中断请求

        ; 开启 8259 的 IRQ1 键盘中断请求许可
        call enable_keyboard

        mov esi, msg0
        call puts

        ; 屏蔽 LINT 0
        mov eax, [APIC_BASE + LVT_LINT0]
        bts eax, 16                                ; masked
        mov [APIC_BASE + LVT_LINT0], eax
        
        call dump_lvt                                ; 打印 LVT 寄存器

        sti                                        ; 打开中断许可


        jmp $




bp_msg1         db '<bootstrap processor>  : '
bp_msg2         db 'now, send IPI to processor 01', 10, 10, 0

msg0    db 'now: mask LVT LINT0 ...', 10, 0

msg1    db 'APIC ID: 0x', 0
msg2    db 'pkg_ID: 0x', 0
msg3    db 'core_ID: 0x', 0
msg4    db 'smt_ID: 0x', 0


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



%define APIC_PERFMON_HANDLER
%define APIC_TIMER_HANDLER
%define APIC_ERROR_HANDLER
%define AP_PROTECTED_ENTER

;******** include 共用的代码 ***********
%include "..\common\application_processor.asm"

        bits 32
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