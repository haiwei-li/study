; handler64.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


;*
;* 这是 long-mode 模式下的 interrupt/exception handler 代码
;* 由各个实验例子的 long.asm 模块来 include 进去
;*


%ifndef HANDLER64_ASM
%define HANDLER64_ASM


;-------------------------------------------
; gp_handler:
;------------------------------------------
GP_handler:
        STORE_CONTEXT64
        jmp do_GP_handler
gmsg1   db '---> Now, enter #GP handler, occur at: 0x', 0
gmsg2   db 'error code = 0x', 0
gmsg3   db 'rsp = 0x', 0
gmsg4   db '--------------- register context ------------', 10, 0
do_GP_handler:        
        mov esi, gmsg1
        LIB32_PUTS_CALL
        mov esi, [rsp + 8]
        mov edi, [rsp + 8 + 4]
        LIB32_PRINT_QWORD_VALUE_CALL
        LIB32_PRINTLN_CALL

        mov esi, gmsg2
        LIB32_PUTS_CALL
        mov esi, [rsp]
        mov edi, [rsp + 4]
        LIB32_PRINT_QWORD_VALUE_CALL
        LIB32_PRINTLN_CALL

        mov esi, gmsg3
        LIB32_PUTS_CALL
        mov esi, [rsp + 32]
        mov edi, [rsp + 32 + 4]
        LIB32_PRINT_QWORD_VALUE_CALL
        LIB32_PRINTLN_CALL

        mov esi, gmsg4
        LIB32_PUTS_CALL
        call dump_reg64

        jmp $ 
        iret64

;-------------------------------------------
; #PF handler:
;------------------------------------------
PF_handler:
        jmp do_PF_handler
pf_msg1 db 10, '>>> Now, enter #PF handler', 10, 0
pf_msg2 db '>>>>>>> occur at: 0x', 0        
pf_msg3 db '>>>>>>> page fault address: 0x', 0
do_PF_handler:        
        add rsp, 8
        mov esi, pf_msg1
        LIB32_PUTS_CALL
        mov esi, pf_msg2
        LIB32_PUTS_CALL
        mov esi, [rsp]
        mov edi, [rsp + 4]
        LIB32_PRINT_QWORD_VALUE_CALL
        LIB32_PRINTLN_CALL
        mov esi, pf_msg3
        LIB32_PUTS_CALL
        mov rsi, cr2
        mov rdi, rsi
        shr rdi, 32
        LIB32_PRINT_QWORD_VALUE_CALL
        LIB32_PRINTLN_CALL
        jmp $ 
        iret64


;*********************************
; #DB handler
;*********************************
DB_handler:
        jmp do_db_handler
db_msg1 db '>>> now, enter #DB handler', 0
db_msg2 db 'now, exit #DB handler <<<', 10, 0
do_db_handler:        
        mov esi, db_msg1
        LIB32_PUTS_CALL
        
; 关掉 L0 enable 位
        mov rax, dr7
        btr rax, 0
        mov dr7, rax
        
;        call dump_debugctl
        call dump_lbr_stack
        
do_db_handler_done:        
        bts QWORD [rsp+16], 16                ; RF=1
        mov esi, db_msg2
        LIB32_PUTS_CALL
        iret64        



%ifndef EX14_13

%define CONTEXT_POINTER64       debug_context64

;-------------------------------
; perfmon handler
;------------------------------
apic_perfmon_handler:
        jmp do_apic_perfmon_handler
ph_msg1 db '>>> now: enter PMI handler, occur at 0x', 0
ph_msg2 db 'exit the PMI handler <<<', 10, 0        
ph_msg3 db '****** BTS buffer full! *******', 10, 0
ph_msg4 db '****** PMI interrupt occur *******', 10, 0
ph_msg5 db '****** PEBS buffer full! *******', 10, 0
ph_msg6 db '****** PEBS interrupt occur *******', 10, 0

do_apic_perfmon_handler:
        ;; 保存处理器上下文
        STORE_CONTEXT64

;*
;* 下面在 handler 里关闭相关的功能
;* 在关闭功能之前, 先保存原值, 以便返回前恢复
;*
        mov ecx, IA32_DEBUGCTL
        rdmsr
        mov [debugctl_value], eax 
        mov [debugctl_value + 4], edx
        mov eax, 0 
        mov edx, 0
        wrmsr                                   ; 关闭所有 debug 功能
        mov ecx, IA32_PEBS_ENABLE
        rdmsr
        mov [pebs_enable_value], eax
        mov [pebs_enable_value + 4], edx
        mov eax, 0
        mov edx, 0
        wrmsr                                   ; 关闭所有 PEBS 中断许可
        mov ecx, IA32_PERF_GLOBAL_CTRL
        rdmsr
        mov [perf_global_ctrl_value], eax
        mov [perf_global_ctrl_value + 4], edx
        mov eax, 0
        mov edx, 0
        wrmsr                                   ; 关闭所有 performace counter

        ;; 打印信息
        mov esi, ph_msg1
        LIB32_PUTS_CALL
        mov esi, [rsp]
        mov edi, [rsp + 4]
        LIB32_PRINT_QWORD_VALUE_CALL
        LIB32_PRINTLN_CALL

;*
;* 接下来判断 APIC performon monitor 中断触发的原因
;* 1. PMI 中断
;* 2. PEBS 中断
;* 3. BTS buffer 溢出中断
;* 4. PEBS buffer 溢出中断
;*

check_counter_overflow:
        ;*
        ;* 检测是否发生 PMI 中断
        ;*
        call test_counter_overflow
        test eax, eax
        jz check_pebs_interrupt

        ; 打印信息
        mov esi, ph_msg4
        LIB32_PUTS_CALL
        call dump_perfmon_global_status       
        
        ;* 修复中断条件 *
        RESET_COUNTER_OVERFLOW                  ; 清所有溢出位

check_pebs_interrupt:
        ;*
        ;* 检测是否发生 PEBS 中断
        ;*
        call test_pebs_interrupt
        test eax, eax
        jz check_bts_buffer_overflow

        ; 打印信息
        mov esi, ph_msg6
        LIB32_PUTS_CALL

        call dump_pebs_record

        ;* 修复中断条件 *
        call update_pebs_index_track            ; 更新 pebs index 监控轨迹



check_bts_buffer_overflow:
        ;*
        ;* 检测是否发生 BTS buffer 溢出中断
        ;*
        call test_bts_buffer_overflow
        test eax, eax
        jz check_pebs_buffer_overflow

        ;* 修复中断条件 */
        call reset_bts_index                    ; 重置 BTS index 值        

        ; 打印信息
        mov esi, ph_msg3
        LIB32_PUTS_CALL

check_pebs_buffer_overflow:
        ;*
        ;* 检测是否发生 PEBS buffer 溢出中断
        ;*
        call test_pebs_buffer_overflow
        test eax, eax
        jz apic_perfmon_handler_done

        ;* 修复中断条件 */
        RESET_PEBS_BUFFER_OVERFLOW              ; 清 OvfBuffer 位
        call reset_pebs_index                   ; 重置 PEBS index 值

        ; 打印信息
        mov esi, ph_msg5
        LIB32_PUTS_CALL


apic_perfmon_handler_done:
        mov esi, ph_msg2
        LIB32_PUTS_CALL

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

;*
;* apic performon handler 返回前
;*
        RESTORE_CONTEXT64                                       ; 恢复 context
        btr DWORD [APIC_BASE + LVT_PERFMON], 16                 ; 清 LVT_PERFMON 寄存器 mask 位
        mov DWORD [APIC_BASE + EOI], 0                          ; 写 EOI 命令
        iret64              
%endif
        
        

;---------------------------------------------
; apic_timer_handler(): 这是 APIC TIMER 的 ISR
;---------------------------------------------
apic_timer_handler:
        jmp do_apic_timer_handler
at_msg  db '>>> now: enter the APIC timer handler', 10, 0
at_msg1 db 10, 'exit ther APIC timer handler <<<', 10, 0        
do_apic_timer_handler:        
        mov esi, at_msg
        LIB32_PUTS_CALL
        call dump_apic                        ; 打印 apic 寄存器信息
        mov esi, at_msg1
        LIB32_PUTS_CALL
        mov DWORD [APIC_BASE + EOI], 0
        iret64


%endif