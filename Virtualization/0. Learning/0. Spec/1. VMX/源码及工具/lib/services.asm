;*************************************************
;* service.asm                                   *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************



;-----------------------------------------------------
; DO_EXCEPTION_REPORT
; input:
;       none
; output:
;       none
; 描述: 
;       1) 实现打印异常信息
;-----------------------------------------------------
%macro DO_EXCEPTION_REPORT 0
        mov esi, Services.ProcessorIdMsg
        call puts
        mov esi, [gs: PCB.ProcessorIndex]
        call print_dword_decimal
        mov esi, ':'
        call putc
        bsf ecx, [gs: PCB.ExceptionBitMask]
        btr [gs: PCB.ExceptionBitMask], ecx
        lea esi, [Services.ExcetpionMsgTable + ecx * 4]
        call puts        
        mov esi, Services.ExceptionReportMsg
        call puts
        mov esi, Services.CsIpMsg
        call puts
        mov esi, [ebp + 8 * 4 + 4]                      ; CS 值
        call print_word_value
        mov esi, ':'
        call putc
        mov esi, [ebp + 8 * 4]                          ; EIP 
        call print_dword_value
        mov esi, ','
        call putc
        mov esi, Services.ErrorCodeMsg
        call puts
        mov esi, [gs: PCB.ErrorCode]                    ; error code
        call print_word_value
        call println
        mov esi, Services.RegisterContextMsg 
        call puts
        
        ;;
        ;; 打印寄存器值
        ;;
        mov esi, Services.EflagsMsg
        call puts
        mov esi, [ebp + 8 * 4 + 8]                      ; eflags
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
        mov esi, cr2 
        call print_dword_value
%%0:              
        call println
        
        
        
        
        mov ecx, 7
        mov ebx, Services.RegisterMsg
%%1:        
        mov esi, ebx
        call puts
        mov esi, [ebp + ecx * 4]
        call print_dword_value
        call println
        add ebx, REG_MSG_LENGTH
        dec ecx
        jns %%1
        
        call println       
        
%endmacro






;-----------------------------------------------------
; MASK_EXCEPTION_BITMAP
; input:
;       none
; output:
;       none
; 描述: 
;       1) 实现 64/32 下的设置 exception bitmap
;       2) 这个宏在 bits 32 下编译
;-----------------------------------------------------
%macro MASK_EXCEPTION_BITMAP    1
        ;;
        ;; 实现指令 or DWORD [gs: PCB.ExceptionBitMask], X
        ;;
        ;;
%if %1 > 0FFh
        %ifdef __STAGE1
                DB 65h, 81h, 0Dh
                DD PCB.ExceptionBitMask
                DD %1
                
        %elifdef __X64
                DB 65h, 81h, 0Ch, 25h
                DD PCB.ExceptionBitMask
                DD %1
        %else
                DB 65h, 81h, 0Dh
                DD PCB.ExceptionBitMask
                DD %1
        %endif
        
%else

        %ifdef __STAGE1
                DB 65h, 83h, 0Dh
                DD PCB.ExceptionBitMask
                DB %1         
        %elifdef __X64
                DB 65h, 83h, 0Ch, 25h
                DD PCB.ExceptionBitMask
                DB %1
        %else
                DB 65h, 83h, 0Dh
                DD PCB.ExceptionBitMask
                DB %1                
        %endif     
        
%endif
%endmacro




;;
;; 定义 64/32 位下的异常处理例程
;;

ExceptionHandlerTable:
        DQ     exception00
        DQ     exception01
        DQ     nmi_handler
        DQ     exception03
        DQ     exception04
        DQ     exception05
        DQ     exception06
        DQ     exception07
        DQ     exception08
        DQ     exception09
        DQ     exception10
        DQ     exception11
        DQ     exception12
        DQ     exception13
        DQ     exception14
        DQ     exception15
        DQ     exception16
        DQ     exception17
        DQ     exception18
        DQ     exception19
        
        
        
        
        
;-----------------------------------------------------
; exception00()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 0 处理例程
;-----------------------------------------------------
exception00:
        MASK_EXCEPTION_BITMAP   (1 << 0)
        jmp exception_default_handler




;-----------------------------------------------------
; exception01()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 1 处理例程
;-----------------------------------------------------        
exception01:
        MASK_EXCEPTION_BITMAP   (1 << 1)
        jmp exception_default_handler


;-----------------------------------------------------
; exception02()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 2 处理例程
;-----------------------------------------------------        
exception02:
        MASK_EXCEPTION_BITMAP   (1 << 2)
        mov ebp, esp  
        jmp exception_default_handler.@0



;-----------------------------------------------------
; nmi_handler32()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 由硬件或IPI调用
;-----------------------------------------------------
nmi_handler32:
        pusha        
        
        ;;
        ;; 读取处理器index, 判断NMI handler处理方式
        ;; 1) 当处理器index 相应的 RequestMask 位为 1时, 执行 IPI routine
        ;; 2) RequestMask 为 0时, 执行缺省的异常处理例程
        ;;        
        mov ecx, [gs: PCB.ProcessorIndex]
        lock btr DWORD [fs: SDA.NmiIpiRequestMask], ecx
        jnc exception02                                 ; 转入缺省异常处理例程


        ;;
        ;; 下面调用 IPI routine
        ;;
        mov eax, [fs: SDA.NmiIpiRoutine]
        call eax

        ;;
        ;; 置内部信号有效
        ;;        
        SET_INTERNAL_SIGNAL        
        
        popa
        iret
        
        
        
                
        
;-----------------------------------------------------
; exception03()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 3 处理例程
;-----------------------------------------------------         
exception03:
        MASK_EXCEPTION_BITMAP   (1 << 3)
        jmp exception_default_handler



;-----------------------------------------------------
; exception04()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 4 处理例程
;-----------------------------------------------------         
exception04:
        MASK_EXCEPTION_BITMAP   (1 << 4)
        jmp exception_default_handler



;-----------------------------------------------------
; exception05()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 5 处理例程
;----------------------------------------------------- 
exception05:
        MASK_EXCEPTION_BITMAP   (1 << 5)
        jmp exception_default_handler



;-----------------------------------------------------
; exception06()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 6 处理例程
;----------------------------------------------------- 
exception06:
        DEBUG_RECORD         "[exception]: enter #UD handler !"
        
        MASK_EXCEPTION_BITMAP   (1 << 6)
        jmp exception_default_handler



;-----------------------------------------------------
; exception07()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 7 处理例程
;----------------------------------------------------- 
exception07:
        MASK_EXCEPTION_BITMAP   (1 << 7)
        jmp exception_default_handler




;-----------------------------------------------------
; exception08()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 8 处理例程
;----------------------------------------------------- 
exception08:
        MASK_EXCEPTION_BITMAP   (1 << 8)
        jmp error_code_default_handler




;-----------------------------------------------------
; exception09()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 9 处理例程
;----------------------------------------------------- 
exception09:
        MASK_EXCEPTION_BITMAP   (1 << 9)
        jmp exception_default_handler



;-----------------------------------------------------
; exception10()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 10 处理例程
;----------------------------------------------------- 
exception10:
        MASK_EXCEPTION_BITMAP   (1 << 10)
        jmp error_code_default_handler


;-----------------------------------------------------
; exception11()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 11 处理例程
;----------------------------------------------------- 
exception11:
        MASK_EXCEPTION_BITMAP   (1 << 11)
        jmp error_code_default_handler



;-----------------------------------------------------
; exception12()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 12 处理例程
;----------------------------------------------------- 
exception12:
        MASK_EXCEPTION_BITMAP   (1 << 12)
        jmp error_code_default_handler



;-----------------------------------------------------
; exception13()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 13 处理例程
;-----------------------------------------------------         
exception13:
        DEBUG_RECORD         "[exception]: enter #GP handler !"
        
        MASK_EXCEPTION_BITMAP   (1 << 13)
        jmp error_code_default_handler



;-----------------------------------------------------
; exception14()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 14 处理例程
;-----------------------------------------------------         
exception14:
        DEBUG_RECORD         "[exception]: enter #PF handler !"

        MASK_EXCEPTION_BITMAP   (1 << 14)
        jmp error_code_default_handler



;-----------------------------------------------------
; exception15()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 15 处理例程
;----------------------------------------------------- 
exception15:
        MASK_EXCEPTION_BITMAP   (1 << 15)
        jmp exception_default_handler
                                                                           


;-----------------------------------------------------
; exception16()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 16 处理例程
;----------------------------------------------------- 
exception16:
        MASK_EXCEPTION_BITMAP   (1 << 16)
        jmp exception_default_handler



;-----------------------------------------------------
; exception17()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 17 处理例程
;----------------------------------------------------- 
exception17:
        MASK_EXCEPTION_BITMAP   (1 << 17)
        jmp error_code_default_handler
             



;-----------------------------------------------------
; exception18()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 18 处理例程
;-----------------------------------------------------                         
exception18:
        MASK_EXCEPTION_BITMAP   (1 << 18)
        jmp exception_default_handler

        
        
;-----------------------------------------------------
; exception19()
; input: 
;       none
; output:
;       none
; 描述: 
;       1) vector 19 处理例程
;----------------------------------------------------- 
exception19:
        MASK_EXCEPTION_BITMAP   (1 << 19)
        jmp exception_default_handler







;-----------------------------------------------------
; error_code_default_handler()
; 描述: 
;       1) 需要压入错误码的缺省 handler
;-----------------------------------------------------
error_code_default_handler32:
        ;;
        ;; pop 出错误码
        ;;
        pop DWORD [gs: PCB.ErrorCode]


;-----------------------------------------------------
; exception_default_handler()
; input:
;       none
; output:
;       none
; 描述: 
;       1)缺省的异常服务例程
;       2)所有缺省的异常处理放在下半部分
;       3)在下半部分中, 允许被中断
;-----------------------------------------------------
exception_default_handler32:
        pusha
        mov ebp, esp
exception_default_handler32.@0:
        ;;
        ;; 打印异常 context 信息, ebp 指向当前栈顶
        ;;
        DO_EXCEPTION_REPORT
        
        ;;
        ;; 等待 <ESC> 键重启
        ;;
        call wait_esc_for_reset
        
        popa
        iret




        


;-----------------------------------------------------------------------
; install_kernel_interrupt_handler()
; input:
;       esi - vector
;       edi - handler
; 描述:
;       在 IDT 里设置描述符, 以供 kernel 权限使用
;-----------------------------------------------------------------------
install_kernel_interrupt_handler32:
        push ebx
        push edx
        mov edx, edi
        movzx eax, WORD [fs: SDA.KernelCsSelector]      ; CS selector
        shl eax, 16
        and edi, 0FFFFh
        or eax, edi
        and edx, 0FFFF0000h
        or edx, 8E00h                                   ; 32-bit Interrupt-gate
        call set_idt_descriptor                         ; 写入 IDT 表
        pop edx
        pop ebx
        ret




;-----------------------------------------------------------------------
; install_user_interrupt_handler32()
; input:
;       esi - vector
;       edi - handler
; 描述:
;       在 IDT 里设置描述符, 以供 user 代码调用
;-----------------------------------------------------------------------
install_user_interrupt_handler32:     
        push ebx
        push edx
        mov edx, edi
        movzx eax, WORD [fs: SDA.KernelCsSelector]      ; CS selector
        shl eax, 16
        and edi, 0FFFFh
        or eax, edi
        and edx, 0FFFF0000h
        or edx, 0EE00h                                  ; 32-bit Interrupt-gate, DPL=3
        call set_idt_descriptor                         ; 写入 IDT 表
        pop edx
        pop ebx   
        ret
        



;-----------------------------------------------------
; setup_sysenter32()
; input:
;       none
; output:
;       none
; 描述: 
;       设置 sysenter 指令使用环境
;-----------------------------------------------------
setup_sysenter32:
        push edx
        push ecx
        xor edx, edx
        movzx eax, WORD [fs: SDA.SysenterCsSelector]
        mov ecx, IA32_SYSENTER_CS
        wrmsr
        
        mov eax, [gs: PCB.FastSystemServiceStack]
        test eax, eax
        jnz setup_sysenter.next
        
        ;;
        ;; 分配一个 kernel stack 以供 SYSENTER 使用
        ;;        
        call get_kernel_stack_pointer               
        mov [gs: PCB.FastSystemServiceStack], eax               ; 保存快速系统服务例程 stack        
        
setup_sysenter.next:        
        mov ecx, IA32_SYSENTER_ESP
        wrmsr
        
        mov eax, fast_sys_service_routine
        xor edx, edx
        mov ecx, IA32_SYSENTER_EIP
        wrmsr
        pop ecx
        pop edx
        ret   



;-----------------------------------------------------
; sys_service_enter()
; input:
;       eax - 系统服务例程号
; 描述:
;       执行 SYSENTER 指令快速切入系统服务例程
;-----------------------------------------------------
sys_service_enter:
        push ecx
        push edx
        REX.Wrxb
        mov ecx, esp                    ; ecx 保存 stack
        mov edx, return_address         ; edx 保存返回地址
        sysenter
return_address:
        pop edx
        pop ecx        
        ret


;------------------------------------------------------------------
; fast_sys_service_routine()
; input:
;       eax - 系统服务例程号
; 描述: 
;       使用于 sysenter/sysexit 版本的系统服务例程
;-------------------------------------------------------------------
fast_sys_service_routine:
        push ecx
        push edx
        REX.Wrxb
        mov eax, [fs: SRT.Entry + eax * 8]
        call eax
        pop edx
        pop ecx
        REX.Wrxb
        sysexit


;------------------------------------------------------------------
; sys_service_routine()
; input:
;       eax - 系统服务例程号
; 描述: 
;       使用于中断调用 本的系统服务例程
;-------------------------------------------------------------------
sys_service_routine:
        push ebp

%ifdef __X64
        LoadFsBaseToRbp
        REX.Wrxb
%else
        mov ebp, [fs: SDA.Base]
%endif        
        mov eax, [ebp + SRT.Entry + eax * 8]
        call eax
        
        pop ebp
        REX.Wrxb
        iret



;--------------------------------------------
; append_system_service_routine()
; input:
;       esi - routine
; output:
;       eax - routine number
;--------------------------------------------
append_system_service_routine:
        push ebp

%ifdef __X64
        LoadFsBaseToRbp
%else
        mov ebp, [fs: SDA.Base]
%endif 
        REX.Wrxb
        mov eax, [ebp + SRT.Index]
        REX.Wrxb
        mov [eax], esi
        add DWORD [ebp + SRT.Index], 8        
        pop ebp
        ret





;--------------------------------------------
; install_system_service_routine()
; input:
;       esi - sys_service number
;       edi - system service routine
; output:
;       eax - routine number
;--------------------------------------------
install_system_service_routine:
        push ebp

%ifdef __X64
        LoadFsBaseToRbp
%else
        mov ebp, [fs: SDA.Base]
%endif 

        and esi, 3Fh
        REX.Wrxb
        mov [ebp + SRT.Entry + esi * 8], edi
        
        pop ebp
        ret


;------------------------------------------------------------------
; init_sys_service_call()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 初始化系统调用表
;------------------------------------------------------------------
init_sys_service_call:
        mov esi, READ_SDA_DATA
        mov edi, read_sda_data
        call install_system_service_routine
        mov esi, READ_PCB_DATA
        mov edi, read_pcb_data
        call install_system_service_routine
        mov esi, WRITE_SDA_DATA
        mov edi, write_sda_data
        call install_system_service_routine        
        mov esi, WRITE_PCB_DATA
        mov edi, write_pcb_data
        call install_system_service_routine    
        mov esi, READ_SYS_DATA
        mov edi, read_sys_data
        call install_system_service_routine       
        mov esi, WRITE_SYS_DATA
        mov edi, write_sys_data
        call install_system_service_routine 
        ret
       



;------------------------------------------------------------------
; read_sda_data()
; input:
;       esi - offset of SDA
; output:
;       eax - data
; 描述: 
;       1) 读取 SDA 数据
;------------------------------------------------------------------
read_sda_data:
        push ebp
%ifdef __X64
        LoadFsBaseToRbp
%else
        mov ebp, [fs: SDA.Base]
%endif  
        jmp read_data_start

;------------------------------------------------------------------
; read_pcb_data()
; input:
;       esi - offset of PCB
; output:
;       eax - data
; 描述: 
;       1) 读取 PCB 数据
;------------------------------------------------------------------
read_pcb_data:
        push ebp       
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif  
        jmp read_data_start


;------------------------------------------------------------------
; write_sda_data()
; input:
;       esi - offset of SDA
;       edi - data
; output:
;       none
; 描述: 
;       1) 写 SDA 数据
;------------------------------------------------------------------
write_sda_data:
        push ebp
%ifdef __X64
        LoadFsBaseToRbp
%else
        mov ebp, [fs: SDA.Base]
%endif 
        jmp write_data_start
        

;------------------------------------------------------------------
; write_pcb_data()
; input:
;       esi - offset of PCB
;       edi - data
; output:
;       none
; 描述: 
;       1) 写 PCB 数据
;------------------------------------------------------------------
write_pcb_data:
        push ebp
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif 
        jmp write_data_start
        



read_data_start:
        mov eax, esi
        and esi, 0FFFFh
        test eax, 10000000h
        jnz read_data_byte
        test eax, 20000000h
        jnz read_data_word
        test eax, 40000000h
        jnz read_data_dword
        
%ifdef __X64        
        test eax, 80000000h
        jnz read_data_qword
%endif        

        REX.Wrxb
        mov eax, [ebp + esi]
        jmp read_write_data.done


write_data_start:
        REX.Wrxb
        mov eax, edi
        mov edi, esi
        and esi, 0FFFFh
        test edi, 10000000h
        jnz write_data_byte
        test edi, 20000000h
        jnz write_data_word
        test edi, 40000000h
        jnz write_data_dword
        
%ifdef __X64        
        test edi, 80000000h
        jnz write_data_qword
%endif        

        REX.Wrxb
        mov [ebp + esi], eax
        jmp read_write_data.done
        
        


read_data_byte:
        movzx eax, BYTE [ebp + esi]
        jmp read_write_data.done

read_data_word:
        movzx eax, WORD [ebp + esi]
        jmp read_write_data.done 

read_data_qword:
        REX.Wrxb
        
read_data_dword:
        mov eax, [ebp + esi]
        jmp read_write_data.done

write_data_byte:
        mov [ebp + esi], al
        jmp read_write_data.done

write_data_word:
        mov [ebp + esi], ax
        jmp read_write_data.done 

write_data_qword:
        REX.Wrxb
        
write_data_dword:
        mov [ebp + esi], eax
        jmp read_write_data.done

read_write_data.done:
        pop ebp
        ret     
        


;------------------------------------------------------------------
; read_sys_data()
; input:
;       esi - address
; output:
;       eax - data
; 描述: 
;       1) 读取系统区域数据
;------------------------------------------------------------------
read_sys_data:
        REX.Wrxb
        mov eax, [esi]
        ret
        
;------------------------------------------------------------------
; write_sys_data()
; input:
;       esi - address
;       edi - data
; output:
;       none
; 描述: 
;       1) 写系统区域数据
;------------------------------------------------------------------
write_sys_data:
        REX.Wrxb
        mov [esi], edi
        ret
        
