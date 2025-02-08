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
        ;; 示例4-1: 观察注入事件下, 单步调试与数据断点 #DB 异常的 delivery
        ;; 说明: 
        ;;      1) 打开两个虚拟机, 分别由 CPU1 与 CPU2 执行
        ;;      2) guest1 产生单步调试#DB, 并且pending debug exception
        ;;      3) guest2 产生数据断点#DB, 并且pending debug exception
        ;;

        
        ;;
        ;; 调度最后一个 CPU 执行 dump_debug_record() 函数
        ;;                
        mov esi, [fs: SDA.ProcessorCount]
        dec esi
        mov edi, dump_debug_record
        call dispatch_to_processor


        ;;
        ;; 测试使用的 #BP 与 #DB 例程
        ;;
        mov esi, BP_VECTOR
        mov edi, foo
        call install_kernel_interrupt_handler
        
        mov esi, DB_VECTOR
        mov edi, bar
        call install_kernel_interrupt_handler     
        
               
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
        DEBUG_RECORD    "[#BP]: enter #BP handler !"
        mov eax, 1
        mov eax, 2    
        REX.Wrxb
        iret  


bar:
        DEBUG_RECORD    "[#DB]: enter #DB handler !"
        
%if __BITS__ == 64        
        mov rcx, rax
        mov esi, Ex.Msg0
        call puts
        mov rsi, rcx
        call print_qword_value64
        call println
        mov esi, Ex.Msg1
        call puts
        mov rsi, rsp
        call print_qword_value64

        lock btr DWORD [rsp + 16], 8            ;; 清 TF 
%else
        mov ecx, eax
        mov esi, Ex.Msg0
        call puts
        mov esi, ecx
        call print_dword_value
        call println
        mov esi, Ex.Msg1
        call puts
        mov esi, esp
        call print_dword_value
        
        lock btr DWORD [esp + 8], 8             ;; 清 TF
%endif

        REX.Wrxb
        iret        
        


Ex.Msg0         db 'RAX = ', 0
Ex.Msg1         db 'RSP = ', 0

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
; guest_entry1():
; input:
;       none
; output:
;       none
; 描述: 
;       1) 这是 guest 的入口点
;-----------------------------------------------------------------------
guest_entry1:
        DEBUG_RECORD    "[VM-entry]: switch to guest 1 !"       ; 插入 debug 记录点


        mov ax, ss
        
        ;;
        ;; 打开单步调试
        ;;
        pushf
        bts DWORD [R4], 8                                       ; TF=1
        popf        

        mov ss, ax                                              ; 产生 MOV-SS 阻塞状态
        int3                                                    ; 产生 #BP 异常
        mov eax, 3
        mov eax, 5
        mov eax, 6
        
        hlt
        jmp $-1
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
        DEBUG_RECORD    "[VM-entry]: switch to guest 2 !"       ; 插入 debug 记录点

        ;;
        ;; 设置断点
        ;;      
        mov ax, ss
        mov [R4], ax
        SET_BREAKPOINT  0, BP_READ_WRITE2, R4
                  
        mov ss, [R4]                                            ; 触发数据断点与"blocking by MOV-SS"
        int3                                                    ; 产生 VM-exit
        mov eax, 3
        mov eax, 5
        mov eax, 6
        
        hlt
        jmp $ - 1  
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
        REX.Wrxb
        mov ebx, foo
        
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



