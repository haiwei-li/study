; perfmon.asm
; Copyright (c) 2009-2012 邓志
; All rights reserved.

;
; 性能监控库
;



;--------------------------------------------
; get_unhalted_cpi(): 测量 non-halted CPI 值
; input:
;       esi - 需测的函数代码
; outpu:
;       eax - CPI 值
; 描述:
;       使用 CPU_CLK_UNHALTED.CORE 事件
;-------------------------------------------
get_unhalted_cpi:
        push ecx
        push edx
        ;*
        ;* 先关闭Fixed计数器，并清为0值
        ;*
        DISABLE_COUNTER 0, (IA32_FIXED_CTR0_EN | IA32_FIXED_CTR1_EN)
        RESET_FIXED_PMC

        ;*
        ;* 开启Fixed计数器，开始计数
        ;*
        mov ecx, IA32_FIXED_CTR_CTRL
        mov eax, 0BBh
        mov edx, 0
        wrmsr
        ENABLE_COUNTER 0, (IA32_FIXED_CTR0_EN | IA32_FIXED_CTR1_EN)

        call esi                ; 调用被测量函数
        
        ;*
        ;* 关闭Fxied计数器，停止计数
        DISABLE_COUNTER 0, (IA32_FIXED_CTR0_EN | IA32_FIXED_CTR1_EN)
        
        mov ecx, IA32_FIXED_CTR0
        rdmsr
        push eax
        push edx
        mov ecx, IA32_FIXED_CTR1
        rdmsr
        push eax
        push edx
        RESET_FIXED_PMC
        pop edx
        pop eax
        pop edi
        pop esi 
        div esi
        pop edx
        pop ecx
        ret


;--------------------------------------------
; get_nominal_cpi(): 测量 non-nominal CPI 值
; input:
;       esi - 需测的函数代码
; outpu:
;       eax - CPI 值
; 描述：
;       使用 CPU_CLK_UNHALTED.REF 事件
;-------------------------------------------
get_nominal_cpi:
        push ecx
        push edx
        ;*
        ;* 先关闭Fixed计数器，并清为0值
        ;*
        DISABLE_COUNTER 0, (IA32_FIXED_CTR0_EN | IA32_FIXED_CTR2_EN)
        RESET_FIXED_PMC

        ;*
        ;* 开启Fixed计数器，开始计数
        mov ecx, IA32_FIXED_CTR_CTRL
        mov eax, 0B0Bh
        mov edx, 0
        wrmsr
        ENABLE_COUNTER 0, (IA32_FIXED_CTR0_EN | IA32_FIXED_CTR2_EN)
        call esi                ; 调用测试函数
        
        ;*
        ;* 关闭Fxied计数器，停止计数
        DISABLE_COUNTER 0, (IA32_FIXED_CTR0_EN | IA32_FIXED_CTR2_EN)
        
        mov ecx, IA32_FIXED_CTR0
        rdmsr
        push eax
        push edx
        mov ecx, IA32_FIXED_CTR2
        rdmsr
        push eax
        push edx
        RESET_FIXED_PMC
        pop edx
        pop eax
        pop edi
        pop esi
        div esi                 
        pop edx
        pop ecx
        ret


;-----------------------------------------------
; support_full_write(): 测试是否支持 full-write
; output:
;        1-support, 0-no support
;-----------------------------------------------
support_full_write:
        mov eax, 1
        cpuid
        bt ecx, 15                              ; 测试 PDCM 位，是否支持 IA32_PERF_CAPABILITIES
        setc al
        jnc support_full_write_done
        mov ecx, IA32_PERF_CAPABILITIES
        rdmsr
        bt eax, 13                               ; 测试 FW_WRITE 位
        setc al
support_full_write_done:        
        movzx eax, al
        ret

;----------------------------------------------
; write_counter_maximum(): 写入 counter 的最大值
; input:
;       esi-counter
;-----------------------------------------------
write_counter_maximum:
        call support_full_write         ; 是否支持写入最大值
        mov edi, 0FFFFh
        mov edx, 0
        test eax, eax
        cmovnz edx, edi
        mov eax, 0FFFFFFFFh
        mov ecx, esi
        wrmsr
        ret

;---------------------------------------------------
; test_counter_overflow(): 测试是否 counter 发生溢出
; output:
;        1-yes, 0-no
;---------------------------------------------------
test_counter_overflow:
        mov ecx, IA32_PERF_GLOBAL_STATUS
        rdmsr
        test edx, 7                        ; 测试 IA32_FIXED_CTRx 寄存器
        setnz dl
        jnz test_counter_overflow_done
        test eax, 0Fh                        ; 测试 IA32_PMCx 寄存器
        setnz dl
test_counter_overflow_done:
        movzx eax, dl
        ret

;-------------------------------------------------------
; test_pebs_buffer_overflow(): 测试 PEBS buffer 是否溢出
; output:
;        1-yes, 0-no
;-------------------------------------------------------
test_pebs_buffer_overflow:
        mov ecx, IA32_PERF_GLOBAL_STATUS
        rdmsr
        bt edx, 30                        ; 测试 OvfBuffer 位
        setc al
        movzx eax, al
        ret

;-----------------------------------------------
; test_pebs_interrupt(): 测试是否产生 PEBS 中断
; output:
;       1-yes, 0-no
;----------------------------------------------
test_pebs_interrupt:
        mov eax, [pebs_buffer_index]    ; 原 PEBS index 值
        mov esi, [pebs_index_pointer]
        mov esi, [esi]                  ; 读当前 PEBS index 值
        cmp esi, eax
        seta al                         ; 当前 PEBS index 大于原值，就置 1
        movzx eax, al
        ret


;--------------------------------------------------------------------
; reset_pmi_counter_overflow(): 清由 PMI 中断产生的 counter overflow 
;---------------------------------------------------------------------
reset_pmi_counter_overflow:
        mov ecx, IA32_PERF_GLOBAL_STATUS
        rdmsr
        mov esi, eax                    ; 保存 overflow status
        mov ecx, IA32_PEBS_ENABLE
        rdmsr
        and eax, esi                    ; 取 PEBS overflow status
        not eax
        and eax, esi                    ; 取 PMI overflow status
        mov ecx, IA32_PERF_GLOBAL_OVF_CTRL
        mov edx, 0
        wrmsr
        ret


;------------------------------
; 打印 IA32_PERFEVTSELx 寄存器
;-----------------------------
dump_perfevtsel:
        jmp do_dump_perfevtsel
dp_msg1 db '<', 0
dp_msg2 db '>', 0        
dp_msg3 db ' ', 0
do_dump_perfevtsel:        
        push ecx
        push ebx
        xor ebx, ebx
        mov ecx, IA32_PERFEVTSEL0
        mov esi, perfevtsel
        call puts
        
do_dump_perfevtsel_loop:        
        mov esi, dp_msg1
        call puts
        mov esi, ebx
        call print_dword_decimal
        mov esi, dp_msg2
        call puts
        rdmsr
        mov esi, eax
        call print_dword_value
        mov esi, dp_msg3
        call puts
        inc ebx
        inc ecx
        cmp ecx, IA32_PERFEVTSEL3
        jbe do_dump_perfevtsel_loop
        call println
        pop ebx
        pop ecx
        ret

;----------------------------------
; 打印 PMC 寄存器
;----------------------------------
dump_pmc:
        push ecx
        push ebx
        xor ebx, ebx
        mov ecx, IA32_PMC0
        mov esi, pmc
        call puts
        
dump_pmc_loop:        
        mov esi, dp_msg1
        call puts
        mov esi, ebx
        call print_dword_decimal
        mov esi, dp_msg2
        call puts
        rdmsr
        mov esi, eax
        mov edi, edx
        call print_qword_value
        mov esi, dp_msg3
        call puts
        inc ebx
        inc ecx
        cmp ecx, IA32_PMC3
        jbe dump_pmc_loop
        call println
        pop ebx
        pop ecx
        ret
        
;----------------------------
; 打印 Fixed-function counter
;----------------------------
dump_fixed_pmc:
        push ecx
        push ebx
        xor ebx, ebx
        mov ecx, IA32_FIXED_CTR0
        mov esi, fixed_pmc
        call puts
        
dump_fixed_pmc_loop:        
        mov esi, dp_msg1
        call puts
        mov esi, ebx
        call print_dword_decimal
        mov esi, dp_msg2
        call puts
        rdmsr
        mov esi, eax
        mov edi, edx
        call print_qword_value
        mov esi, dp_msg3
        call puts
        inc ebx
        inc ecx
        cmp ecx, IA32_FIXED_CTR2
        jbe dump_fixed_pmc_loop
        call println
        pop ebx
        pop ecx
        ret

;--------------------------
;打印 fixed counter control
;---------------------------
dump_fixed_counter_control:
        mov esi, fixed_ctr_ctrl
        call puts
        mov ecx, IA32_FIXED_CTR_CTRL
        rdmsr
        mov esi, eax
        mov edi, edx
        call print_qword_value
        call println
        ret

;----------------------------------
; 打印 IA32_PERF_GLOBAL_CTRL 寄存器
;----------------------------------
dump_perf_global_ctrl:
dump_perfmon_global_ctrl:
        mov esi, perfmon_global_ctrl
        call puts
        mov ecx, IA32_PERF_GLOBAL_CTRL
        rdmsr
        mov esi, eax
        mov edi, edx
        call print_qword_value
        call println
        ret

;----------------------------------
; 打印 IA32_PERF_GLOBAL_STATUS 寄存器
;----------------------------------        
dump_perf_global_status:
dump_perfmon_global_status:
        mov esi, perfmon_global_status
        call puts
        mov ecx, IA32_PERF_GLOBAL_STATUS
        rdmsr
        mov esi, eax
        mov edi, edx
        call print_qword_value
        call println
        ret        
;----------------------------------
; 打印 IA32_PERF_GLOBAL_OVF 寄存器
;----------------------------------
dump_perf_global_ovf_ctrl:
dump_perfmon_global_ovf:
        mov esi, perfmon_global_ovf
        call puts
        mov ecx, IA32_PERF_GLOBAL_OVF_CTRL
        rdmsr
        mov esi, eax
        mov edi, edx
        call print_qword_value
        call println
        ret

;----------------------------------
; 打印所有 performace monitor 寄存器
;----------------------------------
dump_perfmon:
        call dump_perfevtsel
        call dump_pmc
        call dump_fixed_pmc
        call dump_fixed_counter_control
        call dump_perfmon_global_ctrl
        call dump_perfmon_global_status
        call dump_perfmon_global_ovf
        ret                        


;; **** 数据区 *******

; 下面定义保存 performance monitor 相关的寄存器值
perf_global_ctrl_value          dq 0
perf_global_status_value        dq 0




perfevtsel                      db 'PERFEVTSEL: ', 0
pmc                             db 'PMC: ', 0
fixed_pmc                       db 'FIXED_PMC: ', 0
fixed_ctr_ctrl                  db 'FIXED_CTR_CTRL:       ', 0
perfmon_global_ctrl             db 'PERF_GLOBAL_CTRL:     ', 0
perfmon_global_status           db 'PERF_GLOBAL_STATUS:   ', 0
perfmon_global_ovf              db 'PERF_GLOBAL_OVF_CTRL: ', 0