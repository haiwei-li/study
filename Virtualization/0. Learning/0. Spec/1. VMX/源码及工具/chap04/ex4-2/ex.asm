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
        ;; 示例4-2: VMM利用MTF对guest进行单步调试
        ;;
        
        
        
        ;;
        ;; 调度最后一个 CPU 执行 dump_debug_record() 函数
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
TargetCpuVmentry1:       
        push R5
        mov R5, [gs: PCB.Base]

                       
        ;;
        ;; CR0.PG = CR.PE = 1
        ;;
        mov eax, GUEST_FLAG_PE | GUEST_FLAG_PG
        
%ifdef __X64        
        or eax, GUEST_FLAG_IA32E
%endif  
        mov [R5 + PCB.GuestA + VMB.GuestFlags], eax

        ;;
        ;; 初始化 VMCS region
        ;;
        mov DWORD [R5 + PCB.GuestA + VMB.GuestEntry], guest_entry1
        mov DWORD [R5 + PCB.GuestA + VMB.HostEntry], VmmEntry

        ;;
        ;; 分配 guest stack
        ;;
        mov edi, get_user_stack_pointer
        mov esi, get_kernel_stack_pointer
        test eax, GUEST_FLAG_USER
        cmovnz esi, edi
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
        ;; #BP 产生 VM-exit, #DB 保持执行
        ;;     
        SET_EXCEPTION_BITMAP            BP_VECTOR
        CLEAR_EXCEPTION_BITMAP          DB_VECTOR


        mov esi, 60h
        mov edi, foo
        call install_kernel_interrupt_handler     

        SET_PRIMARY_PROCBASED_CTLS      MONITOR_TRAP_FLAG               ; 启用 MTF 调试功能

%if __BITS__ == 64
        mov rax, [fs: SDA.DmbBase]
        mov DWORD [rax + DMB.DecodeEntry], guest_entry1	        	; 起始decode 点设在guest第1条指令
%else
        mov eax, [fs: SDA.DmbBase]
        mov DWORD [eax + DMB.DecodeEntry], guest_entry1
%endif
        ;;
        ;; 需要 VMM 进行解码
        ;;
        mov DWORD [R5 + PCB.GuestA + VMB.DoProcessParam], DO_PROCESS_DECODE

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
        
        
        

foo:
        mov eax, 11
        REX.Wrxb
        iret


        
;-----------------------------------------------------------------------
; guest_entry1():
; input:
;       none
; output:
;       none
; 描述: 
;       1) 这是 guest 的入口点
;-----------------------------------------------------------------------
guest_entry1:
        mov eax, 1
        mov eax, 2
        mov eax, 3
        int 60h
        mov eax, 4
        mov eax, 5
        mov eax, 6
        
        jmp $
        ret        





;----------------------------------------------
; TargetCpuVmentry2()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 调度执行的目标代码
;----------------------------------------------
TargetCpuVmentry2:       
        push R5
        mov R5, [gs: PCB.Base]

                       
        mov eax, GUEST_FLAG_PE | GUEST_FLAG_PG
        
%ifdef __X64        
        or eax, GUEST_FLAG_IA32E
%endif  
        mov DWORD [R5 + PCB.GuestB + VMB.GuestFlags], eax


        ;;
        ;; 初始化 VMCS region
        ;;
        mov DWORD [R5 + PCB.GuestB + VMB.GuestEntry], guest_entry2
        mov DWORD [R5 + PCB.GuestB + VMB.HostEntry], VmmEntry
        
        ;;
        ;; 分配 guest stack
        ;;
        mov edi, get_user_stack_pointer
        mov esi, get_kernel_stack_pointer
        test eax, GUEST_FLAG_USER
        cmovnz R6, R7
        call R6        
        mov [R5 + PCB.GuestB + VMB.GuestStack], R0
       

        ;;
        ;; 初始化 VMCS buffer
        ;;
        mov R6, [R5 + PCB.VmcsB]
        call initialize_vmcs_buffer
        
                                
        ;;
        ;; 执行 VMCLEAR 操作
        ;;
        vmclear [R5 + PCB.GuestB]
        jc @1
        jz @1         
        
        ;;
        ;; 加载 VMCS pointer
        ;;
        vmptrld [R5 + PCB.GuestB]
        jc TargetCpuVmentry1.@1
        jz TargetCpuVmentry1.@1  

        ;;
        ;; 更新当前 VMB 指针
        ;;
        mov R0, [R5 + PCB.VmcsB]
        mov [R5 + PCB.CurrentVmbPointer], R0

        ;;
        ;; 配置 VMCS
        ;;
        call setup_vmcs_region
        call update_system_status
        

        ;;
        ;; #BP 产生 VM-exit, #DB 保持执行
        ;;     
        SET_EXCEPTION_BITMAP            BP_VECTOR
        CLEAR_EXCEPTION_BITMAP          DB_VECTOR
        
        
        ;;
        ;; 进入 guest 环境
        ;;  
        call reset_guest_context
        or DWORD [gs: PCB.ProcessorStatus], CPU_STATUS_GUEST       
        vmlaunch
        
TargetCpuVmentry1.@1:
        call dump_vmcs
        call wait_esc_for_reset
        ret





;-----------------------------------------------------------------------
; guest_entry2():
; input:
;       none
; output:
;       none
; 描述: 
;       1) 这是 guest 2 的入口点
;-----------------------------------------------------------------------
guest_entry2:

        DEBUG_RECORD    "[VM-entry]: switch to guest2 !"         ; 插入 debug 记录点

        mov eax, 5
        mov eax, 6        
        jmp $       
        ret











;-------------------------------------------------
; 
;-------------------------------------------------
do_command:
%if __BITS__ == 64
        push rbx
%else        
        push ebx
%endif

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
        
%if __BITS__ == 64        
        mov [rax + PCB.IpiRoutinePointer], rbx        
        mov esi, [rax + PCB.ApicId]
%else        
        mov [eax + PCB.IpiRoutinePointer], ebx
        mov esi, [eax + PCB.ApicId]        
%endif        
        DEBUG_RECORD         "[command]: sending a NMI message !"
        
        SEND_IPI_TO_PROCESSOR   esi, edi
        jmp do_command.loop
        
        
do_command.vmentry:

        DEBUG_RECORD         "[command]: *** dispatch to CPU for VM-entry *** "
        
        dec al
        movzx eax, al
        mov esi, 1
        cmp eax, [fs: SDA.ProcessorCount]
        cmovb esi, eax
        mov [Ex.TargetCpu], esi
        mov edi, [TargetVmentryRoutine + esi * 4 - 4]
        call goto_processor
        jmp do_command.loop
do_esc:        
        RESET_CPU
        
do_command.done:        
%if __BITS__ == 64
        pop rbx
%else
        pop ebx        
%endif
        ret





Ex.CmdMsg       db '===================<<< press a key to do command >>>=========================', 10
Ex.SysMsg       db '[system command       ]:   reset - <ESC>, Quit - q,     CPUn - <Fn+1>',  10
Ex.VmxEntryMsg  db '[CPU for VM-entry     ]:   CPU1  - 1,     CPUn - n', 10, 
Ex.IpiMsg       db '[Send Message to CPU  ]:   INT   - i,     NMI  - n,     INIT - t,    SIPI - s', 10, 0


Ex.TargetCpu    dd      1
TargetVmentryRoutine    dd      TargetCpuVmentry1, TargetCpuVmentry2, 0



