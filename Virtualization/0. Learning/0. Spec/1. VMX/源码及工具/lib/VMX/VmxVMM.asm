;*************************************************
;* VmxVMM.asm                                    *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************



        
        


;-----------------------------------------------------------------------
; VmmEntry()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 这里 VMM 监控例程
;-----------------------------------------------------------------------  
VmmEntry:
        ;;
        ;; 回到 host 环境, 清 CPU_STATUS_GUEST 位
        ;;
%ifdef __X64
        DB 65h                          ; GS
        DB 81h, 24h, 25h                ; AND mem, imme32
        DD PCB.ProcessorStatus
        DD ~CPU_STATUS_GUEST
        DB 65h
        DB 81h, 0Ch, 25h
        DD PCB.ProcessorStatus
        DD CPU_STATUS_VMM               ; or DWORD [gs: PCB.ProcessorStatus], CPU_STATUS_VMM
%else
        and DWORD [gs: PCB.ProcessorStatus], ~CPU_STATUS_GUEST
        or DWORD [gs: PCB.ProcessorStatus], CPU_STATUS_VMM
%endif

        ;;
        ;; VM-exit 后, 必须保存 guest context 信息
        ;;
        call store_guest_context

        push ebp

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        
        
        DEBUG_RECORD         "[VM-exit]: return back to VMM !"          ; 插入 debug 记录点
        
        call update_guest_context                                       ; 更新 debug 记录中的 guest context

        
        
        ;;
        ;; 读取 VM-exit information 字段
        ;;
        call store_exit_info
        
        ;;
        ;; 传给 DoProcess 函数的参数
        ;;
        REX.Wrxb
        mov eax, [ebp + PCB.CurrentVmbPointer]
        mov esi, [eax + VMB.DoProcessParam]

        ;;
        ;; 读取 VM-exit 原因码, 转入执行相应的处理例程
        ;;
        movzx eax, WORD [ebp + PCB.ExitInfoBuf + EXIT_INFO.ExitReason]
        mov eax, [DoVmExitRoutineTable + eax * 4]
        call eax
        
        ;;
        ;; 是否忽略
        ;;
        cmp eax, VMM_PROCESS_IGNORE
        je VmmEntry.done
        
        ;;
        ;; 是否 RESUME, 回到 guest 执行
        ;;
        cmp eax, VMM_PROCESS_RESUME
        je VmmEntry.resume
        
        ;;
        ;; 是否首次 launch 操作
        ;;
        cmp eax, VMM_PROCESS_LAUNCH
        jne VmmEntry.Failure
        
        
        ;;
        ;; 进行 launch 操作
        ;;
        DEBUG_RECORD    "[VMM]: launch to guest !"
        
        call reset_guest_context                        ; 清 guest context 环境
        
%ifdef __X64
        DB 65h                                          ; GS
        DB 81h, 0Ch, 25h                                ; OR mem, imme32
        DD PCB.ProcessorStatus
        DD CPU_STATUS_GUEST
%else        
        or DWORD [gs: PCB.ProcessorStatus], CPU_STATUS_GUEST
%endif
        vmlaunch
        jmp VmmEntry.Failure
        
        
VmmEntry.resume:
        
        DEBUG_RECORD    "[VMM]: resume to guest !"

        ;;
        ;; resume 前, 必须恢复 guest context 信息
        ;;
        call restore_guest_context                      ; 恢复 guest context
        
%ifdef __X64
        DB 65h                                          ; GS
        DB 81h, 0Ch, 25h                                ; OR mem, imme32
        DD PCB.ProcessorStatus
        DD CPU_STATUS_GUEST
%else        
        or DWORD [gs: PCB.ProcessorStatus], CPU_STATUS_GUEST
%endif
        vmresume


                        
VmmEntry.Failure:

%ifdef __X64
        DB 65h                          ; GS
        DB 81h, 24h, 25h                ; AND mem, imme32
        DD PCB.ProcessorStatus
        DD ~CPU_STATUS_GUEST
%else
        and DWORD [gs: PCB.ProcessorStatus], ~CPU_STATUS_GUEST
%endif

        DEBUG_RECORD    "[VMM]: dump VMCS !"
        
        sti
        call dump_vmcs

VmmEntry.done:        
        pop ebp
        ret



;-----------------------------------------------------------------------
; DoExceptionNMI()
; input:
;       none
; output:
;       eax - process code
; 描述: 
;       1) 处理由 exception 或者 NMI 引发的 VM-exit
;-----------------------------------------------------------------------
DoExceptionNMI: 
        push ebp

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        ;;
        ;; 根据向量号调用目标处理例程
        ;;
        movzx eax, BYTE [ebp + PCB.ExitInfoBuf + EXIT_INFO.InterruptionInfo]
        mov eax, [DoExceptionTable + eax * 4]
        call eax

DoExceptionNMI.Done:        
        pop ebp
        ret
        
        



;-----------------------------------------------------------------------
; DoExternalInterrupt()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由外部中断引发的 VM-exit
;-----------------------------------------------------------------------        
DoExternalInterrupt: 
        push ebp
        push ebx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        
        DEBUG_RECORD    "[DoExternalInterrupt]: inject an external-interrupt !"
        
        ;;
        ;; 直接反射外部中断给 guest 处理
        ;;
        mov eax, [ebp + PCB.ExitInfoBuf + EXIT_INFO.InterruptionInfo]
        SetVmcsField    VMENTRY_INTERRUPTION_INFORMATION, eax
        
        mov eax, VMM_PROCESS_RESUME        
        pop ebx
        pop ebx
        ret



;-----------------------------------------------------------------------
; DoTripleFault()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 triple fault 引发的 VM-exit
;----------------------------------------------------------------------- 
DoTripleFault: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        

;-----------------------------------------------------------------------
; DoINIT()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 INIT 信号引发的 VM-exit
;----------------------------------------------------------------------- 
DoINIT:
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        
        GetVmcsField    GUEST_RIP
        cmp eax, 20556h
        mov eax, VMM_PROCESS_RESUME                
        jne DoINIT.done

        call stop_lapic_timer
        mov eax, VMM_PROCESS_DUMP_VMCS         
        
DoINIT.done:
        pop ebp
        ret
        

;-----------------------------------------------------------------------
; DoSIPI()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 SIPI 信号引发的 VM-exit
;----------------------------------------------------------------------- 
DoSIPI: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret



;-----------------------------------------------------------------------
; DoIoSMI()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 I/O SMI 引发的 VM-exit
;----------------------------------------------------------------------- 
DoIoSMI: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret




;-----------------------------------------------------------------------
; DoOtherSMI()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 Other SMI 引发的 VM-exit
;----------------------------------------------------------------------- 
DoOtherSMI:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret




;-----------------------------------------------------------------------
; DoInterruptWindow()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 interrupt-window 引发的 VM-exit
;----------------------------------------------------------------------- 
DoInterruptWindow: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret





;-----------------------------------------------------------------------
; DoNMIWindow()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 NMI window 引发的 VM-exit
;----------------------------------------------------------------------- 
DoNMIWindow: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        

;-----------------------------------------------------------------------
; DoTaskSwitch()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 task switch 引发的 VM-exit
;----------------------------------------------------------------------- 
DoTaskSwitch: 
        push ebp
        push ecx
        push edx
        push ebx

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif        

        DEBUG_RECORD    "[DoTaskSwitch]: the VMM to complete the task switching"
        
        ;;
        ;; 收集任务切换 VM-exit 的相关信息
        ;;
        call GetTaskSwitchInfo        
        
        ;;
        ;; ### VMM 需要模拟处理器的任务切换动作 ###
        ;; 注意: 
        ;;  1) 不能使用事件注入重启任务切换！        
        ;;  2) 这里的"当前"指"旧任务"
        ;;

        mov ecx, [ebp + PCB.GuestExitInfo + TASK_SWITCH_INFO.Source]            ;; 读发起源

        ;;
        ;; step 1: 处理当前的 TSS 描述符
        ;; a) JMP,  IRET 指令发起: 则清 busy 位. 
        ;; b) CALL, 中断或异常发起: 则 busy 位保持不变(原 busy 为 1)
        ;;        
DoTaskSwitch.Step1:
        cmp ecx, TASK_SWITCH_JMP
        je DoTaskSwitch.Step1.ClearBusy
        cmp ecx, TASK_SWITCH_IRET
        jne DoTaskSwitch.Step2              
          
DoTaskSwitch.Step1.ClearBusy:
        ;;
        ;; 清当前 TSS 描述符 busy 位
        ;;
        REX.Wrxb
        mov ebx, [ebp + PCB.GuestExitInfo + TASK_SWITCH_INFO.CurrentTssDesc]
        btr DWORD [ebx + 4], 9
        
        
        ;;
        ;; step 2: 在当前 TSS 里保存 context 信息
        ;;
DoTaskSwitch.Step2:        
        REX.Wrxb
        mov ebx, [ebp + PCB.GuestExitInfo + TASK_SWITCH_INFO.CurrentTss]  ;; 当前 TSS 块
        REX.Wrxb
        mov edx, [ebp + PCB.CurrentVmbPointer]
        REX.Wrxb
        mov edx, [edx + VMB.VsbBase]                                      ;; 当前 VM store block
        
        ;;
        ;; 将 VSB 保存的 guest context 复制到当前 TSS 块
        ;;
        mov eax, [edx + VSB.Rax]
        mov [ebx + TSS32.Eax], eax                                       ;; 保存 eax
        mov eax, [edx + VSB.Rcx]
        mov [ebx + TSS32.Ecx], eax                                       ;; 保存 ecx
        mov eax, [edx + VSB.Rdx]
        mov [ebx + TSS32.Edx], eax                                       ;; 保存 edx
        mov eax, [edx + VSB.Rbx]
        mov [ebx + TSS32.Ebx], eax                                       ;; 保存 ebx
        mov eax, [edx + VSB.Rsp]
        mov [ebx + TSS32.Esp], eax                                       ;; 保存 esp
        mov eax, [edx + VSB.Rbp]
        mov [ebx + TSS32.Ebp], eax                                       ;; 保存 ebp
        mov eax, [edx + VSB.Rsi]
        mov [ebx + TSS32.Esi], eax                                       ;; 保存 esi
        mov eax, [edx + VSB.Rdi]
        mov [ebx + TSS32.Edi], eax                                       ;; 保存 edi
        mov eax, [edx + VSB.Rflags]
        mov [ebx + TSS32.Eflags], eax                                    ;; 保存 eflags
        
        ;;
        ;; 注意: 保存 EIP 时需要加上指令长度
        ;;
        mov eax, [edx + VSB.Rip]
        add eax, [ebp + PCB.GuestExitInfo + TASK_SWITCH_INFO.InstructionLength]
        mov [ebx + TSS32.Eip], eax                                       ;; 保存 eip
                
        ;;
        ;; 读取 guest selector 与 CR3 保存在当前 TSS 里
        ;;
        GetVmcsField    GUEST_CS_SELECTOR
        mov [ebx + TSS32.Cs], ax                                         ;; 保存 cs selector
        GetVmcsField    GUEST_ES_SELECTOR
        mov [ebx + TSS32.Es], ax                                         ;; 保存 es selector
        GetVmcsField    GUEST_DS_SELECTOR
        mov [ebx + TSS32.Ds], ax                                         ;; 保存 ds selector
        GetVmcsField    GUEST_SS_SELECTOR
        mov [ebx + TSS32.Ss], ax                                         ;; 保存 ss selector
        GetVmcsField    GUEST_FS_SELECTOR
        mov [ebx + TSS32.Fs], ax                                         ;; 保存 fs selector
        GetVmcsField    GUEST_GS_SELECTOR
        mov [ebx + TSS32.Gs], ax                                         ;; 保存 gs selector
        GetVmcsField    GUEST_LDTR_SELECTOR
        mov [ebx + TSS32.LdtrSelector], ax                               ;; 保存 ldt selector
        GetVmcsField    GUEST_CR3
        mov [ebx + TSS32.Cr3], eax                                       ;; 保存 cr3

        
        ;;
        ;; step 3: 处理当前 TSS 内的 eflags.NT 标志位
        ;; a) IRET 指令发起: 则清 TSS 内 eflags.NT 位
        ;; b) CALL, JMP, 中断或异常发起: TSS 内 eflags.NT 位保持不变
        ;;        
DoTaskSwitch.Step3:
        cmp ecx, TASK_SWITCH_IRET
        jne DoTaskSwitch.Step4
        ;;
        ;; 清当前 TSS 内的 eflags.NT 位
        ;;
        btr DWORD [ebx + TSS32.Eflags], 14
        
        
        ;;
        ;; step 4: 处理目标 TSS 的 eflags.NT 位
        ;; a) CALL, 中断或异常发起: 置 TSS 内的 eflags.NT 位
        ;; b) IRET, JMP 发起: 保持 TSS 内的 eflags.NT 位不变
        ;;
DoTaskSwitch.Step4:
        REX.Wrxb
        mov ebx, [ebp + PCB.GuestExitInfo + TASK_SWITCH_INFO.NewTaskTss]          ;; 目标 TSS 块
        
        cmp ecx, TASK_SWITCH_CALL
        je DoTaskSwitch.Step4.SetNT
        cmp ecx, TASK_SWITCH_GATE
        jne DoTaskSwitch.Step5

DoTaskSwitch.Step4.SetNT:
        ;;
        ;; 置目标 TSS 的 eflags.NT 位
        ;;
        bts DWORD [ebx + TSS32.Eflags], 14

        ;;
        ;; step 5: 处理目标 TSS 描述符
        ;; a) CALL, JMP, 中断或异常发起: 置 busy 位
        ;; b) IRET 发起: busy 位保持不变
        ;;
DoTaskSwitch.Step5:        
        cmp ecx, TASK_SWITCH_IRET
        je DoTaskSwitch.Step6
        ;;
        ;; 置目标 TSS 描述符 busy 位
        ;;
        REX.Wrxb
        mov ebx, [ebp + PCB.GuestExitInfo + TASK_SWITCH_INFO.NewTaskTssDesc]
        bts DWORD [ebx + 4], 9
        
        ;;
        ;; step 6: 加载目标 TR 寄存器
        ;;
DoTaskSwitch.Step6:        
        REX.Wrxb
        mov edx, [ebp + PCB.GuestExitInfo + TASK_SWITCH_INFO.NewTaskTssDesc]    ;; 目标 TSS 描述符
        mov eax, [ebp + PCB.GuestExitInfo + TASK_SWITCH_INFO.NewTrSelector]     ;; 目标 TSS selector
        
        SetVmcsField    GUEST_TR_SELECTOR, eax
        movzx eax, WORD [edx]                                   ;; 读取 limit
        SetVmcsField    GUEST_TR_LIMIT, eax                     ;; 设置 TR.limit
        movzx eax, WORD [edx + 5]                               ;; 读取 access rights
        and eax, 0F0FFh
        SetVmcsField    GUEST_TR_ACCESS_RIGHTS, eax             ;; 设置 TR access rights
        mov eax, [ebp + PCB.GuestExitInfo + TASK_SWITCH_INFO.NewTaskTssBase]
        SetVmcsField    GUEST_TR_BASE, eax                      ;; 设置 TR base
        
        
        ;;
        ;; step 7: 加载目标任务 context
        ;;
DoTaskSwitch.Step7:
        REX.Wrxb
        mov ebx, [ebp + PCB.GuestExitInfo + TASK_SWITCH_INFO.NewTaskTss]        ;; 目标 TSS 块
        REX.Wrxb
        mov edx, [ebp + PCB.CurrentVmbPointer]
        REX.Wrxb
        mov edx, [edx + VMB.VsbBase]                    ;; 当前 VM store block        
        
        ;;
        ;; 将目标 TSS 内的值复制到当前 VSB 内
        ;;
        mov eax, [ebx + TSS32.Eax]
        mov [edx + VSB.Rax], eax                        ;; 加载 eax     
        mov eax, [ebx + TSS32.Ecx]
        mov [edx + VSB.Rcx], eax                        ;; 加载 ecx
        mov eax, [ebx + TSS32.Edx]
        mov [edx + VSB.Rdx], eax                        ;; 加载 edx
        mov eax, [ebx + TSS32.Ebx]
        mov [edx + VSB.Rbx], eax                        ;; 加载 ebx
        mov eax, [ebx + TSS32.Ebp]
        mov [edx + VSB.Rbp], eax                        ;; 加载 ebp
        mov eax, [ebx + TSS32.Esi]
        mov [edx + VSB.Rsi], eax                        ;; 加载 esi
        mov eax, [ebx + TSS32.Edi]
        mov [edx + VSB.Rdi], eax                        ;; 加载 edi 
        
        ;;
        ;; 设置 guest ESP, EIP, EFLAGS, CR3
        ;;
        mov eax, [ebx + TSS32.Esp]
        SetVmcsField    GUEST_RSP, eax                  ;; 加载 esp 
        mov eax, [ebx + TSS32.Cr3]
        SetVmcsField    GUEST_CR3, eax                  ;; 加载 cr3
        mov eax, [ebx + TSS32.Eip]
        SetVmcsField    GUEST_RIP, eax                  ;; 加载 eip
        mov eax, [ebx + TSS32.Eflags] 
        SetVmcsField    GUEST_RFLAGS, eax               ;; 加载 eflags
        
        ;;
        ;; 加载 SS
        ;;
        mov esi, [ebx + TSS32.Ss]
        call load_guest_ss_register
        cmp eax, TASK_SWITCH_LOAD_STATE_SUCCESS
        jne DoTaskSwitch.Done
        
        ;;
        ;; 加载 CS
        ;;
        mov esi, [ebx + TSS32.Cs]
        call load_guest_cs_register
        cmp eax, TASK_SWITCH_LOAD_STATE_SUCCESS
        jne DoTaskSwitch.Done
        
        ;;
        ;; 加载 ES
        ;;
        mov esi, [ebx + TSS32.Es]
        call load_guest_es_register
        cmp eax, TASK_SWITCH_LOAD_STATE_SUCCESS
        jne DoTaskSwitch.Done
        
        ;;
        ;; 加载 DS
        ;;
        mov esi, [ebx + TSS32.Ds]
        call load_guest_ds_register
        cmp eax, TASK_SWITCH_LOAD_STATE_SUCCESS
        jne DoTaskSwitch.Done
        
        ;;
        ;; 加载 FS
        ;;        
        mov esi, [ebx + TSS32.Fs]
        call load_guest_fs_register
        cmp eax, TASK_SWITCH_LOAD_STATE_SUCCESS
        jne DoTaskSwitch.Done
                
        ;;
        ;; 加载 GS
        ;;
        mov esi, [ebx + TSS32.Gs]
        call load_guest_gs_register        
        cmp eax, TASK_SWITCH_LOAD_STATE_SUCCESS
        jne DoTaskSwitch.Done
        
        ;;
        ;; 加载 LDTR
        ;;        
        mov esi, [ebx + TSS32.LdtrSelector]
        call load_guest_ldtr_register
        cmp eax, TASK_SWITCH_LOAD_STATE_SUCCESS
        jne DoTaskSwitch.Done
                                
        ;;
        ;; step 8: 在目标 TSS 内保存当前 TR selector
        ;;
DoTaskSwitch.Step8:
        mov eax, [ebp + PCB.GuestExitInfo + TASK_SWITCH_INFO.CurrentTrSelector]
        mov [ebx + TSS32.TaskLink], ax                                  ;; 保存 task link

        ;;
        ;; step 9: 设置 CR0.TS 位
        ;;
DoTaskSwitch.Step9:
        GetVmcsField    GUEST_CR0
        or eax, CR0_TS
        SetVmcsField    GUEST_CR0, eax

DoTaskSwitch.Done:
        mov eax, VMM_PROCESS_RESUME
        pop ebx
        pop edx
        pop ecx
        pop ebp
        ret
        




;-----------------------------------------------------------------------
; DoCPUID()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 CPUID 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoCPUID: 
        push ebp
        push ebx
        push ecx
        push edx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif  

        DEBUG_RECORD    '[DoCPUID]: virtualize CPUID!'
        
        REX.Wrxb
        mov ebp, [ebp + PCB.CurrentVmbPointer]
        REX.Wrxb
        mov ebp, [ebp + VMB.VsbBase]
        
        ;;
        ;; 由 VMM 反射一个 CPUID 虚拟化结果给 guest
        ;;
        mov eax, [ebp + VSB.Rax]                                        ; 读取 CPUID 功能号
        cpuid                                                           ; 执行 CPUID 指令
        mov eax, 633h                                                   ; 修改 guest CPU 的型号

        ;;
        ;; 将 CPUID 结果反射给 guest
        ;;        
        REX.Wrxb
        mov [ebp + VSB.Rax], eax
        REX.Wrxb
        mov [ebp + VSB.Rbx], ebx
        REX.Wrxb
        mov [ebp + VSB.Rcx], ecx
        REX.Wrxb
        mov [ebp + VSB.Rdx], edx                        
        
        ;;
        ;; 调整 guest-RIP
        ;;
        call update_guest_rip
        
        mov eax, VMM_PROCESS_RESUME                                     ; 通知 VMM 进行 RESUME 操作
    
        pop edx
        pop ecx
        pop ebx
        pop ebp
        ret




;-----------------------------------------------------------------------
; DoGETSEC()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 GETSEC 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoGETSEC: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret


;-----------------------------------------------------------------------
; DoHLT()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 HLT 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoHLT:
        DEBUG_RECORD    "[DoHLT]: enter HLT state"
        
        ;;
        ;; 将 guest 设置为 HLT 状态
        ;;
        SetVmcsField    GUEST_ACTIVITY_STATE, GUEST_STATE_HLT
        
        mov eax, VMM_PROCESS_RESUME
        ret
        
        
        

;-----------------------------------------------------------------------
; DoINVD()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 INVD 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoINVD:
        ;;
        ;; VMM 直接执行 INVD 指令
        ;;
        invd
        call update_guest_rip
        
        DEBUG_RECORD    "[DoINVD]: execute INVD !"
        
        mov eax, VMM_PROCESS_RESUME
        ret
        
        
        

;-----------------------------------------------------------------------
; DoINVLPG()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 INVLPG 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoINVLPG: 
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif        


        
        DEBUG_RECORD    "[DoINVLPG]: invalidate the cache !"
        
        ;;
        ;; 读取当前 VPID 值
        ;;
        GetVmcsField    CONTROL_VPID
        
        ;;
        ;; INVVPID 描述符
        ;;
        mov [ebp + PCB.InvDesc + INV_DESC.Vpid], eax
        mov DWORD [ebp + PCB.InvDesc + INV_DESC.Dword1], 0
        mov DWORD [ebp + PCB.InvDesc + INV_DESC.Dword3], 0        
        REX.Wrxb
        mov eax, [ebp + PCB.ExitInfoBuf + EXIT_INFO.ExitQualification]
        REX.Wrxb
        mov [ebp + PCB.InvDesc + INV_DESC.LinearAddress], eax
        
        ;;
        ;; 使用刷新类型 individual-address invalidation
        ;;
        mov eax, INDIVIDUAL_ADDRESS_INVALIDATION
        invvpid eax, [ebp + PCB.InvDesc]
        
        call update_guest_rip
        mov eax, VMM_PROCESS_RESUME
        
        pop ebp
        ret



;-----------------------------------------------------------------------
; DoRDPMC()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 RDPMC 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoRDPMC: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        

;-----------------------------------------------------------------------
; DoRDTSC()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 RDTSC 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoRDTSC: 
        DEBUG_RECORD    "[DoRDTSC]: processing RDTSC"
        
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        

;-----------------------------------------------------------------------
; DoRSM()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 RSM 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoRSM: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        

;-----------------------------------------------------------------------
; DoVMCALL()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 VMCALL 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoVMCALL:
        push ebp
        push ebx
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif    
        
        ;LOADv   esi, 0FFFF800081000000h
        ;mov edi, 0
        ;call dump_guest_longmode_paging_structure64
        ;jmp $
        ;REX.Wrxb
        ;mov ebx, [ebp + PCB.CurrentVmbPointer]
        ;REX.Wrxb
        ;mov ebx, [ebx + VMB.VsbBase]
        ;REX.Wrxb
        ;mov esi, [ebx + VSB.Rbx]
        ;call get_system_va_of_guest_os
        ;REX.Wrxb
        ;mov esi, eax
        ;call dump_memory
        
        mov eax, VMM_PROCESS_DUMP_VMCS
        pop ebx
        pop ebp
        ret


;-----------------------------------------------------------------------
; DoVMCLEAR()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 VMCLEAR 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoVMCLEAR: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret



;-----------------------------------------------------------------------
; DoVMLAUNCH()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 VMLAUNCH 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoVMLAUNCH: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        

;-----------------------------------------------------------------------
; DoVMPTRLD()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 VMPTRLD 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoVMPTRLD: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret



;-----------------------------------------------------------------------
; DoVMPTRST()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 VMPTRST 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoVMPTRST: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        
        

;-----------------------------------------------------------------------
; DoVMREAD()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 VMREAD 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoVMREAD: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        

;-----------------------------------------------------------------------
; DoVMRESUME()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 VMRESUME 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoVMRESUME:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        
        
        
;-----------------------------------------------------------------------
; DoVMWRITE()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 VMWRITE 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoVMWRITE: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        

;-----------------------------------------------------------------------
; DoVMXOFF()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 VMXOFF 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoVMXOFF:
        call update_guest_rip
        mov eax, VMM_PROCESS_RESUME
        ret
        
        


;-----------------------------------------------------------------------
; DoVMXON()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 VMXON 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoVMXON: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        
        
        

;-----------------------------------------------------------------------
; DoControlRegisterAccess()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试访问 control 寄存器引发的 VM-exit
;----------------------------------------------------------------------- 
DoControlRegisterAccess: 
        push ebp
        push ebx
        push ecx
        push edx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif        
               
        ;;
        ;; 收集由 MOV-CR VM-exit 的相关信息
        ;;
        call GetMovCrInfo
        
        
        
        ;;
        ;; ### 分析 MOV-CR 指令信息, 有 4 类指令 ###
        ;; 1) MOV to CRn 指令
        ;; 2) MOV from CRn 指令
        ;; 3) CLTS 指令
        ;; 4) LMSW 指令
        ;;          
        mov ecx, [ebp + PCB.GuestExitInfo + MOV_CR_INFO.Type]        

        cmp ecx, CAT_MOV_FROM_CR
        je DoControlRegisterAccess.MovFromCr            ; 处理 MOV from CR 指令
        cmp ecx, CAT_CLTS
        je DoControlRegisterAccess.Clts                 ; 处理 CLTS 指令        
        cmp ecx, CAT_LMSW
        je DoControlRegisterAccess.Lmsw                 ; 处理 LMSW 指令
        
        ;;
        ;; 处理 MOV-to-CR 指令
        ;;        
DoControlRegisterAccess.MovToCr:        
        ;;
        ;; 读取目标控制寄存器ID 与源寄存器值
        ;;
        mov ebx, [ebp + PCB.GuestExitInfo + MOV_CR_INFO.ControlRegisterID]      ; ebx = CRn
        REX.Wrxb
        mov edx, [ebp + PCB.GuestExitInfo + MOV_CR_INFO.Register]               ; edx = register

        ;;
        ;; 分析目标控制寄存器, 并读取源寄存器值
        ;;                
        cmp ebx, 0
        je DoControlRegisterAccess.MovToCr.@0
        cmp ebx, 4
        je DoControlRegisterAccess.MovToCr.@4

        ;;
        ;; ### 处理 MOV-to-CR3 指令 ###
        ;;
        DEBUG_RECORD    "[DoControlRegisterAccess]: processing MOV to CR3"
        
        mov eax, GUEST_CR3
        
        ;;
        ;; 使用 single-context invalidateion, retaining-global 方式刷新 cache
        ;;
        mov ebx, SINGLE_CONTEXT_EXCLUDE_GLOBAL_INVALIDATION
        
DoControlRegisterAccess.MovToCr.SetCr:
        ;;
        ;; 写入目标控制寄存器值
        ;;
        DoVmWrite       eax, [ebp + PCB.GuestExitInfo + MOV_CR_INFO.Register]
        jmp DoControlRegisterAccess.Next


DoControlRegisterAccess.MovToCr.@0:
        ;;
        ;; 处理 MOV-to-CR0 指令
        ;;
        DEBUG_RECORD    "[DoControlRegisterAccess]: processing MOV to CR0"        
        
        ;;
        ;; 读取 CR0 guest/host mask 与 read shadow
        ;;
        DoVmRead        CONTROL_CR0_GUEST_HOST_MASK, [ebp + PCB.ExecutionControlBuf + EXECUTION_CONTROL.Cr0GuestHostMask]
        DoVmRead        CONTROL_CR0_READ_SHADOW, [ebp + PCB.ExecutionControlBuf + EXECUTION_CONTROL.Cr0ReadShadow]
        
        ;;
        ;; 检查由哪个位产生 VM-exit
        ;; 1) X = source ^ ReadShadow
        ;; 2) Y = X & GuestHostMask
        ;; 3) 检查 Y 值
        ;;
        mov eax, edx
        mov esi, [ebp + PCB.ExecutionControlBuf + EXECUTION_CONTROL.Cr0ReadShadow]
        xor eax, esi
        and eax, [ebp + PCB.ExecutionControlBuf + EXECUTION_CONTROL.Cr0GuestHostMask]       
        

        test eax, (CR0_PE | CR0_PG)
        jnz DoControlRegisterAccess.MovToCr.@0.PG_PE
        test eax, CR0_NE
        jnz DoControlRegisterAccess.MovToCr.@0.NE
        test eax, (CR0_CD | CR0_NW)
        jnz DoControlRegisterAccess.MovToCr.@0.CD_NW

DoControlRegisterAccess.MovToCr.@0.PG_PE:
        mov ebx, SINGLE_CONTEXT_INVALIDATION
        jmp DoControlRegisterAccess.Next
        
DoControlRegisterAccess.MovToCr.@0.NE:        
        mov ebx, SINGLE_CONTEXT_INVALIDATION
        jmp DoControlRegisterAccess.Next
                
DoControlRegisterAccess.MovToCr.@0.CD_NW:
        ;;
        ;; 检查 CR0.CD 与 CR0.NW 的设置
        ;; 1) 如果属于 CR0.CD = 0, CR0.NW = 1 时, 直接注入 #GP(0) 异常给 guest OS
        ;;
        mov eax, edx
        and eax, (CR0_CD | CR0_NW)
        cmp eax, CR0_NW
        jne DoControlRegisterAccess.MovToCr.@0.CD_NW.@1
        
        ;;
        ;; 注入 #GP(0) 异常
        ;;
        SetVmcsField    VMENTRY_INTERRUPTION_INFORMATION, INJECT_EXCEPTION_GP
        SetVmcsField    VMENTRY_EXCEPTION_ERROR_CODE, 0
        
        mov eax, VMM_PROCESS_RESUME
        jmp DoControlRegisterAccess.Done
        
DoControlRegisterAccess.MovToCr.@0.CD_NW.@1:
        ;;
        ;; 更新 CR0 寄存器值
        ;;
        and edx, (CR0_CD | CR0_NW)
        mov eax, cr0
        or eax, edx
        mov cr0, eax
                
        ;;
        ;; 设置新的 CR0.CD/CR0.NW 位 read shadow 值
        ;;
        and esi, ~(CR0_CD | CR0_NW)
        or edx, esi
        SetVmcsField    CONTROL_CR0_READ_SHADOW, edx
        
        
        mov ebx, SINGLE_CONTEXT_INVALIDATION
        
        jmp DoControlRegisterAccess.Next


DoControlRegisterAccess.MovToCr.@4:
        ;;
        ;; 使用 single-context invalidateion 方式刷新 cache
        ;;
        mov ebx, SINGLE_CONTEXT_INVALIDATION
        
        DEBUG_RECORD    '[DoControlRegisterAccess]: processing MOV to CR4'   
        jmp DoControlRegisterAccess.Next
        
        
        
        
DoControlRegisterAccess.MovFromCr:
        ;;
        ;; 处理 MOV from CR 指令
        ;;
        ;; 注意: 
        ;; 1) 这里忽略 MOV-from-CR8 指令 !
        ;; 2) 只有 MOV-from-CR3 指令需要处理 !
        ;;        
        
        ;;
        ;; 将源控制寄存器值写入目标寄存器里
        ;;
        REX.Wrxb
        mov esi, [ebp + PCB.GuestExitInfo + MOV_CR_INFO.ControlRegister]
        REX.Wrxb
        mov edi, [ebp + PCB.CurrentVmbPointer]
        REX.Wrxb
        mov edi, [edi + VMB.VsbBase]
        mov eax, [ebp + PCB.GuestExitInfo + MOV_CR_INFO.RegisterID]
        REX.Wrxb
        mov [edi + VSB.Context + eax * 8], esi
                
        jmp DoControlRegisterAccess.Resume


DoControlRegisterAccess.Clts:
        ;;
        ;; 处理由 CLTS 指令引发的 VM-exit
        ;;
        jmp DoControlRegisterAccess.Next

DoControlRegisterAccess.Lmsw:  
        ;;
        ;; 处理 LMSW 指令
        ;;
        jmp DoControlRegisterAccess.Next




DoControlRegisterAccess.Next:        
        ;;
        ;; 刷新 cache
        ;;
        GetVmcsField    CONTROL_VPID
        mov [ebp + PCB.InvDesc + INV_DESC.Vpid], eax
        mov DWORD [ebp + PCB.InvDesc + INV_DESC.Dword1], 0
        mov DWORD [ebp + PCB.InvDesc + INV_DESC.Dword2], 0
        mov DWORD [ebp + PCB.InvDesc + INV_DESC.Dword3], 0

        invvpid ebx, [ebp + PCB.InvDesc]
        
        DEBUG_RECORD    "[DoControlRegisterAccess]: invalidate cache !"

DoControlRegisterAccess.Resume:        
        ;;
        ;; 跳过 MOV-CR 指令
        ;;
        call update_guest_rip
        
        mov eax, VMM_PROCESS_RESUME

DoControlRegisterAccess.Done:        
        pop edx
        pop ecx
        pop ebx
        pop ebp
        ret
        



;-----------------------------------------------------------------------
; DoMovDr()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 MOV-DR 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoMovDr: 
        call update_guest_rip
        mov eax, VMM_PROCESS_RESUME
        ret
        
        
        

;-----------------------------------------------------------------------
; DoIoInstruction()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 I/O 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoIoInstruction:
        push ebp
        push ebx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif

        ;DEBUG_RECORD    "[DoIoInstruction]: ignore execution of I/O instruction !"
        
        call get_io_instruction_info                    ;; 收集 IO 指令信息

        
        ;;
        ;; 执行 IO 处理
        ;;
        call do_guest_io_process
        
        
        ;;
        ;; 跳过 I/O 指令
        ;;
        call update_guest_rip
        
        mov eax, VMM_PROCESS_RESUME        
        pop ebx
        pop ebp
        ret
        
        
        

;-----------------------------------------------------------------------
; DoRDMSR()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 RDMSR 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoRDMSR: 
        push ebp
        push ebx
        push ecx

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        REX.Wrxb
        mov ebx, [ebp + PCB.CurrentVmbPointer]
        REX.Wrxb
        mov ebx, [ebx + VMB.VsbBase]
        
        ;;
        ;; 读取 MSR index
        ;;
        mov ecx, [ebx + VSB.Rcx]
        cmp ecx, IA32_APIC_BASE
        jne DoRDMSR.@1
        
        ;;
        ;; 处理器读 IA32_APIC_BASE
        ;;
        call DoReadMsrForApicBase

DoRDMSR.@1:
        
DoRDMSR.Done:
        mov eax, VMM_PROCESS_RESUME        
        pop ecx
        pop ebx
        pop ebp
        ret
        
        
        

;-----------------------------------------------------------------------
; DoWRMSR()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 WRMSR 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoWRMSR:
        push ebp
        push ebx
        push ecx

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        REX.Wrxb
        mov ebx, [ebp + PCB.CurrentVmbPointer]
        REX.Wrxb
        mov ebx, [ebx + VMB.VsbBase]
        
        ;;
        ;; 读取 MSR index
        ;;
        mov ecx, [ebx + VSB.Rcx]
        cmp ecx, IA32_APIC_BASE
        jne DoWRMSR.@1
        
        ;;
        ;; 处理写 IA32_APIC_BASE 寄存器
        ;;
        call DoWriteMsrForApicBase

DoWRMSR.@1:        
        
DoWRMSR.Done:
        mov eax, VMM_PROCESS_RESUME                
        pop ecx
        pop ebx
        pop ebp
        ret
        
        
        

;-----------------------------------------------------------------------
; DoInvalidGuestState()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由于无效 guest-state 字段导致 VM-entry 失败引发的 VM-exit
;----------------------------------------------------------------------- 
DoInvalidGuestState: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        
        

;-----------------------------------------------------------------------
; DoMSRLoading()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理在加载 guest MSR 出错导致VM-entry失败引发的 VM-exit
;----------------------------------------------------------------------- 
DoMSRLoading: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        

;-----------------------------------------------------------------------
; DoMWAIT()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 MWAIT 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoMWAIT:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        

;-----------------------------------------------------------------------
; DoMTF()
; input:
;       esi - DO process 控制
; output:
;       none
; 描述: 
;       1) 处理由 pending MTF VM-exit 引发的 VM-exit
;----------------------------------------------------------------------- 
DoMTF:
        push ebp
        push ebx
        push edx
        push ecx

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif


        
        ;;
        ;; 如果不需要decode, 则跳过
        ;;
        cmp esi, DO_PROCESS_DECODE
        jne DoMTF.done
        
        
        ;;
        ;; 分析 guest 环境
        ;;        
        mov eax, [ebp + PCB.EntryControlBuf + ENTRY_CONTROL.VmEntryControl]
        mov edx, [ebp + PCB.GuestStateBuf + GUEST_STATE.CsAccessRight]        
        test eax, IA32E_MODE_GUEST
        jz DoMTF.@1
        test edx, SEG_L
        jz DoMTF.@1                
        mov eax, TARGET_CODE64        
        jmp DoMTF.@2
DoMTF.@1: 
        mov eax, TARGET_CODE32       
        test edx, SEG_D
        jnz DoMTF.@2
        mov eax, TARGET_CODE16
DoMTF.@2:
        

        
        REX.Wrxb
        mov ebp, [ebp + PCB.SdaBase]
        REX.Wrxb
        mov ebx, [ebp + SDA.DmbBase]
        
        mov [ebx + DMB.TargetCpuMode], eax

        ;;
        ;; 对 GuestRip 处进行 decode
        ;;        
        mov esi, [ebx + DMB.DecodeEntry]
        test esi, esi
        jz DoMTF.done
        REX.Wrxb
        mov edi, [ebx + DMB.DecodeBufferPtr]
        call Decode
        test eax, DECODE_STATUS_FAILURE
        jnz DoMTF.done
        
        REX.Wrxb
        mov edx, edi
        
        ;;
        ;; 更新 debug record 信息
        ;;
        mov eax, [ebx + DMB.DecodeEntry]
        xor edi, edi
        REX.Wrxb
        mov esi, [ebx + DMB.DecodeBufferPtr]
        call update_append_msg
        
        REX.Wrxb
        mov [ebx + DMB.DecodeBufferPtr], edx
        
        ;;
        ;; 指向 guest 下一条指令
        ;;
        GetVmcsField    GUEST_RIP
        mov [ebx + DMB.DecodeEntry], eax
                        
        mov ecx, VMM_PROCESS_RESUME

DoMTF.done:      
        mov eax, ecx
        pop ecx
        pop edx
        pop ebx
        pop ebp
        ret
        
        
        

;-----------------------------------------------------------------------
; DoMONITOR()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 MONITOR 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoMONITOR: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        

;-----------------------------------------------------------------------
; DoPAUSE()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 PAUSE 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoPAUSE: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        
        

;-----------------------------------------------------------------------
; DoMachineCheck()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 machine check event 引发的 VM-exit
;----------------------------------------------------------------------- 
DoMachineCheck:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        
        

;-----------------------------------------------------------------------
; DoTPRThreshold()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 VPTR 低于 TPR threshold 引发的 VM-exit
;----------------------------------------------------------------------- 
DoTPRThreshold: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        

;-----------------------------------------------------------------------
; DoAPICAccessPage()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由访问 APIC-access page 页面引发的 VM-exit
;----------------------------------------------------------------------- 
DoAPICAccessPage: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        


;-----------------------------------------------------------------------
; DoEOIBitmap()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 EOI exit bitmap 引发的 VM-exit
;----------------------------------------------------------------------- 
DoEOIBitmap: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        
        

;-----------------------------------------------------------------------
; DoGDTR_IDTR()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试访问 GDTR/IDTR 引发的 VM-exit
;----------------------------------------------------------------------- 
DoGDTR_IDTR: 
        push ebp
        push ebx
        push ecx
        push edx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif        


        REX.Wrxb
        lea edx, [ebp + PCB.GuestExitInfo]
        
        ;;
        ;; 收集信息
        ;;
        call GetDescTableRegisterInfo

        xor ebx, ebx
        
DoGDTR_IDTR.GetLinearAddress:        

        ;;
        ;; 计算线性地址值, 分析内存操作数的 base, index 及 scale
        ;;
        test DWORD [edx + INSTRUCTION_INFO.Flags], INSTRUCTION_FLAGS_BASE
        jnz DoGDTR_IDTR.GetLinearAddress.@1        
        
        ;;
        ;; 读取 base 寄存器值
        ;;
        mov esi, [edx + INSTRUCTION_INFO.Base]
        call get_guest_register_value
        REX.Wrxb
        mov ebx, eax

DoGDTR_IDTR.GetLinearAddress.@1:
        test DWORD [edx + INSTRUCTION_INFO.Flags], INSTRUCTION_FLAGS_INDEX
        jnz DoGDTR_IDTR.GetLinearAddress.@2
        
        ;;
        ;; 读取 index 寄存器值
        ;;
        mov esi, [edx + INSTRUCTION_INFO.Index]
        call get_guest_register_value
        
        ;;
        ;; 检查 scale 值
        ;;
        cmp DWORD [edx + INSTRUCTION_INFO.Scale], SCALE_0
        jne DoGDTR_IDTR.GetLinearAddress.Check2
        REX.Wrxb
        lea ebx, [ebx + eax]
        jmp DoGDTR_IDTR.GetLinearAddress.@2
        
DoGDTR_IDTR.GetLinearAddress.Check2:
        cmp DWORD [edx + INSTRUCTION_INFO.Scale], SCALE_2
        jne DoGDTR_IDTR.GetLinearAddress.Check4
        REX.Wrxb
        lea ebx, [ebx + eax * 2]
        jmp DoGDTR_IDTR.GetLinearAddress.@2
        
DoGDTR_IDTR.GetLinearAddress.Check4:
        cmp DWORD [edx + INSTRUCTION_INFO.Scale], SCALE_4
        jne DoGDTR_IDTR.GetLinearAddress.Check8
        REX.Wrxb
        lea ebx, [ebx + eax * 4]
        jmp DoGDTR_IDTR.GetLinearAddress.@2        

DoGDTR_IDTR.GetLinearAddress.Check8:
        cmp DWORD [edx + INSTRUCTION_INFO.Scale], SCALE_8
        jne DoGDTR_IDTR.GetLinearAddress.@2
        REX.Wrxb
        lea ebx, [ebx + eax * 8]
                        
DoGDTR_IDTR.GetLinearAddress.@2:
        ;;
        ;; Linear address = base + index * scale + disp
        ;;
        mov eax, [edx + INSTRUCTION_INFO.Displacement]
        REX.Wrxb
        lea ebx, [ebx + eax]

        ;;
        ;; 分析 address size, 得到最终的线性地址值
        ;;
        mov eax, [edx + INSTRUCTION_INFO.AddressSize]
        cmp eax, INSTRUCTION_ADRS_WORD
        jne DoGDTR_IDTR.GetLinearAddress.CheckAddr32
        
        movzx ebx, bx                                   ;; 16 位地址
        jmp DoGDTR_IDTR.GetLinearAddress.GetHostVa

DoGDTR_IDTR.GetLinearAddress.CheckAddr32:
        cmp eax, INSTRUCTION_ADRS_DWORD
        jne DoGDTR_IDTR.GetLinearAddress.GetHostVa
        
        or ebx, ebx                                    ;; 32 位地址值

DoGDTR_IDTR.GetLinearAddress.GetHostVa:
        ;;
        ;; 得到 host 端虚拟地址
        ;;
        REX.Wrxb
        mov esi, ebx
        call get_system_va_of_guest_os
        REX.Wrxb
        mov ebx, eax
        REX.Wrxb
        test eax, eax
        jnz DoGDTR_IDTR.CheckType
        
        ;;
        ;; 地址无效, 注入 #PF 异常
        ;;
        SetVmcsField    VMENTRY_INTERRUPTION_INFORMATION, INJECT_EXCEPTION_PF
        SetVmcsField    VMENTRY_EXCEPTION_ERROR_CODE, 0
        mov eax, VMM_PROCESS_RESUME
        jmp DoGDTR_IDTR.Done
        
        
DoGDTR_IDTR.CheckType:
        REX.Wrxb
        mov ecx, [ebp + PCB.CurrentVmbPointer]
        
        ;;
        ;; 分析指令: 
        ;; 1) SGDT: 保存 gdt pointer 
        ;; 2) SIDT: 保存 idt pointer
        ;; 3) LGDT: 加载 gdt pointer
        ;; 4) LIDT: 加载 idt pointer
        ;;        
        mov eax, [edx + INSTRUCTION_INFO.Type]
        cmp eax, INSTRUCTION_TYPE_SGDT
        REX.Wrxb
        lea esi, [ecx + VMB.GuestGmb + GGMB.GdtPointer]         
        je DoGDTR_IDTR.SgdtSidt
        cmp eax, INSTRUCTION_TYPE_SIDT
        REX.Wrxb
        lea esi, [ecx + VMB.GuestImb + GIMB.IdtPointer]         
        je DoGDTR_IDTR.SgdtSidt       
        cmp eax, INSTRUCTION_TYPE_LGDT
        je DoGDTR_IDTR.Lgdt
        cmp eax, INSTRUCTION_TYPE_LIDT   
        je DoGDTR_IDTR.Lidt


DoGDTR_IDTR.SgdtSidt:
        ;;
        ;; 处理 SGDT 与 SIDT 指令: 保存 GDT/IDT pointer
        ;;
        mov ax, [esi]
        mov [ebx], ax
        mov eax, [esi + 2]
        mov [ebx + 2], eax

        ;;
        ;; 检查 operand size, 如果是 64 位则写入 10 bytes
        ;;
        cmp DWORD [edx + INSTRUCTION_INFO.OperandSize], INSTRUCTION_OPS_QWORD
        jne DoGDTR_IDTR.Done
        mov eax, [esi + 6]
        mov [ebx + 6], eax
        jmp DoGDTR_IDTR.Done        

        
DoGDTR_IDTR.Lgdt:
        DEBUG_RECORD    "[DoGDTR_IDTR]: load GDTR"
        
        ;;
        ;; 处理 LGDT 指令: 写入 GGMB.GdtPointer 以及加载 guest GDTR
        ;;
        REX.Wrxb
        lea ecx, [ecx + VMB.GuestGmb + GGMB.GdtPointer]
        movzx eax, WORD [ebx]        
        mov [ecx], ax                                           ; 保存 GDTR.limit
        SetVmcsField    GUEST_GDTR_LIMIT, eax                   ; 加载 guest GDTR.limit
        mov eax, [ebx + 2]
        and eax, 00FFFFFFh
        cmp DWORD [edx + INSTRUCTION_INFO.OperandSize], INSTRUCTION_OPS_WORD
        cmovne eax, [ebx + 2]
        cmp DWORD [edx + INSTRUCTION_INFO.OperandSize], INSTRUCTION_OPS_QWORD
        REX.Wrxb
        cmove eax, [ebx + 2]
        REX.Wrxb
        mov [ecx + 2], eax                                      ; 保存 GDTR.base
        SetVmcsField    GUEST_GDTR_BASE, eax                    ; 加载 guest GDTR.base
        jmp DoGDTR_IDTR.Done

DoGDTR_IDTR.Lidt:        
        DEBUG_RECORD    "[DoGDTR_IDTR]: load IDTR"
        
        ;;
        ;; 处理 LIDT 指令: 写入 GIMB.IdtPointer 以及加载 guest IDTR
        ;;
        REX.Wrxb
        lea ecx, [ecx + VMB.GuestImb + GIMB.IdtPointer]
        movzx eax, WORD [ebx]        
        mov [ecx + GIMB.IdtLimit], ax                           ; 保存 guest 原 IDTR.limit

        ;;
        ;; 在 IA-32e 模式下是 1FFh, 否则为 0FFh
        ;;
        GetVmcsField    GUEST_IA32_EFER_FULL
        mov esi, (31 * 8 + 7)
        test eax, EFER_LMA
        mov eax, (31 * 16 + 15)
        cmovz eax, esi
        
        ;;
        ;; 设置 guest IDTR.limit
        ;;        
        SetVmcsField    GUEST_IDTR_LIMIT, eax                  ; 加载 guest IDTR.limit
        mov WORD [ecx + GIMB.HookIdtLimit], ax                 ; 保存 VMM 设置的 IDTR.limit
        mov eax, [ebx + 2]
        and eax, 00FFFFFFh
        cmp DWORD [edx + INSTRUCTION_INFO.OperandSize], INSTRUCTION_OPS_WORD
        cmovne eax, [ebx + 2]
        cmp DWORD [edx + INSTRUCTION_INFO.OperandSize], INSTRUCTION_OPS_QWORD
        REX.Wrxb
        cmove eax, [ebx + 2]
        REX.Wrxb
        mov [ecx + GIMB.IdtBase], eax                           ; 保存 guest 原 IDTR.base
        SetVmcsField    GUEST_IDTR_BASE, eax                    ; 加载 guest IDTR.base
        
DoGDTR_IDTR.Done:
        call update_guest_rip        
        mov eax, VMM_PROCESS_RESUME
        pop edx
        pop ecx
        pop ebx
        pop ebp
        ret
        
        
        

;-----------------------------------------------------------------------
; DoLDTR_TR()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试访问 LDTR/TR 引发的 VM-exit
;----------------------------------------------------------------------- 
DoLDTR_TR: 
        push ebp
        push ebx
        push ecx
        push edx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif        
                
        call GetDescTableRegisterInfo

        REX.Wrxb
        lea edx, [ebp + PCB.GuestExitInfo]
   
        ;;
        ;; 检查操作数类型: 
        ;; 1) 内存操作数, 则获到线性地址值
        ;; 2) 寄存器操作数, 则读取寄存器值
        ;;
        test DWORD [edx + INSTRUCTION_INFO.Flags], INSTRUCTION_FLAGS_REG
        jnz DoLDTR_TR.GetRegister

        xor ebx, ebx

        ;;
        ;; 计算线性地址值, 分析内存操作数的 base, index 及 scale
        ;;
        test DWORD [edx + INSTRUCTION_INFO.Flags], INSTRUCTION_FLAGS_BASE
        jnz DoLDTR_TR.GetLinearAddress.@1        
        
        ;;
        ;; 读取 base 寄存器值
        ;;
        mov esi, [edx + INSTRUCTION_INFO.Base]
        call get_guest_register_value
        REX.Wrxb
        mov ebx, eax

DoLDTR_TR.GetLinearAddress.@1:
        test DWORD [edx + INSTRUCTION_INFO.Flags], INSTRUCTION_FLAGS_INDEX
        jnz DoLDTR_TR.GetLinearAddress.@2
        
        ;;
        ;; 读取 index 寄存器值
        ;;
        mov esi, [edx + INSTRUCTION_INFO.Index]
        call get_guest_register_value
        
        ;;
        ;; 检查 scale 值
        ;;
        cmp DWORD [edx + INSTRUCTION_INFO.Scale], SCALE_0
        jne DoLDTR_TR.GetLinearAddress.Check2
        REX.Wrxb
        lea ebx, [ebx + eax]
        jmp DoLDTR_TR.GetLinearAddress.@2
        
DoLDTR_TR.GetLinearAddress.Check2:
        cmp DWORD [edx + INSTRUCTION_INFO.Scale], SCALE_2
        jne DoLDTR_TR.GetLinearAddress.Check4
        REX.Wrxb
        lea ebx, [ebx + eax * 2]
        jmp DoLDTR_TR.GetLinearAddress.@2
        
DoLDTR_TR.GetLinearAddress.Check4:
        cmp DWORD [edx + INSTRUCTION_INFO.Scale], SCALE_4
        jne DoLDTR_TR.GetLinearAddress.Check8
        REX.Wrxb
        lea ebx, [ebx + eax * 4]
        jmp DoLDTR_TR.GetLinearAddress.@2        

DoLDTR_TR.GetLinearAddress.Check8:
        cmp DWORD [edx + INSTRUCTION_INFO.Scale], SCALE_8
        jne DoLDTR_TR.GetLinearAddress.@2
        REX.Wrxb
        lea ebx, [ebx + eax * 8]
                        
DoLDTR_TR.GetLinearAddress.@2:
        ;;
        ;; Linear address = base + index * scale + disp
        ;;
        mov eax, [edx + INSTRUCTION_INFO.Displacement]
        REX.Wrxb
        lea ebx, [ebx + eax]
        ;;
        ;; 分析 address size, 得到最终的线性地址值
        ;;
        mov eax, [edx + INSTRUCTION_INFO.AddressSize]
        cmp eax, INSTRUCTION_ADRS_WORD
        jne DoLDTR_TR.GetLinearAddress.CheckAddr32
        
        movzx ebx, bx                                   ;; 16 位地址
        jmp DoLDTR_TR.GetLinearAddress.GetHostVa

DoLDTR_TR.GetLinearAddress.CheckAddr32:
        cmp eax, INSTRUCTION_ADRS_DWORD
        jne DoLDTR_TR.GetLinearAddress.GetHostVa
        
        or ebx, ebx                                    ;; 32 位地址值

DoLDTR_TR.GetLinearAddress.GetHostVa:
        ;;
        ;; 读取 selector
        ;;
        REX.Wrxb
        mov esi, ebx
        call get_system_va_of_guest_os
        REX.Wrxb
        mov ebx, eax
        REX.Wrxb
        test eax, eax
        jnz DoLDTR_TR.CheckType

        ;;
        ;; 地址无效, 注入 #PF 异常
        ;;
        SetVmcsField    VMENTRY_INTERRUPTION_INFORMATION, INJECT_EXCEPTION_PF
        SetVmcsField    VMENTRY_EXCEPTION_ERROR_CODE, 0
        mov eax, VMM_PROCESS_RESUME
        jmp DoLDTR_TR.Done
        
DoLDTR_TR.GetRegister:        
        ;;
        ;; 读取寄存器值
        ;;
        mov esi, [edx + INSTRUCTION_INFO.Register]
        call get_guest_register_value
        movzx esi, ax
        

DoLDTR_TR.CheckType:
        ;;
        ;; 检查指令类型
        ;;
        mov eax, [edx + INSTRUCTION_INFO.Type]        
        cmp eax, INSTRUCTION_TYPE_SLDT
        je DoLDTR_TR.Sldt
        cmp eax, INSTRUCTION_TYPE_STR
        je DoLDTR_TR.Str       
        cmp eax, INSTRUCTION_TYPE_LLDT
        mov edi, do_load_ldtr_register
        je DoLDTR_TR.LldtLtr
        cmp eax, INSTRUCTION_TYPE_LTR
        mov edi, do_load_tr_register
        je DoLDTR_TR.LldtLtr


DoLDTR_TR.Sldt:
        ;;
        ;; 处理 SLDT 指令
        ;;
        DEBUG_RECORD    "[DoLDTR_TR]: store LDTR"
        
        GetVmcsField    GUEST_LDTR_SELECTOR
        test DWORD [edx + INSTRUCTION_INFO.Flags], INSTRUCTION_FLAGS_REG
        jnz DoLDTR_TR.Sldt.@1
        mov [ebx], ax
        jmp DoLDTR_TR.Resume
        
DoLDTR_TR.Sldt.@1:        
        mov esi, [edx + INSTRUCTION_INFO.Register]
        mov edi, eax
        call set_guest_register_value
        jmp DoLDTR_TR.Resume
        
DoLDTR_TR.Str:
        ;;
        ;; 处理 STR 指令
        ;;
        DEBUG_RECORD    "[DoLDTR_TR]: store TR"
        
        GetVmcsField    GUEST_TR_SELECTOR
        test DWORD [edx + INSTRUCTION_INFO.Flags], INSTRUCTION_FLAGS_REG
        jnz DoLDTR_TR.Str.@1
        mov [ebx], ax
        jmp DoLDTR_TR.Resume
        
DoLDTR_TR.Str.@1:        
        mov esi, [edx + INSTRUCTION_INFO.Register]
        mov edi, eax
        call set_guest_register_value
        jmp DoLDTR_TR.Resume
        
        
DoLDTR_TR.LldtLtr:        
        ;;
        ;; 处理 LLDT 与 LTR 指令
        ;;
        DEBUG_RECORD    "[DoLDTR_TR]: load LDTR or TR"

        test DWORD [edx + INSTRUCTION_INFO.Flags], INSTRUCTION_FLAGS_REG
        jnz DoLDTR_TR.LldtLtr.@1
        movzx esi, WORD [ebx]        
DoLDTR_TR.LldtLtr.@1:
        call edi
        cmp eax, LOAD_LDTR_TR_SUCCESS
        jne DoLDTR_TR.Done

        
DoLDTR_TR.Resume:
        call update_guest_rip        
  
DoLDTR_TR.Done: 
        mov eax, VMM_PROCESS_RESUME      
        pop edx
        pop ecx
        pop ebx
        pop ebp
        ret
        
        
        

;-----------------------------------------------------------------------
; DoEptViolation()
; input:
;       esi - do process code
; output:
;       eax - VMM process code
; 描述: 
;       1) 处理由 EPT violation 引发的 VM-exit
;----------------------------------------------------------------------- 
DoEptViolaton:
        push ebp
        push edx
        push ebx
        push ecx
        
%ifdef __X64        
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif        

        
        ;;
        ;; 读取发生 EPT violation 的 guest-physical address 值
        ;;
        REX.Wrxb
        mov ebx, [ebp + PCB.ExitInfoBuf + EXIT_INFO.GuestPhysicalAddress]
        
        ;;
        ;; 检查 GPA 是否需要进行额外处理
        ;;
        REX.Wrxb
        mov esi, ebx
        REX.Wrxb
        and esi, ~0FFFh
        call GetGpaHte
        REX.Wrxb
        test eax, eax
        jz DoEptViolaton.next        
        REX.Wrxb
        mov eax, [eax + GPA_HTE.Handler]
        call eax
        
        ;;
        ;; 处理完毕后, 是否需要修复 EPT violation 故障
        ;; a)需要则执行下面的修复工作
        ;; b)否则直接返回
        ;;
        cmp eax, EPT_VIOLATION_FIXING
        jne DoEptViolation.resume
        
DoEptViolaton.next:        
        ;;
        ;; 检查页面是否属于 not-present
        ;; 1) 如果属于 not-present, 则分配物理页面, 进行重新映射
        ;; 2) 如果属于无访问权限时, 修复映射
        ;;
        mov eax, [ebp + PCB.ExitInfoBuf + EXIT_INFO.ExitQualification]
        test eax, (EPT_READ | EPT_WRITE | EPT_EXECUTE) << 3                     ; ExitQualification[5:3]
        jz DoEptViolaton.@0

        DEBUG_RECORD            "[DoEptViolation]: fixing access !"  
        
        ;;
        ;; 下面修复由于访问权限引起的 EPT violation 问题
        ;;
%ifdef __X64        
        REX.Wrxb
        mov esi, ebx                                                            ; guest-physical address
        and eax, 07h                                                            ; 访问类型
        or eax, FIX_ACCESS                                                      ; 进行 FIX_ACCESS 操作
%else
        xor edi, edi
        mov esi, ebx
        mov ecx, eax
        and ecx, 07h
        or ecx, FIX_ACCESS
%endif
        jmp DoEptViolation.DoMapping


DoEptViolaton.@0:
        ;;
        ;; 从处理器 domain 里分配一个 4K 物理页面
        ;;
        mov esi, 1
        call vm_alloc_pool_physical_page
        
        REX.Wrxb
        test eax, eax
        jz DoEptViolation.done
        

DoEptViolaton.remaping:

        DEBUG_RECORD            "[DoEptViolation]: remaping! (eax = HPA, ebx = GPA)"
        
        ;;
        ;; 下面进行 guest-physical address 映射
        ;; 注意: 这里添加所有访问权限, read/write/execute
        ;; 1) 因为, guest-physical address 访问, 可能会进行多种访问, 需要多种权限
        ;;
%ifdef __X64
        ;;
        ;; rsi - guest-physical address
        ;; rdi - host-physical address
        ;; eax - page attribute
        ;;
        REX.Wrxb
        mov esi, ebx                            ; guest-physical address
        REX.Wrxb
        mov edi, eax                            ; host-physical address
        mov eax, [ebp + PCB.ExitInfoBuf + EXIT_INFO.ExitQualification]
        or eax, EPT_FIXING | FIX_ACCESS | EPT_READ | EPT_WRITE | EPT_EXECUTE
%else
        ;;
        ;; edi:esi - guest-physical address
        ;; edx:eax - host-physical address
        ;; ecx     - page attribute
        ;;
        xor edi, edi
        xor edx, edx
        mov esi, ebx                            ; guest-physical address
        mov ecx, [ebp + PCB.ExitInfoBuf + EXIT_INFO.ExitQualification]
        or ecx, EPT_FIXING | FIX_ACCESS | EPT_READ | EPT_WRITE | EPT_EXECUTE
%endif


DoEptViolation.DoMapping:
        ;;
        ;; 执行 guest-physical address 映射工作
        ;;
        call do_guest_physical_address_mapping
        
        
        ;;
        ;; ### 刷新 cache ###
        ;;
              
        ;;
        ;; INVEPT 描述符
        ;;
        mov DWORD [ebp + PCB.InvDesc + INV_DESC.Dword1], 0
        mov DWORD [ebp + PCB.InvDesc + INV_DESC.Dword2], 0
        mov DWORD [ebp + PCB.InvDesc + INV_DESC.Dword3], 0
        
                
%ifdef __X64
       
        GetVmcsField    CONTROL_EPT_POINTER_FULL
        REX.Wrxb
        mov [ebp + PCB.InvDesc + INV_DESC.Eptp], eax
%else
        GetVmcsField    CONTROL_EPT_POINTER_FULL
        mov [ebp + PCB.InvDesc + INV_DESC.Eptp], eax
        GetVmcsField    CONTROL_EPT_POINTER_HIGH
        mov [ebp + PCB.InvDesc + INV_DESC.Eptp + 4], eax       
%endif    
    
        ;;
        ;; 使用 single-context invalidation 刷新方式
        ;;
        mov eax, SINGLE_CONTEXT_INVALIDATION
        invept eax, [ebp + PCB.InvDesc]
        
        
DoEptViolation.resume:
        mov eax, VMM_PROCESS_RESUME
DoEptViolation.done:        
        pop ecx
        pop ebx
        pop edx
        pop ebp
        ret
        
        
        
        
        

;-----------------------------------------------------------------------
; DoEptMisconfiguration()
; input:
;       none
; output:
;       eax - VMM process code
; 描述: 
;       1) 处理由 EPT misconfiguration 引发的 VM-exit
;----------------------------------------------------------------------- 
DoEptMisconfiguration: 
        push ebp
        push ecx
        push edx
        
        ;;
        ;; 发生 EPT misconfiguration 时, 进行修复工作
        ;;

        REX.Wrxb
        mov esi, [ebp + PCB.ExitInfoBuf + EXIT_INFO.GuestPhysicalAddress]
        

        DEBUG_RECORD            "[DoEptMisconfiguration]: fixing !"
        
        ;;
        ;; 下面进行修复
        ;;
%ifdef __X64
        ;;
        ;; rsi - guest-physical address
        ;; rdi - host-physical address
        ;; eax - page attribute
        ;;
        REX.Wrxb
        mov edi, esi        
        mov eax, [ebp + PCB.ExitInfoBuf + EXIT_INFO.ExitQualification]
        or eax, FIX_MISCONF
%else
        ;;
        ;; edi:esi - guest-physical address
        ;; edx:eax - host-physical address
        ;; ecx     - page attribute
        ;;
        xor edi, edi
        xor edx, edx
        mov eax, esi        
        mov ecx, [ebp + PCB.ExitInfoBuf + EXIT_INFO.ExitQualification]
        or ecx, FIX_MISCONF        
%endif
        call do_guest_physical_address_mapping
      
        mov eax, VMM_PROCESS_RESUME

DoEptMisconfiguration.done:        
        pop edx
        pop ecx
        pop ebp
        ret
        
        
        

;-----------------------------------------------------------------------
; DoINVEPT()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 INVEPT 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoINVEPT: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        

;-----------------------------------------------------------------------
; DoRDTSCP()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 RDTSCP 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoRDTSCP: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        


;-----------------------------------------------------------------------
; DoVmxPreemptionTimer()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由VMX-preemption timer 超时引发的 VM-exit
;----------------------------------------------------------------------- 
DoVmxPreemptionTimer: 
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif   

        mov eax, VMM_PROCESS_DUMP_VMCS
        pop ebp
        ret
        
        
        


;-----------------------------------------------------------------------
; DoINVVPID()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 INVVPID 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoINVVPID: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        
        

;-----------------------------------------------------------------------
; DoWBINVD()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 WBINVD 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoWBINVD:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        
        

;-----------------------------------------------------------------------
; DoXSETBV()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理尝试执行 XSETBV 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoXSETBV: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        

;-----------------------------------------------------------------------
; DoAPICWrite()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 APIC-write 引发的 VM-exit
;----------------------------------------------------------------------- 
DoAPICWrite: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        

;-----------------------------------------------------------------------
; DoRDRAND()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 RDRAND 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoRDRAND: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        

;-----------------------------------------------------------------------
; DoINVPCID()
; input:
;       none
; output:
;       none
; 描述: 
;       1)  处理由 INVPCID 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoINVPCID: 
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        

;-----------------------------------------------------------------------
; DoVMFUNC()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理由 VMFUNC 指令引发的 VM-exit
;----------------------------------------------------------------------- 
DoVMFUNC:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret






;**********************************
; 退出处理例程表                   *
;**********************************

DoVmExitRoutineTable:
        DD      DoExceptionNMI, DoExternalInterrupt, DoTripleFault, DoINIT, DoSIPI, DoIoSMI, DoOtherSMI
        DD      DoInterruptWindow, DoNMIWindow, DoTaskSwitch, DoCPUID, DoGETSEC, DoHLT
        DD      DoINVD, DoINVLPG, DoRDPMC, DoRDTSC, DoRSM, DoVMCALL                   
        DD      DoVMCLEAR, DoVMLAUNCH, DoVMPTRLD, DoVMPTRST, DoVMREAD, DoVMRESUME     
        DD      DoVMWRITE, DoVMXOFF, DoVMXON, DoControlRegisterAccess, DoMovDr, DoIoInstruction
        DD      DoRDMSR, DoWRMSR, DoInvalidGuestState, DoMSRLoading, 0, DoMWAIT
        DD      DoMTF, 0, DoMONITOR, DoPAUSE, DoMachineCheck, 0
        DD      DoTPRThreshold, DoAPICAccessPage, DoEOIBitmap, DoGDTR_IDTR, DoLDTR_TR, DoEptViolaton
        DD      DoEptMisconfiguration, DoINVEPT, DoRDTSCP, DoVmxPreemptionTimer, DoINVVPID, DoWBINVD
        DD      DoXSETBV, DoAPICWrite, DoRDRAND, DoINVPCID, DoVMFUNC, 0
