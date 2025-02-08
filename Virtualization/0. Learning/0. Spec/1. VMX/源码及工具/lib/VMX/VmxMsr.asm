;*************************************************
;* VmxMsr.asm                                    *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************


;;
;; 处理访问 MSR 例程
;;

  
        
;-----------------------------------------------------------------------
; GetMsrVte()
; input:
;       esi - MSR index
; output:
;       eax - MSR VTE(value table entry)地址
; 描述: 
;       1) 返回 MSR 对应的 VTE 表项地址
;       2) 不存在 MSR 时, 返回 0 值　
;-----------------------------------------------------------------------
GetMsrVte:
        push ebp
        push ebx
                
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif  

        REX.Wrxb
        mov ebx, [ebp + PCB.CurrentVmbPointer]
        cmp DWORD [ebx + VMB.MsrVteCount], 0
        je GetMsrVte.NotFound
        
        REX.Wrxb
        mov eax, [ebx + VMB.MsrVteBuffer]               
        
GetMsrVte.@1:                
        cmp esi, [eax]                                  ; 检查 MSR index 值
        je GetMsrVte.Done
        REX.Wrxb
        add eax, MSR_VTE_SIZE                           ; 指向下一条 entry
        REX.Wrxb
        cmp eax, [ebx + VMB.MsrVteIndex]
        jb GetMsrVte.@1
GetMsrVte.NotFound:
        xor eax, eax
GetMsrVte.Done:        
        pop ebx
        pop ebp
        ret



;-----------------------------------------------------------------------
; AppendMsrVte()
; input:
;       esi - MSR index
;       eax - MSR low32
;       edx - MSR hi32
; output:
;       eax - VTE 地址
; 描述: 
;       1) 向 MSR VTE buffer 里写入 MSR VTE 信息
;-----------------------------------------------------------------------
AppendMsrVte:
        push ebp
        push ebx
                
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif  

        REX.Wrxb
        mov ebp, [ebp + PCB.CurrentVmbPointer]     
        mov ebx, eax
        call GetMsrVte
        REX.Wrxb
        test eax, eax
        jnz AppendMsrVte.WriteVte
        
        mov eax, MSR_VTE_SIZE
        REX.Wrxb
        xadd [ebp + VMB.MsrVteIndex], eax
        inc DWORD [ebp + VMB.MsrVteCount]
                
AppendMsrVte.WriteVte:
        ;;
        ;; 写入 MSR VTE 内容
        ;;
        mov [eax + MSR_VTE.MsrIndex], esi
        mov [eax + MSR_VTE.Value], ebx
        mov [eax + MSR_VTE.Value + 4], edx
        pop ebx
        pop ebp
        ret




;-----------------------------------------------------------------------
; DoWriteMsrForApicBase()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理 guest 访问 IA32_APIC_BASE 寄存器
;-----------------------------------------------------------------------
DoWriteMsrForApicBase:
        push ebp
        push ebx
        push edx
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
        ;; 读取 guest 写入的 MSR 值
        ;;
        mov eax, [ebx + VSB.Rax]
        mov edx, [ebx + VSB.Rdx]

        DEBUG_RECORD    "[DoWriteMsrForApicBase]: write to IA32_APIC_BASE"
                
        ;;
        ;; ### 检查写入值是否合法 ###
        ;; 1) 保留位(bits 7:0, bit 9, bits 63:N)需为 0
        ;; 2) 检查 bit 11 与 bit 10 的设置
        ;;      a) 当 bit 11 = 1, bit 10 = 0 时, 设置 bit 11 = 1,  bit 10 = 1 开启 x2APIC 模式
        ;;      b) 当 bit 11 = 0, bit 10 = 1 时, 无效
        ;;      c) 当 bit 11 = 0, bit 10 = 0 时, 关闭 local APIC
        ;;      d) 当 bit 11 = 1, bit 10 = 1 时, 设置 bit 11 = 1, bit 10 = 0 时, 产生 #GP 异常 
        ;;
        
        ;;
        ;; 检查保留位, 不为 0 时注入 #GP 异常
        ;;
        test eax, 2FFh
        jnz DoWriteMsrForApicBase.Error
        mov esi, [ebp + PCB.MaxPhyAddrSelectMask + 4]
        not esi
        test edx, esi
        jnz DoWriteMsrForApicBase.Error
        
        ;;
        ;; 检查 xAPIC enable(bit 11)与 x2APIC enable(bit 10)
        ;;
        test eax, APIC_BASE_X2APIC
        jz DoWriteMsrForApicBase.Check.@1

        ;;
        ;; 当 bit 10 = 1 时, 检查 CPUID.01H:ECX[21].x2APIC 位
        ;; 1) 为 0 时表明不支持 x2APIC 模式, 注入 #GP(0) 异常
        ;; 
        test DWORD [ebp + PCB.CpuidLeaf01Ecx], (1 << 21)
        jz DoWriteMsrForApicBase.Error

        ;;
        ;; 当 bit 10 = 1 时, bit 11 = 0, 无效设置则注入 #GP(0) 异常
        ;;
        test eax, APIC_BASE_ENABLE
        jz DoWriteMsrForApicBase.Error
        

DoWriteMsrForApicBase.x2APIC:
        ;;
        ;; 现在 bit 10 = 1, bit 11 = 1
        ;; 1) 使用 x2APIC 模式的虚拟化设置
        ;;       
        mov esi, IA32_APIC_BASE
        call AppendMsrVte                                ;; 保存 guest 写入原值
        

        ;;
        ;; 检查 secondary prcessor-based VM-execution control 字段"virtualize x2APIC mode"位
        ;; 1) 为 1 时, 使用 VMX 原生的 x2APIC 虚拟化, 直接返回
        ;; 2) 为 0 时, 监控 800H - 8FFH MSR 的读写
        ;;
        GetVmcsField    CONTROL_PROCBASED_SECONDARY
        test eax, VIRTUALIZE_X2APIC_MODE
        jnz DoWriteMsrForApicBase.Done
        
        ;;
        ;; 现在监控 x2APIC MSR 的读写, 范围从 800H 到 8FFH
        ;;
        call set_msr_read_bitmap_for_x2apic
        call set_msr_write_bitmap_for_x2apic
        jmp DoWriteMsrForApicBase.Done
                
DoWriteMsrForApicBase.Check.@1:
        ;;
        ;; bit 10 = 0, bit 11 = 0, 关闭 local APIC, 不进行虚拟化处理
        ;; 1)写入 IA32_APIC_BASE 寄存器
        ;; 2)恢复映射
        ;;
        test eax, APIC_BASE_ENABLE
        jnz DoWriteMsrForApicBase.Check.@2
        
        ;;
        ;; guest 尝试关闭 local APIC
        ;; 1) 恢复 guest 对 IA32_APIC_BASE 寄存器的写入
        ;; 2) 恢复 EPT 映射
        ;;
        mov esi, IA32_APIC_BASE
        mov eax, [ebx + VSB.Rax]
        mov edx, [ebx + VSB.Rdx]
        call append_vmentry_msr_load_entry

%ifdef __X64        
        REX.Wrxb
        mov esi, [ebx + VSB.Rax]
        mov edi, 0FEE00000h
        mov eax, EPT_WRITE | EPT_READ
        call do_guest_physical_address_mapping
%else
        mov esi, [ebx + VSB.Rax]
        mov edi, [ebx + VSB.Rdx]
        mov eax, 0FEE00000h
        mov edx, 0
        mov ecx, EPT_WRITE | EPT_READ
        call do_guest_physical_address_mapping
%endif

        jmp DoWriteMsrForApicBase.Done
        
DoWriteMsrForApicBase.Check.@2:
        ;;
        ;; 读取原 guest 设置的 APIC_APIC_BASE 值
        ;; 1) 假如返回 0 值, 则表明 guest 第 1 次写 IA32_APIC_BASE
        ;;
        mov esi, IA32_APIC_BASE
        call GetMsrVte
        test eax, eax
        jz DoWriteMsrForApicBase.xAPIC
                
        ;;
        ;; 如果原值 bit 11 = 1, bit 10 = 1 时, 当设置 bit 11 = 1, bit 10 = 0 时, 将产生 #GP 异常
        ;;
        test DWORD [eax + MSR_VTE.Value], APIC_BASE_X2APIC
        jnz DoWriteMsrForApicBase.Error
        
        
DoWriteMsrForApicBase.xAPIC:
        ;;
        ;; ### 下面虚拟化 local APIC 的 xAPIC 模式 ###
        ;;                
        mov esi, IA32_APIC_BASE
        mov eax, [ebx + VSB.Rax]
        mov edx, [ebx + VSB.Rdx]
        call AppendMsrVte                               ; 保存 guest 写入值
        
        REX.Wrxb
        mov edx, eax
        
        ;;
        ;; 1)检查是否开启了"virtualize APIC access "
        ;;     a) 是, 则设置 APIC-access page 页面
        ;;     b) 否, 则提供 GPA 例程处理 local APIC 访问
        ;; 2)检查是否开启了"enable EPT"
        ;;     a)是, 则映射 IA32_APIC_BASE[N-1:12], 将 APIC-access page 设置为该 HPA 值
        ;;     b)否, 则直接将 IA32_APIC_BASE[N-1:12] 设为 APIC-access page
        ;;
        
        GetVmcsField    CONTROL_PROCBASED_SECONDARY
        
        test eax, VIRTUALIZE_APIC_ACCESS
        jz DoWriteMsrForApicBase.SetForEptViolation        
        test eax, ENABLE_EPT
        jz DoWriteMsrForApicBase.EptDisable
        
        ;;
        ;; 执行 EPT 映射到 0FEE00000H
        ;;
%ifdef __X64        
        REX.Wrxb
        mov esi, [edx + MSR_VTE.Value]
        mov edi, 0FEE00000h
        mov eax, EPT_READ | EPT_WRITE
        call do_guest_physical_address_mapping
%else
        mov esi, [edx + MSR_VTE.Value]
        mov edi, [edx + MSR_VTE.Value + 4]
        mov eax, 0FEE00000H
        mov edx, 0
        mov ecx, EPT_READ | EPT_WRITE
        call do_guest_physical_address_mapping
%endif

        mov eax, 0FEE00000h
        mov edx, 0
        jmp DoWriteMsrForApicBase.SetApicAccessPage


DoWriteMsrForApicBase.EptDisable:
        REX.Wrxb
        mov eax, [edx + MSR_VTE.Value]
        mov edx, [edx + MSR_VTE.Value + 4]
        REX.Wrxb
        and eax, ~0FFFh
        
DoWriteMsrForApicBase.SetApicAccessPage:        
        SetVmcsField    CONTROL_APIC_ACCESS_ADDRESS_FULL, eax
%ifndef __X64
        SetVmcsField    CONTROL_APIC_ACCESS_ADDRESS_HIGH, edx
%endif        
        
        call update_guest_rip
        jmp DoWriteMsrForApicBase.Done
        
        
DoWriteMsrForApicBase.SetForEptViolation:
        ;;
        ;; 处理 guest 写入 IA32_APIC_BASE 寄存器的值: 
        ;; 1)将 IA32_APIC_BASE[N-1:12] 映射到 host 的 IA32_APIC_BASE 值, 但是为 not-present
        ;; 2)GPA 不进行任何映射
        ;;        
        
        ;;
        ;; 为 GPA 提供处理例程
        ;;
        REX.Wrxb
        mov esi, [edx + MSR_VTE.Value]
        REX.Wrxb
        and esi, ~0FFFh
        mov edi, EptHandlerForGuestApicPage
        call AppendGpaHte

       
        call update_guest_rip
        jmp DoWriteMsrForApicBase.Done
        
DoWriteMsrForApicBase.Error:
        ;;
        ;; 反射 #GP(0) 给 guest 处理
        ;;
        SetVmcsField    VMENTRY_INTERRUPTION_INFORMATION, INJECT_EXCEPTION_GP
        SetVmcsField    VMENTRY_EXCEPTION_ERROR_CODE, 0

DoWriteMsrForApicBase.Done:        
        pop ecx
        pop edx
        pop ebx
        pop ebp
        ret
        
        

;-----------------------------------------------------------------------
; DoReadMsrForApicBase()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理 guest 读 IA32_APIC_BASE 寄存器
;-----------------------------------------------------------------------
DoReadMsrForApicBase:
        push ebp
        push ebx
        push edx

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif  
        REX.Wrxb
        mov ebx, [ebp + PCB.CurrentVmbPointer]
        REX.Wrxb
        mov ebx, [ebx + VMB.VsbBase]

        mov esi, IA32_APIC_BASE
        call GetMsrVte
        REX.Wrxb
        test eax, eax
        jz DoReadMsrForApicBase.Done
        
        mov edx, [eax + MSR_VTE.Value + 4]
        mov eax, [eax + MSR_VTE.Value]
        mov [ebx + VSB.Rax], eax
        mov [ebx + VSB.Rdx], edx
        
        DEBUG_RECORD    "[DoWriteMsrForApicBase]: read from IA32_APIC_BASE"
        
        call update_guest_rip
DoReadMsrForApicBase.Done:
        pop edx
        pop ebx
        pop ebp
        ret



;-----------------------------------------------------------------------
; set_msr_read_bitmap_for_x2apic()
; input:
;       none
; output:
;       none
;-----------------------------------------------------------------------        
set_msr_read_bitmap_for_x2apic:
        SET_MSR_READ_BITMAP        IA32_X2APIC_APICID
        SET_MSR_READ_BITMAP        IA32_X2APIC_VERSION
        SET_MSR_READ_BITMAP        IA32_X2APIC_TPR
        SET_MSR_READ_BITMAP        IA32_X2APIC_PPR
        SET_MSR_READ_BITMAP        IA32_X2APIC_EOI
        SET_MSR_READ_BITMAP        IA32_X2APIC_LDR
        SET_MSR_READ_BITMAP        IA32_X2APIC_SVR
        SET_MSR_READ_BITMAP        IA32_X2APIC_ISR0
        SET_MSR_READ_BITMAP        IA32_X2APIC_ISR1
        SET_MSR_READ_BITMAP        IA32_X2APIC_ISR2
        SET_MSR_READ_BITMAP        IA32_X2APIC_ISR3
        SET_MSR_READ_BITMAP        IA32_X2APIC_ISR4
        SET_MSR_READ_BITMAP        IA32_X2APIC_ISR5
        SET_MSR_READ_BITMAP        IA32_X2APIC_ISR6
        SET_MSR_READ_BITMAP        IA32_X2APIC_ISR7
        SET_MSR_READ_BITMAP        IA32_X2APIC_TMR0
        SET_MSR_READ_BITMAP        IA32_X2APIC_TMR1
        SET_MSR_READ_BITMAP        IA32_X2APIC_TMR2
        SET_MSR_READ_BITMAP        IA32_X2APIC_TMR3
        SET_MSR_READ_BITMAP        IA32_X2APIC_TMR4
        SET_MSR_READ_BITMAP        IA32_X2APIC_TMR5
        SET_MSR_READ_BITMAP        IA32_X2APIC_TMR6
        SET_MSR_READ_BITMAP        IA32_X2APIC_TMR7
        SET_MSR_READ_BITMAP        IA32_X2APIC_IRR0
        SET_MSR_READ_BITMAP        IA32_X2APIC_IRR1
        SET_MSR_READ_BITMAP        IA32_X2APIC_IRR2
        SET_MSR_READ_BITMAP        IA32_X2APIC_IRR3
        SET_MSR_READ_BITMAP        IA32_X2APIC_IRR4
        SET_MSR_READ_BITMAP        IA32_X2APIC_IRR5
        SET_MSR_READ_BITMAP        IA32_X2APIC_IRR6
        SET_MSR_READ_BITMAP        IA32_X2APIC_IRR7
        SET_MSR_READ_BITMAP        IA32_X2APIC_ESR
        SET_MSR_READ_BITMAP        IA32_X2APIC_LVT_CMCI
        SET_MSR_READ_BITMAP        IA32_X2APIC_ICR
        SET_MSR_READ_BITMAP        IA32_X2APIC_LVT_TIMER
        SET_MSR_READ_BITMAP        IA32_X2APIC_LVT_THERMAL
        SET_MSR_READ_BITMAP        IA32_X2APIC_LVT_PMI 
        SET_MSR_READ_BITMAP        IA32_X2APIC_LVT_LINT0 
        SET_MSR_READ_BITMAP        IA32_X2APIC_LVT_LINT1 
        SET_MSR_READ_BITMAP        IA32_X2APIC_LVT_ERROR
        SET_MSR_READ_BITMAP        IA32_X2APIC_INIT_COUNT
        SET_MSR_READ_BITMAP        IA32_X2APIC_CUR_COUNT
        SET_MSR_READ_BITMAP        IA32_X2APIC_DIV_CONF
        SET_MSR_READ_BITMAP        IA32_X2APIC_SELF_IPI
        ret
        
        
;-----------------------------------------------------------------------
; set_msr_write_bitmap_for_x2apic()
; input:
;       none
; output:
;       none
;-----------------------------------------------------------------------        
set_msr_write_bitmap_for_x2apic:
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_APICID
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_VERSION
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_TPR
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_PPR
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_EOI
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_LDR
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_SVR
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_ISR0
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_ISR1
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_ISR2
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_ISR3
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_ISR4
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_ISR5
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_ISR6
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_ISR7
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_TMR0
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_TMR1
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_TMR2
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_TMR3
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_TMR4
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_TMR5
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_TMR6
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_TMR7
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_IRR0
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_IRR1
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_IRR2
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_IRR3
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_IRR4
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_IRR5
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_IRR6
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_IRR7
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_ESR
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_LVT_CMCI
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_ICR
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_LVT_TIMER
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_LVT_THERMAL
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_LVT_PMI 
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_LVT_LINT0 
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_LVT_LINT1 
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_LVT_ERROR
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_INIT_COUNT
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_CUR_COUNT
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_DIV_CONF
        SET_MSR_WRITE_BITMAP        IA32_X2APIC_SELF_IPI
        ret


;-----------------------------------------------------------------------
; clear_msr_read_bitmap_for_x2apic()
; input:
;       none
; output:
;       none
;-----------------------------------------------------------------------        
clear_msr_read_bitmap_for_x2apic:
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_APICID
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_VERSION
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_TPR
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_PPR
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_EOI
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_LDR
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_SVR
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_ISR0
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_ISR1
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_ISR2
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_ISR3
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_ISR4
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_ISR5
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_ISR6
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_ISR7
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_TMR0
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_TMR1
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_TMR2
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_TMR3
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_TMR4
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_TMR5
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_TMR6
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_TMR7
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_IRR0
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_IRR1
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_IRR2
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_IRR3
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_IRR4
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_IRR5
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_IRR6
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_IRR7
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_ESR
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_LVT_CMCI
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_ICR
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_LVT_TIMER
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_LVT_THERMAL
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_LVT_PMI 
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_LVT_LINT0 
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_LVT_LINT1 
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_LVT_ERROR
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_INIT_COUNT
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_CUR_COUNT
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_DIV_CONF
        CLEAR_MSR_READ_BITMAP        IA32_X2APIC_SELF_IPI
        ret
        
        
;-----------------------------------------------------------------------
; clear_msr_write_bitmap_for_x2apic()
; input:
;       none
; output:
;       none
;-----------------------------------------------------------------------        
clear_msr_write_bitmap_for_x2apic:
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_APICID
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_VERSION
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_TPR
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_PPR
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_EOI
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_LDR
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_SVR
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_ISR0
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_ISR1
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_ISR2
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_ISR3
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_ISR4
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_ISR5
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_ISR6
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_ISR7
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_TMR0
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_TMR1
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_TMR2
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_TMR3
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_TMR4
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_TMR5
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_TMR6
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_TMR7
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_IRR0
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_IRR1
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_IRR2
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_IRR3
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_IRR4
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_IRR5
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_IRR6
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_IRR7
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_ESR
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_LVT_CMCI
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_ICR
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_LVT_TIMER
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_LVT_THERMAL
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_LVT_PMI 
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_LVT_LINT0 
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_LVT_LINT1 
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_LVT_ERROR
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_INIT_COUNT
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_CUR_COUNT
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_DIV_CONF
        CLEAR_MSR_WRITE_BITMAP        IA32_X2APIC_SELF_IPI
        ret
        
        
        
;-----------------------------------------------------------------------
; DoWriteMsrForApicBase()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理 guest 访问 IA32_EFER 寄存器
;-----------------------------------------------------------------------
DoWriteMsrEfer:
        push ebp
        push ebx
        push edx

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
        ;; 检查保留位
        ;;
        mov eax, [ebx + VSB.Rax]
        mov edx, [ebx + VSB.Rdx]
        test eax, ~(EFER_LME | EFER_LMA | EFER_SCE | EFER_NXE)
        jnz DoWriteMsrEfer.Gp
        test edx, edx
        jnz DoWriteMsrEfer.Gp
        
        ;;
        ;; 检查是否开启 long-mode 模式
        ;;
        test eax, EFER_LME
        jz DoWriteMsrEfer.Write
        
        ;;
        ;; 在 long-mode 模式下, 更新 IDT 的 limit 为 1FFh
        ;;
        SetVmcsField    GUEST_IDTR_LIMIT, 1FFh
        
        ;;
        ;; 更新 VMM 设置的 IDTR.limit 
        ;;
        REX.Wrxb
        mov ebx, [ebp + PCB.CurrentVmbPointer]
        mov WORD [ebx + VMB.GuestImb + GIMB.HookIdtLimit], 1FFh
        
DoWriteMsrEfer.Write:
        ;;
        ;; 写入 IA32_EFER 寄存器
        ;;
        SetVmcsField    GUEST_IA32_EFER_FULL, eax
        SetVmcsField    GUEST_IA32_EFER_HIGH, edx
        jmp DoWriteMsrEfer.Resume
        
DoWriteMsrEfer.Gp:
        ;;
        ;; 注入 #GP(0) 异常
        ;;
        SetVmcsField    VMENTRY_EXCEPTION_ERROR_CODE, 0
        SetVmcsField    VMENTRY_INTERRUPTION_INFORMATION, INJECT_EXCEPTION_GP
        jmp DoWriteMsrEfer.Done

DoWriteMsrEfer.Resume:
        call update_guest_rip
                
DoWriteMsrEfer.Done:
        mov eax, VMM_PROCESS_RESUME        
        pop edx
        pop ebx
        pop ebp
        ret