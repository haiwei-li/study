;*************************************************
;* VmxInit.asm                                   *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************
        






;----------------------------------------------------------
; vmx_operation_enter()
; input:
;       esi - VMXON region pointer
; output:
;       0 - successful
;       otherwise - 错误码
; 描述: 
;       1) 使处理器进入 VMX root operation 环境
;----------------------------------------------------------
vmx_operation_enter:
        push ecx
        push edx
        push ebp
        
                
        
%ifdef __X64        
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif

        mov eax, STATUS_SUCCESS
        
        ;;
        ;; 检查是否已经进入了 VMX root operation 模式
        ;;
        test DWORD [ebp + PCB.ProcessorStatus], CPU_STATUS_VMXON
        jnz vmx_operation_enter.done

        ;;
        ;; 检测是否支持 VMX 
        ;;
        bt DWORD [ebp + PCB.FeatureEcx], 5
        mov eax, STATUS_UNSUCCESS
        jnc vmx_operation_enter.done        
        
        ;;
        ;; 开启 VMX operation 允许
        ;;
        REX.Wrxb
        mov eax, cr4
        REX.Wrxb
        bts eax, 13                                     ; CR4.VMEX = 1
        REX.Wrxb
        mov cr4, eax
        
        ;;
        ;; 更新指令状态, 允许执行 VMX 指令
        ;;
        or DWORD [ebp + PCB.InstructionStatus], INST_STATUS_VMX
        
        ;;
        ;; 初始化 VMXON 区域
        ;;
        call initialize_vmxon_region
        cmp eax, STATUS_SUCCESS
        jne vmx_operation_enter.done

        ;;
        ;; 进入 VMX root operation 模式
        ;; 1) operand 是物理地址 pointer
        ;;
        vmxon [ebp + PCB.VmxonPhysicalPointer]

        ;;
        ;; 检查 VMXON 指令是否执行成功
        ;; 1) 当 CF = 0 时, WMXON 执行成功
        ;; 1) 当 CF = 1 时, 返回失败
        ;;
        mov eax, STATUS_UNSUCCESS
        jc vmx_operation_enter.done
        jz vmx_operation_enter.done

        ;;
        ;; 使用 "all-context invalidation" 类型刷新 cache
        ;;
        mov eax, ALL_CONTEXT_INVALIDATION
        invvpid eax, [ebp + PCB.InvDesc]
        invept eax, [ebp + PCB.InvDesc]
        
        
        ;;
        ;; 根据处理器 index 值, 生成 VPID 头
        ;;
        mov ecx, [ebp + PCB.ProcessorIndex]
        shl ecx, 8
        
        ;;
        ;; 分配 VMM stack
        ;;
        call get_kernel_stack_pointer
        REX.Wrxb
        mov [ebp + PCB.VmmStack], eax
        
        ;;
        ;; 分配 VMM Msr-load 区域
        ;;
        call get_vmcs_access_pointer
        REX.Wrxb
        mov [ebp + PCB.VmmMsrLoadAddress], eax
        REX.Wrxb
        mov [ebp + PCB.VmmMsrLoadPhyAddress], edx
        
        
        ;;
        ;; 分配 VMCS A 区域, 并作为缺省的 VMCS 区域
        ;;
        call get_vmcs_pointer
        REX.Wrxb
        mov [ebp + PCB.GuestA + 8], eax                                 ; VMCS A 虚拟地址
        REX.Wrxb
        mov [ebp + PCB.GuestA], edx                                     ; VMCS A 物理地址
        mov ax, cx
        or ax, 1
        mov [ebp + PCB.GuestA + VMB.Vpid], ax                           ; VMCS A 的 VPID
        
        ;;
        ;; 分配 VMCS B 区域
        ;;        
        call get_vmcs_pointer
        REX.Wrxb
        mov [ebp + PCB.GuestB + 8], eax                                 ; VMCS B 虚拟地址
        REX.Wrxb
        mov [ebp + PCB.GuestB], edx                                     ; VMCS B 物理地址        
        mov ax, cx
        or ax, 2
        mov [ebp + PCB.GuestB + VMB.Vpid], ax                           ; VMCS B 的 VPID
        
        ;;
        ;; 分配 VMCS C 区域
        ;;        
        call get_vmcs_pointer
        REX.Wrxb
        mov [ebp + PCB.GuestC + 8], eax                                 ; VMCS C 虚拟地址
        REX.Wrxb
        mov [ebp + PCB.GuestC], edx                                     ; VMCS C 物理地址
        mov ax, cx
        or ax, 3
        mov [ebp + PCB.GuestC + VMB.Vpid], ax
        
        ;;
        ;; 分配 VMCS D 区域
        ;;          
        call get_vmcs_pointer
        REX.Wrxb
        mov [ebp + PCB.GuestD + 8], eax                                 ; VMCS D 虚拟地址
        REX.Wrxb
        mov [ebp + PCB.GuestD], edx                                     ; VMCS D 物理地址
        mov ax, cx
        or ax, 4
        mov [ebp + PCB.GuestC + VMB.Vpid], ax
                
        
%if 0        
                
        ;;
        ;; 初始化 EPT 结构
        ;;
        cmp BYTE [ebp + PCB.IsBsp], 1
        jne vmx_operation_enter.@0
     
        call init_ept_pxt_ppt
%endif        

vmx_operation_enter.@0:        
                
        ;;
        ;; 更新处理器状态
        ;;
        or DWORD [ebp + PCB.ProcessorStatus], CPU_STATUS_VMXON
        
        mov eax, STATUS_SUCCESS
        
vmx_operation_enter.done:
        pop ebp
        pop edx
        pop ecx
        ret




;----------------------------------------------
; initialize_vmxon_region()
; input:
;       none
; output:
;       0 - successful
;       otherwise - 错误码
; 描述: 
;       1) 初始化 VMM(host)的 vmxon region
;----------------------------------------------
initialize_vmxon_region:
        push ebx
        push ecx
        push ebp

%ifdef __X64
        LoadGsBaseToRbp      
%else
        mov ebp, [gs: PCB.Base]
%endif        

        ;;
        ;; 读 CR0 当前值
        ;;
        REX.Wrxb
        mov ecx, cr0
        mov ebx, ecx
        
        ;;
        ;; 检查 CR0.PE 与 CR0.PG 是否符合 fixed 位, 这里只检查低 32 位值
        ;; 1) 对比 Cr0FixedMask 值(固定为1值), 不相同则返回错误码
        ;;
        mov eax, STATUS_VMX_UNEXPECT                    ; 错误码(超出期望值)
        xor ecx, [ebp + PCB.Cr0FixedMask]               ; 与 Cr0FixedMask 值异或, 检查是否相同
        js initialize_vmxon_region.done                 ; 检查 CR0.PG 位是否相等
        test ecx, 1
        jnz initialize_vmxon_region.done                ; 检查 CR0.PE 位是否相等
        
        ;;
        ;; 如果 CR0.PE 与 CR0.PG 位相符, 设置 CR0 其它位
        ;;
        or ebx, [ebp + PCB.Cr0Fixed0]                   ; 设置 Fixed 1 位
        and ebx, [ebp + PCB.Cr0Fixed1]                  ; 设置 Fixed 0 位
        REX.Wrxb
        mov cr0, ebx                                    ; 写回 CR0
        
        ;;
        ;; 直接设置 CR4 fixed 1 位
        ;;
        REX.W
        mov ecx, cr4
        or ecx, [ebp + PCB.Cr4FixedMask]                ; 设置 Fixed 1 位
        and ecx, [ebp + PCB.Cr4Fixed1]                  ; 设置 Fixed 0 位
        REX.W
        mov cr4, ecx
        
        ;;
        ;; 分配 VMXON region
        ;;
        call get_vmcs_access_pointer                    ; edx:eax = pa:va
        REX.Wrxb
        mov [ebp + PCB.VmxonPointer], eax
        REX.Wrxb
        mov [ebp + PCB.VmxonPhysicalPointer], edx
        
        ;;
        ;; 设置 VMCS region 信息
        ;;
        REX.Wrxb      
        mov ebx, [ebp + PCB.VmxonPointer]
        mov eax, [ebp + PCB.VmxBasic]                   ; 读取 VMCS revision identifier 值 
        mov [ebx], eax                                  ; 写入 VMCS ID

        mov eax, STATUS_SUCCESS
                
initialize_vmxon_region.done:        
        pop ebp
        pop ecx
        pop ebx
        ret        
        



        
;----------------------------------------------------------
; vmx_operation_exit()
; input:
;       none
; output:
;       0 - successful
;       otherwise - 错误码
; 描述: 
;       1) 使处理器退出 VMX root operation 环境
;----------------------------------------------------------
vmx_operation_exit:
        push ebp
        
%ifdef __X64        
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif        
        ;;
        ;; 检查是否开启 VMX 模式
        ;;
        test DWORD [ebp + PCB.ProcessorStatus], CPU_STATUS_VMXON
        jz vmx_operation_exit.done
        
        ;;
        ;; 使用 "all-context invalidation" 类型刷新 cache
        ;;
        mov eax, ALL_CONTEXT_INVALIDATION
        invvpid eax, [ebp + PCB.InvDesc]
        invept eax, [ebp + PCB.InvDesc]
        
        vmxoff
        ;;
        ;; 检查是否成功
        ;; 1) 当 CF = 0 且 ZF = 0 时, VMXOFF 执行成功
        ;;
        mov eax, STATUS_VMXOFF_UNSUCCESS
        jc vmx_operation_exit.done
        jz vmx_operation_exit.done

                
        ;;
        ;; 下面关闭 CR4.VMXE 标志位
        ;;
        REX.Wrxb
        mov eax, cr4
        btr eax, 13
        REX.Wrxb
        mov cr4, eax
                
        ;;
        ;; 更新指令状态
        ;;
        and DWORD [ebp + PCB.InstructionStatus], ~INST_STATUS_VMX
        ;;
        ;; 更新处理器状态
        ;;
        and DWORD [ebp + PCB.ProcessorStatus], ~CPU_STATUS_VMXON
        
        mov eax, STATUS_SUCCESS
        
vmx_operation_exit.done:
        pop ebp
        ret
        

      


;-----------------------------------------------------------
; initialize_vmcs_buffer()
; input:
;       esi - VM_MANAGE_BLOCK pointer
; output:
;       0 - successful
;       otherwise - 错误码
; 描述: 
;       1) 初始化提供的 vmcs buffer(由 VM 管理块指针提供)
;-----------------------------------------------------------
initialize_vmcs_buffer:
        push ebp
        push ecx
        push ebx
        push edx        
        
        ;;
        ;; PCB 基址
        ;;
%ifdef __X64
        LoadGsBaseToRbp              
%else
        mov ebp, [gs: PCB.Base]
%endif      

        push esi                                                ; 保存 VMCS 管理块指针
        
        REX.Wrxb
        mov ebx, esi

        ;;
        ;; 写入 VMCS region 的 Identifier 值
        ;;
        mov eax, [ebp + PCB.VmxBasic]
        REX.Wrxb
        mov edi, [ebx + VMB.Base]                               ; VMCS region 虚拟地址
        mov [edi], eax
        
        ;;
        ;; 写入 VMM 管理记录
        ;;
        REX.Wrxb
        mov eax, [ebp + PCB.VmmStack]
        REX.Wrxb
        mov [ebx + VMB.HostStack], eax
        REX.Wrxb
        mov eax, [ebp + PCB.VmmMsrLoadAddress]
        REX.Wrxb
        mov [ebx + VMB.VmExitMsrLoadAddress], eax
        REX.Wrxb
        mov eax, [ebp + PCB.VmmMsrLoadPhyAddress]
        REX.Wrxb
        mov [ebx + VMB.VmExitMsrLoadPhyAddress], eax
        
        
        ;;
        ;; 初始化 VM 的 VSB 区域
        ;;
        REX.Wrxb
        mov esi, ebx
        call init_vm_storage_block
        
        ;;
        ;; 初始化 VM domain
        ;;
        call vm_alloc_domain
        REX.Wrxb
        mov [ebx + VMB.DomainBase], eax
        REX.Wrxb
        mov [ebx + VMB.DomainPhysicalBase], edx
        REX.Wrxb
        add edx, (DOMAIN_SIZE - 1)
        mov [ebx + VMB.DomainPhysicalTop], edx

        ;;
        ;; 初始化 EP4TA
        ;;
        call get_vmcs_access_pointer
        REX.Wrxb
        mov [ebx + VMB.Ep4taBase], eax
        REX.Wrxb
        mov [ebx + VMB.Ep4taPhysicalBase], edx
        
        ;;
        ;; 下面为 VMCS region 分配相关的 access page, 包括: 
        ;; 1) IoBitmap A page
        ;; 2) IoBitmap B page
        ;; 3) Virtual-access page
        ;; 4) MSR-Bitmap page
        ;; 5) VM-entry/VM-exit MSR store page
        ;; 6) VM-exit MSR load page
        ;; 7) IoVteBuffer page
        ;; 8) MsrVteBuffer page
        ;; 9) GpaHteBuffer page
        ;;

        mov ecx, 9                                              ; 共 9 个 access page
        REX.Wrxb
        lea ebx, [ebx + VMB.IoBitmapAddressA]                   ; VMB.IoBitmapAddressA 地址

        
        ;;
        ;; 使用 get_vmcs_access_pointer() 分配一个 access page
        ;; 1) edx:eax 返回对应的 physical address 与 virtual address
        ;; 2) 在 X64 下返回对应的 64 位地址
        ;; 3) 注意: 这里不检查 get_vmcs_access_pointer() 的返回值, 
        ;;          作为演示, 并没设计当超出内存资源的情形！
        ;;
        
initialize_vmcs_buffer.loop:
        call get_vmcs_access_pointer
        REX.Wrxb
        mov [ebx], eax                                          ; 写入 access page 虚拟地址
        REX.Wrxb
        mov [ebx + 8], edx                                      ; 写入 access page 物理地址
        REX.Wrxb
        add ebx, 16                                             ; 指向下一条记录        
        DECv ecx
        jnz initialize_vmcs_buffer.loop
        

        pop ebx                                                ; ebx - VMCS 管理块指针        
        xor eax, eax
        
        ;;
        ;; 初始化 IO & MSR table entry 计数值
        ;;
        mov [ebx + VMB.IoVteCount], eax
        mov [ebx + VMB.MsrVteCount], eax
        mov [ebx + VMB.GpaHteCount], eax


        ;;
        ;; 初始化 MSR-store/MSR-load 列表计数值
        ;;
        mov [ebx + VMB.VmExitMsrStoreCount], eax
        mov [ebx + VMB.VmExitMsrLoadCount], eax
        
        ;;
        ;; 初始化 IO VTE, MSR VTE, GPA HTE, EXTINT ITE 指针
        ;;
        REX.Wrxb
        mov eax, [ebx + VMB.IoVteBuffer]
        REX.Wrxb
        mov [ebx + VMB.IoVteIndex], eax
        REX.Wrxb
        mov eax, [ebx + VMB.MsrVteBuffer]
        REX.Wrxb
        mov [ebx + VMB.MsrVteIndex], eax
        REX.Wrxb
        mov eax, [ebx + VMB.GpaHteBuffer]
        REX.Wrxb
        mov [ebx + VMB.GpaHteIndex], eax

        ;;
        ;; IO 操作标志位
        ;;
        mov DWORD [ebx + VMB.IoOperationFlags], 0
        
        ;;
        ;; 初始化 guest-status
        ;;
        mov DWORD [ebx + VMB.GuestSmb + GSMB.ProcessorStatus], 0
        mov DWORD [ebx + VMB.GuestSmb + GSMB.InstructionStatus], 0

                
        
        ;;
        ;; 清空 VMCS buffer
        ;;
        mov esi, EXECUTION_CONTROL_SIZE
        REX.Wrxb
        lea edi, [ebp + PCB.ExecutionControlBuf]
        call zero_memory
        mov esi, ENTRY_CONTROL_SIZE
        REX.Wrxb
        lea edi, [ebp + PCB.EntryControlBuf]
        call zero_memory        
        mov esi, EXIT_CONTROL_SIZE
        REX.Wrxb
        lea edi, [ebp + PCB.ExitControlBuf]
        call zero_memory
        mov esi, HOST_STATE_SIZE
        REX.Wrxb
        lea edi, [ebp + PCB.HostStateBuf]
        call zero_memory        
        mov esi, GUEST_STATE_SIZE
        REX.Wrxb
        lea edi, [ebp + PCB.GuestStateBuf]
        call zero_memory        

        
        ;;
        ;; 下面分别初始化各个 VMCS 域, 包括: 
        ;; 1) VM execution control fields
        ;; 2) VM-exit control fields
        ;; 3) VM-entry control fields
        ;; 4) VM host state fields
        ;; 5) VM guest state fields
        ;;       
        REX.Wrxb
        mov esi, ebx
        call init_vm_execution_control_fields
        REX.Wrxb
        mov esi, ebx
        call init_vm_exit_control_fields
        REX.Wrxb
        mov esi, ebx
        call init_vm_entry_control_fields
        REX.Wrxb
        mov esi, ebx
        call init_host_state_area

        REX.Wrxb
        mov esi, ebx

        ;;
        ;; 如果guest为实模式, 则调用 init_realmode_guest_sate
        ;;
        mov eax, init_guest_state_area
        mov ebx, init_realmode_guest_state
        test DWORD [esi + VMB.GuestFlags], GUEST_FLAG_PE
        cmovz eax, ebx
        call eax

        pop edx
        pop ebx
        pop ecx
        pop ebp        
        ret



;-----------------------------------------------------------
; init_vm_storage_block()
; input:
;       esi - VMB pointer
; output:
;       none
; 描述: 
;       1) 初始化 VM 私的存储区域
;-----------------------------------------------------------
init_vm_storage_block:
        push ebx
        push edx
        
        
        REX.Wrxb
        mov ebx, esi
        
        ;;
        ;; 分配 VSB(VM storage block)区域
        ;;
        mov esi, ((VSB_SIZE + 0FFFh) / 1000h)
        call alloc_kernel_pool_n
        REX.Wrxb
        mov [ebx + VMB.VsbBase], eax                            ; edx:eax = PA:VA
        REX.Wrxb
        mov [ebx + VMB.VsbPhysicalBase], edx  

        ;;
        ;; 初始化 VSB 管理记录
        ;;
        REX.Wrxb
        mov [eax + VSB.Base], eax
        REX.Wrxb
        mov [eax + VSB.PhysicalBase], edx
        
        ;;
        ;; 初始化 VM video buffer 管理记录
        ;;        
        REX.Wrxb
        lea esi, [eax + VSB.VmVideoBuffer]
        REX.Wrxb
        mov [eax + VSB.VmVideoBufferHead], esi
        REX.Wrxb
        mov [eax + VSB.VmVideoBufferPtr], esi

        ;;
        ;; 初始化 VM keryboard buffer 管理记录
        ;;
        REX.Wrxb
        lea esi, [eax + VSB.VmKeyBuffer]
        REX.Wrxb
        mov [eax + VSB.VmKeyBufferHead], esi
        REX.Wrxb
        mov [eax + VSB.VmKeyBufferPtr], esi
        mov DWORD [eax + VSB.VmKeyBufferSize], 256
        
        ;;
        ;; 更新处理器状态, 表明存在 guest 环境
        ;;
        mov eax, PCB.ProcessorStatus
        or DWORD [gs: eax], CPU_STATUS_GUEST_EXIST
        
        pop edx
        pop ebx      
        ret




;-----------------------------------------------------------
; setup_vmcs_region():
; input:
;       none
; output:
;       none
;-----------------------------------------------------------
setup_vmcs_region:
        ;;
        ;; 下面将 VMCS buffer 数据刷新到 VMCS 中
        ;;
        call flush_execution_control
        call flush_exit_control
        call flush_entry_control
        call flush_host_state
        call flush_guest_state        
        ret

        
        
      



;----------------------------------------------------------
; init_guest_state_area()
; input:
;       esi - VMB pointer
; output:
;       none
; 描述: 
;       1) 设置 VMCS 的 HOST STAGE 区域
;       2) 这是保护模式或者IA-32e模式的 guest区域设置
;----------------------------------------------------------   
init_guest_state_area:
        push ebp
        push edx
        push ecx
        push ebx
        
%ifdef __X64
        LoadGsBaseToRbp                                         ; ebp = PCB.Base
        LoadFsBaseToRbx                                         ; ebx = SDA.Base
%else
        mov ebp, [gs: PCB.Base]
        mov ebx, [fs: SDA.Base]
%endif

%define GuestStateBufBase                       (ebp + PCB.GuestStateBuf)
%define ExecutionControlBufBase                 (ebp + PCB.ExecutionControlBuf)
%define EntryControlBufBase                     (ebp + PCB.EntryControlBuf)
        
        REX.Wrxb
        mov edx, esi
        
        
        ;;
        ;; 在保护模式和 IA-32e 模式下, guest 的设置
        ;; 1) CR0 = Cr0FixedMask
        ;; 2) CR4 = Cr4FixedMask | PAE | OSFXSR
        ;; 3) CR3 = 当前值
        ;;
        mov eax, [ebp + PCB.Cr0FixedMask]               ; CR0 固定值
        REX.Wrxb
        mov esi, [ebp + PCB.Cr4FixedMask]
        or esi, CR4_PAE | CR4_OSFXSR                    ; 使用 PAE 分页模式
        
        REX.Wrxb
        mov edi, cr3                                    ; CR3 当前值
        
        ;;
        ;; 如果 GUEST_PG 为 0, 则清 CR0.PG 位
        ;;
        test DWORD [edx + VMB.GuestFlags], GUEST_FLAG_PG
        jnz init_guest_state_area.@0
        and eax, 7FFFFFFFh
        
init_guest_state_area.@0:        
        ;;
        ;; 写入 CR0, CR4 以及 CR3
        ;;
        REX.Wrxb
        mov [GuestStateBufBase  + GUEST_STATE.Cr0], eax
        REX.Wrxb
        mov [GuestStateBufBase  + GUEST_STATE.Cr4], esi
        REX.Wrxb
        mov [GuestStateBufBase  + GUEST_STATE.Cr3], edi
        
     
        ;;
        ;; DR7 = 400h
        ;;        
        mov eax, 400h
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.Dr7], eax
        
        ;;
        ;; RIP = guest_entry, Rflags = 202h(IF=1)
        ;;
        REX.Wrxb
        mov eax, [edx + VMB.GuestEntry]
        mov ecx, 02h | FLAGS_IF
        
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.Rip], eax
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.Rflags], ecx


        REX.Wrxb
        mov eax, [edx + VMB.GuestStack]                
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.Rsp], eax



                
        ;;
        ;; 下面设置 segment register 相关值
        ;; 1) 16 位 selector
        ;; 2) 32 位 base
        ;; 3) 32 位 limit
        ;; 4) 32 位 access right
        ;;  
        
        ;;
        ;; 检查 guest 是否为 IA-32e 模式
        ;;
        test DWORD [edx + VMB.GuestFlags], GUEST_FLAG_IA32E
        jz init_guest_state_area.@1
        
        ;;
        ;; 在 IA-32e 模式下的 selector:
        ;; 1) CS = KerelCsSelector64
        ;; 2) ES/SS/DS = KernelSsSelector64
        ;; 3) FS = FsSelector, GS = 当前值
        ;; 4) LDTR = 0
        ;; 5) TR = 当前值
        ;;
        mov WORD [GuestStateBufBase + GUEST_STATE.FsSelector], FsSelector
        mov ax, [ebp + PCB.GsSelector]        
        mov WORD [GuestStateBufBase + GUEST_STATE.GsSelector], ax        
        mov WORD [GuestStateBufBase + GUEST_STATE.LdtrSelector], 0        
        mov ax, [ebp + PCB.TssSelector]
        mov [GuestStateBufBase + GUEST_STATE.TrSelector], ax

        ;;
        ;; 如果 guest 使用 3 级(USER)权限
        ;;
        test DWORD [edx + VMB.GuestFlags], GUEST_FLAG_USER
        jz init_guest_state_area.@01
        
        mov WORD [GuestStateBufBase + GUEST_STATE.CsSelector], KernelCsSelector64 | 3
        mov WORD [GuestStateBufBase + GUEST_STATE.SsSelector], KernelSsSelector64 | 3
        mov WORD [GuestStateBufBase + GUEST_STATE.DsSelector], KernelSsSelector64 | 3
        mov WORD [GuestStateBufBase + GUEST_STATE.EsSelector], KernelSsSelector64 | 3
        
        jmp init_guest_state_area.@02
        
init_guest_state_area.@01:        
        
        mov WORD [GuestStateBufBase + GUEST_STATE.CsSelector], KernelCsSelector64
        mov WORD [GuestStateBufBase + GUEST_STATE.SsSelector], KernelSsSelector64
        mov WORD [GuestStateBufBase + GUEST_STATE.DsSelector], KernelSsSelector64
        mov WORD [GuestStateBufBase + GUEST_STATE.EsSelector], KernelSsSelector64

        
init_guest_state_area.@02:
                        
        ;;
        ;; 在 IA-32e 模式下的 limit, 为了与 host 达成一致, 这里 limit 设置为
        ;; 1) ES/CS/SS/DS = 0FFFFFFFFh
        ;; 2) FS/GS = 0FFFFFh
        ;; 3) LDTR = 0
        ;; 4) TR = 2FFFh
        ;;
        mov eax, 0FFFFFFFFh
        mov DWORD [GuestStateBufBase + GUEST_STATE.CsLimit], eax
        mov DWORD [GuestStateBufBase + GUEST_STATE.SsLimit], eax
        mov DWORD [GuestStateBufBase + GUEST_STATE.DsLimit], eax
        mov DWORD [GuestStateBufBase + GUEST_STATE.EsLimit], eax
        mov DWORD [GuestStateBufBase + GUEST_STATE.FsLimit], 0000FFFFFh
        mov DWORD [GuestStateBufBase + GUEST_STATE.GsLimit], 0000FFFFFh
        mov DWORD [GuestStateBufBase + GUEST_STATE.LdtrLimit], 0
        mov DWORD [GuestStateBufBase + GUEST_STATE.TrLimit], 2FFFh

        ;;
        ;; 在 IA-32e 模式下的 base
        ;; 1) ES/CS/SS/DS = 0
        ;; 2) FS/GS = 当前值
        ;; 3) LDTR = 0
        ;; 4) TR = 当前值
        ;;
        xor eax, eax
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.CsBase], eax
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.SsBase], eax
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.DsBase], eax
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.EsBase], eax
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.LdtrBase], eax
        REX.Wrxb            
        mov [GuestStateBufBase + GUEST_STATE.FsBase], ebx
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.GsBase], ebp
        REX.Wrxb
        mov eax, [ebp + PCB.TssBase]
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.TrBase], eax
        
        ;;
        ;; 64-bit Kernel CS/SS 描述符设置说明: 
        ;; 1)在 x64 体系下描述符可以设置为: 
        ;;      * CS = 00209800_00000000h (L=P=1, G=D=0, C=R=A=0)
        ;;      * SS = 00009200_00000000h (L=1, G=B=0, W=1, E=A=0)
        ;; 2) 在 VMX 架构下, 在VM-exit 返回 host 后会将描述符设置为: 
        ;;      * CS = 00AF9B00_0000FFFFh (G=L=P=1, D=0, C=0, R=A=1)
        ;;      * SS = 00CF9300_0000FFFFh (G=P=1, B=1, E=0, W=A=1)
        ;;
        ;; 3) 因此, 为了与 host 的描述符达成一致, 这里将描述符设为: 
        ;;      * CS = 00AF9A00_0000FFFFh (G=L=P=1, D=0, C=A=0, R=1)
        ;;      * SS = 00CF9200_0000FFFFh (G=P=1, B=1, E=A=0, W=1)  
        ;;        
        mov DWORD [GuestStateBufBase + GUEST_STATE.FsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_uGDlP | DPL_0
        mov DWORD [GuestStateBufBase + GUEST_STATE.GsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_uGDlP | DPL_0        
        mov DWORD [GuestStateBufBase + GUEST_STATE.LdtrAccessRight], TYPE_SYS | TYPE_LDT | SEG_Ugdlp | DPL_0
        mov DWORD [GuestStateBufBase + GUEST_STATE.TrAccessRight], TYPE_SYS | TYPE_BUSY_TSS64 | SEG_ugdlP | DPL_0
        
        ;;
        ;; 如果 guest 使用 3 级(USER)权限
        ;;
        test DWORD [edx + VMB.GuestFlags], GUEST_FLAG_USER
        jz init_guest_state_area.@03
        
        ;;
        ;; CS, SS, ES, DS 设为 3 级
        ;;
        mov DWORD [GuestStateBufBase + GUEST_STATE.CsAccessRight], TYPE_NON_SYS | TYPE_CcRA | SEG_uGdLP | DPL_3
        mov DWORD [GuestStateBufBase + GUEST_STATE.SsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_uGDlP | DPL_3
        mov DWORD [GuestStateBufBase + GUEST_STATE.DsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_uGDlP | DPL_3
        mov DWORD [GuestStateBufBase + GUEST_STATE.EsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_uGDlP | DPL_3
        
        jmp init_guest_state_area.@2

        
init_guest_state_area.@03:
        ;;
        ;; CS, SS, ES, DS 设为 0 级
        ;;
        mov DWORD [GuestStateBufBase + GUEST_STATE.CsAccessRight], TYPE_NON_SYS | TYPE_CcRA | SEG_uGdLP | DPL_0
        mov DWORD [GuestStateBufBase + GUEST_STATE.SsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_uGDlP | DPL_0
        mov DWORD [GuestStateBufBase + GUEST_STATE.DsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_uGDlP | DPL_0
        mov DWORD [GuestStateBufBase + GUEST_STATE.EsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_uGDlP | DPL_0
        
        jmp init_guest_state_area.@2

        
init_guest_state_area.@1:
        ;;
        ;; 保护模式下 selector
        ;; 1) CS = KernelCsSelector32
        ;; 2) ES/SS/DS = KernelSsSelector32
        ;; 3) FS/GS/TR = 当前值
        ;; 
        test DWORD [edx + VMB.GuestFlags], GUEST_FLAG_USER
        jz init_guest_state_area.@11
        ;;
        ;; 设为 3 级
        ;;           
        mov WORD [GuestStateBufBase + GUEST_STATE.CsSelector], KernelCsSelector32 | 3
        mov WORD [GuestStateBufBase + GUEST_STATE.SsSelector], KernelSsSelector32 | 3
        mov WORD [GuestStateBufBase + GUEST_STATE.DsSelector], KernelSsSelector32 | 3
        mov WORD [GuestStateBufBase + GUEST_STATE.EsSelector], KernelSsSelector32 | 3
                
        jmp init_guest_state_area.@12
        
init_guest_state_area.@11:
        ;;
        ;; 设为 0 级
        ;;
        mov WORD [GuestStateBufBase + GUEST_STATE.CsSelector], KernelCsSelector32
        mov WORD [GuestStateBufBase + GUEST_STATE.SsSelector], KernelSsSelector32
        mov WORD [GuestStateBufBase + GUEST_STATE.DsSelector], KernelSsSelector32
        mov WORD [GuestStateBufBase + GUEST_STATE.EsSelector], KernelSsSelector32
                
init_guest_state_area.@12:

        mov WORD [GuestStateBufBase + GUEST_STATE.FsSelector], FsSelector
        ;mov ax, [ebp + PCB.GsSelector]
        ;mov WORD [GuestStateBufBase + GUEST_STATE.GsSelector], ax
        mov WORD [GuestStateBufBase + GUEST_STATE.GsSelector], GsSelector
        mov WORD [GuestStateBufBase + GUEST_STATE.LdtrSelector], 0        
        ;mov ax, [ebp + PCB.TssSelector]
        ;mov [GuestStateBufBase + GUEST_STATE.TrSelector], ax
        mov WORD [GuestStateBufBase + GUEST_STATE.TrSelector], TssSelector32

        ;;
        ;; 保护模式下 limit
        ;; 1) ES/CS/SS/DS = 0FFFFFFFFh
        ;; 2) FS/GS = 0FFFFFh
        ;; 3) LDTR = 0
        ;; 4) TR = 2FFFh
        ;;
        mov DWORD [GuestStateBufBase + GUEST_STATE.CsLimit], 0FFFFFFFFh
        mov DWORD [GuestStateBufBase + GUEST_STATE.SsLimit], 0FFFFFFFFh
        mov DWORD [GuestStateBufBase + GUEST_STATE.DsLimit], 0FFFFFFFFh
        mov DWORD [GuestStateBufBase + GUEST_STATE.EsLimit], 0FFFFFFFFh
        mov DWORD [GuestStateBufBase + GUEST_STATE.FsLimit], 0000FFFFFh
        mov DWORD [GuestStateBufBase + GUEST_STATE.GsLimit], 0000FFFFFh
        mov DWORD [GuestStateBufBase + GUEST_STATE.LdtrLimit], 0
        mov DWORD [GuestStateBufBase + GUEST_STATE.TrLimit], 2FFFh
        
        ;;
        ;; 保护模式下 base
        ;; 1) ES/CS/SS/DS = 0
        ;; 2) FS/GS/TR = 当前值
        ;; 3) LDTR = 0
        ;;
        xor eax, eax
        REX.Wrxb        
        mov [GuestStateBufBase + GUEST_STATE.CsBase], eax
        REX.Wrxb        
        mov [GuestStateBufBase + GUEST_STATE.SsBase], eax
        REX.Wrxb        
        mov [GuestStateBufBase + GUEST_STATE.DsBase], eax
        REX.Wrxb        
        mov [GuestStateBufBase + GUEST_STATE.EsBase], eax
        REX.Wrxb        
        mov [GuestStateBufBase + GUEST_STATE.FsBase], ebx
        REX.Wrxb        
        mov [GuestStateBufBase + GUEST_STATE.GsBase], ebp
        REX.Wrxb        
        mov [GuestStateBufBase + GUEST_STATE.LdtrBase], eax        
        REX.Wrxb
        mov eax, [ebp + PCB.TssBase]
        REX.Wrxb        
        mov [GuestStateBufBase + GUEST_STATE.TrBase], eax
        
                
        ;;
        ;; 保护模式下 access rights
        ;; 1) CS = 0000C09Bh
        ;; 2) ES/SS/DS = 0000C093h
        ;; 3) FS/GS = 00004093h
        ;; 4) LDTR = 00010002h
        ;; 5) TR = 0000000Bh
        ;; 
        mov DWORD [GuestStateBufBase + GUEST_STATE.FsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_ugDlP | DPL_0
        mov DWORD [GuestStateBufBase + GUEST_STATE.GsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_ugDlP | DPL_0        
        mov DWORD [GuestStateBufBase + GUEST_STATE.LdtrAccessRight], TYPE_SYS | TYPE_LDT | SEG_Ugdlp | DPL_0
        mov DWORD [GuestStateBufBase + GUEST_STATE.TrAccessRight], TYPE_SYS | TYPE_BUSY_TSS32 | SEG_ugdlP | DPL_0       
                
        test DWORD [edx + VMB.GuestFlags], GUEST_FLAG_USER
        jz init_guest_state_area.@13
        ;;
        ;; 设为 3 级
        ;;    
        mov DWORD [GuestStateBufBase + GUEST_STATE.CsAccessRight], TYPE_NON_SYS | TYPE_CcRA | SEG_uGDlP | DPL_3
        mov DWORD [GuestStateBufBase + GUEST_STATE.SsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_uGDlP | DPL_3
        mov DWORD [GuestStateBufBase + GUEST_STATE.DsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_uGDlP | DPL_3
        mov DWORD [GuestStateBufBase + GUEST_STATE.EsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_uGDlP | DPL_3
                
        jmp init_guest_state_area.@2
        
init_guest_state_area.@13:
        ;;
        ;; 设为 0 级
        ;;        
        mov DWORD [GuestStateBufBase + GUEST_STATE.CsAccessRight], TYPE_NON_SYS | TYPE_CcRA | SEG_uGDlP | DPL_0
        mov DWORD [GuestStateBufBase + GUEST_STATE.SsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_uGDlP | DPL_0
        mov DWORD [GuestStateBufBase + GUEST_STATE.DsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_uGDlP | DPL_0
        mov DWORD [GuestStateBufBase + GUEST_STATE.EsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_uGDlP | DPL_0

        
        
        
init_guest_state_area.@2:
        ;;
        ;; 写入 GDTR 与 IDTR 值
        ;; 1) 32 位 base(x64下 64 位)
        ;; 2) 32 位 limit
        ;;
        REX.Wrxb
        mov esi, [ebp + PCB.GdtPointer]
        REX.Wrxb
        mov eax, [esi + 2] 
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.GdtrBase], eax
        movzx eax, WORD [esi]
        mov [GuestStateBufBase + GUEST_STATE.GdtrLimit], eax
        REX.Wrxb
        mov eax, [ebx + SDA.IdtBase]
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.IdtrBase], eax
        movzx eax, WORD [ebx + SDA.IdtLimit]
        mov [GuestStateBufBase + GUEST_STATE.IdtrLimit], eax


        REX.Wrxb
        mov esi, edx
     
        ;;
        ;; 以当前值写入 MSRs
        ;; 1) IA32_DEBUGCTL
        ;; 2) IA32_SYSENTER_CS(32位)
        ;; 3) IA32_SYSENTER_ESP
        ;; 4) IA32_SYSENTER_EIP
        ;; 5) IA32_PERF_GLOBAL_CTRL
        ;; 6) IA32_PAT
        ;; 7) IA32_EFER
        ;;            
        mov ecx, IA32_SYSENTER_CS
        rdmsr
        mov [GuestStateBufBase + GUEST_STATE.SysenterCsMsr], eax
        mov ecx, IA32_SYSENTER_ESP
        rdmsr
        mov [GuestStateBufBase + GUEST_STATE.SysenterEspMsr], eax
        mov [GuestStateBufBase + GUEST_STATE.SysenterEspMsr + 4], edx
        mov ecx, IA32_SYSENTER_EIP
        rdmsr
        mov [GuestStateBufBase + GUEST_STATE.SysenterEipMsr], eax
        mov [GuestStateBufBase + GUEST_STATE.SysenterEipMsr + 4], edx        
        mov ecx, IA32_PERF_GLOBAL_CTRL
        rdmsr
        mov [GuestStateBufBase + GUEST_STATE.PerfGlobalCtlMsr], eax
        mov [GuestStateBufBase + GUEST_STATE.PerfGlobalCtlMsr + 4], edx   
        mov ecx, IA32_PAT
        rdmsr
        mov [GuestStateBufBase + GUEST_STATE.PatMsr], eax
        mov [GuestStateBufBase + GUEST_STATE.PatMsr + 4], edx
        
        

        mov ecx, IA32_EFER
        rdmsr
        
        test DWORD [EntryControlBufBase + ENTRY_CONTROL.VmEntryControl], IA32E_MODE_GUEST
        jnz init_guest_state_area.@3
        
        ;;
        ;; 当 "IA-32e mode guest"为 0 时, 清掉 LME, LMA 以及 SCE 位
        ;;        
        and eax, ~(EFER_LME | EFER_LMA | EFER_SCE)

init_guest_state_area.@3:        

        mov [GuestStateBufBase + GUEST_STATE.EferMsr], eax
        mov [GuestStateBufBase + GUEST_STATE.EferMsr + 4], edx        

        
        ;;
        ;; SMBASE  = 0
        ;;
        mov DWORD [GuestStateBufBase + GUEST_STATE.SmBase], 0
        
        
        ;;
        ;;==== 设置 guest non-register state 信息 ====
        ;;
        ;;
        ;; 1. Activity state = Active
        ;;
        ;;
        mov DWORD [GuestStateBufBase + GUEST_STATE.ActivityState], GUEST_STATE_ACTIVE
        
        ;; 2. Interruptibility state:
        ;; 说明: 
        ;;    1) 全部设置为 0
        ;;    2) 除了当 guest processor 处于 SMM 模式时, Block by SMI 必须设为 1 值
        ;; 因此: 
        ;;    [0]: Blocking by STI: No
        ;;    [1]: Blocking by MOV SS: No
        ;;    [2]: Blocking by SMI: No
        ;;    [3]: Blocking by NMI: No
        ;;
        mov DWORD [GuestStateBufBase + GUEST_STATE.InterruptibilityState], 0
        
        ;;
        ;; 3. Pending debug exceptions = 0
        ;;
        mov DWORD [GuestStateBufBase + GUEST_STATE.PendingDebugException], 0
        mov DWORD [GuestStateBufBase + GUEST_STATE.PendingDebugException + 4], 0
        
        ;;
        ;; 4. VMCS link pointer = FFFFFFFF_FFFFFFFFh
        ;;
        mov eax, 0FFFFFFFFh
        mov [GuestStateBufBase + GUEST_STATE.VmcsLinkPointer], eax
        mov [GuestStateBufBase + GUEST_STATE.VmcsLinkPointer + 4], eax
        
        ;;
        ;; 5. VMX-preemption timer value
        ;; 说明: 
        ;;    1) guest 每 500ms 执行 VM-exit
        ;;    2) PCB.ProcessorFrequency * us 数
        ;;
%if 0        
        mov esi, [ebp + PCB.ProcessorFrequency]
        mov eax, 500000                                                 ; 500ms
        mul esi
%endif
        mov eax, [esi + VMB.VmxTimerValue]                                      ; 从 VMB 里读取 timer value        
        mov [GuestStateBufBase + GUEST_STATE.VmxPreemptionTimerValue], eax
        
        ;;
        ;; 6. PDPTEs(Page-Directory-Pointer Table Enties)
        ;; 说明: 
        ;;      1) 从 PCB.Ppt 表里读取 4 个 PDPTEs 值
        ;;
        mov eax, [ebp + PCB.Ppt]
        mov edx, [ebp + PCB.Ppt + 4]
        mov [GuestStateBufBase + GUEST_STATE.Pdpte0], eax
        mov [GuestStateBufBase + GUEST_STATE.Pdpte0 + 4], edx        
        mov eax, [ebp + PCB.Ppt + 8 * 1]
        mov edx, [ebp + PCB.Ppt + 8 * 1 + 4]
        mov [GuestStateBufBase + GUEST_STATE.Pdpte1], eax
        mov [GuestStateBufBase + GUEST_STATE.Pdpte1 + 4], edx
        mov eax, [ebp + PCB.Ppt + 8 * 2]
        mov edx, [ebp + PCB.Ppt + 8 * 2 + 4]
        mov [GuestStateBufBase + GUEST_STATE.Pdpte2], eax
        mov [GuestStateBufBase + GUEST_STATE.Pdpte2 + 4], edx
        mov eax, [ebp + PCB.Ppt + 8 * 3]
        mov edx, [ebp + PCB.Ppt + 8 * 3 + 4]     
        mov [GuestStateBufBase + GUEST_STATE.Pdpte3], eax
        mov [GuestStateBufBase + GUEST_STATE.Pdpte3 + 4], edx
               



        ;;
        ;; guest interrupt status
        ;;                
        mov WORD [GuestStateBufBase + GUEST_STATE.GuestInterruptStatus], 0
        
        
%undef GuestStateBufBase        
%undef ExecutionControlBufBase
%undef EntryControlBufBase

        pop ebx
        pop ecx
        pop edx
        pop ebp
        ret
        


;----------------------------------------------------------
; init_realmode_guest_state()
; input:
;       esi - VMB pointer
; output:
;       none
; 描述: 
;       1) 设置实模式下 VMCS 的 GUEST STAGE 区域
;----------------------------------------------------------     
init_realmode_guest_state:
        push ebp
        push edx
        push ecx
        push ebx
        
%ifdef __X64
        LoadGsBaseToRbp                                         ; ebp = PCB.Base
        LoadFsBaseToRbx                                         ; ebx = SDA.Base
%else
        mov ebp, [gs: PCB.Base]
        mov ebx, [fs: SDA.Base]
%endif

%define GuestStateBufBase                       (ebp + PCB.GuestStateBuf)

        
        ;;
        ;; 实模式下 guest 的设置
        ;; 1) CR0 = 固定值
        ;; 2) CR4 = 固定值
        ;; 3) CR3 =  0
        ;;
        mov eax, [ebp + PCB.Cr0FixedMask]               ; CR0 固定值
        and eax, ~(CR0_PG | CR0_PE)        
        mov edx, [ebp + PCB.Cr4FixedMask]               ; CR4 的固定值
        xor ecx, ecx                                    ; 清 CR3

      
        ;;
        ;; 写入 CR0, CR4 以及 CR3
        ;;
        REX.Wrxb
        mov [GuestStateBufBase  + GUEST_STATE.Cr0], eax
        REX.Wrxb
        mov [GuestStateBufBase  + GUEST_STATE.Cr4], edx
        REX.Wrxb
        mov [GuestStateBufBase  + GUEST_STATE.Cr3], ecx
        
     
        ;;
        ;; DR7 = 400h
        ;;        
        mov eax, 400h
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.Dr7], eax
        
        ;;
        ;; RIP = GuestEntry
        ;; Rflags = 00000002h
        ;;
        mov eax, [esi + VMB.GuestEntry]
        mov ecx, 02h
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.Rip], eax
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.Rflags], ecx


        ;;
        ;; RSP = GuestStack
        ;;
        mov eax, [esi + VMB.GuestStack]
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.Rsp], eax
          
                
        ;;
        ;; 下面设置 segment register 相关值
        ;; 1) 16 位 selector
        ;; 2) 32 位 base
        ;; 3) 32 位 limit
        ;; 4) 32 位 access right
        ;;  

        ;;
        ;; selector = 0
        ;;
        mov WORD [GuestStateBufBase + GUEST_STATE.CsSelector], 0
        mov WORD [GuestStateBufBase + GUEST_STATE.SsSelector], 0
        mov WORD [GuestStateBufBase + GUEST_STATE.DsSelector], 0
        mov WORD [GuestStateBufBase + GUEST_STATE.EsSelector], 0
        mov WORD [GuestStateBufBase + GUEST_STATE.FsSelector], 0
        mov WORD [GuestStateBufBase + GUEST_STATE.GsSelector], 0
        mov WORD [GuestStateBufBase + GUEST_STATE.LdtrSelector], 0        
        mov WORD [GuestStateBufBase + GUEST_STATE.TrSelector], 0        
        
        ;;
        ;; 所有 limit 为 0FFFFh
        ;;
        mov DWORD [GuestStateBufBase + GUEST_STATE.CsLimit], 0FFFFh
        mov DWORD [GuestStateBufBase + GUEST_STATE.SsLimit], 0FFFFh
        mov DWORD [GuestStateBufBase + GUEST_STATE.DsLimit], 0FFFFh
        mov DWORD [GuestStateBufBase + GUEST_STATE.EsLimit], 0FFFFh
        mov DWORD [GuestStateBufBase + GUEST_STATE.FsLimit], 0FFFFh
        mov DWORD [GuestStateBufBase + GUEST_STATE.GsLimit], 0FFFFh
        mov DWORD [GuestStateBufBase + GUEST_STATE.LdtrLimit], 0FFFFh
        mov DWORD [GuestStateBufBase + GUEST_STATE.TrLimit], 0FFFFh
        
        ;;
        ;; base = 0
        ;;
        xor eax, eax
        REX.Wrxb
        mov DWORD [GuestStateBufBase + GUEST_STATE.CsBase], eax
        REX.Wrxb        
        mov [GuestStateBufBase + GUEST_STATE.SsBase], eax
        REX.Wrxb        
        mov [GuestStateBufBase + GUEST_STATE.DsBase], eax
        REX.Wrxb        
        mov [GuestStateBufBase + GUEST_STATE.EsBase], eax
        REX.Wrxb        
        mov [GuestStateBufBase + GUEST_STATE.LdtrBase], eax
        REX.Wrxb        
        mov [GuestStateBufBase + GUEST_STATE.FsBase], eax
        REX.Wrxb        
        mov [GuestStateBufBase + GUEST_STATE.GsBase], eax
        REX.Wrxb        
        mov [GuestStateBufBase + GUEST_STATE.TrBase], eax

        ;;
        ;; access rights:
        ;; 1) CS = 9Bh
        ;; 1) ES/SS/DS/FS/GS = 93h
        ;; 2) LDTR = 00082h
        ;; 3) TR = 00083h
        ;;
        mov DWORD [GuestStateBufBase + GUEST_STATE.CsAccessRight], TYPE_NON_SYS | TYPE_CcRA | SEG_ugdlP
        mov DWORD [GuestStateBufBase + GUEST_STATE.SsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_ugdlP
        mov DWORD [GuestStateBufBase + GUEST_STATE.DsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_ugdlP
        mov DWORD [GuestStateBufBase + GUEST_STATE.EsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_ugdlP
        mov DWORD [GuestStateBufBase + GUEST_STATE.FsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_ugdlP
        mov DWORD [GuestStateBufBase + GUEST_STATE.GsAccessRight], TYPE_NON_SYS | TYPE_ceWA | SEG_ugdlP
        mov DWORD [GuestStateBufBase + GUEST_STATE.LdtrAccessRight], TYPE_SYS | TYPE_LDT | SEG_ugdlP
        mov DWORD [GuestStateBufBase + GUEST_STATE.TrAccessRight], TYPE_SYS | TYPE_BUSY_TSS16 | SEG_ugdlP
                        
        

        ;;
        ;; GDTR 与 IDTR
        ;; 1) base = 0
        ;; 2) limit = 0FFFFh
        ;;
        xor eax, eax
        mov edx, 0FFFFh
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.GdtrBase], eax
        REX.Wrxb
        mov [GuestStateBufBase + GUEST_STATE.IdtrBase], eax
        mov [GuestStateBufBase + GUEST_STATE.GdtrLimit], edx
        mov [GuestStateBufBase + GUEST_STATE.IdtrLimit], edx


        ;;
        ;; MSRs 设置: 
        ;; 1) IA32_DEBUGCTL = 0
        ;; 2) IA32_SYSENTER_CS = 0
        ;; 3) IA32_SYSENTER_ESP = 0
        ;; 4) IA32_SYSENTER_EIP = 0
        ;; 5) IA32_PERF_GLOBAL_CTRL = 0
        ;; 6) IA32_PAT = 当前值
        ;; 7) IA32_EFER = 0
        ;;            
        xor eax, eax
        xor edx, edx
        mov [GuestStateBufBase + GUEST_STATE.SysenterCsMsr], eax
        mov [GuestStateBufBase + GUEST_STATE.SysenterEspMsr], eax
        mov [GuestStateBufBase + GUEST_STATE.SysenterEspMsr + 4], edx
        mov [GuestStateBufBase + GUEST_STATE.SysenterEipMsr], eax
        mov [GuestStateBufBase + GUEST_STATE.SysenterEipMsr + 4], edx        
        mov [GuestStateBufBase + GUEST_STATE.PerfGlobalCtlMsr], eax
        mov [GuestStateBufBase + GUEST_STATE.PerfGlobalCtlMsr + 4], edx   
        mov [GuestStateBufBase + GUEST_STATE.EferMsr], eax
        mov [GuestStateBufBase + GUEST_STATE.EferMsr + 4], edx    
        mov ecx, IA32_PAT
        rdmsr
        mov [GuestStateBufBase + GUEST_STATE.PatMsr], eax
        mov [GuestStateBufBase + GUEST_STATE.PatMsr + 4], edx

       
        ;;
        ;; SMBASE=0
        ;;
        mov DWORD [GuestStateBufBase + GUEST_STATE.SmBase], 0
        
        
        ;;
        ;;==== 设置 guest non-register state 信息 ====
        ;;
        ;;
        ;; 1. Activity state = Active
        ;;
        ;;
        mov DWORD [GuestStateBufBase + GUEST_STATE.ActivityState], GUEST_STATE_ACTIVE
        
        ;; 2. Interruptibility state:
        ;; 说明: 
        ;;    1) 全部设置为 0
        ;;    2) 除了当 guest processor 处于 SMM 模式时, Block by SMI 必须设为 1 值
        ;; 因此: 
        ;;    [0]: Blocking by STI: No
        ;;    [1]: Blocking by MOV SS: No
        ;;    [2]: Blocking by SMI: No
        ;;    [3]: Blocking by NMI: No
        ;;
        mov DWORD [GuestStateBufBase + GUEST_STATE.InterruptibilityState], 0
        
        ;;
        ;; 3. Pending debug exceptions = 0
        ;;
        mov DWORD [GuestStateBufBase + GUEST_STATE.PendingDebugException], 0
        mov DWORD [GuestStateBufBase + GUEST_STATE.PendingDebugException + 4], 0
        
        ;;
        ;; 4. VMCS link pointer = FFFFFFFF_FFFFFFFFh
        ;;
        mov eax, 0FFFFFFFFh
        mov [GuestStateBufBase + GUEST_STATE.VmcsLinkPointer], eax
        mov [GuestStateBufBase + GUEST_STATE.VmcsLinkPointer + 4], eax
        
        ;;
        ;; 5. VMX-preemption timer value = 0
        ;;
        mov eax, [esi + VMB.VmxTimerValue]                                      ; 从 VMB 里读取 timer value        
        mov [GuestStateBufBase + GUEST_STATE.VmxPreemptionTimerValue], eax        
        
        ;;
        ;; 6. PDPTEs(Page-Directory-Pointer Table Enties)
        ;; 说明: 
        ;;      1) 所有 PDPTEs 为 0
        ;;
        xor eax, eax
        xor edx, edx
        mov [GuestStateBufBase + GUEST_STATE.Pdpte0], eax
        mov [GuestStateBufBase + GUEST_STATE.Pdpte0 + 4], edx        
        mov [GuestStateBufBase + GUEST_STATE.Pdpte1], eax
        mov [GuestStateBufBase + GUEST_STATE.Pdpte1 + 4], edx
        mov [GuestStateBufBase + GUEST_STATE.Pdpte2], eax
        mov [GuestStateBufBase + GUEST_STATE.Pdpte2 + 4], edx  
        mov [GuestStateBufBase + GUEST_STATE.Pdpte3], eax
        mov [GuestStateBufBase + GUEST_STATE.Pdpte3 + 4], edx
               
        ;;
        ;; guest interrupt status
        ;;                
        mov WORD [GuestStateBufBase + GUEST_STATE.GuestInterruptStatus], 0
        
        
%undef GuestStateBufBase        

        pop ebx
        pop ecx
        pop edx
        pop ebp
        ret
    
    
        
;----------------------------------------------------------
; init_host_state_area()
; input:
;       esi - VMB pointer
; output:
;       none
; 描述: 
;       1) 设置 VMCS 的 HOST STAGE 区域
;----------------------------------------------------------   
init_host_state_area:
        push ebp
        push edx
        push ebx
        push ecx

%ifdef __X64
        LoadGsBaseToRbp
        LoadFsBaseToRbx
%else
        mov ebp, [gs: PCB.Base]
        mov ebx, [fs: SDA.Base]
%endif        

%define HostStateBufBase                (ebp + PCB.HostStateBuf)


        ;;
        ;; 以当前值分别写入 CR0, CR3, CR4
        ;;
        REX.Wrxb
        mov eax, cr0
        REX.Wrxb
        mov [HostStateBufBase + HOST_STATE.Cr0], eax
        REX.Wrxb
        mov eax, cr3
        REX.Wrxb
        mov [HostStateBufBase + HOST_STATE.Cr3], eax
        REX.Wrxb
        mov eax, cr4
        REX.Wrxb
        mov [HostStateBufBase + HOST_STATE.Cr4], eax


        ;;
        ;; 写入 rsp 与 rip
        ;;
        REX.Wrxb
        mov eax, [esi + VMB.HostStack]    
        REX.Wrxb
        mov [HostStateBufBase + HOST_STATE.Rsp], eax            
        REX.Wrxb
        mov eax, [esi + VMB.HostEntry]
        REX.Wrxb
        mov [HostStateBufBase + HOST_STATE.Rip], eax        
        

        ;;
        ;; 以当前值写入 selector 值
        ;;
        mov ax, cs
        mov [HostStateBufBase + HOST_STATE.CsSelector], ax
        mov ax, ss
        mov [HostStateBufBase + HOST_STATE.SsSelector], ax
        mov ax, ds
        mov [HostStateBufBase + HOST_STATE.DsSelector], ax
        mov ax, es
        mov [HostStateBufBase + HOST_STATE.EsSelector], ax
        mov ax, fs
        mov [HostStateBufBase + HOST_STATE.FsSelector], ax
        mov ax, gs
        mov [HostStateBufBase + HOST_STATE.GsSelector], ax
        mov ax, [ebp + PCB.TssSelector]
        mov [HostStateBufBase + HOST_STATE.TrSelector], ax

        ;;
        ;; 写入 segment base 值
        ;;
        REX.Wrxb
        mov [HostStateBufBase + HOST_STATE.GsBase], ebp
        REX.Wrxb
        mov [HostStateBufBase + HOST_STATE.FsBase], ebx
        REX.Wrxb
        mov eax, [ebp + PCB.TssBase]
        REX.Wrxb
        mov [HostStateBufBase + HOST_STATE.TrBase], eax        
        REX.Wrxb
        mov eax, [ebp + PCB.GdtPointer]
        REX.Wrxb
        mov eax, [eax + 2]
        REX.Wrxb
        mov [HostStateBufBase + HOST_STATE.GdtrBase], eax
        REX.Wrxb
        mov eax, [ebx + SDA.IdtBase]
        REX.Wrxb
        mov [HostStateBufBase + HOST_STATE.IdtrBase], eax

               
        ;;
        ;; 以当前值写入 MSR
        ;; 1) IA32_SYSENTER_CS(32位)
        ;; 2) IA32_SYSENTER_ESP
        ;; 3) IA32_SYSENTER_EIP
        ;; 4) IA32_PERF_GLOBAL_CTRL
        ;; 5) IA32_PAT
        ;; 6) IA32_EFER
        ;; 
        mov ecx, IA32_SYSENTER_CS
        rdmsr
        mov [HostStateBufBase + HOST_STATE.SysenterCsMsr], eax
        mov ecx, IA32_SYSENTER_ESP
        rdmsr
        mov [HostStateBufBase + HOST_STATE.SysenterEspMsr], eax
        mov [HostStateBufBase + HOST_STATE.SysenterEspMsr + 4], edx
        mov ecx, IA32_SYSENTER_EIP
        rdmsr
        mov [HostStateBufBase + HOST_STATE.SysenterEipMsr], eax
        mov [HostStateBufBase + HOST_STATE.SysenterEipMsr + 4], edx        
        mov ecx, IA32_PERF_GLOBAL_CTRL
        rdmsr
        mov [HostStateBufBase + HOST_STATE.PerfGlobalCtlMsr], eax
        mov [HostStateBufBase + HOST_STATE.PerfGlobalCtlMsr + 4], edx        
        mov ecx, IA32_PAT
        rdmsr
        mov [HostStateBufBase + HOST_STATE.PatMsr], eax
        mov [HostStateBufBase + HOST_STATE.PatMsr + 4], edx
        mov ecx, IA32_EFER
        rdmsr
        mov [HostStateBufBase + HOST_STATE.EferMsr], eax
        mov [HostStateBufBase + HOST_STATE.EferMsr + 4], edx        
        
%undef HostStateBufBase        
        pop ecx
        pop ebx
        pop edx
        pop ebp
        ret     




;----------------------------------------------------------
; init_vm_execution_control_fields()
; input:
;       esi - VMCS 管理块指针(VMCS_MANAGE_BLOCK)
; output:
;       none
; 描述: 
;       1) 设置 VMCS 的 VM-execution 控制域
;----------------------------------------------------------   
init_vm_execution_control_fields:
        push ebx
        push edx
        push ebp

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif

%define ExecutionControlBufBase         (ebp + PCB.ExecutionControlBuf)


        
        ;;
        ;; 设置 Pin-based 控制域:
        ;; 1) [0]  - external-interrupt exiting: Yes
        ;; 2) [3]  - NMI exiting: Yes
        ;; 3) [5]  - Virtual NMIs: No
        ;; 4) [6]  - Activate VMX preemption timer: Yes
        ;; 5) [7]  - process posted interrupts: No
        ;;
        ;; 注意: 
        ;; 1) 如果 VMB.VmxTimerValue = 0 时, 不使用 VMX-preemption timer
        ;;
        
        mov ebx, EXTERNAL_INTERRUPT_EXITING | NMI_EXITING
        mov eax, EXTERNAL_INTERRUPT_EXITING | NMI_EXITING | ACTIVATE_VMX_PREEMPTION_TIMER        
        
        cmp DWORD [esi + VMB.VmxTimerValue], 0
        cmove eax, ebx
        
        ;;
        ;; 注意, PCB.PinBasedCtls 的值在 stage1 阶段时已更新, 它的值为: 
        ;; 1) 当 IA32_VMX_BASIC[55] = 1 时, 等于 IA32_VMX_TRUE_PINBASED_CTLS 寄存器
        ;; 2) 当 IA32_VMX_BASIC[55] = 0 时, 等于 IA32_VMX_PINBASED_CTLS 寄存器
        ;; 
        
        ;;######################################################################################
        ;; PCB.PinBasedCtls 值说明: 
        ;; 1) [31:0]  - allowed 0-setting 位
        ;;              当 bit 为 1 时, Pin-based VM-execution control 位为 0, 则出错!
        ;;              当 bit 为 0 时, Pin-based VM-execution control 位可为 0 值. 
        ;;     因此:    当 bit 为 1 时, Pin-based VM-execution control 必须为 1 值!!!    
        ;;              
        ;; 2) [63:32] - allowed 1-setting 位
        ;;              当 bit 为 0 时, Pin-based VM-execution control 位为 1, 则出错！
        ;;              当 bit 为 1 时, Pin-based VM-execution control 位可为 1 值. 
        ;;     因此:    当 bit 为 0 时, Pin-based VM-execution control 必须为 0 值!!!
        ;;
        ;; 3) 当 [31:0] 的位为 0, 而 [63:32] 的相应位同时为 1 时, 
        ;;    说明 Pin-based VM-execution control 位允许设置为 0 或 1 值
        ;;
        ;; 生成最终的 Pin-based VM-execution control 值说明: 
        ;; 1) 当 eax 输入用户设置的值后, 下面算法生成最终的值
        ;; 算法一: 
        ;; 1) mask1 = (allowed 0-setting) AND (allowed 1-setting): 得出必须为 1 的 mask 值
        ;; 2) eax = (eax) OR (mask1): 置 1 值
        ;; 3) mask0 = (allowed 0-setting) OR (allowed 1-setting): 得出必须为 0 的 mask 值
        ;; 4) eax = (eax) AND (mask0): 清 0 值
        ;; 
        ;; 算法二: 
        ;; 1) eax = (eax) OR (allowed 0-setting)
        ;; 2) eax = (eax) AND (allowed 1-setting)
        ;;
        ;; 算法二是算法一的简便实现, 它们的结果是一样的！
        ;; 这是因为当前:
        ;;      1) allowed 0-setting = (allowed 0-setting) AND (allowed 1-setting)
        ;;      2) allowed 1-setting = (allowed 0-setting) OR (allowed 1-setting)
        ;;
        ;;######################################################################################
        
                       
        ;;
        ;; 使用算法二, 生成最终的 Pin-based VM-execution control 值
        ;;
        or eax, [ebp + PCB.PinBasedCtls]                                ; OR  allowed 0-setting
        and eax, [ebp + PCB.PinBasedCtls + 4]                           ; AND allowed 1-setting

        ;;
        ;; 写入 Pin-based VM-execution control 值
        ;;        
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.PinControl], eax

        
        ;;
        ;; 设置 Processor-based VM-execution control 域
        ;; [2]  - Interrupt-window exiting: No
        ;; [3]  - Use TSC offsetting: No
        ;; [7]  - HLT exiting: Yes
        ;; [9]  - INVLPG exiting: Yes
        ;; [10] - NWAIT exiting: Yes
        ;; [11] - RDPMC exiting: No
        ;; [12] - RDTSC exiting: No
        ;; [15] - CR3-load exiting: Yes
        ;; [16] - CR3-store exiting: Yes
        ;; [19] - CR8-load exiting: No
        ;; [20] - CR8-store exiting: No
        ;; [21] - Use TPR shadow: Yes
        ;; [22] - NMI-window exiting: No
        ;; [23] - MOV-DR exiting: No
        ;; [24] - Unconditional I/O exiting: Yes
        ;; [25] - Use I/O bitmaps: Yes
        ;; [27] - Monitor trap flag: No
        ;; [28] - Use MSR bitmaps: Yes
        ;; [29] - MONITOR exiting: Yes
        ;; [30] - PAUSE exiting: No
        ;; [31] - Active secondary controls: Yes
        ;;
        mov eax, 0B3218680h
        
        ;;
        ;; 设置 Primary Processor-based VM-execution control 值
        ;; 1) 原理和　Pin-based VM-execution control 值相同!
        ;;   
        or eax, [ebp + PCB.ProcessorBasedCtls]                          ; OR  allowed 0-setting
        and eax, [ebp + PCB.ProcessorBasedCtls + 4]                     ; AND allowed 1-setting
        
        ;;
        ;; 写入 Primary Processor-based VM-execution control 值
        ;;
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.ProcessorControl1], eax
        
        
        ;;
        ;; 设置　Secondary Processor-based VM-execution control 值
        ;; 1) [0]  - Virtualize APIC access: Yes
        ;; 2) [1]  - Enable EPT: No
        ;; 3) [2]  - Descriptor-table exiting: Yes
        ;; 4) [3]  - Enable RDTSCP: Yes
        ;; 5) [4]  - Virtualize x2APIC mode: No
        ;; 6) [5]  - Enable VPID: Yes
        ;; 7) [6]  - WBINVD exiting: Yes
        ;; 8) [7]  - unrestricted guest: 由 VMB.GuestFlags 决定
        ;; 9) [8]  - APIC-register virtualization: Yes
        ;; 10) [9] - virutal-interrupt delivery: Yes
        ;; 11) [10] - PAUSE-loop exiting: No
        ;; 12) [11] - RDRAND exiting: No
        ;; 13) [12] - Enable INVPCID: Yes
        ;; 14) [13] - Enable VM functions: No
        ;;
        mov edx, 136Dh
        
        ;;
        ;; 下面情况下之一, 使用 unrestricted guest 设置
        ;; 1) GUEST_FLAG_PE = 0
        ;; 2) GUEST_FLAG_PG = 0
        ;; 3) GUEST_FLAG_UNRESTRICTED = 1
        ;;
        ;; "unrestricted guest" = 1 时, "Enable EPT"必须为 1
        ;;
        mov edi, [esi + VMB.GuestFlags]
        
        test edi, GUEST_FLAG_PE
        jz init_vm_execution_control_fields.@0
        test edi, GUEST_FLAG_PG
        jz init_vm_execution_control_fields.@0
        test edi, GUEST_FLAG_UNRESTRICTED
        jnz init_vm_execution_control_fields.@0
        test edi, GUEST_FLAG_EPT
        jz init_vm_execution_control_fields.@01
        
        or edx, ENABLE_EPT
        jmp init_vm_execution_control_fields.@01
        
init_vm_execution_control_fields.@0:
        or edx, UNRESTRICTED_GUEST | ENABLE_EPT


init_vm_execution_control_fields.@01:

        ;;
        ;; 如果 "Use TPR shadow" 为 0, 下面位必须为 0
        ;; 1) "virtualize x2APIC mode"
        ;; 2) "APIC-registers virtualization"
        ;; 3) "virutal-interrupt delivery"
        ;;
        test eax, USE_TPR_SHADOW
        jnz init_vm_execution_control_fields.@02
        
        and edx, ~(VIRTUALIZE_X2APIC_MODE | APIC_REGISTER_VIRTUALIZATION | VIRTUAL_INTERRUPT_DELIVERY)
        
init_vm_execution_control_fields.@02:        
                       
        ;;
        ;; 设置 Secondary Processor-Based VM-excution control 最终值
        ;; 1) 算法与 Pin-Based VM-excution control 值一致
        ;;
        or edx, [ebp + PCB.ProcessorBasedCtls2]                         ; OR  allowed 0-setting
        and edx, [ebp + PCB.ProcessorBasedCtls2 + 4]                    ; AND allowed 1-setting
        
        ;;
        ;; 写入 Secondary Processor-based VM-execution control 值
        ;;
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.ProcessorControl2], edx
        
                
        ;;
        ;; 设置 Exception Bitmap
        ;; 1) #BP exiting - Yes
        ;; 2) #DE exiting - Yes
        ;; 3) #UD exiting - Yes
        ;; 4) #PF exiting - Yes
        ;; 5) #GP exiting - Yes
        ;; 6) #SS exiting - Yes
        ;; 7) #DF exiting - Yes
        ;; 8) #DB exiting - Yes
        ;; 9) #TS exiting - Yes
        ;; 10) #NP exiting - Yes
        ;;
        mov eax, 7D4Bh
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.ExceptionBitmap], eax
        
        ;;
        ;; 设置 #PF 异常的 PFEC_MASK 与 PFEC_MATCH 值
        ;; PFEC 与 PFEC_MASK, PFEC_MATCH 说明: 
        ;; 当 PFEC & PFEC_MASK = PFEC_MATCH 时, #PF 导致 VM exit 发生
        ;;      1) 当 PFEC_MASK = PFEC_MATCH = 0 时, 所有的 #PF 都导致 VM exit
        ;;      2) 当 PFEC_MASK = 0, 而 PFEC_MATCH = FFFFFFFFh 时, 任何 #PF 都不会导致 VM exit
        ;;
        ;; PFEC 说明:
        ;; 1) [0] - P 位:   为 0 时, #PF 由 not present 产生
        ;;                  为 1 时, #PF 由其它 voilation 产生
        ;; 2) [1] - R/W 位: 为 0 时, #PF 由 read access 产生
        ;;                  为 1 时, #PF 由 write access 产生
        ;; 3) [2] - U/S 位: 为 0 时, 发生 #PF 时, 处理器在 supervisor 权限下
        ;;                  为 1 时, 发生 #PF 时, 处理器在 user 权限下
        ;; 4) [3] - RSVD 位: 为 0 时, 指示保留位为 0
        ;;                   为 1 时, 指示保留位为 1
        ;; 5) [4] - I/D 位:  为 0 时, 执行页正常
        ;;                   为 1 时, 执行页产生 #PF
        ;; 6) [31:5] - 保留位
        ;;
        
        
       
        ;;
        ;; 下面设置所有的 #PF 都引发 VM exit
        ;; 1) PFEC_MASK  = 0
        ;; 2) PFEC_MATCH = 0
        ;;        
        mov DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.PfErrorCodeMask], 0
        mov DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.PfErrorCodeMatch], 0
        
        
        
        ;;
        ;; 设置 IO bitmap address(物理地址)
        ;;                
        mov eax, [esi + VMB.IoBitmapPhyAddressA]
        mov edx, [esi + VMB.IoBitmapPhyAddressA + 4]
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.IoBitmapAddressA], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.IoBitmapAddressA + 4], edx
        mov eax, [esi + VMB.IoBitmapPhyAddressB]
        mov edx, [esi + VMB.IoBitmapPhyAddressB + 4]
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.IoBitmapAddressB], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.IoBitmapAddressB + 4], edx
                
        ;;
        ;; 设置 TSC-offset
        ;;
        mov DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.TscOffset], 0
        mov DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.TscOffset + 4], 0
        
        
        ;;
        ;; 设置 CR0/CR4 的 guest/host mask 及 read shadows 值
        ;; 说明: 
        ;; 1) 当 mask 相应位为 1 时, 表明此位属于 Host 设置, guest 无权设置
        ;; 2) 当 mask 相应位为 0 时, 表时此位 guest 可以设置
        ;;
        
        ;;
        ;; CR0 guest/host mask 设置, 根据提供的 guest flags 来进行设置
        ;; 1) CR0.NE 属 host 权限
        ;; 2) 当 GUEST_FLAG_PE = 1, CR0.PE 属于 host 权限, 否则为 guest 权限
        ;; 3) 当 GUEST_FLAG_PG = 1, CR0.PG 属于 host 权限, 否则为 guest 权限
        ;; 5) CR0.CD 属于 host 权限
        ;; 6) CR0.NW 属于 host 权限
        ;;
        ;; CR0 read shadow 设置:
        ;; 1) CR0.PE 等于 CR0 guest/host mask 的 CR0.PE
        ;; 2) CR0.PG 等于 CR0 guest/host mask 的 CR0.PG
        ;; 3) CR0.NE = 1
        ;; 4) CR0.CD = 0
        ;; 5) CR0.NW = 0
        ;;       
        mov eax, [esi + VMB.GuestFlags]
        and eax, (GUEST_FLAG_PG | GUEST_FLAG_PE)
        or eax, CR0_NE | CR0_CD | CR0_NW
        mov edx, eax
        and edx, ~(CR0_CD | CR0_NW)                     
        mov DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.Cr0GuestHostMask], eax
        mov DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.Cr0GuestHostMask + 4], 0FFFFFFFFh
        mov DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.Cr0ReadShadow], edx
        mov DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.Cr0ReadShadow + 4], 0
        
        ;;
        ;; CR4 guest/host mask 与 read shadow 设置
        ;; 1)  CR4.VMXE 及 CR4.VME 属于 host 权限
        ;; 2) 当 GUEST_FLAG_PG = 1 时, CR4.PAE 属于 host 权限, 否则 guest 权限
        ;;
        mov eax, 00002021h
        mov edi, 00002020h        
        test DWORD [esi + VMB.GuestFlags], GUEST_FLAG_PG
        jnz init_vm_execution_control_fields.Cr4
        
        mov eax, 00002001h                              ;; guest/host mask[PAE] = 0
        mov edi, 00002000h                              ;; read shadow[PAE] = 0
        
init_vm_execution_control_fields.Cr4:        
        mov DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.Cr4GuestHostMask], eax
        mov DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.Cr4GuestHostMask + 4], 0FFFFFFFFh
        mov DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.Cr4ReadShadow], edi
        mov DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.Cr4ReadShadow + 4], 0
        
        
        ;;
        ;; CR3 target control 设置
        ;; 1) CR3-target count = 0
        ;; 2) CR3-target value = 0
        ;;
        xor eax, eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.Cr3TargetCount], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.Cr3Target0], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.Cr3Target0 + 4], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.Cr3Target1], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.Cr3Target1 + 4], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.Cr3Target2], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.Cr3Target2 + 4], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.Cr3Target3], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.Cr3Target3 + 4], eax
                
        ;;
        ;; APIC virtualization 设置
        ;; 1) APIC-access address  = 0FEE00000H(默认)
        ;; 2) Virtual-APIC address = 分配获得(物理地址)
        ;; 3) TPR thresold = 10h
        ;; 4) EOI-exit bitmap = 0
        ;; 5) posted-interrupt notification vector = 0
        ;; 6) posted-interrupt descriptor address = 0
        ;;
        mov DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.ApicAccessAddress], 0FEE00000H
        mov DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.ApicAccessAddress + 4], 0
        mov eax, [esi + VMB.VirtualApicPhyAddress]
        mov edx, [esi + VMB.VirtualApicPhyAddress + 4]
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.VirtualApicAddress], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.VirtualApicAddress + 4], edx                


        REX.Wrxb
        mov edx, esi
        
        ;;
        ;; 初始化 virtual-APIC page
        ;;
        REX.Wrxb
        mov esi, [edx + VMB.VirtualApicAddress]
        call init_virtual_local_apic
                             
        ;;
        ;;  ### 设置 TPR shadow ###
        ;;
        ;; 1) 当 "Use TPR shadow" = 0 时, TPR threshold = 0
        ;; 2) 当 "Use TPR shadow" = 1 并且 "Virtual-interrupt delivery" = 0 时, TPR threshold = VPTR[7:4]
        ;; 3) 否则 TPR threshold = 20h
        ;;       
        xor eax, eax                
        test DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.ProcessorControl1], USE_TPR_SHADOW
        jz init_vm_execution_control_fields.@1
        ;;
        ;; 读取 VPTR
        ;;
        REX.Wrxb
        mov eax, [edx + VMB.VirtualApicAddress]
        mov eax, [eax + TPR]
        shr eax, 4
        and eax, 0Fh                                            ; VPTR[7:4]                       

        test DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.ProcessorControl1], ACTIVATE_SECONDARY_CONTROL
        jz init_vm_execution_control_fields.@1
        test DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.ProcessorControl2], VIRTUAL_INTERRUPT_DELIVERY
        jz init_vm_execution_control_fields.@1
        mov eax, 2

init_vm_execution_control_fields.@1:
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.TprThreshold], eax
        
        
        xor eax, eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.EoiBitmap0], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.EoiBitmap0 + 4], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.EoiBitmap1], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.EoiBitmap1 + 4], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.EoiBitmap2], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.EoiBitmap2 + 4], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.EoiBitmap3], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.EoiBitmap3 + 4], eax                
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.PostedInterruptVector], ax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.PostedInterruptDescriptorAddr], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.PostedInterruptDescriptorAddr + 4], eax  
        
        ;;
        ;; MSR-bitmap address 设置(物理地址)
        ;;
        mov esi, [edx + VMB.MsrBitmapPhyAddress]
        mov edi, [edx + VMB.MsrBitmapPhyAddress + 4]
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.MsrBitmapAddress], esi
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.MsrBitmapAddress + 4], edi

        ;;
        ;; Executive-VMCS pointer
        ;;
        xor eax, eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.ExecutiveVmcsPointer], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.ExecutiveVmcsPointer + 4], eax          
        
        ;;
        ;; 如果 "Enable EPT" = 1, 必须设置 EPT
        ;;
        mov BYTE [ebp + PCB.EptEnableFlag], 0
        test DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.ProcessorControl2], ENABLE_EPT
        jz init_vm_execution_control_fields.@2
                
        mov BYTE [ebp + PCB.EptEnableFlag], 1                           ; 更新 EptEnableFlag 值
        
        REX.Wrxb
        mov esi, [edx + VMB.Ep4taPhysicalBase]
        
%ifndef __X64        
        mov edi, [edx + VMB.Ep4taPhysicalBase + 4]
%endif
        ;;
        ;; 初始化 EPTP 字段
        ;;
        call init_eptp_field
                
init_vm_execution_control_fields.@2:
        xor eax, eax
        ;;
        ;; 如果支持 "enable VPID"并开启, 则设置 VPID
        ;;
        test DWORD [ExecutionControlBufBase + EXECUTION_CONTROL.ProcessorControl2], ENABLE_VPID
        jz init_vm_execution_control_fields.@3
        
        mov ax, [edx + VMB.Vpid]                                        ; VMCS 对应的 VPID 值
        
init_vm_execution_control_fields.@3:        

        mov [ExecutionControlBufBase + EXECUTION_CONTROL.Vpid], ax      ; 写入 VPID 值        

        ;;
        ;; PAUSE-loop exiting 设置
        ;;
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.PleGap], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.PleWindow], eax  

        ;;
        ;; VM-funciton control
        ;;                
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.VmFunctionControl], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.VmFunctionControl + 4], eax          
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.EptpListAddress], eax
        mov [ExecutionControlBufBase + EXECUTION_CONTROL.EptpListAddress + 4], eax          
        
        ;;
        ;; 为了方便, 恢复 esi 值
        ;;
        REX.Wrxb
        mov esi, edx
           
%undef ExecutionControlBufBase        
        pop ebp
        pop edx
        pop ebx
        ret



;----------------------------------------------------------
; init_vm_exit_control_fields()
; input:
;     esi - VMB pointer
; 描述: 
;       1) 设置 VM-Entry 控制域  
;---------------------------------------------------------- 
init_vm_exit_control_fields:
        push ebp
        push edx
        
%ifdef __X64        
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif

%define ExitControlBufBase              (ebp + PCB.ExitControlBuf)

        ;;
        ;; VM-exit control 设置
        ;; 1) [2]  - Save debug controls: Yes
        ;; 2) [9]  - Host address size: No(x86), Yes(x64)
        ;; 3) [12] - load IA32_PREF_GLOBAL_CTRL: Yes
        ;; 4) [15] - acknowledge interrupt on exit: Yes
        ;; 5) [18] - save IA32_PAT: Yes
        ;; 6) [19] - load IA32_PAT: Yes
        ;; 7) [20] - save IA32_EFER: Yes
        ;; 8) [21] - load IA32_EFER: Yes
        ;; 9) [22] - save VMX-preemption timer value: 取决于"activity VMX-preemption timer"位
        ;;
        
        ;;
        ;; Host address size 值取决于 host 的模式
        ;; 1) 在 x86 下, Host address size = 0
        ;; 2) 在 64-bit 模式下, VM-exit 返回的 host 必须是 64-bit 模式, Host address size = 1
        ;;
%ifdef __X64
        mov eax, 3C9004h | HOST_ADDRESS_SPACE_SIZE
%else
        mov eax, 3C9004h
%endif


        ;;
        ;; 如果"activity VMX-preemption timer"=1时, "save VMX-preemption timer value"=1
        ;;
        test DWORD [ebp + PCB.ExecutionControlBuf + EXECUTION_CONTROL.PinControl], ACTIVATE_VMX_PREEMPTION_TIMER
        jz init_vm_exit_control_fields.@0
        
        or eax, SAVE_VMX_PREEMPTION_TIMER_VALUE        

        
init_vm_exit_control_fields.@0:

        
        ;;
        ;;　设置最终的 VM-exit control 值
        ;;
        or eax, [ebp + PCB.ExitCtls]                                    ; OR allowed 0-setting
        and eax, [ebp + PCB.ExitCtls + 4]                               ; AND allowed 1-setting
        mov [ExitControlBufBase + EXIT_CONTROL.VmExitControl], eax      ; 写入 Vm-exit control buffer
        
        
        ;;
        ;; VM-exit MSR-store 设置: 这里暂时不设置 MSR-store 
        ;; 1) MsrStoreCount = 0
        ;; 2) MsrStoreAddress =  分配获得
        ;;
        mov DWORD [ExitControlBufBase + EXIT_CONTROL.MsrStoreCount], 0
        mov eax, [esi + VMB.VmExitMsrStorePhyAddress]
        mov edx, [esi + VMB.VmExitMsrStorePhyAddress + 4]
        mov [ExitControlBufBase + EXIT_CONTROL.MsrStoreAddress], eax
        mov [ExitControlBufBase + EXIT_CONTROL.MsrStoreAddress + 4], edx


        ;;
        ;; Vm-exit Msr-load 设置: 这里暂不设置 Msr-store
        ;; 1) MsrLoadCount = 0
        ;; 2) MsrLoadAddress = 分配获得
        ;;
        mov DWORD [ExitControlBufBase + EXIT_CONTROL.MsrLoadCount], 0
        mov eax, [esi + VMB.VmExitMsrLoadPhyAddress]
        mov edx, [esi + VMB.VmExitMsrLoadPhyAddress + 4]
        mov [ExitControlBufBase + EXIT_CONTROL.MsrLoadAddress], eax
        mov [ExitControlBufBase + EXIT_CONTROL.MsrLoadAddress + 4], edx        


%undef ExitControlBufBase

        pop edx
        pop ebp
        ret




;----------------------------------------------------------
; init_vm_entry_control_fields()
; input:
;       esi - VMB pointer
; 描述: 
;       1) 设置 VM-Entry 控制域  
;---------------------------------------------------------- 
init_vm_entry_control_fields:
        push edx
        push ebp

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif

%define EntryControlBufBase             (ebp + PCB.EntryControlBuf)


        ;;
        ;; 在 legacy 模式下设置 VM-Entry control
        ;; 1) [2]  - load debug controls : Yes
        ;; 2) [9]  - IA-32e mode guest   : No(x86), Yes(x64)
        ;; 3) [10] - Entry to SMM        : No
        ;; 4) [11] - deactiveate dual-monitor treatment : No
        ;; 5) [13] - load IA32_PERF_GLOBAL_CTRL : Yes
        ;; 6) [14] - load IA32_PAT : Yes
        ;; 7) [15] - load IA32_EFER : Yes
        ;;
        
        ;;
        ;; 检查是否进入 IA-32e guest
        ;;
        mov edx, 0E004h
        mov eax, 0E004h | IA32E_MODE_GUEST        
        test DWORD [esi + VMB.GuestFlags], GUEST_FLAG_IA32E
        cmovz eax, edx
                
        ;;
        ;; 生成最终的 VM-entry control 值
        ;;
        or eax, [ebp + PCB.EntryCtls]                                   ; OR allowed 0-setting
        and eax, [ebp + PCB.EntryCtls + 4]                              ; AND allowed 1-setting
        mov [EntryControlBufBase + ENTRY_CONTROL.VmEntryControl], eax   ; 写入 Vm-entry control buffer
        

        ;;
        ;; VM-entry MSR-load 设置: 这里暂时不设置
        ;; 1) MsrLoadCount = 0
        ;; 2) VM-entry MsrLoadAddress =  VM-entry MsrStoreAddress
        ;;
        mov DWORD [EntryControlBufBase + ENTRY_CONTROL.MsrLoadCount], 0
        mov eax, [esi + VMB.VmExitMsrStorePhyAddress]
        mov edx, [esi + VMB.VmExitMsrStorePhyAddress + 4]
        mov [EntryControlBufBase + ENTRY_CONTROL.MsrLoadAddress], eax
        mov [EntryControlBufBase + ENTRY_CONTROL.MsrLoadAddress + 4], edx          
        
        
        ;;
        ;; 写入 event injection: 此时没有 event injection
        ;; 1) VM-entry interruption-inoformation = 0
        ;; 2) VM-entry exception error code = 0
        ;; 3) VM-entry instruction length = 0
        ;;
        mov DWORD [EntryControlBufBase + ENTRY_CONTROL.InterruptionInfo], 0
        mov DWORD [EntryControlBufBase + ENTRY_CONTROL.ExceptionErrorCode], 0
        mov DWORD [EntryControlBufBase + ENTRY_CONTROL.InstructionLength], 0

%undef EntryControlBufBase        

        pop ebp
        pop edx
        ret



;----------------------------------------------------------
; init_virutal_local_apic()
; input:
;       esi - virtual apic address
; output:
;       none
; 描述: 
;       1) 初始化 virtual local apic
;----------------------------------------------------------
init_virtual_local_apic:
        push ebp
        push ebx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif

        REX.Wrxb	        
        mov ebx, [ebp + PCB.LapicBase]
        
        mov eax, [ebx + LAPIC_ID]
        mov [esi + LAPIC_ID], eax
        mov eax, [ebx + LAPIC_VER]
        mov [esi + LAPIC_VER], eax
        
        xor eax, eax
        mov DWORD [esi + LAPIC_TPR], 20h                ; VTPR = 20h
        mov [esi + LAPIC_APR], eax
        mov [esi + LAPIC_PPR], eax
        mov [esi + LAPIC_RRD], eax
        mov [esi + LAPIC_LDR], eax
        mov [esi + LAPIC_DFR], eax
        mov eax, [ebx + LAPIC_SVR]
        mov [esi + LAPIC_SVR], eax
        
        ;;
        ;; 所有 LVTE 为 masked
        ;;
        mov eax, LVT_MASKED
        mov [esi + LAPIC_LVT_CMCI], eax
        mov [esi + LAPIC_LVT_TIMER], eax
        mov [esi + LAPIC_LVT_THERMAL], eax
        mov [esi + LAPIC_LVT_PERFMON], eax
        mov [esi + LAPIC_LVT_LINT0], eax
        mov [esi + LAPIC_LVT_LINT1], eax
        mov [esi + LAPIC_LVT_ERROR], eax

        xor eax, eax        
        mov [esi + LAPIC_TIMER_ICR], eax
        mov [esi + LAPIC_TIMER_CCR], eax
        mov [esi + LAPIC_TIMER_DCR], eax
        
        pop ebx
        pop ebp
        ret



;----------------------------------------------------------
; init_guest_page_table()
; input:
;       esi - VMB pointer
; output:
;       none
; 描述: 
;       1) 初始化 guest 环境的页表结构
;----------------------------------------------------------
init_guest_page_table:
        ret
        
        
