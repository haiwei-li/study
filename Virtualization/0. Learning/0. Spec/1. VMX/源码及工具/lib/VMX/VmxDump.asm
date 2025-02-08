;*************************************************
;* VmxDump.asm                                   *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************


%include "..\..\inc\cpu.inc"



;-------------------------------------------------
; DUMP_GUEST_STATE_SEGMENT
; input:
;       none
; output:
;       none
; 描述: 
;       1) 打印 guest-state 段寄存器
;-------------------------------------------------
%macro  DUMP_GUEST_STATE_SEGMENT 1
        mov esi, GuestState.%1Msg
        call puts
        movzx esi, WORD [ebp + GUEST_STATE.%1Selector]
        call print_word_value
        mov esi, ','
        call putc
%ifdef __X64        
        mov edi, [ebp + GUEST_STATE.%1Base + 4]
        mov esi, [ebp + GUEST_STATE.%1Base]
        call print_qword_value
%else
        mov esi, [ebp + GUEST_STATE.%1Base]
        call print_dword_value
%endif
        mov esi, ','
        call putc
        mov esi, [ebp + GUEST_STATE.%1Limit]      
        call print_dword_value        
        mov esi, ','
        call putc
        mov esi, [ebp + GUEST_STATE.%1AccessRight]
        call print_dword_value
        call println      
%endmacro







;-------------------------------------------------
; support_intel_vmx()
; input:
;       none
; output:
;       1 - support, 0 - unsupport
; 描述: 
;       1) 检查是否支持 Intel VT-x 技术
;------------------------------------------------
support_intel_vmx:
        ;;
        ;; 检查 CPUID.01H:ECX[5].VMX 位
        ;;
        bt DWORD [gs: PCB.FeatureEcx], 5
        setc al
        movzx eax, al
        ret
        


;---------------------------------
; dump_support_intel_vmx()
; input:
;       none
; output:
;       none
;---------------------------------
dump_support_intel_vmx:
        mov esi, vmx.intel.support
        call puts
        ;;
        ;; 检查 CPUID.01H:ECX[5].VMX 位
        ;;
        bt DWORD [gs: PCB.FeatureEcx], 5
        mov eax, 1
        mov esi, vmx.yes
        mov edi, vmx.no
        cmovnc esi, edi
        call puts
        ret
    
        
        
;----------------------------------
; report vmx capabilities
;---------------------------------
dump_vmx_capabilities:       
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif  
      
        call dump_vmx_basic
        call dump_vmx_pin_based       
        call dump_vmx_processor_based        
        call dump_vmx_exit
        call dump_vmx_entry      
        call dump_vmx_fixed_cr0  
        call dump_vmx_fixed_cr4 
        call dump_vmx_vmcs_enum
        
        ;;
        ;; 打印 vmx misc
        ;;
        mov esi, vmx.miscellaneous_data
        call puts
        mov esi, [ebp + PCB.Misc + 4]
        call print_dword_value
        mov esi, vmx.underline
        call puts
        mov esi, [ebp + PCB.Misc]
        call print_dword_value        
        call println
        
        ;;
        ;; 打印 vpid ept 值
        ;;
        mov esi, vmx.vpid_ept_value
        call puts
        mov esi, [ebp + PCB.EptVpidCap + 4]
        call print_dword_value
        mov esi, vmx.underline
        call puts
        mov esi, [ebp + PCB.EptVpidCap]
        call print_dword_value        
        call println 
        
        mov esi, vmx.vm_function
        call puts
        mov ecx, IA32_VMX_VMFUNC
        xchg eax, edx
        mov esi, eax
        call print_dword_value
        mov esi, vmx.underline
        call puts
        mov esi, edx
        call print_dword_value        
        call println 

        mov esi, vmx.feature_control
        call puts
        mov ecx, IA32_FEATURE_CONTROL
        rdmsr
        xchg eax, edx
        mov esi, eax
        call print_dword_value
        mov esi, '_'
        call putc
        mov esi, edx
        call print_dword_value
        call println
        pop ebp
        ret


;---------------------------------
; report vmx basic information
;---------------------------------
dump_vmx_basic:       
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif        
        mov esi, vmx_basic.id
        call puts
        mov esi, [ebp + PCB.VmxBasic]
        call print_dword_value
        mov esi, vmx.comma
        call puts
        mov esi, vmx_basic.vmcs_size
        call puts
        mov esi, [ebp + PCB.VmxBasic + 4]
        and esi, 1FFFh
        call print_dword_decimal
        mov esi, vmx.comma
        call puts
        mov esi, vmx_basic.memory_type
        call puts
        mov eax, [ebp + PCB.VmxBasic + 4]
        shr eax, 18
        and eax, 0Fh
        test eax, eax        
        mov esi, memory_type0
        mov edi, memory_type6
        cmovnz esi, edi
        cmp eax, 6
        mov edi, memory_type
        cmovnz esi, edi
        call puts
        call println
        mov esi, dual_monitor_treatment
        call puts
        bt DWORD [ebp + PCB.VmxBasic + 4], 17                             ; dual-monitor_treatment bit
        mov esi, vmx.yes
        mov edi, vmx.no
        cmovnc esi, edi
        call puts
        mov esi, vmx.comma
        call puts
        mov esi, vmexit_instruction_info
        call puts
        bt DWORD [ebp + PCB.VmxBasic + 4], 22                             ; store VM-exit instruction information support bit
        mov esi, vmx.yes
        mov edi, vmx.no
        cmovnc esi, edi
        call puts
        mov esi, vmx.comma
        call puts      
        mov esi, vmcontrol_reset
        call puts
        bt DWORD [ebp + PCB.VmxBasic + 4], 23                             ; support VMX_TRUE_xxx MSRs
        mov esi, vmx.yes
        mov edi, vmx.no
        cmovnc esi, edi
        call puts
        call println         
        pop ebp
        ret
        
        
;---------------------------------------
; report VMX-excution control of pinbased
;---------------------------------------
dump_vmx_pin_based:
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        mov esi, vmx.pin_based
        call puts
        mov esi, vmx.pin_based_ctls
        call puts
        mov esi, vmx.pin_based.allow0
        call puts        
        mov esi, [ebp + PCB.PinBasedCtls]
        call print_dword_value
        mov esi, vmx.comma
        call puts
        mov esi, vmx.pin_based.allow1
        call puts 
        mov esi, [ebp + PCB.PinBasedCtls + 4]
        call print_dword_value
        call println   
        pop ebp 
        ret 
        
               
;---------------------------------------
; report VMX-excution control of procbased
;---------------------------------------
dump_vmx_processor_based:
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        mov esi, vmx.processor_based
        call puts
        mov esi, vmx.proc_based_primary
        call puts
        mov esi, vmx.pin_based.allow0
        call puts   
        mov esi, [ebp + PCB.ProcessorBasedCtls]
        call print_dword_value
        mov esi, vmx.comma
        call puts
        mov esi, vmx.pin_based.allow1
        call puts 
        mov esi, [ebp + PCB.ProcessorBasedCtls + 4]
        call print_dword_value
        call println
        mov esi, vmx.proc_based_secondary
        call puts
        mov esi, vmx.pin_based.allow0
        call puts 
        mov esi, [ebp + PCB.ProcessorBasedCtls2]
        call print_dword_value
        mov esi, vmx.comma
        call puts
        mov esi, vmx.pin_based.allow1
        call puts 
        mov esi, [ebp + PCB.ProcessorBasedCtls2 + 4]
        call print_dword_value
        call println
        pop ebp
        ret



;---------------------------------------
; report VMX-exit control
;---------------------------------------
dump_vmx_exit:
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        mov esi, vmx.vm_exit
        call puts
        mov esi, vmx.pin_based_ctls
        call puts
        mov esi, vmx.pin_based.allow0
        call puts        
        mov esi, [ebp + PCB.ExitCtls]
        call print_dword_value
        mov esi, vmx.comma
        call puts
        mov esi, vmx.pin_based.allow1
        call puts 
        mov esi, [ebp + PCB.ExitCtls + 4]
        call print_dword_value
        call println
        pop ebp
        ret


;---------------------------------------
; report VMX-entry control
;---------------------------------------
dump_vmx_entry:
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        mov esi, vmx.vm_entry
        call puts
        mov esi, vmx.pin_based_ctls
        call puts
        mov esi, vmx.pin_based.allow0
        call puts        
        mov esi, [ebp + PCB.EntryCtls]
        call print_dword_value
        mov esi, vmx.comma
        call puts
        mov esi, vmx.pin_based.allow1
        call puts 
        mov esi, [ebp + PCB.EntryCtls + 4]
        call print_dword_value
        call println
        pop ebp
        ret        
        
;---------------------------------------
; dump_vmx_fixed_cr0()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 打印 CR0 Fixed 信息
;---------------------------------------        
dump_vmx_fixed_cr0:
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        mov esi, vmx.cr0_fixed1
        call puts
        mov esi, [ebp + PCB.Cr0Fixed0]
        call print_dword_value
        mov esi, vmx.comma
        call puts
        mov esi, vmx.cr0_fixed0
        call puts
        mov esi, [ebp + PCB.Cr0Fixed1]
        call print_dword_value
        call println
        pop ebp
        ret



;---------------------------------------
; dump_vmx_fixed_cr4()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 打印 CR4 Fixed 信息
;---------------------------------------           
dump_vmx_fixed_cr4:
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        mov esi, vmx.cr4_fixed1
        call puts
        mov esi, [ebp + PCB.Cr4Fixed0]
        call print_dword_value
        mov esi, vmx.comma
        call puts
        mov esi, vmx.cr4_fixed0
        call puts
        mov esi, [ebp + PCB.Cr4Fixed1]
        call print_dword_value
        call println
        pop ebp
        ret


;---------------------------------------
; dump_vmx_vmcs_enum()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 打印 VMCS enum 信息
;--------------------------------------- 
dump_vmx_vmcs_enum:
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        mov esi, vmx.high_index
        call puts
        mov esi, [ebp + PCB.VmcsEnum]
        shr esi, 1
        and esi, 01FFh
        call print_dword_decimal
        call println
        pop ebp
        ret
        

;---------------------------------------
; dump_vmx_misc()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 打印 VMX 杂项信息
;---------------------------------------  
dump_vmx_misc:
        push ebx
        push ecx
        push edx
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif              
        mov esi, vmx.tsc_interval
        call puts
        mov ebx, [ebp + PCB.Misc]
        mov ecx, vmx.yes
        mov edx, vmx.no
        mov esi, ebx
        and esi, 1Fh
        call print_dword_decimal
        call println
        mov esi, vmx.lma_store
        call puts
        bt ebx, 5
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println
        mov esi, vmx.hlt
        call puts
        bt ebx, 6
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println        
        mov esi, vmx.shutdown
        call puts
        bt ebx, 7
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println          
        mov esi, vmx.sipi
        call puts
        bt ebx, 8
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println   
        mov esi, vmx.cr3_target
        call puts
        mov esi, ebx
        shr esi, 16
        and esi, 1FFh
        call print_dword_decimal
        call println
        mov esi, vmx.msr_maximum
        call puts
        mov esi, ebx
        shr esi, 25
        and esi, 7
        call print_dword_decimal
        call println
        mov esi, vmx.smm_monitor_ctl2
        call puts
        bt ebx, 28
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println
        mov esi, vmx.mesg_id
        call puts
        mov esi, [ebp + PCB.Misc + 4]
        call print_dword_value
        call println
        pop ebp
        pop edx
        pop ecx
        pop ebx
        ret


;---------------------------------------
; dump_vpid_ept()
; input:
;       none
; output:
;       none
;---------------------------------------
dump_vpid_ept:
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        mov esi, vmx.ept_bit2_0
        call puts
        mov ebx, [ebp + PCB.EptVpidCap]
        mov ecx, vmx.yes
        mov edx, vmx.no
        bt ebx, 0
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println
        mov esi, vmx.ept_walk_4
        call puts
        bt ebx, 6
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println     
        mov esi, vmx.ept_uc
        call puts
        bt ebx, 8
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println            
        mov esi, vmx.ept_wb
        call puts
        bt ebx, 14
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println 
        mov esi, vmx.ept_2m
        call puts
        bt ebx, 16
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println      
        mov esi, vmx.ept_1g
        call puts
        bt ebx, 17
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println    
        mov esi, vmx.invept
        call puts
        bt ebx, 20
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println    
        mov esi, vmx.invept_single
        call puts
        bt ebx, 25
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println                    
        mov esi, vmx.invept_all
        call puts
        bt ebx, 26
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println        
        mov esi, vmx.ept_accessed 
        call puts
        bt ebx, 21
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println  
        mov ebx, [ebp + PCB.EptVpidCap + 4]
        mov esi, vmx.invvpid
        call puts
        bt ebx, 0
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println   
        mov esi, vmx.invvpid_individual
        call puts
        bt ebx, 8
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println    
        mov esi, vmx.invvpid_single
        call puts
        bt ebx, 9
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println 
        mov esi, vmx.invvpid_all
        call puts
        bt ebx, 10
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println     
        mov esi, vmx.invvpid_scrg
        call puts
        bt ebx, 10
        mov esi, ecx
        cmovnc esi, edx
        call puts
        call println         
        pop ebp                                    
        ret
        


;--------------------------------------------------------------
; dump_vmcs()
; input:
;       none
; output:
;       none
; 描述:
;       1)打印 VMCS 所有字段信息
;--------------------------------------------------------------
dump_vmcs:
        push ebp
        push ecx
        

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif

        ;;
        ;; 清 VMCS buffer, 再读 VMCS 
        ;;
        mov esi, EXIT_INFO_SIZE
        REX.Wrxb
        lea edi, [ebp + PCB.ExitInfoBuf]
        call zero_memory
        mov esi, GUEST_STATE_SIZE
        REX.Wrxb
        lea edi, [ebp + PCB.GuestStateBuf]
        call zero_memory
        mov esi, HOST_STATE_SIZE
        REX.Wrxb
        lea edi, [ebp + PCB.HostStateBuf]
        call zero_memory  
        mov esi, EXECUTION_CONTROL_SIZE
        REX.Wrxb
        lea edi, [ebp + PCB.ExecutionControlBuf]
        call zero_memory
        mov esi, EXIT_CONTROL_SIZE
        REX.Wrxb
        lea edi, [ebp + PCB.ExitControlBuf]
        call zero_memory
        mov esi, ENTRY_CONTROL_SIZE
        REX.Wrxb
        lea edi, [ebp + PCB.EntryControlBuf]
        call zero_memory   
        
        call store_exit_info        
        call store_guest_state
        call store_host_state
        call store_execution_control
        call store_exit_control
        call store_entry_control


        ;;
        ;; 打印状态栏
        ;;
        mov esi, 24
        mov edi, 0
        call set_video_buffer
        mov esi, Status.Msg1
        call puts
        
        
        xor ecx, ecx

dump_vmcs.@0:
        ;;
        ;; 从 (2, 0) 位置, 开始清 screen
        ;;
        mov esi, 2
        mov edi, 0
        call clear_screen

        
        ;;
        ;; 定位在 (2,0) 位置
        ;;
        mov esi, 2
        mov edi, 0
        call set_video_buffer
        

        
        ;;
        ;; dump vmcs
        ;;        
        REX.Wrxb
        mov eax, [DumpFunc + ecx * 8]
        call eax

        ;;
        ;; 控制键盘
        ;;
dump_vmcs.@1:        
        call wait_a_key        
        cmp al, SC_ESC                          ; 是否为 <Esc>
        je dump_vmcs.@3
        cmp al, SC_PGUP                         ; 是否为 <PageUp>
        jne dump_vmcs.@2    
        xor esi, esi
        DECv ecx
        cmovs ecx, esi
        jmp dump_vmcs.@0
        
        
dump_vmcs.@2:
        cmp al, SC_PGDN                         ; 是否为 <PageDown>
        jne dump_vmcs.@0
        mov esi, 5
        INCv ecx
        cmp ecx, 6
        cmovae ecx, esi
        jmp dump_vmcs.@0

dump_vmcs.@3:
        ;;
        ;; 执行 CPU hard reset 操作
        ;;
        RESET_CPU  
                
        pop ecx
        pop ebp
        ret








;--------------------------------------------------------------
; dump_exit_info()
; input:
;       none
; output:
;       none
; 描述: 　
;       1) 打印 VM-exit information 域信息        
;--------------------------------------------------------------
dump_exit_info:
        push ebp
        push ecx
        
%ifdef __X64
        LoadGsBaseToRbp
        REX.Wrxb
%else
        mov ebp, [gs: PCB.Base]
%endif        
        add ebp, PCB.ExitInfoBuf

        
        
        mov esi, Vmx.ExitInfoMsg
        call puts
        mov esi, Vmx.ExitReasonMsg
        call puts
        
        
        ;;
        ;;　假如发生指令执行错误, 则打印 ExitReason 值
        ;;       
        movzx esi, WORD [ebp + EXIT_INFO.ExitReason]
        cmp DWORD [ebp + EXIT_INFO.InstructionError], 0
        cmove esi, [Vmx.ExitResonInfoTable + esi * 4]
        mov eax, puts
        mov edi, print_word_value
        cmove edi, eax
        call edi
        call println        
        
        
        
        mov esi, Vmx.QualificationMsg
        call puts        

%ifdef __X64
        mov esi, [ebp + EXIT_INFO.ExitQualification + 4]
        call print_dword_value
%endif        
        mov esi, [ebp + EXIT_INFO.ExitQualification]
        call print_dword_value
        call println
        mov esi, Vmx.GuestLinearAddrMsg
        call puts
%ifdef __X64
        mov esi, [ebp + EXIT_INFO.GuestLinearAddress + 4]
        call print_dword_value
%endif        
        mov esi, [ebp + EXIT_INFO.GuestLinearAddress]
        call print_dword_value
        call println
        mov esi, Vmx.GuestPhysicalAddrMsg
        call puts
%ifdef __X64
        mov esi, [ebp  + EXIT_INFO.GuestPhysicalAddress + 4]
        call print_dword_value
%endif        
        mov esi, [ebp  + EXIT_INFO.GuestPhysicalAddress]
        call print_dword_value
        call println
        mov esi, Vmx.VmexitInterruptionInfoMsg
        call puts
        mov esi, [ebp + EXIT_INFO.InterruptionInfo]
        call print_dword_value
        call println        
        mov esi, Vmx.VmexitInterruptionErrorCodeMsg
        call puts
        mov esi, [ebp + EXIT_INFO.InterruptionErrorCode]
        call print_dword_value
        call println        
        mov esi, Vmx.IdtVectoringInfoMsg
        call puts
        mov esi, [ebp + EXIT_INFO.IdtVectoringInfo]
        call print_dword_value
        call println        
        mov esi, Vmx.IdtVectoringErrorCodeMsg
        call puts
        mov esi, [ebp + EXIT_INFO.IdtVectoringErrorCode]
        call print_dword_value
        call println          
        mov esi, Vmx.VmexitInstructionLengthMsg
        call puts
        mov esi, [ebp + EXIT_INFO.InstructionLength]
        call print_dword_value
        call println  
        mov esi, Vmx.VmexitInstructionInfoMsg
        call puts
        mov esi, [ebp + EXIT_INFO.InstructionInfo]
        call print_dword_value
        call println  
        mov esi, Vmx.VmInstructionErrorMsg
        call puts
        mov esi, [ebp + EXIT_INFO.InstructionError]
        test esi, esi
        mov eax, dump_instruction_error_detail
        mov edi, print_dword_value
        cmovnz edi, eax
        call edi
        call println   
        
        ;;
        ;; 打印 detail 信息
        ;;
  
        cmp DWORD [ebp + EXIT_INFO.InstructionError], 0
        jne dump_exit_info.done
        
        movzx eax, WORD [ebp + EXIT_INFO.ExitReason]
        mov ecx, [Vmx.DumpDetailInfoTable + eax * 4]
        test ecx, ecx
        jz dump_exit_info.done
        
        call println
        mov esi, Vmx.ExitInfoDetailMsg
        call puts
        call ecx
                
dump_exit_info.done:        
        pop ecx
        pop ebp
        ret
        

;--------------------------------------------------------------
; dump_instruction_error_detail()
; input:
;       none
; output:
;       none
; 描述: 　
;       1) 打印 VM 指令错误信息
;--------------------------------------------------------------
dump_instruction_error_detail:
        push ebp

%ifdef __X64
        LoadGsBaseToRbp
        REX.Wrxb
%else
        mov ebp, [gs: PCB.Base]
%endif        
        add ebp, PCB.ExitInfoBuf
        mov esi, [ebp + EXIT_INFO.InstructionError]
        mov esi, [Vmx.InstructionErrorInfoTable + esi * 4]
        call puts
        pop ebp
        ret




;--------------------------------------------------------------
; dump_guest_state()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 打印 guest state 信息
;--------------------------------------------------------------
dump_guest_state:
        push ebp

%ifdef __X64
        LoadGsBaseToRbp
        REX.Wrxb
%else
        mov ebp, [gs: PCB.Base]
%endif
        add ebp, PCB.GuestStateBuf

        
        ;;
        ;; 打印信息
        ;;
        mov esi, Vmcs.GuestStateMsg
        call puts
                        
        ;;
        ;; 打印控制寄存器
        ;;
        mov esi, GuestState.CrMsg
        call puts
        mov esi, [ebp + GUEST_STATE.Cr0 + 4]
        test esi, esi
        jz dump_guest_state.@0
        call print_dword_value
dump_guest_state.@0:        
        mov esi, [ebp + GUEST_STATE.Cr0]                ; cr0
        call print_dword_value
        mov esi, ','
        call putc
        mov esi, [ebp + GUEST_STATE.Cr3 + 4]
        test esi, esi
        jz dump_guest_state.@1
        call print_dword_value
dump_guest_state.@1:             
        mov esi, [ebp + GUEST_STATE.Cr3]                ; cr3
        call print_dword_value
        mov esi, ','
        call putc
        mov esi, [ebp + GUEST_STATE.Cr4 + 4]
        test esi, esi
        jz dump_guest_state.@2
        call print_dword_value
dump_guest_state.@2:             
        mov esi, [ebp + GUEST_STATE.Cr4]                ; cr4
        call print_dword_value
        mov esi, ','
        call putc
        mov esi, [ebp + GUEST_STATE.Dr7]                ; dr7
        call print_dword_value
        call println           
        mov esi, GuestState.RspMsg
        call puts
        
%ifdef  __X64
        mov esi, [ebp + GUEST_STATE.Rsp]                ; rsp
        mov edi, [ebp + GUEST_STATE.Rsp + 4]            ; 
        call print_qword_value        
%else      
        mov esi, [ebp + GUEST_STATE.Rsp]                ; rsp
        call print_dword_value
%endif        
        mov esi, ','
        call putc
        
%ifdef  __X64
        mov esi, [ebp + GUEST_STATE.Rip]                ; rip
        mov edi, [ebp + GUEST_STATE.Rip + 4]            ; 
        call print_qword_value        
%else      
        mov esi, [ebp + GUEST_STATE.Rip]
        call print_dword_value
%endif 
        mov esi, ','
        call putc
        mov esi, [ebp + GUEST_STATE.Rflags]             ; rflags
        call print_dword_value
        call println
        
                
        ;;
        ;; 打印段寄存器
        ;;
        DUMP_GUEST_STATE_SEGMENT        Es
        DUMP_GUEST_STATE_SEGMENT        Cs
        DUMP_GUEST_STATE_SEGMENT        Ss
        DUMP_GUEST_STATE_SEGMENT        Ds
        DUMP_GUEST_STATE_SEGMENT        Fs
        DUMP_GUEST_STATE_SEGMENT        Gs
        DUMP_GUEST_STATE_SEGMENT        Ldtr
        DUMP_GUEST_STATE_SEGMENT        Tr
        
        ;;
        ;; 打印 GDTR/IDTR
        ;;
        mov esi, GuestState.GdtrMsg
        call puts
%ifdef __X64        
        mov esi, [ebp + GUEST_STATE.GdtrBase]
        mov edi, [ebp + GUEST_STATE.GdtrBase + 4]
        call print_qword_value
%else        
        mov esi, [ebp + GUEST_STATE.GdtrBase]
        call print_dword_value
%endif        
        mov esi, ','
        call putc
        mov esi, [ebp + GUEST_STATE.GdtrLimit]
        call print_dword_value
        call println
        mov esi, GuestState.IdtrMsg
        call puts
%ifdef __X64        
        mov esi, [ebp + GUEST_STATE.IdtrBase]
        mov edi, [ebp + GUEST_STATE.IdtrBase + 4]
        call print_qword_value
%else        
        mov esi, [ebp + GUEST_STATE.IdtrBase]
        call print_dword_value
%endif        
        mov esi, ','
        call putc        
        mov esi, [ebp + GUEST_STATE.IdtrLimit]
        call print_dword_value
        call println        

        
        ;;
        ;; 打印 IA32_SYSENTER 组
        ;;
        mov esi, GuestState.SysenterMsg
        call puts
        mov esi, [ebp + GUEST_STATE.SysenterCsMsr]
        call print_dword_value
        mov esi, ','
        call putc
%ifdef __X64        
        mov esi, [ebp + GUEST_STATE.SysenterEspMsr]
        mov edi, [ebp + GUEST_STATE.SysenterEspMsr + 4]
        call print_qword_value
%else
        mov esi, [ebp + GUEST_STATE.SysenterEspMsr]
        call print_dword_value
%endif        
        mov esi, ','
        call putc
%ifdef __X64        
        mov esi, [ebp + GUEST_STATE.SysenterEipMsr]
        mov edi, [ebp + GUEST_STATE.SysenterEipMsr + 4]
        call print_qword_value
%else
        mov esi, [ebp + GUEST_STATE.SysenterEipMsr]
        call print_dword_value
%endif  
        call println        
        
        
        ;;
        ;; 打印 debug ctl 组
        ;;
        mov esi, GuestState.MsrCtlMsg
        call puts
        mov esi, [ebp + GUEST_STATE.DebugCtlMsr]
        mov edi, [ebp + GUEST_STATE.DebugCtlMsr + 4]
        call print_qword_value
        mov esi, ','
        call putc
        mov esi, [ebp + GUEST_STATE.PerfGlobalCtlMsr]
        mov edi, [ebp + GUEST_STATE.PerfGlobalCtlMsr + 4]
        call print_qword_value        
        call println
        
        ;;
        ;; 打印 Msr
        ;;
        mov esi, GuestState.MsrMsg
        call puts
        mov esi, [ebp + GUEST_STATE.PatMsr]
        mov edi, [ebp + GUEST_STATE.PatMsr + 4]
        call print_qword_value
        mov esi, ','
        call putc
        mov esi, [ebp + GUEST_STATE.EferMsr]
        mov edi, [ebp + GUEST_STATE.EferMsr + 4]
        call print_qword_value        
        call println

        mov esi, GuestState.StateMsg
        call puts
        mov esi, [ebp + GUEST_STATE.ActivityState]              ; activity state
        call print_dword_value
        mov esi, ','
        call putc
        mov esi, [ebp + GUEST_STATE.InterruptibilityState]      ; interruptibility state
        call print_dword_value
        mov esi, ','
        call putc
        mov esi, [ebp + GUEST_STATE.PendingDebugException]      ; pending debug exception
        call print_dword_value
        call println         
        mov esi, GuestState.VlpMsg
        call puts
        mov esi, [ebp + GUEST_STATE.VmcsLinkPointer]            ; VMCS link pointer
        mov edi, [ebp + GUEST_STATE.VmcsLinkPointer + 4]
        call print_qword_value
        call println
        mov esi, GuestState.PtvMsg
        call puts
        mov esi, [ebp + GUEST_STATE.VmxPreemptionTimerValue]    ; vmx preemption timer value
        call print_dword_value
        call println    
        mov esi, GuestState.PdpteMsg
        call puts
        mov esi, [ebp + GUEST_STATE.Pdpte0]                     ; Pdpte0
        mov edi, [ebp + GUEST_STATE.Pdpte0 + 4]
        call print_qword_value
        mov esi, ','
        call putc
        mov esi, [ebp + GUEST_STATE.Pdpte1]                     ; Pdpte1
        mov edi, [ebp + GUEST_STATE.Pdpte1 + 4]
        call print_qword_value
        call println
        mov esi, GuestState.SpaceMsg
        call puts
        mov esi, [ebp + GUEST_STATE.Pdpte2]                     ; Pdpte2
        mov edi, [ebp + GUEST_STATE.Pdpte2 + 4]
        call print_qword_value
        mov esi, ','
        call putc
        mov esi, [ebp + GUEST_STATE.Pdpte3]                     ; Pdpte3
        mov edi, [ebp + GUEST_STATE.Pdpte3 + 4]
        call print_qword_value
        call println
        
        
        mov esi, GuestState.GisMsg
        call puts
        mov esi, [ebp + GUEST_STATE.GuestInterruptStatus]      ; Guest Interrupt Status
        call print_word_value
        call println                  
        pop ebp                
        ret



;--------------------------------------------------------------
; dump_host_state()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 打印 host state 信息
;--------------------------------------------------------------
dump_host_state:
        push ebp

%ifdef __X64
        LoadGsBaseToRbp
        REX.Wrxb
%else
        mov ebp, [gs: PCB.Base]
%endif
        add ebp, PCB.HostStateBuf

        
        ;;
        ;; 打印信息
        ;;
        mov esi, Vmcs.HostStateMsg
        call puts
                        
        ;;
        ;; 打印控制寄存器
        ;;
        mov esi, HostState.CrMsg
        call puts
        mov esi, [ebp + HOST_STATE.Cr0 + 4]
        test esi, esi
        jz dump_host_state.@0
        call print_dword_value
dump_host_state.@0:        
        mov esi, [ebp + HOST_STATE.Cr0]                ; cr0
        call print_dword_value
        mov esi, ','
        call putc
        mov esi, [ebp + HOST_STATE.Cr3 + 4]
        test esi, esi
        jz dump_host_state.@1
        call print_dword_value
dump_host_state.@1:             
        mov esi, [ebp + HOST_STATE.Cr3]                ; cr3
        call print_dword_value
        mov esi, ','
        call putc
        mov esi, [ebp + HOST_STATE.Cr4 + 4]
        test esi, esi
        jz dump_host_state.@2
        call print_dword_value
dump_host_state.@2:             
        mov esi, [ebp + HOST_STATE.Cr4]                ; cr4
        call print_dword_value
        call println


        ;;
        ;; 打印 rsp/rip
        ;;        
        mov esi, HostState.RspMsg
        call puts
        
%ifdef  __X64
        mov esi, [ebp + HOST_STATE.Rsp]                ; rsp
        mov edi, [ebp + HOST_STATE.Rsp + 4]            ; 
        call print_qword_value        
%else      
        mov esi, [ebp + HOST_STATE.Rsp]                ; rsp
        call print_dword_value
%endif        
        mov esi, ','
        call putc
        
%ifdef  __X64
        mov esi, [ebp + HOST_STATE.Rip]                ; rip
        mov edi, [ebp + HOST_STATE.Rip + 4]            ; 
        call print_qword_value        
%else      
        mov esi, [ebp + HOST_STATE.Rip]
        call print_dword_value
%endif 
        call println
        
        
        ;;
        ;; 打印 selector
        ;;       
        mov esi, HostState.SelectorMsg
        call puts        
        mov si, [ebp + HOST_STATE.EsSelector]           ; es
        call print_word_value
        mov esi, ','
        call putc
        mov si, [ebp + HOST_STATE.CsSelector]           ; cs
        call print_word_value
        mov esi, ','
        call putc
        mov si, [ebp + HOST_STATE.SsSelector]           ; ss
        call print_word_value
        mov esi, ','
        call putc
        mov si, [ebp + HOST_STATE.DsSelector]           ; ds
        call print_word_value
        mov esi, ','
        call putc
        mov si, [ebp + HOST_STATE.FsSelector]           ; fs
        call print_word_value
        mov esi, ','
        call putc
        mov si, [ebp + HOST_STATE.GsSelector]           ; gs
        call print_word_value
        mov esi, ','
        call putc
        mov si, [ebp + HOST_STATE.TrSelector]           ; Tr
        call print_word_value
        call println
        
        ;;
        ;; 打印 base
        ;;
        mov esi, HostState.BaseMsg
        call puts
        
%ifdef __X64
        mov esi, [ebp + HOST_STATE.FsBase + 4]
        call print_dword_value
%endif        
        mov esi, [ebp + HOST_STATE.FsBase]
        call print_dword_value
        mov esi, ','
        call putc
%ifdef __X64
        mov esi, [ebp + HOST_STATE.GsBase + 4]
        call print_dword_value
%endif        
        mov esi, [ebp + HOST_STATE.GsBase]
        call print_dword_value
        mov esi, ','
        call putc
%ifdef __X64
        mov esi, [ebp + HOST_STATE.TrBase + 4]
        call print_dword_value
%endif        
        mov esi, [ebp + HOST_STATE.TrBase]
        call print_dword_value
        call println
        mov esi, HostState.SpaceMsg
        call puts
%ifdef __X64
        mov esi, [ebp + HOST_STATE.GdtrBase + 4]
        call print_dword_value
%endif        
        mov esi, [ebp + HOST_STATE.GdtrBase]
        call print_dword_value
        mov esi, ','
        call putc
%ifdef __X64
        mov esi, [ebp + HOST_STATE.IdtrBase + 4]
        call print_dword_value
%endif        
        mov esi, [ebp + HOST_STATE.IdtrBase]
        call print_dword_value
        call println
        
        ;;
        ;; 打印 IA32_SYSENTER 组
        ;;
        mov esi, HostState.SysenterMsg
        call puts
        mov esi, [ebp + HOST_STATE.SysenterCsMsr]
        call print_dword_value
        mov esi, ','
        call putc
%ifdef __X64        
        mov esi, [ebp + HOST_STATE.SysenterEspMsr]
        mov edi, [ebp + HOST_STATE.SysenterEspMsr + 4]
        call print_qword_value
%else
        mov esi, [ebp + HOST_STATE.SysenterEspMsr]
        call print_dword_value
%endif        
        mov esi, ','
        call putc
%ifdef __X64        
        mov esi, [ebp + HOST_STATE.SysenterEipMsr]
        mov edi, [ebp + HOST_STATE.SysenterEipMsr + 4]
        call print_qword_value
%else
        mov esi, [ebp + HOST_STATE.SysenterEipMsr]
        call print_dword_value
%endif  
        call println        
        
        
        ;;
        ;; 打印 MSR 组
        ;;
        mov esi, HostState.MsrMsg
        call puts
        mov esi, [ebp + HOST_STATE.PerfGlobalCtlMsr]
        mov edi, [ebp + HOST_STATE.PerfGlobalCtlMsr + 4]
        call print_qword_value        
        mov esi, ','
        call putc
        mov esi, [ebp + HOST_STATE.PatMsr]
        mov edi, [ebp + HOST_STATE.PatMsr + 4]
        call print_qword_value
        mov esi, ','
        call putc
        mov esi, [ebp + HOST_STATE.EferMsr]
        mov edi, [ebp + HOST_STATE.EferMsr + 4]
        call print_qword_value        
        call println
                
        pop ebp
        ret



;--------------------------------------------------------------
; dump_execution_control()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 打印 VM-execution control 信息
;--------------------------------------------------------------
dump_execution_control:
        push ebp
        ;push ecx

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif

        REX.Wrxb
        add ebp, PCB.ExecutionControlBuf
        
        
        mov esi, Vmcs.ExecutionCtlMsg
        call puts
        mov esi, ExeCtl.PinbasedMsg
        call puts
        mov esi, [ebp + EXECUTION_CONTROL.PinControl]
        call print_dword_value
        call println
        mov esi, ExeCtl.ProcbasedMsg
        call puts
        mov esi, [ebp + EXECUTION_CONTROL.ProcessorControl1]
        call print_dword_value
        mov esi, ','
        call putc
        mov esi, [ebp + EXECUTION_CONTROL.ProcessorControl2]
        call print_dword_value        
        call println
        mov esi, ExeCtl.ExceBitmapMsg
        call puts
        mov esi, [ebp + EXECUTION_CONTROL.ExceptionBitmap]
        call print_dword_value
        mov esi, ','
        call putc
        mov esi, [ebp + EXECUTION_CONTROL.PfErrorCodeMask]
        call print_dword_value
        mov esi, ','
        call putc
        mov esi, [ebp + EXECUTION_CONTROL.PfErrorCodeMatch]
        call print_dword_value
        call println

        
        mov esi, ExeCtl.IoBitmapAddrMsg
        call puts
        mov esi, [ebp + EXECUTION_CONTROL.IoBitmapAddressA]
        mov edi, [ebp + EXECUTION_CONTROL.IoBitmapAddressA + 4]
        call print_qword_value
        mov esi, ','
        call putc
        mov esi, [ebp + EXECUTION_CONTROL.IoBitmapAddressB]
        mov edi, [ebp + EXECUTION_CONTROL.IoBitmapAddressB + 4]
        call print_qword_value        
        call println
        mov esi, ExeCtl.TscOffsetMsg
        call puts
        mov esi, [ebp + EXECUTION_CONTROL.TscOffset]
        mov edi, [ebp + EXECUTION_CONTROL.TscOffset + 4]
        call print_qword_value
        call println
        mov esi, ExeCtl.MaskShadowMsg
        call puts

%ifdef __X64        
        mov esi, [ebp + EXECUTION_CONTROL.Cr0GuestHostMask + 4]
        call print_dword_value        
%endif        
        mov esi, [ebp + EXECUTION_CONTROL.Cr0GuestHostMask]
        call print_dword_value
        mov esi, ','
        call putc
%ifdef __X64        
        mov esi, [ebp + EXECUTION_CONTROL.Cr0ReadShadow + 4]        
        call print_dword_value
%endif        
        mov esi, [ebp + EXECUTION_CONTROL.Cr0ReadShadow]
        call print_dword_value
        call println
        mov esi, ExeCtl.SpaceMsg
        call puts
%ifdef __X64        
        mov esi, [ebp + EXECUTION_CONTROL.Cr4GuestHostMask + 4]
        call print_dword_value        
%endif        
        mov esi, [ebp + EXECUTION_CONTROL.Cr4GuestHostMask]
        call print_dword_value
        mov esi, ','
        call putc
%ifdef __X64        
        mov esi, [ebp + EXECUTION_CONTROL.Cr4ReadShadow + 4]        
        call print_dword_value
%endif        
        mov esi, [ebp + EXECUTION_CONTROL.Cr4ReadShadow]
        call print_dword_value
        call println     
    

        ;;
        ;; 打印 CR3-target count 与 value
        ;;
        mov esi, ExeCtl.CtcMsg
        call puts   
        mov esi, [ebp + EXECUTION_CONTROL.Cr3TargetCount]
        call print_dword_decimal     
        call println
        mov esi, ExeCtl.CtvMsg
        call puts
%ifdef __X64        
        mov esi, [ebp + EXECUTION_CONTROL.Cr3Target0 + 4]
        call print_dword_value
%endif
        mov esi, [ebp + EXECUTION_CONTROL.Cr3Target0]                   ; CR3-target value0
        call print_dword_value       
        mov esi, ','
        call putc
%ifdef __X64        
        mov esi, [ebp + EXECUTION_CONTROL.Cr3Target1 + 4]
        call print_dword_value
%endif
        mov esi, [ebp + EXECUTION_CONTROL.Cr3Target1]                   ; CR3-target value1
        call print_dword_value           
        call println
        mov esi, ExeCtl.SpaceMsg
        call puts
%ifdef __X64        
        mov esi, [ebp + EXECUTION_CONTROL.Cr3Target2 + 4]
        call print_dword_value
%endif
        mov esi, [ebp + EXECUTION_CONTROL.Cr3Target2]                   ; CR3-target value2
        call print_dword_value           
        mov esi, ','
        call putc
%ifdef __X64        
        mov esi, [ebp + EXECUTION_CONTROL.Cr3Target3 + 4]
        call print_dword_value
%endif
        mov esi, [ebp + EXECUTION_CONTROL.Cr3Target3]                   ; CR3-target value3
        call print_dword_value           
        call println
        ;;
        ;; APIC-access page 与 Virtual-APIC address
        ;;
        mov esi, ExeCtl.ApicAddrMsg 
        call puts
        mov esi, [ebp + EXECUTION_CONTROL.ApicAccessAddress]
        mov edi, [ebp + EXECUTION_CONTROL.ApicAccessAddress + 4]
        call print_qword_value
        mov esi, ','
        call putc
        mov esi, [ebp + EXECUTION_CONTROL.VirtualApicAddress]
        mov edi, [ebp + EXECUTION_CONTROL.VirtualApicAddress + 4]
        call print_qword_value        
        call println
        mov esi, ExeCtl.TprThresholdMsg
        call puts
        mov esi, [ebp + EXECUTION_CONTROL.TprThreshold]
        call print_dword_value
        call println
        
        ;;
        ;; EOI-exit bitmap
        ;;
        mov esi, ExeCtl.EeBitmapMsg  
        call puts
        mov esi, [ebp + EXECUTION_CONTROL.EoiBitmap0]
        mov edi, [ebp + EXECUTION_CONTROL.EoiBitmap0 + 4]
        call print_qword_value
        mov esi, ','
        call putc
        mov esi, [ebp + EXECUTION_CONTROL.EoiBitmap1]
        mov edi, [ebp + EXECUTION_CONTROL.EoiBitmap1 + 4]
        call print_qword_value
        call println
        mov esi, ExeCtl.SpaceMsg
        call puts
        mov esi, [ebp + EXECUTION_CONTROL.EoiBitmap2]
        mov edi, [ebp + EXECUTION_CONTROL.EoiBitmap2 + 4]
        call print_qword_value
        mov esi, ','
        call putc
        mov esi, [ebp + EXECUTION_CONTROL.EoiBitmap3]
        mov edi, [ebp + EXECUTION_CONTROL.EoiBitmap3 + 4]
        call print_qword_value
        call println
        mov esi, ExeCtl.PostedIntMsg
        call puts
        mov si, [ebp + EXECUTION_CONTROL.PostedInterruptVector]
        call print_word_value
        mov esi, ','
        call putc
        mov esi, [ebp + EXECUTION_CONTROL.PostedInterruptDescriptorAddr]
        mov edi, [ebp + EXECUTION_CONTROL.PostedInterruptDescriptorAddr +  4]
        call print_qword_value
        call println
        mov esi, ExeCtl.MsrAddrMsg
        call puts
        mov esi, [ebp + EXECUTION_CONTROL.MsrBitmapAddress]
        mov edi, [ebp + EXECUTION_CONTROL.MsrBitmapAddress + 4]
        call print_qword_value
        call println

     
        mov esi, ExeCtl.EvpMsg
        call puts
        mov esi, [ebp + EXECUTION_CONTROL.ExecutiveVmcsPointer]
        mov edi, [ebp + EXECUTION_CONTROL.ExecutiveVmcsPointer + 4]
        call print_qword_value
        call println
        mov esi, ExeCtl.EptpMsg
        call puts
        mov esi, [ebp + EXECUTION_CONTROL.EptPointer]
        mov edi, [ebp + EXECUTION_CONTROL.EptPointer + 4]
        call print_qword_value
        call println                
        mov esi, ExeCtl.VpidMsg
        call puts
        mov si, [ebp + EXECUTION_CONTROL.Vpid]
        call print_word_value
        call println
        mov esi, ExeCtl.PleMsg
        call puts
        mov esi, [ebp + EXECUTION_CONTROL.PleGap]
        call print_dword_value
        mov esi, ','
        call putc
        mov esi, [ebp + EXECUTION_CONTROL.PleWindow]
        call print_dword_value
        call println        
        mov esi, ExeCtl.VfcMsg
        call puts
        mov esi, [ebp + EXECUTION_CONTROL.VmFunctionControl]
        mov edi, [ebp + EXECUTION_CONTROL.VmFunctionControl + 4]
        call print_qword_value
        mov esi, ','
        call putc
        mov esi, [ebp + EXECUTION_CONTROL.EptpListAddress]
        mov edi, [ebp + EXECUTION_CONTROL.EptpListAddress + 4]
        call print_qword_value
        call println 
        
        ;pop ecx
        pop ebp
        ret




;--------------------------------------------------------------
; dump_exit_control()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 打印 VM-exit control 信息
;--------------------------------------------------------------
dump_exit_control:
        push ebp

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        REX.Wrxb
        add ebp, PCB.ExitControlBuf
        
        
        mov esi, Vmcs.ExitCtlMsg
        call puts
        mov esi, ExitCtl.ExitMsg
        call puts
        mov esi, [ebp + EXIT_CONTROL.VmExitControl]
        call print_dword_value
        call println
        mov esi, ExitCtl.MscMsg
        call puts
        mov esi, [ebp + EXIT_CONTROL.MsrStoreCount]
        call print_dword_decimal
        call println
        mov esi, ExitCtl.MsaMsg
        call puts
        mov esi, [ebp + EXIT_CONTROL.MsrStoreAddress]
        mov edi, [ebp + EXIT_CONTROL.MsrStoreAddress + 4]
        call print_qword_value
        call println        
        mov esi, ExitCtl.MlcMsg
        call puts
        mov esi, [ebp + EXIT_CONTROL.MsrLoadCount]
        call print_dword_decimal
        call println
        mov esi, ExitCtl.MlaMsg
        call puts
        mov esi, [ebp + EXIT_CONTROL.MsrLoadAddress]
        mov edi, [ebp + EXIT_CONTROL.MsrLoadAddress + 4]
        call print_qword_value
        call println  
                
        pop ebp
        ret
        


;--------------------------------------------------------------
; dump_entry_control()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 打印 VM-entry control 信息
;--------------------------------------------------------------
dump_entry_control:
        push ebp

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        REX.Wrxb
        add ebp, PCB.EntryControlBuf
        
       
        mov esi, Vmcs.EntryCtlMsg
        call puts
        mov esi, EntryCtl.EntryMsg
        call puts
        mov esi, [ebp + ENTRY_CONTROL.VmEntryControl]
        call print_dword_value
        call println
        mov esi, EntryCtl.MlcMsg
        call puts
        mov esi, [ebp + ENTRY_CONTROL.MsrLoadCount]
        call print_dword_decimal
        call println
        mov esi, EntryCtl.MlaMsg
        call puts
        mov esi, [ebp + ENTRY_CONTROL.MsrLoadAddress]
        mov edi, [ebp + ENTRY_CONTROL.MsrLoadAddress + 4]
        call print_qword_value
        call println
        mov esi, EntryCtl.IiMsg
        call puts
        mov esi, [ebp + ENTRY_CONTROL.InterruptionInfo]
        call print_dword_value
        call println
        mov esi, EntryCtl.EecMsg
        call puts
        mov esi, [ebp + ENTRY_CONTROL.ExceptionErrorCode]
        call print_dword_value
        call println
        mov esi, EntryCtl.InstLengthMsg
        call puts
        mov esi, [ebp + ENTRY_CONTROL.InstructionLength]
        call print_dword_decimal
        call println                                        
        pop ebp
        ret


;--------------------------------------------------------------
; dump_ept_paging()
; input:
;       esi - guest physical address
; output:
;       none
; 描述: 
;       1) 在 VMM 里打印 GPA 的页表结构
;--------------------------------------------------------------
dump_ept_paging:
        push ebp
        push ebx
        
        REX.Wrxb
        mov ebx, esi
        
        mov eax, SDA.EptPxtBase64
        REX.Wrxb
        mov ebp, [fs: eax]                                      ; ebp = PML4T base
        
dump_ept_paging.@1:
        ;;
        ;; ### walk step 1: 读取 PXE 值 ###
        ;;

        pop ebx        
        pop ebp
        ret



;--------------------------------------------------------------
; dump_detail_of_tpr_threshold()
; input:
;       none
; output:
;       none
;--------------------------------------------------------------
dump_detail_of_tpr_threshold:
        push ebp

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif

        mov esi, Detail.Tpr.Msg
        call puts
        mov esi, [ebp + PCB.ExecutionControlBuf + EXECUTION_CONTROL.TprThreshold]
        call print_dword_value
        call println
        mov esi, Detail.Tpr.Msg1
        call puts
        REX.Wrxb
        mov eax, [ebp + PCB.CurrentVmbPointer]
        REX.Wrxb
        mov eax, [eax + VMB.VirtualApicAddress]
        mov esi, [eax + TPR]
        call print_dword_value
        
        pop ebp        
        ret



;--------------------------------------------------------------
; dump_detail_of_mtf()
; input:
;       none
; output:
;       none
;--------------------------------------------------------------
dump_detail_of_mtf:
        push ebp

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        mov esi, Detail.Mtf.Msg
        call puts
        mov esi, vmx.yes
        mov eax, [ebp + PCB.ExecutionControlBuf + EXECUTION_CONTROL.ProcessorControl1]
        test eax, MONITOR_TRAP_FLAG
        mov eax, vmx.no
        cmovz esi, eax
        call puts         
        pop ebp
        ret



;--------------------------------------------------------------
; dump_detail_of_gdtr()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 打印由 access GDTR 或 IDTR 引发的 VM-exit 信息
;--------------------------------------------------------------
dump_detail_of_gdtr:
        push ebp

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        pop ebp
        ret
        





;----------------------------------------
; vmx global data
;----------------------------------------
vmx_basic                       dq 0
vmx_pin_based_ctls              dq 0
vmx_processor_based_ctls        dq 0
vmx_exit_ctls                   dq 0
vmx_entry_ctls                  dq 0
vmx_misc                        dq 0
vmx_cr0_fixed0                  dq 0
vmx_cr0_fixed1                  dq 0
vmx_cr4_fixed0                  dq 0
vmx_cr4_fixed1                  dq 0
vmx_vmcs_enum                   dq 0
vmx_processor_based_ctls2       dq 0
vmx_ept_vpid_cap                dq 0
vmx_true_pin_based_ctls         dq 0
vmx_true_processor_based_ctls   dq 0
vmx_true_exit_ctls              dq 0
vmx_true_entry_ctls             dq 0




vmx.intel.support       db 'Intel Virtual Machine Extensions support: ', 0
vmx.yes                 db 'Yes', 0
vmx.no                  db 'No', 0
vmx.bracket.left        db '(', 0
vmx.bracket.right       db ')', 0
vmx.comma               db ', ', 0
vmx.underline           db '_', 0

vmx_basic.id            db 'revision id:', 0
vmx_basic.vmcs_size     db 'VMCS region Size:', 0
vmx_basic.memory_type   db 'Memory type:', 0
memory_type0            db 'Uncahceable', 0
memory_type6            db 'WriteBack', 0
memory_type             db 'Not used', 0
dual_monitor_treatment  db 'dual monitor:', 0
vmexit_instruction_info db 'VM-exit INS/OUTS report:', 0
vmcontrol_reset         db 'support VMX_TRUE MSRs:', 0
vmx.pin_based           db '==============<<Pin-based VM-execution control allow>>=========', 10, 0
vmx.processor_based     db '=============<<Proc-based VM-execution control allow>>=========', 10, 0
vmx.pin_based_ctls      db '<ctls>: ', 0
vmx.true_pin_based_ctls db '<true>: ', 0
vmx.proc_based_primary          db '<primary_ctls>: ', 0
vmx.true_proc_based_primary     db '<true_primary>: ', 0
vmx.proc_based_secondary        db '<secondary>:    ', 0
vmx.pin_based.allow0    db 'allowed 0-setting:', 0 
vmx.pin_based.allow1    db 'allowed 1-setting:', 0
vmx.vm_exit             db '=============<<VM-exit control allow>>=================', 10, 0
vmx.vm_entry            db '=============<<VM-entry control allow>>================', 10, 0
vmx.cr0_fixed1          db '<CR0> fixed to 1:', 0
vmx.cr0_fixed0          db 'fixed to 0:', 0
vmx.cr4_fixed1          db '<CR4> fixed to 1:', 0
vmx.cr4_fixed0          db 'fixed to 0:', 0
vmx.high_index          db '<VMCS highest index value>:  ', 0
vmx.miscellaneous_data  db '<vmx miscellaneous data>:    ', 0
vmx.vpid_ept_value      db '<vpid and ept capabilities>: ', 0
vmx.vm_function         db '<VM function control>:       ', 0
vmx.feature_control     db '<IA32_FEATURE_CONTROL>:      ', 0

vmx.tsc_interval        db 'TSC interval:     ', 0
vmx.lma_store           db 'IA32_EFER.LMA store:                ', 0
vmx.hlt                 db 'support HLT state:                  ', 0
vmx.shutdown            db 'support SHUTDOWN state:             ', 0
vmx.sipi                db 'support WAIT_FOR_SIPI state:        ', 0
vmx.cr3_target          db 'CR3 target count: ', 0
vmx.msr_maximum         db 'MSR maximum:      ', 0
vmx.smm_monitor_ctl2    db 'IA32_SMM_MONITOR_CTL[2]: available: ', 0
vmx.mesg_id             db 'MESG revision id: ', 0

vmx.ept_bit2_0          db 'support EPT entry[2:0] to 100b:                   ', 0
vmx.ept_walk_4          db 'support page-walk length of 4:                    ', 0
vmx.ept_uc              db 'support EPT entry for memory type UC:             ', 0
vmx.ept_wb              db 'support EPT entry for memory type WB:             ', 0
vmx.ept_2m              db 'support EPT pde entry for 2M-page:                ', 0
vmx.ept_1g              db 'support EPT pdpte entry for 1g-page:              ', 0
vmx.invept              db 'support INVEPT instruction:                       ', 0
vmx.invept_single       db 'support single-context INVEPT:                    ', 0
vmx.invept_all          db 'support all-conext INVEPT:                        ', 0
vmx.ept_accessed        db 'support EPT entry accessed and dirty flags:       ', 0
vmx.invvpid             db 'support INVVPID instruction:                      ', 0
vmx.invvpid_individual  db 'support individual-address INVVPID:               ', 0
vmx.invvpid_single      db 'support single-context INVVPID:                   ', 0
vmx.invvpid_all         db 'support all-conext INVVPID:                       ', 0
vmx.invvpid_scrg        db 'support single-context-retaining-globals INVVPID: ', 0



Vmx.ExitInfoMsg         db '============= VM-exit information ==================', 10, 0
Vmx.ExitInfoDetailMsg   db '============= detail information ==================', 10, 0

Vmx.ExitReasonMsg                       db 'exit reason:                      ', 0
Vmx.QualificationMsg                    db 'exit qualification:               ', 0
Vmx.GuestLinearAddrMsg                  db 'guest-linear address:             ', 0
Vmx.GuestPhysicalAddrMsg                db 'guest-physical address:           ', 0
Vmx.VmexitInterruptionInfoMsg           db 'VM-exit interruption information: ', 0
Vmx.VmexitInterruptionErrorCodeMsg      db 'VM-exit interruption error code:  ', 0
Vmx.IdtVectoringInfoMsg                 db 'IDT-vectoring information:        ', 0
Vmx.IdtVectoringErrorCodeMsg            db 'IDT-vectoring error code:         ', 0
Vmx.VmexitInstructionLengthMsg          db 'VM-exit instruction length:       ', 0
Vmx.VmexitInstructionInfoMsg            db 'VM-exit instruction information:  ', 0
Vmx.VmInstructionErrorMsg               db 'VM instruction error:             ', 0


Detail.Tpr.Msg                          db 'TPR threshold:                    ', 0
Detail.Tpr.Msg1                         db 'VPTR:                             ', 0
Detail.Mtf.Msg                          db 'monitor trap flag:                ', 0
Detail.Gdtr.Scale.Msg                   db 'scale: ', 0
Detail.Gdtr.Base.Msg                    db 'base: ', 0
Detail.Gdtr.Index.Msg                   db 'index: ', 0
Detail.Gdtr.Adr.Msg                     db 'address size = ', 0
Detail.Gdtr.Ops.Msg                     db 'operand size = ', 0
Detail.Gdtr.Seg.Msg                     db 'segment = ', 0
Detail.Gdtr.Id.Msg                      db 'instruction: ', 0
Detail.Gdtr.Sgdt.Msg                    db 'sgdt', 0
Detail.Gdtr.Sidt.Msg                    db 'sidt', 0
Detail.Gdtr.lgdt.Msg                    db 'lgdt', 0
Detail.Gdtr.lidt.Msg                    db 'lidt', 0





;;
;; VM 指令错误码信息
;;
ErrorNumber1    db      'VMCALL executed in VMX root operation', 0
ErrorNumber2    db      'VMCLEAR with invalid physical address', 0
ErrorNumber3    db      'VMCLEAR with VMXON pointer', 0
ErrorNumber4    db      'VMLAUNCH with non-clear VMCS', 0
ErrorNumber5    db      'VMRESUME with non-launched VMCS', 0
ErrorNumber6    db      'VMRESUME after VMXOFF (VMXOFF and VMXON between VMLAUNCH and VMRESUME)', 10, 0
ErrorNumber7    db      'VM entry with invalid control field(s)', 0
ErrorNumber8    db      'VM entry with invalid host-state field(s)',  0
ErrorNumber9    db      'VMPTRLD with invalid physical address', 0
ErrorNumber10   db      'VMPTRLD with VMXON pointer',  0
ErrorNumber11   db      'VMPTRLD with incorrect VMCS revision identifier', 0
ErrorNumber12   db      'VMREAD/VMWRITE from/to unsupported VMCS component', 0
ErrorNumber13   db      'VMWRITE to read-only VMCS component', 0
ErrorNumber15   db      'VMXON executed in VMX root operation', 0
ErrorNumber16   db      'VM entry with invalid executive-VMCS pointer', 0
ErrorNumber17   db      'VM entry with non-launched executive VMCS', 0
ErrorNumber18   db      'VM entry with executive-VMCS pointer not VMXON pointer', 0
ErrorNumber19   db      'VMCALL with non-clear VMCS', 0
ErrorNumber20   db      'VMCALL with invalid VM-exit control fields', 0
ErrorNumber22   db      'VMCALL with incorrect MSEG revision identifier', 0
ErrorNumber23   db      'VMXOFF under dual-monitor treatment of SMIs and SMM', 0
ErrorNumber24   db      'VMCALL with invalid SMM-monitor features', 0
ErrorNumber25   db      'VM entry with invalid VM-execution control fields in executive VMCS', 0
ErrorNumber26   db      'VM entry with events blocked by MOV SS', 0
ErrorNumber28   db      'Invalid operand to INVEPT/INVVPID', 0


;;
;; VM-exit 原因信息
;;
ExitReson00     db      'exception or NMI', 0
ExitReson01     db      'external-interrupt exiting', 0
ExitReson02     db      'triple fault', 0
ExitReson03     db      'recevice INIT signal', 0
ExitReson04     db      'recevice SIPI', 0
ExitReson05     db      'I/O SMI', 0
ExitReson06     db      'other SMI', 0
ExitReson07     db      'interrupt-window exiting', 0
ExitReson08     db      'NMI-windows exiting', 0
ExitReson09     db      'occur task switch', 0
ExitReson10     db      'CPUID instruction', 0
ExitReson11     db      'GETSEC instruction', 0
ExitReson12     db      'HLT instruction', 0
ExitReson13     db      'INVD instruction', 0
ExitReson14     db      'INVLPG instruction', 0
ExitReson15     db      'RDPMC instruction', 0
ExitReson16     db      'RDTSC instruction', 0
ExitReson17     db      'RSM instruction', 0
ExitReson18     db      'VMCALL instruction', 0
ExitReson19     db      'VMCLEAR instruction', 0
ExitReson20     db      'VMLAUNCH instruction', 0
ExitReson21     db      'VMPTRLD instruction', 0
ExitReson22     db      'VMPTRST instruction', 0
ExitReson23     db      'VMREAD instruction', 0
ExitReson24     db      'VMRESUME instruction', 0
ExitReson25     db      'VMWRITE instruction', 0
ExitReson26     db      'VMXOFF instruction', 0
ExitReson27     db      'VMXON instruction', 0
ExitReson28     db      'control-register access', 0
ExitReson29     db      'MOV-DR exiting', 0
ExitReson30     db      'execute an I/O instruction', 0
ExitReson31     db      'VM-exit due to RDMSR', 0
ExitReson32     db      'VM-exit due to WRMSR', 0
ExitReson33     db      'VM-entry failure due to invalid guest sate', 0
ExitReson34     db      'VM-entry failure due to MSR loading', 0
ExitReson35     db      0
ExitReson36     db      'MWAIT exiting', 0
ExitReson37     db      'MTF VM exit', 0
ExitReson38     db      0
ExitReson39     db      'MONITOR exiting', 0
ExitReson40     db      'PAUSE or PAUSE-loop exiting', 0
ExitReson41     db      'VM-entry failure due to machine-check event', 0
ExitReson42     db      0
ExitReson43     db      'TPR below threshold', 0
ExitReson44     db      'access APIC-access page', 0
ExitReson45     db      'EOI-exit bitmap', 0
ExitReson46     db      'access to GDTR or IDTR', 0
ExitReson47     db      'access to LDTR or TR', 0
ExitReson48     db      'EPT violation', 0
ExitReson49     db      'EPT misconfiguration', 0
ExitReson50     db      'INVEPT instruction', 0
ExitReson51     db      'RDTSCP instruction', 0
ExitReson52     db      'VMX-preemption timer expired', 0
ExitReson53     db      'INVVPID instruction', 0
ExitReson54     db      'WBINVD instruction', 0
ExitReson55     db      'XSETBV instruction', 0
ExitReson56     db      'APIC-write exit', 0
ExitReson57     db      'RDRAND instruction', 0
ExitReson58     db      'INVPCID instruction', 0
ExitReson59     db      'VMFUNC instruction', 0


Vmcs.GuestStateMsg      db '============= Guest-state area ================', 10, 0
GuestState.CrMsg        db 'CR(0,3,4), DR7:        ', 0
GuestState.RspMsg       db 'R(sp,ip,flags):        ', 0
GuestState.EsMsg        db 'ES:                    ', 0
GuestState.CsMsg        db 'CS:                    ', 0
GuestState.SsMsg        db 'SS:                    ', 0
GuestState.DsMsg        db 'DS:                    ', 0
GuestState.FsMsg        db 'FS:                    ', 0
GuestState.GsMsg        db 'GS:                    ', 0
GuestState.LdtrMsg      db 'LDTR:                  ', 0
GuestState.TrMsg        db 'TR:                    ', 0
GuestState.GdtrMsg      db 'GDTR:                  ', 0
GuestState.IdtrMsg      db 'Idtr:                  ', 0
GuestState.SysenterMsg  db 'SYSENTER(cs,esp,eip):  ', 0
GuestState.MsrCtlMsg    db 'MsrCtl(debug, perf):   ', 0
GuestState.MsrMsg       db 'Msr(pat, efer):        ', 0
GuestState.StateMsg     db 'State(act,int,debug):  ', 0
GuestState.VlpMsg       db 'VMCS link pointer:     ', 0
GuestState.PtvMsg       db 'PreemptionTimerValue:  ', 0
GuestState.PdpteMsg     db 'PDPTE(0,1,2,3):        ', 0
GuestState.GisMsg       db 'GuestInterruptStatus:  ', 0
GuestState.SpaceMsg     db '                       ', 0

Vmcs.HostStateMsg       db '============= Host-state area ================', 10, 0
HostState.CrMsg         db 'CR(0,3,4):                ', 0
HostState.RspMsg        db 'R(sp,ip):                 ', 0
HostState.SelectorMsg   db 'Selector(e/c/s/d/f/g,tr): ', 0
HostState.BaseMsg       db 'Base(f/g/tr,gdtr,idtr):   ', 0
HostState.SysenterMsg   db 'SYSENTER(cs,esp,eip):     ', 0
HostState.MsrMsg        db 'Msr(perf,pat,efer):       ', 0
HostState.SpaceMsg      db '                          ', 0

Vmcs.ExecutionCtlMsg    db '============= VM-execution control fields ================', 10, 0
ExeCtl.PinbasedMsg      db 'PinBased:                             ', 0
ExeCtl.ProcbasedMsg     db 'ProcBased(primary,secondary):         ', 0
ExeCtl.ExceBitmapMsg    db 'Exception(bitmap,PfecMask,PfecMatch): ', 0
ExeCtl.IoBitmapAddrMsg  db 'IO bitmap Address(A & B):             ', 0
ExeCtl.TscOffsetMsg     db 'TSC offset:                           ', 0
ExeCtl.MaskShadowMsg    db 'Mask&ReadShadow(CR0,CR4):             ', 0
ExeCtl.CtcMsg           db 'CR3-target count:                     ', 0
ExeCtl.CtvMsg           db 'CR3-target value(0,1,2,3):            ', 0
ExeCtl.ApicAddrMsg      db 'Address(APIC-access, Virtual-APIC):   ', 0
ExeCtl.TprThresholdMsg  db 'TPR threshold:                        ', 0
ExeCtl.EeBitmapMsg      db 'EOI-exit bitmap:                      ', 0
ExeCtl.PostedIntMsg     db 'posted-interrupt(vector/DescAddr):    ', 0
ExeCtl.MsrAddrMsg       db 'MSR-bitmap Address:                   ', 0
ExeCtl.EvpMsg           db 'Executive-VMCS pointer:               ', 0
ExeCtl.EptpMsg          db 'EPTP:                                 ', 0
ExeCtl.VpidMsg          db 'VPID:                                 ', 0
ExeCtl.PleMsg           db 'PLE(Gap,Window):                      ', 0
ExeCtl.VfcMsg           db 'VM-funciton Control & EPTP list addr: ', 0
ExeCtl.SpaceMsg         db '                                      ', 0


Vmcs.ExitCtlMsg         db '============= VM-exit control fields ================', 10, 0
ExitCtl.ExitMsg         db 'VM-exit control:   ', 0
ExitCtl.MscMsg          db 'MSR-store count:   ', 0
ExitCtl.MsaMsg          db 'MSR-store address: ', 0
ExitCtl.MlcMsg          db 'MSR-load count:    ', 0
ExitCtl.MlaMsg          db 'MSR-load address:  ', 0



Vmcs.EntryCtlMsg        db '============= VM-entry control fields ================', 10, 0
EntryCtl.EntryMsg       db 'VM-entry control:      ', 0
EntryCtl.MlcMsg         db 'MSR-load count:        ', 0
EntryCtl.MlaMsg         db 'MSR-load address:      ', 0
EntryCtl.IiMsg          db 'Interrupt-information: ', 0
EntryCtl.EecMsg         db 'Exception error code:  ', 0
EntryCtl.InstLengthMsg  db 'Instruction length:    ', 0


DumpFunc                dq dump_exit_info, dump_execution_control, dump_exit_control
                        dq dump_entry_control, dump_guest_state, dump_host_state, 0


Vmx.InstructionErrorInfoTable:
                dd      0
                dd      ErrorNumber1, ErrorNumber2, ErrorNumber3, ErrorNumber4, ErrorNumber5, ErrorNumber6
                dd      ErrorNumber7, ErrorNumber8, ErrorNumber9, ErrorNumber10, ErrorNumber11, ErrorNumber12
                dd      ErrorNumber13, 0, ErrorNumber15, ErrorNumber16, ErrorNumber17, ErrorNumber18
                dd      ErrorNumber19, ErrorNumber20, 0, ErrorNumber22, ErrorNumber23, ErrorNumber24
                dd      ErrorNumber25, ErrorNumber26, 0, ErrorNumber28

Vmx.ExitResonInfoTable:                
                dd      ExitReson00, ExitReson01, ExitReson02, ExitReson03, ExitReson04, ExitReson05, ExitReson06
                dd      ExitReson07, ExitReson08, ExitReson09, ExitReson10, ExitReson11, ExitReson12, ExitReson13
                dd      ExitReson14, ExitReson15, ExitReson16, ExitReson17, ExitReson18, ExitReson19, ExitReson20
                dd      ExitReson21, ExitReson22, ExitReson23, ExitReson24, ExitReson25, ExitReson26, ExitReson27
                dd      ExitReson28, ExitReson29, ExitReson30, ExitReson31, ExitReson32, ExitReson33, ExitReson34
                dd      ExitReson35, ExitReson36, ExitReson37, ExitReson38, ExitReson39, ExitReson40, ExitReson41
                dd      ExitReson42, ExitReson43, ExitReson44, ExitReson45, ExitReson46, ExitReson47, ExitReson48
                dd      ExitReson49, ExitReson50, ExitReson51, ExitReson52, ExitReson53, ExitReson54, ExitReson55
                dd      ExitReson56, ExitReson57, ExitReson58, ExitReson59


Vmx.DumpDetailInfoTable:
                dd      0, 0, 0, 0, 0, 0, 0
                dd      0, 0, 0, 0, 0, 0, 0
                dd      0, 0, 0, 0, 0, 0, 0
                dd      0, 0, 0, 0, 0, 0, 0
                dd      0, 0, 0, 0, 0, 0, 0
                dd      0, 0, dump_detail_of_mtf, 0, 0, 0, 0
                dd      0, dump_detail_of_tpr_threshold, 0, 0, 0, 0, 0
                dd      0, 0, 0, 0, 0, 0, 0
                dd      0, 0, 0, 0