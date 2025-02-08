;*************************************************
;* exception.asm                                 *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************


;;
;; 处理由于 Exception 而引发的 VM exit
;;




%if 0

;----------------------------------------------------------
; reflect_exception_to_guest()
; input:
;       none
; output:
;       none
; 描述: 
;       在下面的情况下, VMM 需要 reflect exception 给 guest 执行:
;       1) VM exit 是由于 exception 引发
;       2) exception 的是由于 guest OS 条件而产生的
;----------------------------------------------------------
reflect_exception_to_guest:
        push ebx
        push ecx
        push edx
        push ebp
        mov ebp, esp
        sub esp, 8
        
        ;;
        ;; 当 VM-exit IDT-vectoring information 的 bit31 为 1 时, 说明 VM-exit 产生在 event delivery 过程中
        ;; 那么 reflect exception 由两大情况分别对待:
        ;; 1) 直接 reflect 给 guest
        ;; 2) reflect #DF exception 给 guest
        ;;
        
        ;;
        ;; 读 VM-exit interrupt information 和 VM-exit interrupt error code 值
        ;;
        ReadVmcsRegion VMEXIT_INTERRUPTION_INFORMATION
        mov ebx, eax
        ReadVmcsRegion VMEXIT_INTERRUPTION_ERROR_CODE
        mov ecx, eax        
        
        ;;
        ;; 检查 bit12 位(NMI unblocking due to IRET)
        ;; 1) bit12 为 0 时, 不修改 blocking by NMI 位
        ;; 2) bit12 为 1 时, 检查 VM-exit event 是否为 #DF
        ;; 
        xor esi, esi
        btr ebx, 12
        jnc reflect_exception_to_guest.@0
        cmp bl, 8
        je reflect_exception_to_guest.@0
        
        ;;
        ;; 需要设置 blocking by NMI 位
        ;;
        mov esi, GUEST_BLOCKING_BY_NMI        
 
reflect_exception_to_guest.@0:

        
        ;;
        ;; 并判断 VM exit 是否在 event delivery 过程中产生
        ;; 1) 读 VM eixt IDT-vectoring informationg
        ;; 2) 检查 bit31 是否为 1
        ;; 3) 检查是否属于 hardware exception
        ;;
        ReadVmcsRegion IDT_VECTORING_INFORMATION
        mov edx, eax
        test eax, FIELD_VALID_FLAG
        jz reflect_exception_to_guest.inject
        
        ;;
        ;; 当 IDT-vectoring information 有效时, NMI unblocking due to IRET 位属于 undefined 值
        ;;
        xor esi, esi                                                    ; 清 blocking by NMI 位
        
        ;;
        ;; 检查是否属于 hardware exception(3)
        ;;
        and eax, 700h
        cmp eax, INTERRUPT_TYPE_HARDWARE_EXCEPTION
        jne reflect_exception_to_guest.inject
        
        ;;
        ;; 当原始 event 是 #DF 时, 表明 guest 遇到 triple fault
        ;;
        cmp dl, 8
        jne reflect_exception_to_guest.@1

        ;;
        ;; VMM 将 guest 进入 shutdown 状态
        ;;        
        WriteVmcsRegion GUEST_ACTIVITY_STATE, GUEST_STATE_SHUTDOWN
        
        jmp reflect_exception_to_guest.inject
        
        
        ;;
        ;; 下面的情形之一, 需要 reflect #DF exception 给 guest
        ;; 1) 如果原始 event(记录在 IDT-vectoring 里)和引发 VM-exit 的 event 都是属于 #DE, #TS, #NP, #SS 或 #GP
        ;;   (对应的 vector 为 0, 10, 11, 12, 13)
        ;; 2) 如果原始 event 为 #PF, 并且引发 VM-exit 的 event 为 #PF 或 #DE, #TS, #NP, #SS, #GP
        ;;   (对应的 vector 为 14, 0, 10, 11, 12, 13)
        ;; 上面情形之一表明: event delivery 期间发生了 #DF 异常
        ;;

reflect_exception_to_guest.@1:
       
        ;;
        ;; 原始 event 是否为 contributory exception(0, 10, 11, 12, 13)
        ;;
        cmp dl, 0                                                       ; 检查 #DE
        je reflect_exception_to_guest.@2
        cmp dl, 10                                                      ; 检查 10-13
        jb reflect_exception_to_guest.inject
        cmp dl, 13                         
        jbe reflect_exception_to_guest.@2
        
        ;;
        ;; 原始 event 是否为 #PF
        ;;
        cmp dl, 14                                                      ; 检查 #PF
        jne reflect_exception_to_guest.inject   
                
        
        ;;
        ;; 检查 VM-exit event 是否为 #PF
        ;;       
        cmp bl, 14
        je reflect_exception_to_guest.df
        
reflect_exception_to_guest.@2:
        cmp bl, 0                                                       ; 检查 #DE
        je reflect_exception_to_guest.df
        
        ;;
        ;; 是否 contributory exception(10, 11, 12, 13)
        ;;
        cmp bl, 10                                                      ; 检查 10 - 13
        jb reflect_exception_to_guest.inject
        cmp bl, 13
        ja reflect_exception_to_guest.inject           


reflect_exception_to_guest.df:
        ;;
        ;; 构造一个 #DF 异常的 event injection 信息
        ;; 1) vector = 08h
        ;; 2) interrupt type = hardware exception
        ;; 3) deliver error code = 1
        ;; 4) valid flags = 1
        ;; 5) error code = 0
        ;;
        mov ebx, INTERRUPT_TYPE_HARDWARE_EXCEPTION | 08h | 800h | FIELD_VALID_FLAG
        mov ecx, 0
        
reflect_exception_to_guest.inject:        
        ;;
        ;; 设置 injection 信息: 
        ;; 1) 复制 VM exit interrupt-information 
        ;; 2) 复制 VM exit interrupt error code
        ;;
        WriteVmcsRegion VMENTRY_INTERRUPTION_INFORMATION, ebx
        WriteVmcsRegion VMENTRY_EXCEPTION_ERROR_CODE, ecx

        ;;
        ;; 设置 guest interruptibility state
        ;;                
        ReadVmcsRegion GUEST_INTERRUPTIBILITY_STATE
        or esi, eax
        WriteVmcsRegion GUEST_INTERRUPTIBILITY_STATE, esi
        
reflect_exception_to_guest.done:        
        mov esp, ebp
        pop ebp
        pop edx
        pop ecx
        pop ebx
        ret

%endif


;-----------------------------------------------------------------------
; do_DE()
; input:
;       none
; output:
;       eax - VMM 处理码
; 描述: 
;       1) 处理由 #DE 引发的 VM-exit
;-----------------------------------------------------------------------
do_DE:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret


;-----------------------------------------------------------------------
; do_DB()
; input:
;       none
; output:
;       eax - VMM 处理码
; 描述: 
;       1) 处理由 #DB 引发的 VM-exit
;-----------------------------------------------------------------------
do_DB:
        push ebp
%ifdef __X64 
        LoadGsBaseToRbp
%else
        mov ebp, [gs: SDA.Base]
%endif
        
        ;;
        ;; 反射 #DB 异常
        ;;
        SetVmcsField    VMENTRY_INTERRUPTION_INFORMATION, INJECT_EXCEPTION_DB
        DoVmWrite       VMENTRY_INSTRUCTION_LENGTH, [ebp + PCB.ExitInfoBuf + EXIT_INFO.InstructionLength]
        
        mov eax, VMM_PROCESS_RESUME
        pop ebp
        ret
        



;-----------------------------------------------------------------------
; do_NMI()
; input:
;       none
; output:
;       eax - VMM 处理码
; 描述: 
;       1) 处理由 NMI 引发的 VM-exit
;-----------------------------------------------------------------------
do_NMI:
        push ebp
%ifdef __X64 
        LoadFsBaseToRbp
%else
        mov ebp, [fs: SDA.Base]
%endif

        DEBUG_RECORD    "[do_NMI]: call NMI handler !"

        ;;
        ;; 下面采用, 主动调用 NMI handler 方式在VMM内完成 NMI
        ;;
        int NMI_VECTOR

        ;;
        ;; 下面注入 NMI 让 guest 完成
        ;; 1) 将这种方式更改为 VMM 完成
        ;;
%if 0
        DEBUG_RECORD    "[do_NMI]: inject a NMI event !"
        
        ;;
        ;; 注入 NMI 事件
        ;;       
        SetVmcsField    VMENTRY_INTERRUPTION_INFORMATION, INJECT_NMI
        SetVmcsField    VMENTRY_INSTRUCTION_LENGTH, 0
%endif

        mov eax, VMM_PROCESS_RESUME
        pop ebp
        ret



;-----------------------------------------------------------------------
; do_BP()
; input:
;       none
; output:
;       eax - VMM 处理码
; 描述: 
;       1) 处理由 #BP 引发的 VM-exit
;-----------------------------------------------------------------------
do_BP:
        push ebp
%ifdef __X64 
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif

        DEBUG_RECORD    "[do_BP]: inject a #BP event !"        
        
        ;;
        ;; 反射 #BP 异常
        ;;
        SetVmcsField    VMENTRY_INTERRUPTION_INFORMATION, INJECT_EXCEPTION_BP
        DoVmWrite       VMENTRY_INSTRUCTION_LENGTH, [ebp + PCB.ExitInfoBuf + EXIT_INFO.InstructionLength]
        
        mov eax, VMM_PROCESS_RESUME
        ;mov eax, VMM_PROCESS_DUMP_VMCS
        pop ebp
        ret
        
        

;-----------------------------------------------------------------------
; do_OF()
; input:
;       none
; output:
;       eax - VMM 处理码
; 描述: 
;       1) 处理由 #OF 引发的 VM-exit
;-----------------------------------------------------------------------
do_OF:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret



;-----------------------------------------------------------------------
; do_BR()
; input:
;       none
; output:
;       eax - VMM 处理码
; 描述: 
;       1) 处理由 #BR 引发的 VM-exit
;-----------------------------------------------------------------------
do_BR:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        
;-----------------------------------------------------------------------
; do_UD()
; input:
;       none
; output:
;       eax - VMM 处理码
; 描述: 
;       1) 处理由 #UD 引发的 VM-exit
;-----------------------------------------------------------------------
do_UD:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        


;-----------------------------------------------------------------------
; do_NM()
; input:
;       none
; output:
;       eax - VMM 处理码
; 描述: 
;       1) 处理由 #NM 引发的 VM-exit
;-----------------------------------------------------------------------
do_NM:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        

;-----------------------------------------------------------------------
; do_DF()
; input:
;       none
; output:
;       eax - VMM 处理码
; 描述: 
;       1) 处理由 #DF 引发的 VM-exit
;-----------------------------------------------------------------------
do_DF:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret        
        
        


;-----------------------------------------------------------------------
; do_TS()
; input:
;       none
; output:
;       eax - VMM 处理码
; 描述: 
;       1) 处理由 #TS 引发的 VM-exit
;-----------------------------------------------------------------------
do_TS:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        

;-----------------------------------------------------------------------
; do_NP()
; input:
;       none
; output:
;       eax - VMM 处理码
; 描述: 
;       1) 处理由 #NP 引发的 VM-exit
;-----------------------------------------------------------------------
do_NP:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
                


;-----------------------------------------------------------------------
; do_SS()
; input:
;       none
; output:
;       eax - VMM 处理码
; 描述: 
;       1) 处理由 #SS 引发的 VM-exit
;-----------------------------------------------------------------------
do_SS:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
                
;-----------------------------------------------------------------------
; do_GP()
; input:
;       none
; output:
;       eax - VMM 处理码
; 描述: 
;       1) 处理由 #GP 引发的 VM-exit
;-----------------------------------------------------------------------
do_GP:
        push ebp
        push ebx
        push edx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif        

        DEBUG_RECORD    "[do_GP]..."

        REX.Wrxb
        mov ebx, [ebp + PCB.CurrentVmbPointer]
        
        call get_interrupt_info                 ; 收集中断相关信息
        
        ;;
        ;; 属于 software interrupt, external-interrupt 以及 privileged interrupt 时, 执行中断处理
        ;;
        movzx eax, BYTE [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.InterruptType]
        cmp al, INTERRUPT_TYPE_SOFTWARE
        je do_GP.DoInterrupt
        cmp al, INTERRUPT_TYPE_EXTERNAL
        je do_GP.DoInterrupt
        cmp al, INTERRUPT_TYPE_PRIVILEGE
        je do_GP.DoInterrupt

        ;;
        ;; 反射处理: 
        ;; 1) 当 IDT-vectoring information 记录异常为 #DE, #TS, #NP, #SS 或者 #GP 时, 需要反射 #DF 异常
        ;; 2) 当 IDT-vectoring information 记录异常为 #DF 异常, 需要处理 triple fault
        ;;
        cmp eax, INTERRUPT_TYPE_HARD_EXCEPTION
        jne do_GP.ReflectGp
        mov al, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Vector]
        cmp al, DF_VECTOR
        je do_GP.TripleFalut
        cmp al, DE_VECTOR
        je do_GP.ReflectDf
        cmp al, TS_VECTOR
        je do_GP.ReflectDf
        cmp al, NP_VECTOR
        je do_GP.ReflectDf
        cmp al, SS_VECTOR
        je do_GP.ReflectDf
        cmp al, PF_VECTOR
        je do_GP.ReflectDf
        cmp al, GP_VECTOR
        jne do_GP.ReflectGp

do_GP.ReflectDf:
        mov eax, 0
        mov ecx, INJECT_EXCEPTION_DF
        jmp do_GP.ReflectException
        
do_GP.ReflectGp:
        mov eax, [ebp + PCB.ExitInfoBuf + EXIT_INFO.InterruptionErrorCode]
        mov ecx, INJECT_EXCEPTION_GP
        jmp do_GP.ReflectException

do_GP.TripleFalut:
        DEBUG_RECORD    "triple fault ..."
        mov eax, VMM_PROCESS_DUMP_VMCS
        jmp do_GP.Done1
        
        ;;
        ;; 处理 triple fault 
        ;;        
        SetVmcsField    GUEST_ACTIVITY_STATE, GUEST_STATE_SHUTDOWN
        jmp do_GP.Done

        ;;
        ;; #### 下面 VMM 进行中断的 delivery 处理 ####
        ;;
do_GP.DoInterrupt:        
        DEBUG_RECORD    "process INT instruction"
        
        movzx esi, BYTE [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Vector]
        call do_int_process
        jmp do_GP.Done
        
        
do_GP.ReflectException:        
        SetVmcsField    VMENTRY_EXCEPTION_ERROR_CODE, eax
        SetVmcsField    VMENTRY_INTERRUPTION_INFORMATION, ecx        
        
do_GP.Done:        
        mov eax, VMM_PROCESS_RESUME        
do_GP.Done1:        
        pop edx
        pop ebx
        pop ebp
        ret
        


;-----------------------------------------------------------------------
; do_PF()
; input:
;       none
; output:
;       eax - VMM 处理码
; 描述: 
;       1) 处理由 #PF 引发的 VM-exit
;-----------------------------------------------------------------------
do_PF:
        push ebp
        push ebx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif        
        mov eax, VMM_PROCESS_DUMP_VMCS

        REX.Wrxb
        mov eax, [ebp + PCB.ExitInfoBuf + EXIT_INFO.ExitQualification]
        cmp eax, 410000h
        mov eax, VMM_PROCESS_DUMP_VMCS
        jne do_PF.Done
        
        DEBUG_RECORD    "[do_PF]: restart..."
        
        SetVmcsField    GUEST_RIP, 200BBh
        
        mov eax, VMM_PROCESS_RESUME
do_PF.Done:   
        pop ebx
        pop ebp        
        ret
        


;-----------------------------------------------------------------------
; do_MF()
; input:
;       none
; output:
;       eax - VMM 处理码
; 描述: 
;       1) 处理由 #MF 引发的 VM-exit
;-----------------------------------------------------------------------
do_MF:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
                
                                

;-----------------------------------------------------------------------
; do_AC()
; input:
;       none
; output:
;       eax - VMM 处理码
; 描述: 
;       1) 处理由 #AC 引发的 VM-exit
;-----------------------------------------------------------------------
do_AC:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret



;-----------------------------------------------------------------------
; do_MC()
; input:
;       none
; output:
;       eax - VMM 处理码
; 描述: 
;       1) 处理由 #MC 引发的 VM-exit
;-----------------------------------------------------------------------
do_MC:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
        
                

;-----------------------------------------------------------------------
; do_XM()
; input:
;       none
; output:
;       eax - VMM 处理码
; 描述: 
;       1) 处理由 #XM 引发的 VM-exit
;-----------------------------------------------------------------------
do_XM:
        mov eax, VMM_PROCESS_DUMP_VMCS
        ret
        
                
        
;-----------------------------------------------------------------------
; DoReserved()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 保留的异常
;-----------------------------------------------------------------------
DoReserved:
        ret


;-----------------------------------------------------------------------
; do_int_process()
; input:
;       esi - vector
; output:
;       none
; 描述: 
;       1) 处理中断 delivery 操作
;-----------------------------------------------------------------------
do_int_process:
        push ebp
        push ebx
        push edx
        push ecx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif

        DEBUG_RECORD    "[do_int_process]..."
        
        REX.Wrxb
        mov ebx, [ebp + PCB.CurrentVmbPointer]
        
        mov ecx, esi                                    ; ecx = vector
                        
        ;;
        ;; 检查是否处于 IA-32e 模式
        ;; 1) 是, 处理 IA-32e 模式下的 INT 指令
        ;; 2) 否, 处理 protected 模式下的 INT 指令
        ;;
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.GuestStatus], GUEST_STATUS_LONGMODE
        jnz do_int_process.Longmode

do_int_process.Protected:
        DEBUG_RECORD    "[do_int_process.Protected]..."
        
        ;;
        ;; #### 处理 protected 模式下的 INT 指令执行 ####
        ;;
        shl ecx, 3

        ;;
        ;; step 1: 检查 vector 是否超出 IDT limit
        ;; 1) (vector * 8 + 7) > limit ?
        ;;
        mov edx, ecx
        lea esi, [edx + 7]
        cmp si, [ebx + VMB.GuestImb + GIMB.IdtLimit]        
        jbe do_int_process.Protected.ReadDesc

do_int_process.Gp_vector_11B:
        ;;
        ;; error code = vector | IDT | EXT
        ;;
        mov eax, ecx
        or eax, 3
        mov ecx, INJECT_EXCEPTION_GP
        jmp do_int_process.ReflectException

do_int_process.Gp_vector_10B:
        ;;
        ;; error code = vector | IDT | 0
        ;;
        mov eax, ecx
        or eax, 2
        mov ecx, INJECT_EXCEPTION_GP
        jmp do_int_process.ReflectException

do_int_process.Gp_CsSelector_01B:
do_int_process.Gp_vector_01B:
        ;;
        ;; error code = vector | 0 | EXT
        ;;
        mov eax, ecx
        or eax, 1
        mov ecx, INJECT_EXCEPTION_GP
        jmp do_int_process.ReflectException

do_int_process.Gp_01B:
        mov eax, 1
        mov ecx, INJECT_EXCEPTION_GP
        jmp do_int_process.ReflectException

do_int_process.Np_vector_11B:
        ;;
        ;; error code = vector | 1 | EXT
        ;;
        mov eax, ecx
        or eax, 3
        mov ecx, INJECT_EXCEPTION_NP
        jmp do_int_process.ReflectException
                
do_int_process.Np_CsSelector_01B:
        ;;
        ;; error code = selector | 0 | EXT
        ;;
        mov eax, ecx
        or eax, 1
        mov ecx, INJECT_EXCEPTION_NP
        jmp do_int_process.ReflectException


do_int_process.Protected.ReadDesc:
        ;;
        ;; step 2: 读 IDT 描述符
        ;;
        REX.Wrxb
        add edx, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtBase]
        mov esi, [edx]
        mov edi, [edx + 4]
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc], esi
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 4], edi
                
do_int_process.Protected.CheckType:
        ;;
        ;; step 3: 检查 IDT 描述符是否属于 gate
        ;;
        shr edi, 8
        and edi, 0Fh
        cmp edi, 0101B                                  ; task-gate
        je do_int_process.Protected.CheckPrivilege
        cmp edi, 1110B                                  ; interrupt-gate
        je do_int_process.Protected.CheckPrivilege
        cmp edi, 1111B                                  ; trap-gate
        jne do_int_process.Gp_vector_11B
        
do_int_process.Protected.CheckPrivilege:
        ;;
        ;; step 4: 当属于software-interrupt 时, 检查权限: CPL <= IDT-gate.DPL
        ;;
        movzx eax, BYTE [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.InterruptType]
        cmp eax, INTERRUPT_TYPE_SOFTWARE
        jne do_int_process.Protected.CheckPresent
        
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Cpl] 
        mov esi, [edx + 4]
        shr esi, 13
        and esi, 3
        cmp esi, eax
        jb do_int_process.Gp_vector_10B

do_int_process.Protected.CheckPresent:        
        ;;
        ;; step 5: 检查 gate 是否为 present
        ;;
        test DWORD [edx + 4], (1 << 15)
        jz do_int_process.Np_vector_11B


do_int_process.Protected.GateType:
        ;;
        ;; step 6: 检查 gate 类型
        ;;
        test DWORD [edx + 4], (1 << 9)
        jnz do_int_process.InterruptTrap
        
        ;;
        ;; ### 保留处理 task-gate ###
        ;;
        jmp do_int_process.Done
        

do_int_process.InterruptTrap:
        ;;
        ;; step 7: 检查 code-segment selector 是否为 NULL
        ;;
        movzx ecx, WORD [edx + 2]
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCs], cx
        and ecx, 0FFF8h
        jz do_int_process.Gp_01B
        
        ;;
        ;; step 8: 检查 code-segment selector 是否超出 GDT limit
        ;;
        mov esi, ecx
        add esi, 7
        cmp si, [ebx + VMB.GuestGmb + GGMB.GdtLimit]
        ja do_int_process.Gp_CsSelector_01B
        
        ;;
        ;; step 9: 读取 code-segment 描述符
        ;;
        REX.Wrxb
        mov edx, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.GdtBase]
        mov esi, [edx + ecx]
        mov edi, [edx + ecx + 4]
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc], esi
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 4], edi

     
        ;;
        ;; step 10: 检查描述符 C/D 位, 是否为 code-segment
        ;;
        test edi, (1 << 11)
        jz do_int_process.Gp_CsSelector_01B

        ;;
        ;; step 11: 检查权限: DPL <= CPL
        ;;
        mov esi, edi
        shr esi, 13
        and esi, 3
        cmp si, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Cpl]
        ja do_int_process.Gp_CsSelector_01B

        ;;
        ;; step 12: 检查 code-segment 描述符是否为 present
        ;;
        test edi, (1 << 15)
        jz do_int_process.Np_CsSelector_01B


do_int_process.InterruptTrap.Next:
        ;;
        ;; step 13: 根据权限进行相应处理
        ;;
        ;; 注意:  ### 作为例子, 保留实现对 conforming 类型段的处理 ###
        ;;        ### 作为例子, 保留实现对 virutal-8086 模式下的中断处理 ###
        ;;
        mov eax, do_interrupt_for_inter_privilege
        mov edi, do_interrupt_for_intra_privilege        
        cmp si, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Cpl]
        cmove eax, edi
        mov ecx, do_interrupt_for_inter_privilege_longmode
        mov edi, do_interrupt_for_intra_privilege_longmode
        cmove ecx, edi
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.GuestStatus], GUEST_STATUS_LONGMODE
        cmovnz eax, ecx
        call eax
        jmp do_int_process.Done        
 
        
do_int_process.Longmode:
        ;;
        ;; 处理 longmode 模式下的 INT 指令执行
        ;;
        DEBUG_RECORD    "[do_int_process.Longmode]..."
        
        ;;
        ;; step 1: 检查 vector 是否超出 IDT.limit
        ;;
        shl ecx, 4
        lea esi, [ecx + 15]
        cmp si, [ebx + VMB.GuestImb + GIMB.IdtLimit]
        ja do_int_process.Gp_vector_11B

        ;;
        ;; step 2: 读 IDT 描述符
        ;;
        REX.Wrxb
        mov edx, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtBase]
        REX.Wrxb
        add edx, ecx
        REX.Wrxb
        mov esi, [edx]
        REX.Wrxb
        mov edi, [edx + 8]
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc], esi
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 8], edi

        ;;
        ;; step 3: 检查 IDT 描述符是否属于 interrupt-gate, trap-gate
        ;;
        mov edi, [edx + 4]
        shr edi, 8
        and edi, 0Fh
        cmp edi, 1110B                                  ; interrupt-gate
        je do_int_process.Longmode.CheckPrivilege
        cmp edi, 1111B                                  ; trap-gate
        jne do_int_process.Gp_vector_11B        
        
do_int_process.Longmode.CheckPrivilege:
        ;;
        ;; step 4: 当属于software-interrupt 时, 检查权限: CPL <= IDT-gate.DPL
        ;;
        movzx eax, BYTE [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.InterruptType]
        cmp eax, INTERRUPT_TYPE_SOFTWARE
        jne do_int_process.Longmode.CheckPresent
        
        mov eax, [edx + 4]
        shr eax, 13
        and eax, 3
        cmp al, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Cpl]
        jb do_int_process.Gp_vector_10B

do_int_process.Longmode.CheckPresent:
        ;;
        ;; step 5: 检查 IDT-gate 是否为 present
        ;;
        test DWORD [edx + 4], (1 << 15)
        jnz do_int_process.InterruptTrap

        ;;
        ;; #NP (error code = vector | IDT | EXT)
        ;;
        movzx eax, BYTE [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Vector]
        shl eax, 3
        or eax, 3
        mov ecx, INJECT_EXCEPTION_NP
        
        
do_int_process.ReflectException:        
        ;;
        ;; 注入异常
        ;;
        SetVmcsField    VMENTRY_EXCEPTION_ERROR_CODE, eax
        SetVmcsField    VMENTRY_INTERRUPTION_INFORMATION, ecx
        mov eax, DO_INTERRUPT_ERROR
            
do_int_process.Done:  
        pop ecx
        pop edx
        pop ebx
        pop ebp
        ret
        


;-----------------------------------------------------------------------
; do_interrupt_for_inter_privilege()
; input:
;       esi - privilege level
; output:
;       eax - statusf code
; 描述: 
;       1) 处理 legacy 模式下的特权级内的中断(切入高权限)
;-----------------------------------------------------------------------
do_interrupt_for_inter_privilege:
        push ebp
        push ebx
        push edx
        push ecx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif

        DEBUG_RECORD    "[do_interrupt_for_inter_privilege]..."

        REX.Wrxb
        mov ebx, [ebp + PCB.CurrentVmbPointer]
        mov ecx, esi                                                    ; ecx = privilege level
        
        ;;
        ;; step 1: 检查 TSS 是否为 32-bit
        ;;
        test DWORD [ebx + VMB.GuestTmb + GTMB.TssAccessRights], (1 << 3)
        jnz do_interrupt_for_inter_privilege.Tss32
        
do_interrupt_for_inter_privilege.Tss16:        
        shl ecx, 2
        add ecx, 2
        
        ;;
        ;; step 1: 检查 stack pointer 地址是否超出 TSS limit: (DPL << 2) + 2 + 3 > limit ?
        ;; 1) 超出 limit, 则产生 #TS(TSS_selector, 0, EXT)
        ;;
        lea esi, [ecx + 3]
        cmp esi, [ebx + VMB.GuestTmb + GTMB.TssLimit]
        ja do_interrupt_for_inter_privilege.Ts_TssSelector_01B
        
do_interrupt_for_inter_privilege.ReadStack16:        
        ;;
        ;; step 2: 读取中断 handler 使用的 stack pointer
        ;;
        REX.Wrxb
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TssBase]            
        movzx esi, WORD [eax + ecx]                                             ;; new SP
        movzx ecx, WORD [eax + ecx + 2]                                         ;; new SS(ecx)
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSs], cx             ;; 保存 SS
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp], esi           ;; 保存目标 RSP        
        call get_system_va_of_guest_os
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Rsp], eax                 ;; 保存 RSP        
        jmp do_interrupt_for_inter_privilege.CheckSsSelector       
        
do_interrupt_for_inter_privilege.Tss32:
        shl ecx, 3
        add ecx, 4

        ;;
        ;; step 1: 检查 stack pointer 地址是否超出 TSS limit
        ;; 1)  (DPL << 3) + 4 + 5 > limit 则产生 #TS(TSS_selector, 0, EXT)
        ;;
        lea esi, [ecx + 5]
        cmp esi, [ebx + VMB.GuestTmb + GTMB.TssLimit]
        jbe do_interrupt_for_inter_privilege.ReadStack32
        
        
do_interrupt_for_inter_privilege.Ts_TssSelector_01B:
        ;;
        ;; error code = TssSelector | 0 | EXT
        ;;
        mov eax, [ebx + VMB.GuestTmb + GTMB.TssSelector]
        and eax, 0FFF8h
        or eax, 1
        mov ecx, INJECT_EXCEPTION_TS
        jmp do_interrupt_for_inter_privilege.ReflectException

do_interrupt_for_inter_privilege.Ts_SsSelector_01B:
        ;;
        ;; error code = SsSelector | 0 | EXT
        ;;
        mov eax, ecx
        and eax, 0FFF8h
        or eax, 1
        mov ecx, INJECT_EXCEPTION_TS
        jmp do_interrupt_for_inter_privilege.ReflectException
        
do_interrupt_for_inter_privilege.IdtGate16: 
        ;;
        ;; 检查 16 位 IDT-gate 里, stack 是否能容纳 10 bytes(5 *  2), 根据 stack 段是否属于 expand-down 段
        ;; 1) expand-down:  esp - 10 > SS.limit && esp <= SS.Top
        ;; 2) expand-up:    esp <= SS.limit 
        ;;
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSsDesc + 4], (1 << 10)  ; SS.E 位
        jz do_interrupt_for_inter_privilege.IdtGate16.ExpandUp
        
        
do_interrupt_for_inter_privilege.IdtGate16.ExpandDown:
        ;;
        ;; 检查 expand-down 类型段
        ;;
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp]
        sub esi, 10
        cmp esi, eax
        jbe do_interrupt_for_inter_privilege.Ss_SsSelector_01B
        
        ;;
        ;; 根据 SS.B 位检查
        ;;
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSsDesc + 4], (1 << 22)  ; SS.B 位
        jnz do_interrupt_for_inter_privilege.GetCsLimit
        mov eax, 0FFFFFh                                ;; SS.B = 0 时, expand-down 段上限为 0FFFFFh
        
do_interrupt_for_inter_privilege.IdtGate16.ExpandUp:
        ;;
        ;; 检查 expand-up 类型
        ;;        
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp]
        cmp esi, eax
        jbe do_interrupt_for_inter_privilege.GetCsLimit


        
do_interrupt_for_inter_privilege.Ss_SsSelector_01B:
        ;;
        ;; error code = SsSelector | 0 | EXT
        ;;
        mov eax, ecx
        and eax, 0FFF8h
        or eax, 1
        mov ecx, INJECT_EXCEPTION_SS        
        jmp do_interrupt_for_inter_privilege.ReflectException
        
do_interrupt_for_inter_privilege.Ts_01B:
        ;;
        ;; error code = 0 | 0 | EXT
        ;;
        mov eax, 01
        mov ecx, INJECT_EXCEPTION_TS
        jmp do_interrupt_for_inter_privilege.ReflectException

do_interrupt_for_inter_privilege.Gp_01B:
        ;;
        ;; error code = 0 | 0 | EXT
        ;;
        mov eax, 01
        mov ecx, INJECT_EXCEPTION_GP
        jmp do_interrupt_for_inter_privilege.ReflectException



do_interrupt_for_inter_privilege.ReadStack32:
        ;;
        ;; step 2: 读取中断 handler 使用的 stack pointer
        ;;
        REX.Wrxb
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TssBase]
        mov esi, [eax + ecx]                                                    ;; new ESP
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp], esi           ;; 保存目标 RSP
        movzx ecx, WORD [eax + ecx + 4]                                         ;; new SS
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSs], cx             ;; 保存目标 SS
        call get_system_va_of_guest_os
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Rsp], eax                 ;; 保存 RSP

do_interrupt_for_inter_privilege.CheckSsSelector:        
        ;;
        ;; step 3: 检查 SS selector 是否为 NULL, 属于 NULL 则产生 #TS(EXT)
        ;;
        test ecx, 0FFF8h
        jz do_interrupt_for_inter_privilege.Ts_01B

        ;;
        ;; step 4: 检查 SS selector 是否超出 limit, 超出则产生 #TS(SS_selector, 0, EXT)
        ;; 
        ;; 注意: #### 此处保留检查 LDT ####
        ;;
        mov eax, ecx
        and eax, 0FFF8h
        add eax, 7
        cmp eax, [ebx + VMB.GuestGmb + GGMB.GdtLimit]
        ja do_interrupt_for_inter_privilege.Ts_SsSelector_01B

        ;;
        ;; step 5: 检查 SS.RPL 是否等于 CS.DPL, 不等于则产生 #TS(SS_selector, 0, EXT)
        ;;
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 4]                ; code segment
        shr eax, 13                                                                     ; CS.DPL
        xor eax, ecx
        test eax, 3
        jnz do_interrupt_for_inter_privilege.Ts_SsSelector_01B

        ;;
        ;; step 6: 读取 stack-segment 描述符
        ;;
        mov esi, ecx
        and esi, 0FFF8h
        REX.Wrxb
        add esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.GdtBase]
        mov edi, [esi + 4]        
        mov esi, [esi]
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSsDesc], esi
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSsDesc + 4], edi

        ;;
        ;; step 7: 检查 SS 描述符, 以及 SS.DPL 与 CS.DPL
        ;;
        test edi, (1 << 9)                                                              ; 检查是否可写
        jz do_interrupt_for_inter_privilege.Ts_SsSelector_01B                           ;               
        mov esi, edi
        xor edi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 4]                
        test edi, (3 << 13)                                                             ; 检查 SS.DPL == CS.DPL
        jnz do_interrupt_for_inter_privilege.Ts_SsSelector_01B
        test esi, (1 << 15)                                                             ; 检查是否为present
        jz do_interrupt_for_inter_privilege.Ss_SsSelector_01B          

        ;;
        ;; step 8: 读取 SS.limit
        ;;
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSsDesc]            ; limit[15:0]
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSsDesc + 4]
        and esi, 0F0000h
        or eax, esi                                                                     ; limit[19:0]
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSsDesc + 4], (1 << 23)
        jz do_interrupt_for_inter_privilege.CheckSsLimit
        shl eax, 12
        add eax, 0FFFh

do_interrupt_for_inter_privilege.CheckSsLimit:                         
        ;;
        ;; step 9: 检查是否能容纳压入的值
        ;;
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSsLimit], eax               ; 保存 SS.limit     
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 4], (1 << 11)    ; 检查 16-bit gate 还是 32-bit
        jz do_interrupt_for_inter_privilege.IdtGate16

        ;;
        ;; 检查 32 位 stack 是否能容纳 20 bytes(5 *  4), 根据 stack 段是否属于 expand-down 段
        ;; 1) expand-down:  esp - 20 > SS.limit  && esp <= SS.Top
        ;; 2) expand-up:    esp <= SS.limit
        ;;
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSsDesc + 4], (1 << 10)  ; SS.E 位
        jz do_interrupt_for_inter_privilege.CheckSsLimit.ExpandUp
        
        
do_interrupt_for_inter_privilege.CheckSsLimit.ExpandDown:
        ;;
        ;; 检查 expand-down 类型段
        ;;
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp]
        sub esi, 20
        cmp esi, eax
        jbe do_interrupt_for_inter_privilege.Ss_SsSelector_01B
        
        ;;
        ;; 根据 SS.B 位检查
        ;;
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSsDesc + 4], (1 << 22)  ; SS.B 位
        jnz do_interrupt_for_inter_privilege.GetCsLimit
        mov eax, 0FFFFFh                                ;; SS.B = 0 时, expand-down 段上限为 0FFFFFh
        
do_interrupt_for_inter_privilege.CheckSsLimit.ExpandUp:
        ;;
        ;; 检查 expand-up 类型
        ;;        
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp]
        cmp esi, eax
        ja do_interrupt_for_inter_privilege.Ss_SsSelector_01B

do_interrupt_for_inter_privilege.GetCsLimit:
        ;;
        ;; step 10: 读取 CS.limit
        ;;
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc]             ; limit[15:0]
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 4]
        and esi, 0F0000h
        or eax, esi                                                                     ; limit[19:0]
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 4], (1 << 23)
        jz do_interrupt_for_inter_privilege.CheckCsLimit
        shl eax, 12
        add eax, 0FFFh

do_interrupt_for_inter_privilege.CheckCsLimit:
        ;;
        ;; step 11: 读取目标 RIP
        ;;
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsLimit], eax               ; 保存 CS.limit
        movzx esi, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc]              ; offset[15:0]
        mov edi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 4]
        and edi, 0FFFF0000h                                                             ; offset[31:16]
        or esi, edi
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRip], esi                   ; 保存目标 RIP

        ;;
        ;; step 12: 检查 Eip 是否超出 Cs.limit, 超出则产生 #GP(EXT)
        ;;
        cmp esi, eax
        ja do_interrupt_for_inter_privilege.Gp_01B
          
        ;;
        ;; step 13: 加载 SS 与 ESP
        ;;
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSs]
        SetVmcsField    GUEST_SS_SELECTOR, eax
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSsDesc + 5]
        and eax, 0F0FFh
        SetVmcsField    GUEST_SS_ACCESS_RIGHTS, eax
        DoVmWrite       GUEST_SS_LIMIT, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSsLimit]        
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSsDesc + 2]
        and eax, 00FFFFFFh
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSsDesc + 4]
        and esi, 0FF000000h
        or eax, esi
        SetVmcsField    GUEST_SS_BASE, eax
        REX.Wrxb
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp]
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 4], (1 << 11)
        mov esi, 20
        mov edi, 10
        cmovz esi, edi
        sub eax, esi
        SetVmcsField    GUEST_RSP, eax
        
do_interrupt_for_inter_privilege.LoadCsEip:
        ;;
        ;; step 14: 加载 CS:EIP
        ;;       
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCs]
        SetVmcsField    GUEST_CS_SELECTOR, eax
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 5]
        and eax, 0F0FFh
        SetVmcsField    GUEST_CS_ACCESS_RIGHTS, eax
        DoVmWrite       GUEST_CS_LIMIT, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsLimit]        
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 2]
        and eax, 00FFFFFFh
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 4]
        and esi, 0FF000000h
        or eax, esi
        SetVmcsField    GUEST_CS_BASE, eax        
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRip]        
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 4], (1 << 11)
        cmovnz eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRip]
        SetVmcsField    GUEST_RIP, eax

do_interrupt_for_inter_privilege.Push:
        ;;
        ;; step 15: 返回信息压入 stack 中
        ;;
        REX.Wrxb
        mov edx, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Rsp]        
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 4], (1 << 11)
        jz do_interrupt_for_inter_privilege.Push16
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldSs]
        mov [edx - 4], eax
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldRsp]
        mov [edx - 8], eax
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldFlags]
        mov [edx - 12], eax
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldCs]
        mov [edx - 16], eax
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldRip]
        mov [edx - 20], eax        
        jmp do_interrupt_for_inter_privilege.Flags
        
do_interrupt_for_inter_privilege.Push16:    
        ;;
        ;; 压入 16 位数据
        ;;    
        mov ax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldSs]
        mov [edx - 2], ax
        mov ax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldRsp]
        mov [edx - 4], ax
        mov ax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldFlags]
        mov [edx - 6], ax
        mov ax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldCs]
        mov [edx - 8], ax
        mov ax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldRip]
        mov [edx - 10], ax

do_interrupt_for_inter_privilege.Flags:        
        ;;
        ;; step 16: 更新 eflags
        ;;        
        mov esi, ~(FLAGS_TF | FLAGS_VM | FLAGS_RF | FLAGS_NT)
        mov edi, ~(FLAGS_TF | FLAGS_VM | FLAGS_RF | FLAGS_NT | FLAGS_IF)
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldFlags]
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc], (1 << 8)
        cmovz esi, edi
        and eax, esi
        SetVmcsField    GUEST_RFLAGS, eax
        mov eax, DO_INTERRUPT_SUCCESS
        jmp do_interrupt_for_inter_privilege.Done
               

        
do_interrupt_for_inter_privilege.ReflectException:
        ;;
        ;; 注入异常
        ;;
        SetVmcsField    VMENTRY_EXCEPTION_ERROR_CODE, eax
        SetVmcsField    VMENTRY_INTERRUPTION_INFORMATION, ecx
        mov eax, DO_INTERRUPT_ERROR

do_interrupt_for_inter_privilege.Done:        
        pop ecx
        pop edx
        pop ebx
        pop ebp
        ret




;-----------------------------------------------------------------------
; do_interrupt_for_inter_privilege_longmode()
; input:
;       esi - privilege level
; output:
;       eax - status code
; 描述: 
;       1) 处理 longmode 模式下的特权级内的中断(切入高权限)
;-----------------------------------------------------------------------
do_interrupt_for_inter_privilege_longmode:
        push ebp
        push ebx
        push edx
        push ecx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif

        DEBUG_RECORD    "[do_interrupt_for_inter_privilege_longmode]..."
 
        REX.Wrxb
        mov ebx, [ebp + PCB.CurrentVmbPointer]
        mov ecx, esi  
 
        ;;
        ;; step 1: 根据 IST 值计算 stack pointer 偏移量
        ;;
        mov edx, esi       
        shl edx, 3
        add edx, 4
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 4]
        and eax, 7
        lea esi, [eax * 8 + 28]
        cmovnz edx, esi

        ;;
        ;; step 2: 检查 stack pointer 是否超出 TSS limit
        ;;
        mov esi, edx
        add esi, 7
        cmp esi, [ebx + VMB.GuestTmb + GTMB.TssLimit]
        ja do_interrupt_for_inter_privilege_longmode.Ts_TsSelector_01B

        ;;
        ;; step 3: 读取 stack pointer
        ;;
        REX.Wrxb
        add edx, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TssBase]
        REX.Wrxb
        mov esi, [edx]                                                  ;; new RSP
        mov edi, [edx + 4]
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSs], cx     ;; 保存 SS
                                                                        ;; SS selector 被加载为 NULL

        ;;
        ;; step 4: 检查 RSP 是否为 canonical 地址形式, 否则产生 #SS(EXT)
        ;;
        shrd eax, edi, 16
        sar eax, 16
        cmp eax, edi
        jne do_interrupt_for_inter_privilege_longmode.Ss_01B
        
        ;;
        ;; step 5:  RSP 向下调整到 16 字节边界对齐
        ;;
        
        REX.Wrxb
        and esi, ~0Fh                                                   ; new RSP & FFFF_FFFF_FFFF_FFF0h
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp], esi
        call get_system_va_of_guest_os
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Rsp], eax         ;; 保存 RSP

        ;;
        ;; step 6: 检查 RIP 是否为 canonical 地址形式, 否则产生 #GP(EXT)
        ;;
        movzx esi, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc]
        mov edi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 4]
        and edi, 0FFFF0000h
        or esi, edi
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 8]
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRip], esi
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRip + 4], eax        
        shrd esi, eax, 16
        sar esi, 16
        cmp esi, eax
        jne do_interrupt_for_inter_privilege_longmode.Gp_01B
        
        ;;
        ;; step 7: 加载 RSP, SS = NULL-selector
        ;;
        REX.Wrxb
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp]
        REX.Wrxb
        sub eax, (5 * 8)
        SetVmcsField    GUEST_RSP, eax   
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSs]
        SetVmcsField    GUEST_SS_SELECTOR, eax       
        shl eax, 5                      ; SS.DPL
        or eax, 93h                     ; P = S = W = A = 1
        SetVmcsField    GUEST_SS_ACCESS_RIGHTS, eax
        SetVmcsField    GUEST_SS_LIMIT, 0
        SetVmcsField    GUEST_SS_BASE, 0

        ;;
        ;; step 8: 压入返回信息到 stack 中
        ;;
        REX.Wrxb
        mov edx, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Rsp]        
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldSs]
        REX.Wrxb
        mov [edx - 8], eax
        REX.Wrxb
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldRsp]
        REX.Wrxb
        mov [edx - 16], eax
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldFlags]
        REX.Wrxb
        mov [edx - 24], eax        
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldCs]
        REX.Wrxb
        mov [edx - 32], eax
        REX.Wrxb
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldRip]
        REX.Wrxb
        mov [edx - 40], eax
        
        ;;
        ;; step 9: 加载 CS:RIP
        ;;
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCs]
        SetVmcsField    GUEST_CS_SELECTOR, eax
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 5]
        and eax, 0F0FFh
        SetVmcsField    GUEST_CS_ACCESS_RIGHTS, eax
        DoVmWrite       GUEST_CS_LIMIT, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsLimit]        
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 2]
        and eax, 00FFFFFFh
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 4]
        and esi, 0FF000000h
        or eax, esi
        SetVmcsField    GUEST_CS_BASE, eax
        REX.Wrxb
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRip]
        SetVmcsField    GUEST_RIP, eax

  
        ;;
        ;; step 10: 更新 rflags
        ;;
        mov esi, ~(FLAGS_TF | FLAGS_VM | FLAGS_RF | FLAGS_NT)
        mov edi, ~(FLAGS_TF | FLAGS_VM | FLAGS_RF | FLAGS_NT | FLAGS_IF)
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldFlags]
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc], (1 << 8)
        cmovz esi, edi
        and eax, esi
        SetVmcsField    GUEST_RFLAGS, eax
        mov eax, DO_INTERRUPT_SUCCESS
        jmp do_interrupt_for_inter_privilege_longmode.Done
        
        
        
do_interrupt_for_inter_privilege_longmode.Ts_TsSelector_01B:        
        movzx eax, WORD [ebx + VMB.GuestTmb + GTMB.TssSelector]
        and eax, 0FFF8h
        or eax, 1
        mov ecx, INJECT_EXCEPTION_TS
        jmp do_interrupt_for_inter_privilege_longmode.ReflectException

do_interrupt_for_inter_privilege_longmode.Gp_01B:        
        mov eax, 01
        mov ecx, INJECT_EXCEPTION_GP
        jmp do_interrupt_for_inter_privilege_longmode.ReflectException
        
do_interrupt_for_inter_privilege_longmode.Ss_01B:        
        mov eax, 1
        mov ecx, INJECT_EXCEPTION_SS       
        
        
do_interrupt_for_inter_privilege_longmode.ReflectException:
        ;;
        ;; 注入异常
        ;;
        SetVmcsField    VMENTRY_EXCEPTION_ERROR_CODE, eax
        SetVmcsField    VMENTRY_INTERRUPTION_INFORMATION, ecx        
        mov eax, DO_INTERRUPT_ERROR
        
do_interrupt_for_inter_privilege_longmode.Done:        
        pop ecx
        pop edx
        pop ebx
        pop ebp
        ret




;-----------------------------------------------------------------------
; do_interrupt_for_intra_privilege()
; input:
;       none
; output:
;       eax -status code
; 描述: 
;       1) 处理 legacy 模式下的特权级外的中断(同级)
;-----------------------------------------------------------------------
do_interrupt_for_intra_privilege:
        push ebp
        push ebx
        push edx
        push ecx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif

        DEBUG_RECORD    "[do_interrupt_for_intra_privilege]..."

        REX.Wrxb
        mov ebx, [ebp + PCB.CurrentVmbPointer]

        ;;
        ;; 目标 RSP 等于原 RSP
        ;;
        REX.Wrxb
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldRsp]
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp], esi
        call get_system_va_of_guest_os
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Rsp], eax
        
        ;;
        ;; 目标 SS 等于原 SS
        ;;
        mov ax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldSs]
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSs], ax
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.CurrentSsLimit]
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetSsLimit], eax
        
        
do_interrupt_for_intra_privilege.CheckSsLimit:
        ;;
        ;; step 1: 检查是否能容纳压入的值
        ;;
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 4], (1 << 11)    ; 检查 16-bit gate 还是 32-bit
        jz do_interrupt_for_intra_privilege.IdtGate16

        ;;
        ;; 检查 32 位 stack 是否能容纳 12 bytes(3 * 4), 根据 stack 段是否属于 expand-down 段
        ;; 1) expand-down:  esp - 12 > SS.limit && esp <= SS.Top
        ;; 2) expand-up:    esp <= SS.limit 
        ;;
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.CurrentSsDesc + 4], (1 << 10)  ; SS.E 位
        jz do_interrupt_for_intra_privilege.CheckSsLimit.ExpandUp
        
        
do_interrupt_for_intra_privilege.CheckSsLimit.ExpandDown:
        ;;
        ;; 检查 expand-down 类型段
        ;;
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp]
        sub esi, 12
        cmp esi, eax
        jbe do_interrupt_for_intra_privilege.Ss_01B
        
        ;;
        ;; 根据 SS.B 位检查
        ;;
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.CurrentSsDesc + 4], (1 << 22)  ; SS.B 位
        jnz do_interrupt_for_intra_privilege.GetCsLimit
        mov eax, 0FFFFFh                                ;; SS.B = 0 时, expand-down 段上限为 0FFFFFh
        
do_interrupt_for_intra_privilege.CheckSsLimit.ExpandUp:
        ;;
        ;; 检查 expand-up 类型
        ;;        
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp]
        cmp esi, eax
        ja do_interrupt_for_intra_privilege.Ss_01B

do_interrupt_for_intra_privilege.GetCsLimit:
        ;;
        ;; step 2: 读取 CS.limit
        ;;
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc]         ; limit[15:0]
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 4]
        and esi, 0F0000h
        or eax, esi                                                                     ; limit[19:0]
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 4], (1 << 23)
        jz do_interrupt_for_intra_privilege.CheckCsLimit
        shl eax, 12
        add eax, 0FFFh
        
do_interrupt_for_intra_privilege.CheckCsLimit:
        ;;
        ;; step 3: EIP 是否超出 cs.limit
        ;;
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsLimit], eax
        movzx esi, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc]              ; offset[15:0]
        mov edi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 4]
        and edi, 0FFFF0000h                                                             ; offset[31:16]
        or esi, edi
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRip], esi                   ; 保存目标 RIP
        cmp esi, eax
        ja do_interrupt_for_intra_privilege.Gp_01B

        ;;
        ;; step 4: 压入返回信息
        ;;
        REX.Wrxb
        mov edx, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Rsp]
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 4], (1 << 11)
        jz do_interrupt_for_intra_privilege.Push16
        
        ;;
        ;; 压入 32 位数据 
        ;;
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldFlags]
        mov [edx - 4], eax
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldCs]
        mov [edx - 8], eax
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldRip]
        mov [edx - 12], eax

        ;;
        ;; 更新 ESP
        ;;
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp]
        sub eax, 12
        SetVmcsField    GUEST_RSP, eax

do_interrupt_for_intra_privilege.LoadCsEip:        
        ;;
        ;; step 5: 加载 CS:EIP
        ;;
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCs]
        SetVmcsField    GUEST_CS_SELECTOR, eax
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 5]
        and eax, 0F0FFh
        SetVmcsField    GUEST_CS_ACCESS_RIGHTS, eax 
        DoVmWrite       GUEST_CS_LIMIT, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsLimit]
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 2]
        and eax, 00FFFFFFh
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 4]
        and esi, 0FF000000h
        or eax, esi
        SetVmcsField    GUEST_CS_BASE, eax        
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRip]        
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 4], (1 << 11)
        cmovnz eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRip]
        SetVmcsField    GUEST_RIP, eax        

        ;;
        ;; step 6: 更新 eflags
        ;;
        mov eax, ~(FLAGS_TF | FLAGS_NT | FLAGS_VM | FLAGS_RF)
        mov esi, ~(FLAGS_TF | FLAGS_NT | FLAGS_VM | FLAGS_RF | FLAGS_IF)
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 4], (1 << 8)
        cmovz eax, esi
        and eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldFlags]
        SetVmcsField    GUEST_RFLAGS, eax
        mov eax, DO_INTERRUPT_SUCCESS
        jmp do_interrupt_for_intra_privilege.Done        
                        
do_interrupt_for_intra_privilege.Push16:
        ;;
        ;; 压入 16 位数据
        ;;
        mov ax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldFlags]
        mov [edx - 2], ax
        mov ax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldCs]
        mov [edx - 4], ax
        mov ax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldRip]
        mov [edx - 8], ax
        
        ;;
        ;; 更新 RSP
        ;;
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp]
        sub eax, 8
        SetVmcsField    GUEST_RSP, eax
        jmp do_interrupt_for_intra_privilege.LoadCsEip
        
do_interrupt_for_intra_privilege.IdtGate16: 
        ;;
        ;; 检查 16 位 IDT-gate 里, stack 是否能容纳 6 bytes(3 * 2), 根据 stack 段是否属于 expand-down 段
        ;; 1) expand-down:  esp - 6 > SS.limit && esp <= SS.Top
        ;; 2) expand-up:    esp <= SS.limit 
        ;;
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.CurrentSsDesc + 4], (1 << 10)  ; SS.E 位
        jz do_interrupt_for_intra_privilege.IdtGate16.ExpandUp
        
        
do_interrupt_for_intra_privilege.IdtGate16.ExpandDown:
        ;;
        ;; 检查 expand-down 类型段
        ;;
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp]
        sub esi, 6
        cmp esi, eax
        jbe do_interrupt_for_intra_privilege.Ss_01B
        
        ;;
        ;; 根据 SS.B 位检查
        ;;
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.CurrentSsDesc + 4], (1 << 22)  ; SS.B 位
        jnz do_interrupt_for_intra_privilege.GetCsLimit
        mov eax, 0FFFFFh                                ;; SS.B = 0 时, expand-down 段上限为 0FFFFFh
        
do_interrupt_for_intra_privilege.IdtGate16.ExpandUp:
        ;;
        ;; 检查 expand-up 类型
        ;;        
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp]
        cmp esi, eax
        jbe do_interrupt_for_intra_privilege.GetCsLimit



do_interrupt_for_intra_privilege.Ss_01B:
        mov eax, 01
        mov ecx, INJECT_EXCEPTION_SS
        jmp do_interrupt_for_intra_privilege.ReflectException

do_interrupt_for_intra_privilege.Gp_01B:
        mov eax, 01
        mov ecx, INJECT_EXCEPTION_GP


do_interrupt_for_intra_privilege.ReflectException:        
        ;;
        ;; 注入异常
        ;;
        SetVmcsField    VMENTRY_EXCEPTION_ERROR_CODE, eax
        SetVmcsField    VMENTRY_INTERRUPTION_INFORMATION, ecx   
        mov eax, DO_INTERRUPT_ERROR

do_interrupt_for_intra_privilege.Done:
        pop ecx
        pop edx
        pop ebx
        pop ebp
        ret        





;-----------------------------------------------------------------------
; do_interrupt_for_intra_privilege_longmode()
; input:
;       none
; output:
;       eax - status code
; 描述: 
;       1) 处理 longmode 模式下的特权级外的中断(同级)
;-----------------------------------------------------------------------
do_interrupt_for_intra_privilege_longmode:
        push ebp
        push ebx
        push edx
        push ecx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif

        DEBUG_RECORD    "[do_interrupt_for_intra_privilege_longmode]..."


        REX.Wrxb
        mov ebx, [ebp + PCB.CurrentVmbPointer]
        
        ;;
        ;; 当前 RSP
        ;;
        REX.Wrxb
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldRsp]
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp], esi

        ;;
        ;; step 1: 检查 IST
        ;;
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 4]
        and eax, 7
        jz do_interrupt_for_intra_privilege_longmode.CheckRsp
        lea eax, [eax * 8 + 28]
        lea esi, [eax + 7]
        cmp esi, [ebx + VMB.GuestTmb + GTMB.TssLimit]
        ja do_interrupt_for_intra_privilege_longmode.Ts_TsSelector_01B

        ;;
        ;; 读取 IST pointer
        ;;        
        REX.Wrxb
        add eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TssBase]
        REX.Wrxb
        mov esi, [eax]
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp], esi

do_interrupt_for_intra_privilege_longmode.CheckRsp:         
        ;;
        ;; step 2: 检查 RSP 是否为 canonical 地址形式
        ;;
        REX.Wrxb
        mov eax, esi
        REX.Wrxb
        shl eax, 16
        REX.Wrxb
        sar eax, 16
        REX.Wrxb
        cmp eax, esi
        jne do_interrupt_for_intra_privilege_longmode.Ss_01B

        REX.Wrxb
        and esi, ~0Fh                                                   ; new RSP & FFFF_FFFF_FFFF_FFF0h
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp], esi
        call get_system_va_of_guest_os
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Rsp], eax         ;; 保存 RSP

        ;;
        ;; step 3: 读取 RIP, 并检查 RIP 是否为 canonical 地址
        ;;
        movzx esi, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc]              ; offset[15:0]
        mov edi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 4]
        and edi, 0FFFF0000h                                                             ; offset[31:16]
        or esi, edi
        mov edi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 8]
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRip], esi                   ; 保存目标 RIP
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRip + 4], edi
        shl edi, 16
        sar edi, 16
        cmp edi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRip + 4]
        jne do_interrupt_for_intra_privilege_longmode.Gp_01B

        ;;
        ;; step 4: 压入返回信息
        ;;
        REX.Wrxb
        mov edx, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Rsp]
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldSs]
        REX.Wrxb
        mov [edx - 8], eax
        REX.Wrxb
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldRsp]
        REX.Wrxb
        mov [edx - 16], eax
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldFlags]
        REX.Wrxb
        mov [edx - 24], eax
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldCs]
        REX.Wrxb
        mov [edx - 32], eax
        REX.Wrxb
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldRip]
        REX.Wrxb
        mov [edx - 40], eax

        ;;
        ;; step 5: 加载新的 RSP 值
        ;;
        REX.Wrxb
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRsp]
        REX.Wrxb
        sub eax, 40
        SetVmcsField    GUEST_RSP, eax 

        ;;
        ;; step 6: 加载 CS:RIP
        ;;
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCs]
        SetVmcsField    GUEST_CS_SELECTOR, eax
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 5]
        and eax, 0F0FFh
        SetVmcsField    GUEST_CS_ACCESS_RIGHTS, eax 
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 2]
        and eax, 00FFFFFFh
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 4]
        and esi, 0FF000000h
        or eax, esi
        SetVmcsField    GUEST_CS_BASE, eax        
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc]         ; limit[15:0]
        mov esi, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 4]
        and esi, 0F0000h
        or eax, esi                                                                     ; limit[19:0]
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsDesc + 4], (1 << 23)
        jz do_interrupt_for_intra_privilege_longmode.SetCsLimit
        shl eax, 12
        add eax, 0FFFh        
do_interrupt_for_intra_privilege_longmode.SetCsLimit:
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetCsLimit], eax
        SetVmcsField    GUEST_CS_LIMIT, eax
        REX.Wrxb
        mov eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TargetRip]
        SetVmcsField    GUEST_RIP, eax

        ;;
        ;; step 7: 更新 rflags
        ;;
        mov eax, ~(FLAGS_TF | FLAGS_NT | FLAGS_VM | FLAGS_RF)
        mov esi, ~(FLAGS_TF | FLAGS_NT | FLAGS_VM | FLAGS_RF | FLAGS_IF)
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtDesc + 4], (1 << 8)
        cmovz eax, esi
        and eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldFlags]
        SetVmcsField    GUEST_RFLAGS, eax
        mov eax, DO_INTERRUPT_SUCCESS
        jmp do_interrupt_for_intra_privilege_longmode.Done
        
        
do_interrupt_for_intra_privilege_longmode.Gp_01B:
        mov eax, 01
        mov ecx, INJECT_EXCEPTION_GP
        jmp do_interrupt_for_intra_privilege_longmode.ReflectException
        
        
do_interrupt_for_intra_privilege_longmode.Ts_TsSelector_01B:
        movzx eax, WORD [ebx + VMB.GuestTmb + GTMB.TssSelector]
        or eax, 01
        mov ecx, INJECT_EXCEPTION_TS
        jmp do_interrupt_for_intra_privilege_longmode.ReflectException
        
do_interrupt_for_intra_privilege_longmode.Ss_01B:
        mov eax, 01
        mov ecx, INJECT_EXCEPTION_SS        
        
do_interrupt_for_intra_privilege_longmode.ReflectException:
        ;;
        ;; 注入异常
        ;;
        SetVmcsField    VMENTRY_EXCEPTION_ERROR_CODE, eax
        SetVmcsField    VMENTRY_INTERRUPTION_INFORMATION, ecx   
        mov eax, DO_INTERRUPT_ERROR
        
do_interrupt_for_intra_privilege_longmode.Done:
        pop ecx
        pop edx
        pop ebx
        pop ebp        
        ret




;**********************************
; 异常处理例程表                  *
;**********************************
DoExceptionTable:
        DD      do_DE, do_DB, do_NMI, do_BP, do_DF
        DD      do_BR, do_UD, do_NM, do_DF, DoReserved
        DD      do_TS, do_NP, do_SS, do_GP, do_PF
        DD      DoReserved, do_MF, do_AC, do_MC, do_XM
        DD      DoReserved, DoReserved, DoReserved, DoReserved, DoReserved
        DD      DoReserved, DoReserved, DoReserved, DoReserved, DoReserved
        DD      DoReserved, DoReserved
