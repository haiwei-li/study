;*************************************************
; ex.asm                                         *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************


;;
;; ex.asm 说明: 
;; 1) ex.asm 是实验例子的源代码文件, 它嵌入在 protected.asm 和 long.asm 文件内
;; 2) ex.asm 是通用模块, 能在 stage2 和 stage3 阶段运行
;;

        ;;
        ;; 加入 ex.asm 模块使用的头文件
        ;;
        %include "ex.inc"
        
        ;;
        ;; 例子 ex3-1: 使用 guest 与 host 相同环境, 测试 guest
        ;;                
        mov esi, [fs: SDA.ProcessorCount]
        dec esi
        mov edi, dump_debug_record
        call dispatch_to_processor

        ;;
        ;; 等待用户选择命令
        ;;
        call do_command        
        

        ;;
        ;; 等待重启
        ;;
        call wait_esc_for_reset

        





;----------------------------------------------
; TargetCpuVmentry()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 调度执行的目标代码
;       2) 此函数让处理器执行 VM-entry 操作
;----------------------------------------------
TargetCpuVmentry:       
        push R5        
        mov R5, [gs: PCB.Base]
                       
        ;;
        ;; CR0.PG = CR.PE = 1
        ;;
        mov eax, GUEST_FLAG_PE | GUEST_FLAG_PG        
%ifdef __X64        
        or eax, GUEST_FLAG_IA32E
%endif  
        mov DWORD [R5 + PCB.GuestA + VMB.GuestFlags], eax

        ;;
        ;; 初始化 VMCS region
        ;;
        mov DWORD [R5 + PCB.GuestA + VMB.GuestEntry], guest_entry
        mov DWORD [R5 + PCB.GuestA + VMB.HostEntry], VmmEntry

        ;;
        ;; 分配 guest stack
        ;;
        mov R7, get_user_stack_pointer
        mov R6, get_kernel_stack_pointer
        test eax, GUEST_FLAG_USER
        cmovnz R6, R7
        call R6        
        mov [R5 + PCB.GuestA + VMB.GuestStack], R0
        
        ;;
        ;; 初始化 VMCS buffer
        ;;
        mov R6, [R5 + PCB.VmcsA]
        call initialize_vmcs_buffer
        
                                
        ;;
        ;; 执行 VMCLEAR 操作
        ;;
        vmclear [R5 + PCB.GuestA]
        jc @1
        jz @1         
        
        ;;
        ;; 加载 VMCS pointer
        ;;
        vmptrld [R5 + PCB.GuestA]
        jc @1
        jz @1  

        ;;
        ;; 更新当前 VMB 指针
        ;;
        mov R0, [R5 + PCB.VmcsA]
        mov [R5 + PCB.CurrentVmbPointer], R0
                
        ;;
        ;; 配置 VMCS
        ;;
        call setup_vmcs_region
        call update_system_status
        
        ;;
        ;; 进入 guest 环境
        ;;  
        call reset_guest_context
        or DWORD [gs: PCB.ProcessorStatus], CPU_STATUS_GUEST        
        vmlaunch
        
@1:       
        call dump_vmcs
        call wait_esc_for_reset
        pop R5
        ret
        
        
        
        
;-----------------------------------------------------------------------
; guest_entry():
; input:
;       none
; output:
;       none
; 描述: 
;       1) 这是 guest 的入口点
;-----------------------------------------------------------------------
guest_entry:
        
        DEBUG_RECORD    "[VM-entry]: switch to guest !"         ; 插入 debug 记录点

        call dump_guest_env                                     ; 打印环境信息
        
        hlt
        jmp $ - 1
        ret        





;-------------------------------------------------
; dump_guest_env()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 输出 guest 部分环境信息
;-------------------------------------------------
dump_guest_env:
        call println
        mov esi, Guest.Cr0Msg
        call puts
        mov R6, cr0
%if __BITS__ == 64
        call print_qword_value64
%else
        call print_dword_value   
%endif
        call println
        mov esi, Guest.Cr4Msg
        call puts
        mov R6, cr4
%if __BITS__ == 64
        call print_qword_value64
%else
        call print_dword_value   
%endif
        call println
        mov esi, Guest.Cr3Msg
        call puts
        mov R6, cr3
%if __BITS__ == 64
        call print_qword_value64
%else
        call print_dword_value   
%endif
        call println
%if __BITS__ == 64
        mov esi, Guest.CsMsg0
%else
        mov esi, Guest.CsMsg1
%endif 
        call puts
        mov si, cs
        call print_word_value
        mov esi, ':'
        call putc
        mov esi, guest_entry
%if __BITS__ == 64
        call print_qword_value64
%else
        call print_dword_value   
%endif
        call println
        
%if __BITS__ == 64
        mov esi, Guest.SsMsg0
%else
        mov esi, Guest.SsMsg1
%endif 
        call puts
        mov si, ss
        call print_word_value
        mov esi, ':'
        call putc
        mov R6, R4
%if __BITS__ == 64
        add R6, 8
        call print_qword_value64
%else
        add R6, 4
        call print_dword_value   
%endif
        
        ret






;-------------------------------------------------
; do_command()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 由 BSP 调用的命令处理器
;-------------------------------------------------
do_command:
        push R5

do_command.loop:        
        mov esi, 2
        mov edi, 0
        call set_video_buffer
        mov esi, Ex.CmdMsg
        call puts
        
        ;;
        ;; 等待按键
        ;;
        call wait_a_key
        
        cmp al, SC_ESC                                          ; 是否为 <ESC>
        je do_esc
        cmp al, SC_Q                                            ; 是否为 <Q>
        je do_command.done
        
        cmp al, SC_1
        jb do_command.@0
        cmp al, SC_0
        jbe do_command.vmentry
        
do_command.@0:
        ;;
        ;; 是否发送 interrupt
        ;;
        cmp al, SC_I
        jne do_command.@1
               
        mov edi, FIXED_DELIVERY | PHYSICAL | IPI_VECTOR
        jmp do_command.@4
        
do_command.@1:
        ;;
        ;; 是否发送 NMI
        ;;
        DEBUG_RECORD         "[command]: you press a N key !"
        
        cmp al, SC_N
        jne do_command.@2
        mov DWORD [fs: SDA.NmiIpiRequestMask], 0
        mov edi, NMI_DELIVERY | PHYSICAL | 02h
        jmp do_command.@4
        
do_command.@2:
        ;;
        ;; 是否发送 INIT
        ;;
        cmp al, SC_T
        jne do_command.@3
        mov edi, INIT_DELIVERY | PHYSICAL
        jmp do_command.@4

do_command.@3:
        ;;
        ;; 是否发送 SIPI
        ;;
        cmp al, SC_S
        jne do_command.loop
        mov edi, SIPI_DELIVERY | PHYSICAL
        
do_command.@4:
        mov esi, [Ex.TargetCpu]
        call get_processor_pcb
        mov DWORD [R0 + PCB.IpiRoutinePointer], 0


        ;;
        ;; 发送 IPI 
        ;;
        SEND_IPI_TO_PROCESSOR   esi, edi
        jmp do_command.loop
        
        
do_command.vmentry:
        DEBUG_RECORD         "[command]: *** dispatch to CPU for VM-entry *** "
        
        ;;
        ;; 发送目标 CPU 进入 guest
        ;;
        dec al
        movzx eax, al
        mov esi, 1
        cmp eax, [fs: SDA.ProcessorCount]
        cmovb esi, eax
        mov [Ex.TargetCpu], esi
        mov edi, [TargetVmentryRoutine + R6 * 4 - 4]
        test edi, edi
        jz do_command.loop
        call goto_processor
        jmp do_command.loop
do_esc:        
        RESET_CPU
        
do_command.done:        
        pop R5
        ret





Ex.CmdMsg       db '===================<<< press a key to do command >>>=========================', 10
Ex.SysMsg       db '[system command       ]:   reset - <ESC>, Quit - q,     CPUn - <Fn+1>',  10
Ex.VmxEntryMsg  db '[CPU for VM-entry     ]:   CPU1  - 1,     CPUn - n', 10, 
Ex.IpiMsg       db '[Send Message to CPU  ]:   INT   - i,     NMI  - n,     INIT - t,    SIPI - s', 10, 0



Guest.Cr0Msg    db 'CR0:', 0
Guest.Cr4Msg    db 'CR4:', 0
Guest.Cr3Msg    db 'CR3:', 0
Guest.CsMsg0    db 'CS:RIP = ', 0
Guest.CsMsg1    db 'CS:EIP = ', 0
Guest.SsMsg0    db 'SS:RSP = ', 0
Guest.SsMsg1    db 'SS:ESP = ', 0

Ex.TargetCpu    dd      1
TargetVmentryRoutine    dd      TargetCpuVmentry, 0

