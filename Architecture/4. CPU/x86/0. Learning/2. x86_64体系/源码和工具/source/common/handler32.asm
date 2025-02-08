; handler32.asm
; Copyright (c) 2009-2012 mik
; All rights reserved.


;*
;* 这是 protected 模式下的 interrupt/exception handler 代码
;* 由各个实验例子的 protected.asm 模块来 include 进去
;*


%ifndef HANDLER32_ASM
%define HANDLER32_ASM


;----------------------------------------
; DB_handler():  #DB handler
; 描述:
;
;----------------------------------------
DB_handler:
        jmp do_DB_handler
db_msg1         db '-----< Single-Debug information >-----', 10, 0
db_msg2         db '>>>>> END <<<<<', 10, 0

;* 这些字符串地址定义在 debug.asm 文件
register_message_table:
        dd eax_msg, ecx_msg, edx_msg, ebx_msg, esp_msg, ebp_msg, esi_msg, edi_msg, 0

do_DB_handler:
        ;; 得到寄存器值
        STORE_CONTEXT

        mov esi, db_msg1
        call puts

        ;; 停止条件
        mov eax, [db_stop_address]              ; 读 #DB 停止地址
        cmp eax, [esp]                          ; 是否遇到停止条件
        je stop_debug

        mov ebx, CONTEXT_POINTER
do_DB_handler_loop:

        mov esi, [register_message_table + ecx * 4]
        call puts                               ; 打印字符串
        mov esi, [ebx + ecx * 4]
        call print_dword_value                  ; 打印寄存器值

        mov eax, ecx
        and eax, 3
        cmp eax, 3
        mov esi, printblank                     ; 空格
        mov edi, println                        ; 换行
        cmove esi, edi                          ; 打印 4 个后, 换行
        call esi

        inc ecx
        cmp ecx, 7
        jbe do_DB_handler_loop

do_DB_handler_next:
        mov esi, eip_msg
        call puts
        mov esi, [esp]
        call print_dword_value
        call println
        jmp do_DB_handler_done

stop_debug:
        btr DWORD [esp + 8], 8                  ; 清 TF 标志
        mov esi, db_msg2
        call puts
do_DB_handler_done:
        bts DWORD [esp + 8], 16                 ; 设置 eflags.RF 为 1, 以便中断返回时, 继续执行

        RESTORE_CONTEXT
        iret


%ifdef DEBUG
;--------------------------------------------
; #DB handler
; 描述:
;       这个版本的 #DB handler 用于
;-------------------------------------------
debug_handler:
        jmp do_debug_handler
dh_msg1 db '>>> now: enter #DB handler', 10, 0
dh_msg2 db 'new, exit #DB handler <<<', 10, 0
do_debug_handler:
        mov esi, dh_msg1
        call puts
        call dump_drs
        call dump_dr6
        call dump_dr7
        mov eax, [esp]
        cmp WORD [eax], 0xfeeb              ; 测试 jmp $ 指令
        jne do_debug_handler_done
        btr DWORD [esp+8], 8                ; 清 TF
do_debug_handler_done:
        bts DWORD [esp+8], 16               ; RF=1
        mov esi, dh_msg2
        call puts
        iret

%endif


;-------------------------------------------
; GP_handler():  #GP handler
;-------------------------------------------
GP_handler:
        jmp do_GP_handler
gmsg1   db '---> Now, enter #GP handler, occur at: 0x', 0
gmsg2   db ', error code = 0x', 0
gmsg3   db '<ID:', 0
gmsg4   db '--------------- register context ------------', 10, 0
do_GP_handler:
        mov esi, gmsg1
        call puts
        mov esi, [esp + 4]
        call print_dword_value
        call println
        mov esi, gmsg3
        call puts
        mov esi, [APIC_BASE + APIC_ID]
        call print_dword_value
        mov esi, '>'
        call putc
        mov esi, gmsg2
        call puts
        mov esi, [esp]
        call print_dword_value
        call println

        jmp $
do_GP_handler_done:
        iret

;------------------------------------------------
; #GF handler
;------------------------------------------------
PF_handler:
        jmp do_pf_handler
pf_msg  db 10, '---> now, enter #PF handler', 10
        db 'occur at: 0x', 0
pf_msg2 db 10, 'fixed the error', 10, 0
do_pf_handler:
        add esp, 4                              ; 忽略 Error code
        push ecx
        push edx
        mov esi, pf_msg
        call puts

        mov ecx, cr2                            ; 发生#PF异常的virtual address
        mov esi, ecx
        call print_dword_value

        jmp $

        mov esi, pf_msg2
        call puts

;; 下面修正错误
        mov eax, ecx
        shr eax, 30
        and eax, 0x3                        ; PDPTE index
        mov eax, [PDPT_BASE + eax * 8]
        and eax, 0xfffff000
        mov esi, ecx
        shr esi, 21
        and esi, 0x1ff                        ; PDE index
        mov eax, [eax + esi * 8]
        btr DWORD [eax + esi * 8 + 4], 31                ; 清 PDE.XD
        bt eax, 7                                ; PDE.PS=1 ?
        jc do_pf_handler_done
        mov esi, ecx
        shr esi, 12
        and esi, 0x1ff                        ; PTE index
        and eax, 0xfffff000
        btr DWORD [eax + esi * 8 + 4], 31                ; 清 PTE.XD
do_pf_handler_done:
        pop edx
        pop ecx
        iret


;----------------------------------------------
; UD_handler(): #UD handler
;----------------------------------------------
UD_handler:
        jmp do_UD_handler
ud_msg1         db '>>> Now, enter the #UD handler, occur at: 0x', 0
do_UD_handler:
        mov esi, ud_msg1
        call puts
        mov eax, [esp+12]               ; 得到 user esp
        mov eax, [eax]
        mov [esp], eax                  ; 跳过产生#UD的指令
        add DWORD [esp+12], 4           ; pop 用户 stack
        iret

;----------------------------------------------
; NM_handler(): #NM handler
;----------------------------------------------
NM_handler:
        jmp do_NM_handler
nm_msg1         db '---> Now, enter the #NM handler', 10, 0
do_NM_handler:
        mov esi, nm_msg1
        call puts
        mov eax, [esp+12]               ; 得到 user esp
        mov eax, [eax]
        mov [esp], eax                  ; 跳过产生#NM的指令
        add DWORD [esp+12], 4           ; pop 用户 stack
        iret

;-----------------------------------------------
; AC_handler(): #AC handler
;-----------------------------------------------
AC_handler:
        jmp do_AC_handler
ac_msg1         db '---> Now, enter the #AC exception handler <---', 10
ac_msg2         db 'exception location at 0x'
ac_location     dq 0, 0
do_AC_handler:
        pusha
        mov esi, [esp+4+4*8]
        mov edi, ac_location
        call get_dword_hex_string
        mov esi, ac_msg1
        call puts
        call println
;; 现在 disable AC 功能
        btr DWORD [esp+12+4*8], 18      ; 清elfags image中的AC标志
        popa
        add esp, 4                      ; 忽略 error code
        iret


;----------------------------------------
; #TS handler
;----------------------------------------
TS_handler:
        jmp do_ts_handler
ts_msg1        db '--> now, enter the #TS handler', 10, 0
ts_msg2        db 'return addres: 0x', 0
ts_msg3        db 'error code: 0x', 0
do_ts_handler:
        mov esi, ts_msg1
        call puts
        mov esi, ts_msg2
        call puts
        mov esi, [esp+4]
        call print_value
        mov esi, ts_msg3
        call puts
        mov esi, [esp]
        call print_value
        jmp $
        iret



%ifndef EX10_7
%define EX10_7

;-------------------------------------
; BR_handler(): #BR handler
;-------------------------------------
BR_handler:
        jmp do_BR_handler
brmsg1        db 10, 10, '---> Now, enter #BR handler', 10, 0
do_BR_handler:
        mov esi, brmsg1
        call puts
;        mov eax, [bound_rang]                ; 修复错误
        iret

;--------------------------------------
; BP_handler(): #BP handler
;--------------------------------------
BP_handler:
        jmp do_BP_handler
bmsg1        db 10, 10, 10, '---> Now, enter #BP handler, Breakpoint at: ', 0
do_BP_handler:
        push ebx
        mov bl, al
        mov esi, bmsg1
        call puts
        mov esi, [esp + 4]                        ;  返回值
        dec esi                                   ;  breakpoint 位置
        mov [esp + 4], esi                        ; 修正返回值
        mov BYTE [esi], bl                        ; 修复 breakpoint 数据
        call print_value
        pop ebx
        iret

;---------------------------------------
; OF_handler(): #OF handler
;---------------------------------------
OF_handler:
        jmp do_OF_handler
omsg1   db '---> Now, enter #OF handler',10, 10,0

do_OF_handler:
        push ebx
        mov ebx, [esp + 12]             ; 读 eflags 值
        mov esi, omsg1
        call puts
        mov esi, ebx
        call dump_flags_value
        pop ebx
        iret


%endif



;-------------------------------
; system timer handler
; 描述:
;       使用于 8259 IRQ0 handler
;-------------------------------
timer_handler:
        jmp do_timer_handler
t_msg           db 10, '>>> now: enter 8253-timer handler', 10, 0
t_msg1          db 'exit the 8253-timer handler <<<', 10, 0
t_msg2          db 'wait for keyboard...', 10, 0
spin_lock       dd 0
keyboard_done   dd 0
do_timer_handler:
        mov esi, t_msg
        call puts
        call dump_8259_imr
        call dump_8259_irr
        call dump_8259_isr

test_lock:
        bt DWORD [spin_lock], 0                        ; 测试锁
        jnc get_lock
        pause
        jmp test_lock
get_lock:
        lock bts DWORD [spin_lock], 0
        jc test_lock

;发送 special mask mode 命令
        call enable_keyboard
        call send_smm_command
        call disable_timer
        sti
        mov esi, t_msg2
        call puts
wait_for_keyboard:
        mov ecx, 0xffff
delay:
        nop
        loop delay
        bt DWORD [keyboard_done], 0
        jnc wait_for_keyboard
        btr DWORD [spin_lock], 0                ; 释放锁
        mov esi, t_msg1
        call puts
        call write_master_EOI
        call disable_timer
        iret



;----------------------------
; keyboard_handler:
; 描述:
;       使用于 8259 IRQ1 handler
;----------------------------
keyboard_handler:
        jmp do_keyboard_handler
k_msg   db 10, '>>> now: entry keyboard handler', 10, 0
k_msg1  db 'exit the keyboard handler <<<', 10, 0
do_keyboard_handler:
        mov esi, k_msg
        call puts
        call dump_8259_imr
        call dump_8259_irr
        call dump_8259_isr
        bts DWORD [keyboard_done], 0                ; 完成
        mov esi, k_msg1
        call puts
        call write_master_EOI
        iret


%ifdef APIC_TIMER_HANDLER
;---------------------------------------------
; apic_timer_handler(): 这是 APIC TIMER 的 ISR
;---------------------------------------------
apic_timer_handler:
        jmp do_apic_timer_handler
at_msg  db '>>> now: enter the APIC timer handler', 10, 0
at_msg1 db 10, 'exit ther APIC timer handler <<<', 10, 0
do_apic_timer_handler:
        mov esi, at_msg
        call puts
        call dump_apic                        ; 打印 apic 寄存器信息
        mov esi, at_msg1
        call puts
        mov DWORD [APIC_BASE + EOI], 0
        iret

%endif



;*
;* 如果定义了 APIC_PERFMON_HANDLER
;* 则使用 handler32.asm 文件里的 apic_perfmon_handler
;* 作为 PMI 中断 handler
;* 否则: 在 protected.asm 文件里提供 PMI handler
;*

%ifdef APIC_PERFMON_HANDLER

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
        ;; 当 TR 开启时, 就关闭 TR
        mov ecx, IA32_DEBUGCTL
        rdmsr
        mov [debugctl_value], eax        ; 保存原 IA32_DEBUGCTL 寄存器值, 以便恢复
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

;*
;* 接下来判断 PMI 中断引发原因
;*

check_pebs_interrupt:
        ; 是否 PEBS 中断
        call test_pebs_interrupt
        test eax, eax
        jz check_counter_overflow
        ; 打印信息
        mov esi, ph_msg6
        call puts
        call dump_ds_management
        call update_pebs_index_track            ; 更新 PEBS index 的轨迹, 保持对 PEBS 中断的检测


check_counter_overflow:
        ; 检测是否发生 PMI 中断
        call test_counter_overflow
        test eax, eax
        jz check_pebs_buffer_overflow
        ; 打印信息
        mov esi, ph_msg4
        call puts
        call dump_perf_global_status
        call dump_pmc
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

%endif
;*
;* 结束
;*


%ifdef AP_IPI_HANDLER

;---------------------------------------------
; ap_ipi_handler(): 这是 AP IPI handler
;---------------------------------------------
ap_ipi_handler:
	jmp do_ap_ipi_handler
at_msg2 db 10, 10, '>>>>>>> This is processor ID: ', 0
at_msg3 db '---------- extract APIC ID -----------', 10, 0
do_ap_ipi_handler:

        ; 测试 lock
test_handler_lock:
        lock bts DWORD [vacant], 0
        jc get_handler_lock

        mov esi, at_msg2
        call puts
        mov edx, [APIC_BASE + APIC_ID]        ; 读 APIC ID
        shr edx, 24
        mov esi, edx
        call print_dword_value
        call println
        mov esi, at_msg3
        call puts

        mov esi, msg2                        ; 打印 package ID
        call puts
        mov esi, [x2apic_package_id + edx * 4]
        call print_dword_value
        call printblank
        mov esi, msg3                        ; 打印 core ID
        call puts
        mov esi, [x2apic_core_id + edx * 4]
        call print_dword_value
        call printblank
        mov esi, msg4                        ; 打印 smt ID
        call puts
        mov esi, [x2apic_smt_id + edx * 4]
        call print_dword_value
        call println

        mov DWORD [APIC_BASE + EOI], 0

        ; 释放lock
        lock btr DWORD [vacant], 0
        iret

get_handler_lock:
        jmp test_handler_lock
	iret

%endif


%ifdef APIC_ERROR_HANDLER

;-----------------------------------------
; apic_error_handler() 这是 APIC error 处理
;------------------------------------------
apic_error_handler:
        jmp do_apic_error_handler
ae_msg0        db 10, '>>> now: enter APIC Error handler, occur at: 0x', 0
ae_msg1        db 'exit the APIC error handler <<<', 10, 0
ae_msg2        db 'APIC ID: 0x', 0
ae_msg3        db 'ESR:     0x', 0
do_apic_error_handler:
test_error_handler_lock:
        lock bts DWORD [vacant], 0
        jc get_error_handler_lock
        mov esi, ae_msg0
        call puts
        mov esi, [esp]
        call print_dword_value
        call println
        mov esi, ae_msg2
        call puts
        mov esi, [APIC_BASE + APIC_ID]
        call print_dword_value
        call println
        mov esi, ae_msg3
        call puts
        call read_esr
        mov esi, eax
        call print_dword_value
        call println
        mov esi, ae_msg1
        call puts
        mov DWORD [APIC_BASE + EOI], 0
        lock btr DWORD [vacant], 0                ; 释放 lock
        iret
get_error_handler_lock:
        jmp test_error_handler_lock
%endif


;----------------------------------------------------
; ap_init_done_handler(): AP完成初始化后回复BSP
;----------------------------------------------------
ap_init_done_handler:
        cmp DWORD [20100h], 0
        sete al
        movzx eax, al
        mov [ap_init_done], eax
        mov DWORD [APIC_BASE + EOI], 0
        iret

%endif

