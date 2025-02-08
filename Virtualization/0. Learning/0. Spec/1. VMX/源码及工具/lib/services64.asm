;*************************************************
;* services64.asm                                *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************



;-----------------------------------------------------
; EXCEPTION_REPORT64()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 打印 context 信息
;-----------------------------------------------------
%macro DO_EXCEPTION_REPORT64 0
        ;;
        ;; 当前栈中有 16 个 GPRs
        ;; rbp 指向栈顶
        ;;
        mov rsi, Services.ProcessorIdMsg
        call puts
        mov esi, [gs: PCB.ProcessorIndex]
        call print_dword_decimal
        mov esi, ':'
        call putc
        bsf ecx, [gs: PCB.ExceptionBitMask]
        btr [gs: PCB.ExceptionBitMask], ecx
        lea rsi, [Services.ExcetpionMsgTable + ecx * 4]
        call puts
        mov rsi, Services.ExceptionReportMsg
        call puts
        mov rsi, Services.CsIpMsg
        call puts
        mov esi, [rbp + 8 * 16 + 8]                     ; CS
        call print_word_value
        mov esi, ':'
        call putc
        mov rsi, [rbp + 8 * 16]                         ; RIP
        call print_qword_value64
        mov esi, ','
        call putc
        mov rsi, Services.ErrorCodeMsg
        call puts
        mov esi, [gs: PCB.ErrorCode]                    ; Error code
        call print_word_value
        call println
        mov rsi, Services.RegisterContextMsg 
        call puts
        
        ;;
        ;; 打印寄存器值
        ;;
        mov rsi, Services.EflagsMsg
        call puts
        mov esi, [rbp + 8 * 16 + 16]                    ; Rflags
        call print_dword_value
        
        ;;
        ;; 是否属于 #PF 异常
        ;;
        cmp ecx, PF_VECTOR
        jne %%0
        mov esi, 08
        call print_space           
        mov esi, Services.Cr2Msg
        call puts
        mov rsi, cr2 
        call print_qword_value64
%%0:              
        call println

        
        mov ecx, 15
        mov rbx, Services64.RegisterMsg
        
%%1:        
        mov rsi, rbx
        call puts
        mov rsi, [rbp + rcx * 8]
        call print_qword_value64
        call print_tab
        add rbx, REG_MSG_LENGTH
        mov rsi, rbx
        call puts
        mov rsi, [rbp + rcx * 8 - 8]
        call print_qword_value64
        call println
        add rbx, REG_MSG_LENGTH
        sub rcx, 2
        jns %%1
        call println
%endmacro
        
        
                
                
;-----------------------------------------------------
; error_code_default_handler64()
; 描述: 
;       1) 需要压入错误码的缺省 handler
;-----------------------------------------------------
error_code_default_handler64:
        ;;
        ;; 取出错误码
        ;;
        pop QWORD [gs: PCB.ErrorCode]


;-----------------------------------------------------
; exception_default_handler()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 缺省的异常服务例程
;       2) 所有缺省异常放入下半部处理
;       3) 下半部允许中断
;-----------------------------------------------------
exception_default_handler64:
        pusha64
        mov rbp, rsp
exception_default_handler64.@0:                
        ;;
        ;; 打印 context 信息
        ;;
        DO_EXCEPTION_REPORT64                           ; 打印异常信息               
        
        ;;
        ;; 等待 <ESC> 键重启
        ;;
        call wait_esc_for_reset
       
        popa64
        iret64
        
        
        

;-----------------------------------------------------
; nmi_handler64()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 由硬件或IPI调用
;-----------------------------------------------------
nmi_handler64:
        pusha64        
        mov rbp, rsp
        ;; 
        ;; 读取处理器index, 判断NMI handler处理方式
        ;; 1) 当处理器index 相应的 RequestMask 位为 1时, 执行 IPI routine
        ;; 2) RequestMask 为 0时, 执行缺省 NMI 例程
        ;;
        mov ecx, [gs: PCB.ProcessorIndex]
        lock btr DWORD [fs: SDA.NmiIpiRequestMask], ecx
        jnc exception02                                 ; 转入执行缺省 NMI 例程
        

        ;;
        ;; 下面调用 IPI routine
        ;;
        mov rax, [fs: SDA.NmiIpiRoutine]
        call rax

        ;;
        ;; 置内部信号有效
        ;;        
        SET_INTERNAL_SIGNAL

        popa64
        iret64
        
        
        
        

;-----------------------------------------------------
; install_kernel_interrupt_handler64()
; input:
;       rsi - vector
;       rdi - interrupt handler
; output:
;       none
; 描述: 
;       1) 安装 kernel 使用的中断例程
;-----------------------------------------------------
install_kernel_interrupt_handler64:
        push rdx
        push rcx
        mov rcx, rdi
        mov rdx, rdi
        shr rdx, 32                                                     ; offset[63:32]
        mov rax, 00008E0000000000h | (KernelCsSelector64 << 16)         ; Interrupt-gate, DPL=0
        and ecx, 0FFFFh                                                 ; offset[15:0]
        or rax, rcx
        and edi, 0FFFF0000h                                             ; offset[31:16]
        shl rdi, 32
        or rax, rdi
        call write_idt_descriptor64
        pop rcx
        pop rdx
        ret




;-----------------------------------------------------
; install_user_interrupt_handler64()
; input:
;       rsi - vector
;       rdi - interrupt handler
; output:
;       none
; 描述: 
;       1) 安装 user 使用的中断例程
;-----------------------------------------------------
install_user_interrupt_handler64:
        push rdx
        push rcx
        mov rcx, rdi
        mov rdx, rdi
        shr rdx, 32                                                     ; offset[63:32]
        mov rax, 0000EE0000000000h | (KernelCsSelector64 << 16)         ; Interrupt-gate, DPL=3
        and ecx, 0FFFFh                                                 ; offset[15:0]
        or rax, rcx
        and edi, 0FFFF0000h                                             ; offset[31:16]
        shl rdi, 32
        or rax, rdi
        call write_idt_descriptor64
        pop rcx
        pop rdx
        ret
        



;-----------------------------------------------------
; setup_sysenter64()
; input:
;       none
; output:
;       none
; 描述: 
;       设置 sysenter 指令使用环境
;-----------------------------------------------------
setup_sysenter64:
        push rdx
        push rcx
        
        xor edx, edx
        mov eax, KernelCsSelector64
        mov [fs: SDA.SysenterCsSelector], ax
        mov ecx, IA32_SYSENTER_CS
        wrmsr
        
        mov rax, [gs: PCB.FastSystemServiceStack]
        test rax, rax
        jnz setup_sysenter64.next
        
        ;;
        ;; 分配一个 kernel stack 以供 SYSENTER 使用
        ;;        
        call get_kernel_stack_pointer               
        mov [gs: PCB.FastSystemServiceStack], rax               ; 保存快速系统服务例程 stack        
        
setup_sysenter64.next:        
        shld rdx, rax, 32
        mov ecx, IA32_SYSENTER_ESP
        wrmsr
        
        mov rax, fast_sys_service_routine
        shld rdx, rax, 32
        mov ecx, IA32_SYSENTER_EIP
        wrmsr
        
        pop rcx
        pop rdx
        ret   
        
        

;-----------------------------------------------------
; timer_8259_handler64()
; input:
;       none
; output:
;       none
; 描述: 
;       1) PIC 8259 的 IRQ0 中断服务例程
;       2) 具体实现在 32 位的 pic8159a.asm 模块里
;-----------------------------------------------------
timer_8259_handler64:
        jmp timer_8259_handler
        




;-----------------------------------------------------
; lapic_timer_handler64:
; input:
;       none
; output:
;       none
; 描述:
;       1) Local APIC 的 timer 处理例程
;-----------------------------------------------------
lapic_timer_handler64:       
        pusha64
     
        mov rbx, [gs: PCB.LsbBase]
        cmp DWORD [rbx + LSB.LapicTimerRequestMask], LAPIC_TIMER_PERIODIC
        jne lapic_timer_handler.next
        
        
        mov eax, [rbx + LSB.Second]
        inc eax                                                 ; 增加秒数
        cmp eax, 60
        jb lapic_timer_handler64.@1
        ;;
        ;; 如果大于 59 秒, 则增加分钟数
        ;;
        mov ecx, [rbx + LSB.Minute]
        inc ecx                                                 ; 增加分钟数
        cmp ecx, 60
        jb lapic_timer_handler64.@0
        ;;
        ;; 如果大于 59 分, 则增加小时数
        ;;
        xor ecx, ecx
        inc DWORD [rbx + LSB.Hour]
        
lapic_timer_handler64.@0:        
        xor eax, eax
        mov [rbx + LSB.Minute], ecx
        
lapic_timer_handler64.@1:
        mov [rbx + LSB.Second], eax


lapic_timer_handler.next:
        inc DWORD [rbx + LSB.LapicTimerCount]

        ;;
        ;; 如果有回调函数, 则执行
        ;;        
        mov rsi, [rbx + LSB.LapicTimerRoutine]
        test rsi, rsi
        jz lapic_timer_handler64.done
        
        call rsi
        
lapic_timer_handler64.done:  
        ;;
        ;; EOI 命令
        ;;
        mov rax, [gs: PCB.LapicBase]
        mov DWORD [rax + EOI], 0
        
        popa64
        iret64
            




                

;-----------------------------------------------------
; local_default_handler64()
;-----------------------------------------------------
local_interrupt_default_handler64:
        push rbx
        mov rbx, [gs: PCB.LapicBase]
        mov DWORD [rbx + EOI], 0
        pop rbx
        iret64


