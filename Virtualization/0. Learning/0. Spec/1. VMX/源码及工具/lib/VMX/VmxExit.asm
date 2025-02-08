;*************************************************
;* VmxExit.asm                                   *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************




;-----------------------------------------------------------------------
; GetExceptionInfo()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 收集由 exception 或者 NMI 引发的 vector 信息
;-----------------------------------------------------------------------
GetExceptionInfo:

        ret



;-----------------------------------------------------------------------
; GetMovCrInfo()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 收集由于 MOV-CR 引起 VM-exit 的信息
;-----------------------------------------------------------------------
GetMovCrInfo:
        push ebp
        push ebx
        push ecx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        REX.Wrxb
        lea ebx, [ebp + PCB.GuestExitInfo]

        ;;
        ;; 清寄存器值
        ;;
        xor eax, eax
        REX.Wrxb
        mov [ebx + MOV_CR_INFO.Register], eax
        REX.Wrxb
        mov [ebx + MOV_CR_INFO.ControlRegister], eax
        
        ;;
        ;; 读取 VM-exit 明细信息
        ;;
        mov eax, [ebp + PCB.ExitInfoBuf + EXIT_INFO.ExitQualification]
        
        ;;
        ;; 访问类型
        ;;
        mov ecx, eax
        shr ecx, 4
        and ecx, 3
        mov [ebx + MOV_CR_INFO.Type], ecx

        ;;
        ;; 判断访问类型
        ;;
        cmp ecx, CAT_LMSW
        je GetMovCrInfo.Lmsw                            ;; 处理 LMSW
        cmp ecx, CAT_MOV_TO_CR
        je GetMovCrInfo.MovToCr                         ;; 处理 MOV-to-CR
        cmp ecx, CAT_MOV_FROM_CR
        jne GetMovCrInfo.Done                           ;; 处理 MOV-from-CR

GetMovCrInfo.MovFromCr:        
        ;;
        ;; 读取目标寄存器 ID
        ;;
        mov esi, eax
        shr esi, 8
        and esi, 0Fh
        mov [ebx + MOV_CR_INFO.RegisterID], esi
        
        ;;
        ;; 读取源控制寄存器值
        ;;        
        mov esi, eax
        and esi, 0Fh        
        cmp esi, 0
        mov eax, GUEST_CR0
        je GetMovCrInfo.MovFromCr.GetCr
        cmp esi, 3
        mov eax, GUEST_CR3
        je GetMovCrInfo.MovFromCr.GetCr

        mov eax, GUEST_CR4
        
GetMovCrInfo.MovFromCr.GetCr:        
        DoVmRead        eax, [ebx + MOV_CR_INFO.ControlRegister]

        jmp GetMovCrInfo.Done
        

GetMovCrInfo.MovToCr:
        ;;
        ;; 读取目标控制寄存器ID
        ;;
        mov esi, eax
        and esi, 0Fh
        mov [ebx + MOV_CR_INFO.ControlRegisterID], esi

        ;;
        ;; 读取源寄存器值 
        ;;
        mov esi, eax
        shr esi, 8
        and esi, 0Fh
        call get_guest_register_value
        REX.Wrxb
        mov [ebx + MOV_CR_INFO.Register], eax


        jmp GetMovCrInfo.Done
        
GetMovCrInfo.Lmsw:        
        ;;
        ;; 读取 LMSW 源操作数值
        ;;
        mov esi, eax
        shr esi, 16
        and esi, 0FFFFh
        mov [ebx + MOV_CR_INFO.LmswSource], esi
        
        ;;
        ;; 检查 LMSW 指令操作数类型
        ;;
        test eax, (1 << 6)
        jz GetMovCrInfo.Done
        
        ;;
        ;; 属于内存操作数时, 读取线性地址值
        ;;
        REX.Wrxb
        mov esi, [ebp + PCB.ExitInfoBuf + EXIT_INFO.GuestLinearAddress]
        REX.Wrxb
        mov [ebx + MOV_CR_INFO.LinearAddress], esi

GetMovCrInfo.Done:        
        pop ecx
        pop ebx
        pop ebp
        ret
        




;-----------------------------------------------------------------------
; GetTaskSwitchInfo()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 收集由 exception 或者 NMI 引发的 vector 信息
;-----------------------------------------------------------------------
GetTaskSwitchInfo:
        push ebp
        push ebx
        push edx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        REX.Wrxb
        lea ebx, [ebp + PCB.GuestExitInfo]
        
        ;;
        ;; 读取 VM-exit 信息 
        ;;
        mov eax, [ebp + PCB.ExitInfoBuf + EXIT_INFO.ExitQualification]
        movzx esi, ax
        mov [ebx + TASK_SWITCH_INFO.NewTrSelector], esi                 ; 记录目标 TSS selector
        shr eax, 30
        and eax, 3
        mov [ebx + TASK_SWITCH_INFO.Source], eax                        ; 任务切换源
        GetVmcsField    GUEST_TR_SELECTOR
        mov [ebx + TASK_SWITCH_INFO.CurrentTrSelector], eax             ; 记录当前 TSS selector
        
        ;;
        ;; 读取指令长度
        ;;
        mov eax, [ebp + PCB.ExitInfoBuf + EXIT_INFO.InstructionLength]
        mov [ebx + TASK_SWITCH_INFO.InstructionLength], eax
        
        ;;
        ;; 读取 GDT/IDT base
        ;;
        GetVmcsField    GUEST_GDTR_BASE
        REX.Wrxb
        mov esi, eax
        call get_system_va_of_guest_va
        REX.Wrxb
        mov [ebx + TASK_SWITCH_INFO.GuestGdtBase], eax
        REX.Wrxb
        mov edx, eax                                                    ; edx = GuestGdtBase
        GetVmcsField    GUEST_IDTR_BASE
        REX.Wrxb
        mov esi, eax
        call get_system_va_of_guest_va
        REX.Wrxb
        mov [ebx + TASK_SWITCH_INFO.GuestIdtBase], eax

        ;;
        ;; 读取 GDT/IDT limit
        ;;
        GetVmcsField    GUEST_GDTR_LIMIT
        mov [ebx + TASK_SWITCH_INFO.GuestGdtLimit], eax
        GetVmcsField    GUEST_IDTR_LIMIT
        mov [ebx + TASK_SWITCH_INFO.GuestIdtLimit], eax
        

        ;;
        ;; 读取 current/new-task TSS 描述符地址
        ;;
        mov eax, [ebx + TASK_SWITCH_INFO.CurrentTrSelector]       
        REX.Wrxb
        lea eax, [edx + eax]                                            ; Gdt.Base + selector
        REX.Wrxb
        mov [ebx + TASK_SWITCH_INFO.CurrentTssDesc], eax                ; 记录当前 TSS 描述符地址
        mov eax, [ebx + TASK_SWITCH_INFO.NewTrSelector]                 ; 目标 TSS selector
        REX.Wrxb
        lea eax, [edx + eax]                                            ; 目标 TSS 描述符地址 = Gdt.Base + selector
        REX.Wrxb
        mov [ebx + TASK_SWITCH_INFO.NewTaskTssDesc], eax

        ;;
        ;; 读取 current TSS 地址
        ;;
        GetVmcsField    GUEST_TR_BASE
        REX.Wrxb
        mov esi, eax
        call get_system_va_of_guest_va
        REX.Wrxb
        mov [ebx + TASK_SWITCH_INFO.CurrentTss], eax                    ; 当前 TSS 地址

        ;;
        ;; 读取 new-task TSS 地址
        ;; *** 注意, 不需要读取 64 位 TSS 地址. 在 longmode 下不支持任务切换！***        
        ;;
        REX.Wrxb
        mov eax, [ebx + TASK_SWITCH_INFO.NewTaskTssDesc]
        mov esi, [eax]                                                  ; 描述符 low 32
        mov edi, [eax + 4]                                              ; 描述符 high 32
        shr esi, 16
        and esi, 0FFFFh                                                 ; TSS 地址 bits 15:0
        mov eax, edi
        and eax, 0FF000000h                                             ; TSS 地址 bits 31:24
        shl edi, (23 - 7)
        and edi, 00FF0000h                                              ; TSS 地址 bits 23:16
        or edi, eax
        or esi, edi                                                     ; TSS 地址 bits 31:0
        mov [ebx + TASK_SWITCH_INFO.NewTaskTssBase], esi                ; TR.base 的 guest-linear address 值      
        call get_system_va_of_guest_va
        REX.Wrxb
        mov [ebx + TASK_SWITCH_INFO.NewTaskTss], eax                    ; 目标 TSS 地址

        pop edx
        pop ebx
        pop ebp
        ret



;-----------------------------------------------------------------------
; GetDescTableRegisterInfo()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 收集由访问描述符表寄存器引发的 vector 信息
;-----------------------------------------------------------------------
GetDescTableRegisterInfo:
        push ebp
        push ebx
        push edx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        
        REX.Wrxb
        lea ebx, [ebp + PCB.GuestExitInfo]

        ;;
        ;; 收集基本信息
        ;;
        mov eax, [ebp + PCB.ExitInfoBuf + EXIT_INFO.ExitQualification]
        mov [ebx + INSTRUCTION_INFO.Displacement], eax
        mov eax, [ebp + PCB.ExitInfoBuf + EXIT_INFO.InstructionLength]
        mov [ebx + INSTRUCTION_INFO.InstructionLength], eax
        mov edx, [ebp + PCB.ExitInfoBuf + EXIT_INFO.InstructionInfo]
        mov [ebx + INSTRUCTION_INFO.Flags], edx

        ;;
        ;; 分析提取信息
        ;;
        mov eax, edx
        and eax, 03h
        mov [ebx + INSTRUCTION_INFO.Scale], eax                 ; scale 值
        mov eax, edx
        shr eax, 7
        and eax, 07h
        mov [ebx + INSTRUCTION_INFO.AddressSize], eax           ; address size
        mov eax, edx
        shr eax, 15
        and eax, 07h
        mov [ebx + INSTRUCTION_INFO.Segment], eax               ; segment
        mov eax, edx
        shr eax, 18
        and eax, 0Fh
        mov [ebx + INSTRUCTION_INFO.Index], eax                 ; index
        mov eax, edx
        shr eax, 23
        and eax, 0Fh
        mov [ebx + INSTRUCTION_INFO.Base], eax                  ; base
        mov eax, edx
        shr eax, 28
        and eax, 03h
        mov [ebx + INSTRUCTION_INFO.Type], eax                  ; instruction type

        ;;
        ;; LLDT, SLDT, LTR, STR 指令的寄存器操作数
        ;;
        mov eax, edx
        shr eax, 3
        and eax, 0Fh
        mov [ebx + INSTRUCTION_INFO.Register], eax
        
        
        ;;
        ;; 分析 operand size
        ;; 1) SGDT/SIDT: 在非 64-bit 下是 32位, 在 64-bit 下是 64位
        ;; 2) LGDT/LIDT: 16位, 32位, 64位
        ;;             
        GetVmcsField    GUEST_CS_ACCESS_RIGHTS
        mov esi, INSTRUCTION_OPS_DWORD
        
        cmp edx, INSTRUCTION_TYPE_SGDT
        je GetDescTableRegisterInfo.Ops.@1
        cmp edx, INSTRUCTION_TYPE_SIDT
        je GetDescTableRegisterInfo.Ops.@1
        
        bt edx, 11                                              ; operand size 位
        mov esi, 0
        
GetDescTableRegisterInfo.Ops.@1:
        adc esi, 0
        test eax, SEG_L
        mov eax, INSTRUCTION_OPS_QWORD
        cmovz eax, esi
        mov [ebx + INSTRUCTION_INFO.OperandSize], eax           ; operand size
                
        pop edx
        pop ebx
        pop ebp
        ret




;-----------------------------------------------------------------------
; get_interrupt_info()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 收集中断处理相关信息
;-----------------------------------------------------------------------
get_interrupt_info:
        push ebp
        push ebx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        REX.Wrxb
        mov ebx, [ebp + PCB.CurrentVmbPointer]
        
        ;;
        ;; 根据 IDT-vectoring information 字段分析中断类型
        ;; 1) IDT-vectoring information [31] = 0 时, 不需要处理
        ;; 2) 从 IDT-vectoring informating 读取中断向量号及类型, 并保存
        ;;
        mov BYTE [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.InterruptType], INTERRUPT_TYPE_NONE
        mov eax, [ebp + PCB.ExitInfoBuf + EXIT_INFO.IdtVectoringInfo]
        test eax, FIELD_VALID_FLAG
        jz get_interrupt_info.Done
        and eax, 7FFh                                                           ; bits[11:0]
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Vector], ax               ; 保存向量号及中断类型

        ;;
        ;; guest RIP
        ;;
        GetVmcsField    GUEST_RIP
        REX.Wrxb
        mov esi, eax
        call get_system_va_of_guest_os
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Rip], eax
                
        
        ;;
        ;; IDT base
        ;;
        REX.Wrxb
        mov esi, [ebx + VMB.GuestImb + GIMB.IdtBase]
        call get_system_va_of_guest_os
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.IdtBase], eax
        
        ;;
        ;; GDT base
        ;;
        REX.Wrxb
        mov esi, [ebx + VMB.GuestGmb + GGMB.GdtBase]
        call get_system_va_of_guest_os
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.GdtBase], eax
        
        ;;
        ;; TSS
        ;;
        REX.Wrxb
        mov esi, [ebx + VMB.GuestTmb + GTMB.TssBase]
        call get_system_va_of_guest_os
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.TssBase], eax


        ;;
        ;; guest CPL, status
        ;;
        GetVmcsField    GUEST_CS_SELECTOR
        and eax, 3
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.Cpl], ax        
        GetVmcsField    GUEST_IA32_EFER_FULL
        test eax, EFER_LMA
        setnz BYTE [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.GuestStatus]
                
        ;;
        ;; old SS, RIP, FLAGS, CS, EIP
        ;;
        REX.Wrxb
        mov esi, [ebx + VMB.VsbBase]
        REX.Wrxb
        mov eax, [esi + VSB.Rip]
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldRip], eax
        REX.Wrxb
        mov eax, [esi + VSB.Rsp]
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldRsp], eax
        mov eax, [esi + VSB.Rflags]
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldFlags], eax
        GetVmcsField    GUEST_CS_SELECTOR
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldCs], ax
        GetVmcsField    GUEST_SS_SELECTOR
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldSs], ax        

        ;;
        ;; 分析 return RIP 值
        ;;
        mov eax, [ebp + PCB.ExitInfoBuf + EXIT_INFO.InstructionLength]
        cmp BYTE [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.InterruptType], INTERRUPT_TYPE_SOFTWARE
        je get_interrupt_info.@1
        cmp BYTE [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.InterruptType], INTERRUPT_TYPE_PRIVILEGE
        jne get_interrupt_info.@2
get_interrupt_info.@1:        
        REX.Wrxb
        add [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldRip], eax
get_interrupt_info.@2:        

        ;;
        ;; current SS 描述符
        ;;
        movzx eax, WORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.OldSs]
        and eax, 0FFF8h
        REX.Wrxb
        add eax, [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.GdtBase]
        mov esi, [eax]
        mov edi, [eax + 4]
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.CurrentSsDesc], esi
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.CurrentSsDesc + 4], edi
        
        ;;
        ;; current SS limit
        ;;
        and esi, 0FFFFh                                                                 ; limit[15:0]
        and edi, 0F0000h
        or esi, edi                                                                     ; limit[19:0]
        test DWORD [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.CurrentSsDesc + 4], (1 << 23)
        jz get_interrupt_info.SsLimit
        shl esi, 12
        add esi, 0FFFh
get_interrupt_info.SsLimit:                
        mov [ebp + PCB.GuestExitInfo + INTERRUPT_INFO.CurrentSsLimit], esi        
 
get_interrupt_info.Done:
        pop ebx
        pop ebp
        ret




;-----------------------------------------------------------------------
; get_io_instruction_info()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 收集由 IO 指令引起 VM-exit 的相关信息
;-----------------------------------------------------------------------
get_io_instruction_info:
        push ebp
        push ebx
        
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
        ;; IoFlags
        ;;
        mov eax, [ebp + PCB.ExitInfoBuf + EXIT_INFO.ExitQualification]
        mov [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.IoFlags], eax
        
        ;;
        ;; OperandSize
        ;;
        mov esi, eax
        and esi, 7
        mov [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.OperandSize], esi
        
        ;;
        ;; IoPort
        ;;
        mov esi, eax
        shr esi, 16
        and esi, 0FFFFh
        mov [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.IoPort], esi
        
        
        test eax, IO_FLAGS_STRING
        jnz get_io_info.String
        
        ;;
        ;; 非串指令
        ;;
        test eax, IO_FLAGS_IN
        jnz get_io_info.Done
        ;;
        ;; 检查 operand size
        ;;
        mov eax, [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.OperandSize]
        cmp eax, IO_OPS_BYTE
        je get_io_info.Byte        
        cmp eax, IO_OPS_WORD
        je get_io_info.Word
        
        ;;
        ;; 读入 dword 
        ;;
        mov esi, [ebx + VSB.Rax]
        jmp get_io_info.GetValue
        
get_io_info.Byte:
        ;;
        ;; 读入 byte
        ;;
        movzx esi, BYTE [ebx + VSB.Rax]
        jmp get_io_info.GetValue
        
get_io_info.Word:
        ;;
        ;; 读入 word
        ;;
        movzx esi, WORD [ebx + VSB.Rax]
        jmp get_io_info.GetValue
        
        
get_io_info.String:
        test eax, IO_FLAGS_REP
        jz get_io_info.String.@1
        ;;
        ;; count
        ;;
        REX.Wrxb
        mov eax, [ebx + VSB.Rcx]
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.Count], eax
        
get_io_info.String.@1:        
        ;;        
        ;; Address size
        ;;
        mov eax, [ebp + PCB.ExitInfoBuf + EXIT_INFO.InstructionInfo]
        mov esi, eax
        shr esi, 7
        and esi, 7
        mov [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.AddressSize], esi
        
        ;;
        ;; segment
        ;;
        shr eax, 15
        and eax, 7
        mov [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.Segment], eax
        
        ;;
        ;; linear address
        ;;
        mov eax, esi
        REX.Wrxb
        mov esi, [ebp + PCB.ExitInfoBuf + EXIT_INFO.GuestLinearAddress]
        ;;
        ;; 检查 address size
        ;;
        cmp eax, IO_ADRS_WORD
        je get_io_info.String.AddrWord
        cmp eax, IO_ADRS_DWORD
        jne get_io_info.String.GetAddr
        ;;
        ;; 32 位地址
        ;;
        mov esi, esi  
        jmp get_io_info.String.GetAddr              
        
get_io_info.String.AddrWord:
        ;;
        ;; 16 位地址
        ;;
        movzx esi, si
        
get_io_info.String.GetAddr:
        ;;
        ;; 读取 system 地址值
        ;;
        call get_system_va_of_guest_os
        REX.Wrxb
        mov [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.LinearAddress], eax
        REX.Wrxb
        mov ebx, eax
        REX.Wrxb
        test eax, eax
        jz get_io_info.Done
        
        ;;
        ;; 读取尝试写入 IO ports 的值
        ;;        
        test DWORD [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.IoFlags], IO_FLAGS_IN
        jnz get_io_info.Done        
        
        ;;
        ;; 检查 operand size
        ;;
        mov eax, [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.OperandSize]
        cmp eax, IO_OPS_BYTE
        je get_io_info.String.Byte
        cmp eax, IO_OPS_WORD
        je get_io_info.String.Word
        
        ;;
        ;; 读入 32 位
        ;;
        mov esi, [ebx]
        jmp get_io_info.GetValue
        
get_io_info.String.Byte:
        ;;
        ;; 读入 8 位
        ;;
        movzx esi, BYTE [ebx]
        jmp get_io_info.GetValue
        
get_io_info.String.Word:
        ;;
        ;; 读入 16 位
        ;;
        movzx esi, WORD [ebx]
        
get_io_info.GetValue:        
        mov [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.Value], esi        
        
get_io_info.Done:
        pop ebx
        pop ebp
        ret



;**********************************
; VM-exit信息处理例程表           *
;**********************************

GetVmexitInfoRoutineTable:
