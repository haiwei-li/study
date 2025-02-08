;*************************************************
;* VmxApic.asm                                   *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************



EPT_VIOLATION_NO_FIXING                 EQU     0
EPT_VIOLATION_FIXING                    EQU     1



;-----------------------------------------------------------------------
; EptHandlerForGuestApicPage()
; input:
;       none
; output:
;       eax - 处理码
; 描述: 
;       1) 处理由于 guest APIC-page 而引起的 EPT violation
;-----------------------------------------------------------------------
EptHandlerForGuestApicPage:
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
        mov ebx, [ebp + PCB.CurrentVmbPointer]
        
        ;;
        ;; EPT violation 明细信息
        ;;
        mov eax, [ebp + PCB.ExitInfoBuf + EXIT_INFO.ExitQualification]
        
        ;;
        ;; guest 访问 APIC-page 的偏移量
        ;;
        REX.Wrxb
        mov edx, [ebp + PCB.ExitInfoBuf + EXIT_INFO.GuestPhysicalAddress]    
        and edx, 0FFFh
        
        ;;
        ;; 检查 guest 访问类型
        ;;
        test eax, EPT_READ
        jnz EptHandlerForGuestApicPage.Read
        test eax, EPT_EXECUTE
        jz EptHandlerForGuestApicPage.Write
        
        ;;
        ;; 处理 guest 尝试执行 APIC-page 页面, 注入一个 #PF(0x11) 异常
        ;;
        SetVmcsField    VMENTRY_INTERRUPTION_INFORMATION, INJECT_EXCEPTION_PF
        SetVmcsField    VMENTRY_EXCEPTION_ERROR_CODE, 0011h
        REX.Wrxb
        mov eax, [ebp + PCB.ExitInfoBuf + EXIT_INFO.GuestLinearAddress] 
        REX.Wrxb
        mov cr2, eax
        jmp EptHandlerForGuestApicPage.Done
        
EptHandlerForGuestApicPage.Write:
        ;;
        ;; 读取源操作数值
        ;;
        GetVmcsField    GUEST_RIP
        REX.Wrxb
        mov esi, eax
        call get_system_va_of_guest_va
        REX.Wrxb
        mov esi, eax
        mov al, [esi]                           ; opcode
        cmp al, 89h
        je EptHandlerForGuestApicPage.Write.Opcode89
        cmp al, 0C7h
        je EptHandlerForGuestApicPage.Write.OpcodeC7
        
        ;;
        ;; ### 注意, 作为示例, 这里不处理其它指令情况, 包括: 
        ;; 1) 使用其它 opcode 的指令
        ;; 1) 含有 REX prefix(4xH) 指令
        ;;
        jmp EptHandlerForGuestApicPage.Done
        
EptHandlerForGuestApicPage.Write.OpcodeC7:
        ;;
        ;; 分析 ModRM 字节
        ;;
        mov al, [esi + 1]
        mov cl, al
        and ecx, 7        
        cmp cl, 4
        sete cl                                 ; 如果 ModRM.r/m = 4, 则 cl = 1, 否则 cl = 0
        shr al, 6
        jz EptHandlerForGuestApicPage.Write.@2  ; ModRM.Mod = 0, 则 ecx += 0
        cmp al, 1                               ; ModRM.Mod = 1, 则 ecx += 2
        je EptHandlerForGuestApicPage.Write.OpcodeC7.@1
        add ecx, 2        
EptHandlerForGuestApicPage.Write.OpcodeC7.@1:
        add ecx, 2                              ; ModRM.Mod = 2, 则 ecx += 4
                                                ; ModRM.Mod = 3, 属于错误 encode
EptHandlerForGuestApicPage.Write.@2:
        ;;
        ;; 读取写入立即数
        ;;
        mov eax, [esi + ecx + 2]

        jmp EptHandlerForGuestApicPage.Write.Next
        
EptHandlerForGuestApicPage.Write.Opcode89:
        ;;
        ;; 读取源操作数
        ;;
        mov esi, [esi + 1]
        shr esi, 3
        and esi, 7
        call get_guest_register_value        

EptHandlerForGuestApicPage.Write.Next:
        ;;
        ;; virtual APIC-page 页面
        ;;
        REX.Wrxb
        mov esi, [ebx + VMB.VirtualApicAddress]   
        
        ;;
        ;; APIC-page 可写的 offset 为, 写其它区域忽略
        ;; 1) 80h:      TPR
        ;; 2) B0h:      EOI
        ;; 3) D0h:      LDR
        ;; 4) E0h:      DFR
        ;; 5) F0h:      SVR
        ;; 6) 2F0h - 370h:      LVT
        ;; 7) 380h:     TIMER-ICR
        ;; 8) 3E0h:     TIMER-DCR
        ;;
        cmp edx, 80h
        jne EptHandlerForGuestApicPage.Write.@1
        
        DEBUG_RECORD    "[EptHandlerForGuestApicPage]: wirte to APIC-page"
        
        ;;
        ;; 写入 TPR
        ;;
        mov [esi + 80h], eax
        jmp EptHandlerForGuestApicPage.Done
        
EptHandlerForGuestApicPage.Write.@1:
        
        jmp EptHandlerForGuestApicPage.Done



EptHandlerForGuestApicPage.Read:        
        ;;
        ;; 分析指令
        ;;
        GetVmcsField    GUEST_RIP
        REX.Wrxb
        mov esi, eax
        call get_system_va_of_guest_va
        REX.Wrxb
        mov esi, eax
        mov al, [esi]                           ; opcode
        cmp al, 8Bh
        je EptHandlerForGuestApicPage.Read.Opcode8B
        
        ;;
        ;; ### 注意, 作为示例, 这里不处理其它指令情况, 包括: 
        ;; 1) 使用其它 opcode 的指令
        ;; 1) 含有 REX prefix(4xH) 指令
        ;;
        jmp EptHandlerForGuestApicPage.Done
        
EptHandlerForGuestApicPage.Read.Opcode8B:
        ;;
        ;; 读取目标操作数 ID
        ;;
        mov esi, [esi + 1]
        shr esi, 3
        and esi, 7
          
        ;;
        ;; APIC-page 内下面的 offset 为可读区域
        ;; 1) 20h:      APIC ID
        ;; 2) 30h:      VER
        ;; 3) 80h:      TPR
        ;; 4) 90h:      APR
        ;; 5) A0h:      PPR
        ;; 6) B0h:      EOI
        ;; 7) C0h:      RRD
        ;; 8) D0h:      LDR
        ;; 9) E0h:      DFR
        ;; 10) F0h:     SVR
        ;; 11) 100h - 170h:     ISR
        ;; 12) 180h - 1F0h:     TMR
        ;; 13) 200h - 270h:     IRR
        ;; 14) 280h:    ESR
        ;; 15) 2F0h - 370h:     LVT
        ;; 16) 380h:    TIMER-ICR
        ;; 17) 3E0h:    TIMER-DCR
        ;;

        cmp edx, 80h
        jne EptHandlerForGuestApicPage.Read.@1
        
        DEBUG_RECORD    "[EptHandlerForGuestApicPage]: read from APIC-page"  
        
        ;;
        ;; 写入目标寄存器
        ;;
        
        REX.Wrxb
        mov eax, [ebx + VMB.VirtualApicAddress]           
        mov edi, [eax + 80h]
        call set_guest_register_value
        jmp EptHandlerForGuestApicPage.Done

EptHandlerForGuestApicPage.Read.@1:        

EptHandlerForGuestApicPage.Done:
        call update_guest_rip
        mov eax, EPT_VIOLATION_NO_FIXING
        pop edx
        pop ecx
        pop ebx
        pop ebp
        ret
        

