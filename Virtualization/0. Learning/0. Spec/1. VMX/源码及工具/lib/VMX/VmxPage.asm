;*************************************************
;* VmxPage.asm                                   *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************






;----------------------------------------------------------
; get_ept_pointer()
; input:
;       none
; output:
;       eax - vmcs pointer(虚拟地址)
;       edx - vmcs pointer(物理地址)
; 描述:  
;       1) 这个函数从 kernel pool 里分配 4K 块作为 EPT 中的 PT 表
;       2) eax 返回虚拟地址, edx 返回物理地址
;       3) 64-bit 下, rax - 64 位返回虚拟地址,  rdx - 64 位返回物理地址
;       4) 此函数实现在 VmxVmcs.asm 里
;----------------------------------------------------------
get_ept_pointer:
get_ept_page:
        ;;
        ;; EPT 的 page 使用 WB 类型
        ;;
        mov esi, 0
        jmp get_vmcs_region_pointer




;----------------------------------------------------------
; get_ept_page_attribute():
; input:
;       none
; output:
;       eax - page memory attribute
; 描述: 
;       1) 得到 EPT 结构中的 page memory attribute
;       2) 支持两种 attribute: WB 或 UC
;----------------------------------------------------------
get_ept_page_attribute:
        push ebp
%ifdef __X64
        LoadFsBaseToRbp
%else
        mov ebp, [fs: SDA.Base]
%endif           
        pop ebp
        ret



;----------------------------------------------------------
; init_ept_pxt():
; input:
;       none
; output:
;       none
; 描述: 
;       1) 初始化 EPT 的 PXT 表
;----------------------------------------------------------
init_ept_pxt_ppt:
        push ebp
        push ecx
        push edx

%ifdef __X64
        LoadFsBaseToRbp
%else
        mov ebp, [fs: SDA.Base]
%endif
            
        ;;
        ;; 映射 PPT 区域
        ;;
        REX.Wrxb
        mov esi, [ebp + SDA.EptPptBase64]
        REX.Wrxb
        mov edx, esi
        REX.Wrxb
        mov edi, [ebp + SDA.EptPptPhysicalBase64]
        
        mov eax, XD | RW | P                
        REX.Wrxb
        mov ecx, [ebp + SDA.EptPptTop64]
        REX.Wrxb
        sub ecx, esi
        REX.Wrxb
        add ecx, 0FFFh
        REX.Wrxb
        shr ecx, 12 
        
%ifdef __X64
        DB 41h, 89h, 0C0h                       ; mov r8d, eax
        DB 41h, 89h, 0C9h                       ; mov r9d, ecx
%endif        
        call do_virtual_address_mapping_n       
      
        ;;
        ;; 清 PPT 区域
        ;;
        REX.Wrxb
        mov esi, edx
        mov edi, ecx
        call clear_4k_buffer_n
        
        
        ;;
        ;; 写入 PXT 表值, 每个 PML4E 是 PPT 表物理地址
        ;;
        REX.Wrxb
        mov edi, [ebp + SDA.EptPxtBase64]                       ; Pxt 表基地址
        mov esi, [ebp + SDA.EptPptPhysicalBase64]               ; Ppt 表物理地址
        and esi, 0FFFFF000h
        
        xor ecx, ecx        
        mov edx, 00100000h                                      ; bits 54:53 = 1 时, 表示为 PML4E 
        
init_ept_pxt.loop:        
        mov eax, EPT_READ | EPT_WRITE | EPT_EXECUTE | EPT_VALID_FLAG
        or eax, esi
        mov [edi + ecx * 8], eax
        mov [edi + ecx * 8 + 4], edx
        add esi, 1000h
        INCv ecx
        cmp ecx, 512
        jb init_ept_pxt.loop                
        pop ecx
        pop edx
        pop ebp
        ret
        
        
        
;----------------------------------------------------------
; get_ept_ppt_virtual_address(): 
; input:
;       esi - pa
; output:
;       eax - va
; 描述: 
;       1) 根据输入的物理地址转换为虚拟地址
;----------------------------------------------------------
get_ept_ppt_virtual_address:
        push ebp
        
%ifdef __X64
        LoadFsBaseToRbp
%else
        mov ebp, [fs: SDA.Base]
%endif        
        sub esi, [ebp + SDA.EptPptPhysicalBase64]
        REX.Wrxb
        mov eax, [ebp + SDA.EptPptBase64]
        REX.Wrxb
        add eax, esi
        pop ebp
        ret
        

;----------------------------------------------------------
; get_ept_pdt_virtual_address(): 
; input:
;       esi - pa
; output:
;       eax - va
; 描述: 
;       1) 根据输入的物理地址转换为虚拟地址
;----------------------------------------------------------
get_ept_pdt_virtual_address:
get_ept_pt_virtual_address:
        push ebp
        
%ifdef __X64
        LoadFsBaseToRbp
%else
        mov ebp, [fs: SDA.Base]
%endif
        ;;
        ;; 说明: 
        ;; 1) EPT 的 PDT 和 PT 表物理地址从 kernel pool 里分配. 
        ;; 2) 需要减去 KernelPoolPhysicalBase 值(物理地址)
        ;; 2) 加上 KernelPoolBase 值(虚拟地址)
        ;;
        REX.Wrxb
        sub esi, [ebp + SDA.KernelPoolPhysicalBase]
        REX.Wrxb
        mov eax, [ebp + SDA.KernelPoolBase]
        REX.Wrxb
        add eax, esi
        pop ebp
        ret
                


;---------------------------------------------------------------
; get_ept_pxe_offset32():
; input:
;       edx:eax - guest physical address
; output:
;       eax - offset
; 描述: 
;       得到 PXT entry 的 offset 值
; 注意: 
;       在 legacy 模式下使用
;---------------------------------------------------------------
get_ept_pxe_offset32:
        push ecx
        and edx, 0FFFFh                                         ; 清 ga 高 16 位
        mov ecx, (12 + 9 + 9 + 9)                               ; index = ga >> 39
        call shr64
        mov ecx, 3
        call shl64                                              ; offset = index << 3
        pop ecx
        ret
        
                
;---------------------------------------------------------------
; get_ept_ppe_offset32():
; input:
;       edx:eax - ga
; output:
;       eax - offset
; 描述: 
;       1) 得到 PPT entry 的 offset 值
;       2) 在 legacy 下使用
;---------------------------------------------------------------
get_ept_ppe_offset32:
        push ecx
        and edx, 0FFFFh                                         ; 清 ga 高 16 位
        mov ecx, (12 + 9 + 9)                                   ; index = ga >> 30
        call shr64
        mov ecx, 3
        call shl64                                              ; offset = index << 3
        pop ecx
        ret
        
        

;---------------------------------------------------------------
; get_ept_pde_offset32():
; input:
;       edx:eax - ga
; output:
;       eax - offset
; 描述: 
;       1) 得到 PDT entry 的 offset 值
;       2) 在 legacy 下使用
;---------------------------------------------------------------
get_ept_pde_offset32:
        and eax, 3FE00000h                                      ; PDE index
        shr eax, (12 + 9 - 3)                                   ; index = ga >> 21 << 3
        ret
        


;---------------------------------------------------------------
; get_ept_pte_offset32():
; input:
;       edx:eax - ga
; output:
;       eax - offset
; 描述: 
;       1) 得到 PT entry 的 offset 值
;       2) 在 legacy 下使用
;---------------------------------------------------------------
get_ept_pte_offset32:
        and eax, 01FF000h                                       ; PTE index
        shr eax, (12 - 3)                                       ; offset = ga >> 12 << 3
        ret
                        
                        
                        
;----------------------------------------------------------
; get_ept_entry_level_attribute32()
; input:
;       ecx - shld count
; output:
;       edx:eax - level attribute
;----------------------------------------------------------
get_ept_entry_level_attribute32:

        xor edx, edx
        xor eax, eax      
          
        cmp ecx, (47 - 11)
        je get_ept_entry_level_attribute32.@1
        
        cmp ecx, (47 - 11 - 9)
        je get_ept_entry_level_attribute32.@2
        
        cmp ecx, (47 - 11 - 9 - 9)
        je get_ept_entry_level_attribute32.@3
        
        cmp ecx, (47 - 11 - 9 - 9 -9)
        jne get_ept_entry_level_attribute32.Done
        
        mov edx, EPT_PTE32
        mov eax, EPT_MEM_WB                             ;; PTE 使用 WB 内存类型
        jmp get_ept_entry_level_attribute32.Done
        
get_ept_entry_level_attribute32.@1:
        mov edx, EPT_PML4E32
        jmp get_ept_entry_level_attribute32.Done

get_ept_entry_level_attribute32.@2:
        mov edx, EPT_PDPTE32
        jmp get_ept_entry_level_attribute32.Done
        
get_ept_entry_level_attribute32.@3:
        mov edx, EPT_PDE32
        
get_ept_entry_level_attribute32.Done:                
        ret



;----------------------------------------------------------
; do_guest_physical_address_mapping32()
; input:
;       edi:esi - guest physical address (64 位)
;       edx:eax - physical address(64位)
;       ecx - page attribute
; output:
;       0 - successful, otherwise - error code
; 描述: 
;       1) 如果进行映射工作, 则映射 guest physical address 到 physical address
;       2) 如果进行修复工作, 则修复 EPT violation 及 EPT misconfiguration
;       3) legacy模式下使用
;
; page attribute 说明: 
;       ecx 传递过来的 attribute 由下面标志位组成: 
;       [0]    - Read
;       [1]    - Write
;       [2]    - Execute
;       [5:3]  - EPT memory type
;       [27:6] - 忽略
;       [26]   - FIX_ACCESS, 置位时, 进行 access right 修复工作
;       [27]   - FIX_MISCONF, 置位时, 进行 misconfiguration 修复工作
;       [28]   - EPT_FIXING, 置位时, 需要进行修复工作, 而不是映射工作
;              - EPT_FIXING 清位时, 进行映射工作
;       [29] - FORCE, 置位时, 强制进行映射
;       [31:30] - 忽略
;----------------------------------------------------------        
do_guest_physical_address_mapping32:
        push eax
        push ecx
        push edx
        push ebx
        push ebp
        push esi
        push edi

%define STACK_EAX_OFFSET                24
%define STACK_ECX_OFFSET                20
%define STACK_EDX_OFFSET                16
%define STACK_EBX_OFFSET                12    
%define STACK_EBP_OFFSET                 8
%define STACK_ESI_OFFSET                 4
%define STACK_EDI_OFFSET                 0

        ;;
        ;; EPT 映射说明: 
        ;; 1) 所有映射均使用 4K-page 进行
        ;; 2) 在 PML4T(PXT), PDPT(PPT) 以及 PDT 表上, 访问权限都具有 Read/Write/Execute
        ;; 3) 在最后一级 PT 表上, 访问权限是输入的 ecx 参数(page attribute)
        ;; 4) 所有页表需要使用 get_ept_page 动态分配(从 Kernel pool 内分配)
        ;;
        ;;
        ;; page attribute 使用说明: 
        ;; 1) FIX_MISCONF=1 时, 表明修复 EPT misconfiguration 错误.
        ;; 2) FIX_ACCESS=1 时, 表明修复 EPT violation 错误
        ;; 3) GET_PTE=1时, 表明需要返回 PTE 值
        ;; 4) GET_PAGE_FRAME=1时, 表明需要返回 page frame
        ;; 5) EPT_FORCE=1时, 进行强制映射
        ;;

        mov ecx, (47 - 11)                                      ; 初始 shr count

        ;;
        ;; 读取当前 VMB 的 EP4TA 值
        ;;
        mov ebp, [gs: PCB.CurrentVmbPointer]
        mov ebp, [ebp + VMB.Ep4taBase]                          ; ebp = EPT PML4T 虚拟地址

        
        ;;
        ;; 下面进行 EPT paging structure walk 流程
        ;;
do_guest_physical_address_mapping32.Walk:

        mov ebx, [esp + STACK_ECX_OFFSET]                       ; ebx = page attribute
        
        ;;
        ;; 读取 EPT 表项
        ;;
        mov esi, ecx        
        mov edx, [esp + STACK_EDI_OFFSET]
        mov eax, [esp + STACK_ESI_OFFSET]                       ; edx:eax = GPA, ecx = shr count
        call shr64
        and eax, 0FF8h                                          ; eax = EPT entry index
        add ebp, eax                                            ; ebp 指向 EPT 表项
        mov ecx, esi
        mov esi, [ebp]
        mov edi, [ebp + 4]                                      ; edi:esi = EPT 表项值
        
        
        ;;
        ;; 检查 EPT 表项是否为 not present, 包括: 
        ;; 1) access right 不为 0
        ;; 2) EPT_VALID_FLAG
        ;;
        test esi, 7                                             ; access right = 0 ?
        jz do_guest_physical_address_mapping32.NotPrsent
        test esi, EPT_VALID_FLAG                                ; 有效标志位 = 0 ?
        jz do_guest_physical_address_mapping32.NotPrsent

        ;;
        ;; 当 EPT 表项为 Present 时
        ;;
        test ebx, FIX_MISCONF
        jz do_guest_physical_address_mapping32.CheckFix
        
        ;;
        ;; 进行修复 EPT misconfiguration 故障
        ;;        
        and edi, ~EPT_LEVEL_MASK32                              ; 清掉错误 level 类型
        call get_ept_entry_level_attribute32
        or edi, edx                                             ; 设置 level 属性
        or esi, eax
        call do_ept_entry_misconf_fixing32                      ; edi:esi = EPT 表项
        cmp eax, MAPPING_SUCCESS
        jne do_guest_physical_address_mapping32.Done
        mov [ebp], esi
        mov [ebp + 4], edi        
                
do_guest_physical_address_mapping32.CheckFix:        
        test ebx, FIX_ACCESS
        jz do_guest_physical_address_mapping32.CheckGetPageFrame
        
        ;;
        ;; 进行修复 EPT violation 故障
        ;; 
        call do_ept_entry_violation_fixing32                    ; edi:esi = 表项, ebx = attribute
        cmp eax, MAPPING_SUCCESS
        jne do_guest_physical_address_mapping32.Done
        mov [ebp], esi
        mov [ebp + 4], edi
        
do_guest_physical_address_mapping32.CheckGetPageFrame:              
        ;;
        ;; 读取表项内容
        ;;
        and esi, ~0FFFh                                         ; 清 bits 11:0
        and edi, [gs: PCB.MaxPhyAddrSelectMask + 4]             ; 取地址值
        
        ;;
        ;; 检查是否属于 PTE
        ;;
        cmp ecx, (47 - 11 - 9 - 9 - 9)
        jne do_guest_physical_address_mapping32.Next
        
        ;;
        ;; 如果需要返回 PTE 表项内容
        ;;
        test ebx, GET_PTE
        mov edx, [ebp + 4]
        mov eax, [ebp]
        jnz do_guest_physical_address_mapping32.Done
        
        ;;
        ;; 如果需要返回 page frame 值 
        ;;
        test ebx, GET_PAGE_FRAME
        mov edx, edi
        mov eax, esi
        jnz do_guest_physical_address_mapping32.Done
        
        ;;
        ;; 如果属于强制映射
        ;;
        test ebx, EPT_FORCE
        jnz do_guest_physical_address_mapping32.BuildPte
        
        mov eax, MAPPING_USED
        jmp do_guest_physical_address_mapping32.Done
        
        
do_guest_physical_address_mapping32.Next:
        ;;
        ;; 继续向下 walk 
        ;;
        call get_ept_pt_virtual_address
        mov ebp, eax                                            ; ebp = EPT 页表基址
        jmp do_guest_physical_address_mapping32.NextWalk
        
        
        
do_guest_physical_address_mapping32.NotPrsent:  
        ;;
        ;; 当 EPT 表项为 not present 时
        ;; 1) 检查 FIX_MISCONF 标志位, 如果尝试修复 EPT misconfiguration 时, 错误返回
        ;; 2) 如果尝试读取 page frame 值, 错误返回
        ;;
        test ebx, (FIX_MISCONF | GET_PAGE_FRAME)
        mov eax, MAPPING_UNSUCCESS
        jnz do_guest_physical_address_mapping32.Done


do_guest_physical_address_mapping32.BuildPte:
        ;;
        ;; 生成 PTE 表项值
        ;;
        mov esi, ebx
        and esi, 07                                             ; 提供的 page frame 访问权限
        or esi, EPT_VALID_FLAG                                  ; 有效标志位
        or esi, [esp + STACK_EAX_OFFSET]
        mov edi, [esp + STACK_EDX_OFFSET]                       ; edi:esi = 要写入的 PTE
        
        ;;
        ;; 检查是否属于 PTE
        ;; 1)是: 写入提供的 HPA 值
        ;; 2)否: 分配 EPT 页面
        ;;
        cmp ecx, (47 - 11 - 9 - 9 - 9)
        je do_guest_physical_address_mapping32.WriteEptEntry
        
        ;;
        ;; 下面分配 EPT 页面, 作为下一级页表
        ;;        
        call get_ept_page                                       ; edx:eax = pa:va                
        or edx, EPT_VALID_FLAG | EPT_READ | EPT_WRITE | EPT_EXECUTE
        mov esi, edx
        xor edi, edi
        mov ebx, eax
        
do_guest_physical_address_mapping32.WriteEptEntry:
        ;;
        ;; 生成表项值, 写入页表
        ;;
        call get_ept_entry_level_attribute32                    ; 得到 EPT 表项层级属性
        or edi, edx
        or esi, eax
                                
        ;;
        ;; 写入 EPT 表项内容
        ;;
        mov [ebp], esi
        mov [ebp + 4], edi
        mov ebp, ebx                                            ; ebp = EPT 表基址      


do_guest_physical_address_mapping32.NextWalk:
        ;;
        ;; 执行继续 walk 流程
        ;;
        cmp ecx, (47 - 11 - 9 - 9 - 9)
        lea ecx, [ecx - 9]                                      ; 下一级页表的 shr count
        jne do_guest_physical_address_mapping32.Walk

        mov eax, MAPPING_SUCCESS
        
do_guest_physical_address_mapping32.Done:
              
        mov [esp + STACK_EAX_OFFSET], eax

;;################################################
;; 注意: 当返回 PTE 内容时, 这里需要写入 EDX 返回值 #
;;       这里保留这功能　!                        #
;;################################################
        ;;; mov [esp + STACK_EDX_OFFSET], edx                       
        
%undef STACK_EAX_OFFSET
%undef STACK_ECX_OFFSET
%undef STACK_EDX_OFFSET
%undef STACK_EBX_OFFSET
%undef STACK_EBP_OFFSET
%undef STACK_ESI_OFFSET
%undef STACK_EDI_OFFSET
        
        pop edi
        pop esi
        pop ebp
        pop ebx
        pop edx
        pop ecx        
        pop eax        
        ret
        
        
        
        
        
;---------------------------------------------------------------
; do_guest_physical_address_mapping32_n()
; input:
;       edi:esi - guest physical address
;       edx:eax - physical address
;       ecx - page attribute
;       [ebp + 28] - count
; output:
;       0 - succssful, otherwise - error code
; 描述:
;       1) 进行 n 页的 guest physical address 映射
;---------------------------------------------------------------
do_guest_physical_address_mapping32_n:
        push ebp
        push edi
        push esi
        push edx
        push eax
        push ecx
        
        mov ebp, esp

%define STACK_EBP_OFFSET                20
%define STACK_EDI_OFFSET                16
%define STACK_ESI_OFFSET                12
%define STACK_EDX_OFFSET                 8
%define STACK_EAX_OFFSET                 4
%define STACK_ECX_OFFSET                 0
%define VAR_COUNT_OFFSET                28
        
        
do_guest_physical_address_mapping32_n.Loop:
        mov esi, [ebp + STACK_ESI_OFFSET]
        mov edi, [ebp + STACK_EDI_OFFSET]
        mov eax, [ebp + STACK_EAX_OFFSET]
        mov edx, [ebp + STACK_EDX_OFFSET]
        call do_guest_physical_address_mapping32
        cmp eax, MAPPING_SUCCESS
        jne do_guest_physical_address_mapping32_n.done
        
        add DWORD [ebp + STACK_ESI_OFFSET], 1000h
        add DWORD [ebp + STACK_EAX_OFFSET], 1000h
        dec DWORD [ebp + VAR_COUNT_OFFSET]
        jnz do_guest_physical_address_mapping32_n.Loop
        
        mov eax, MAPPING_SUCCESS
        
do_guest_physical_address_mapping32_n.done:
        
        pop ecx
        pop eax
        pop edx
        pop esi
        pop edi
        pop ebp
        ret 4




;---------------------------------------------------------------
; do_ept_entry_misconf_fixing32()
; input:
;       edi:esi - table entry of EPT_MISCONFIGURATION
; output:
;       eax - 0 = successful,  otherwise = error code
; 描述: 
;       1) 修复提供的 EPT table entry 值
; 参数: 
;       edi:esi - 提供发生 EPT misconfiguration 的 EPT 表项, 修复后返回 EPT 表项
;       eax - 为 0 时表示成功, 否则为错误码
;---------------------------------------------------------------
do_ept_entry_misconf_fixing32:
        push ecx
        
        ;;
        ;; EPT misconfigruation 的产生: 
        ;; 1) 表项的 access right 为 010B(write-only)或者 110B(write/execute)
        ;; 2) 表项的 access right 为 100B(execute-only), 但 VMX 并不支持 execute-only 属性
        ;; 3) 当表项是 present 的(access right 不为 000B): 
        ;;      3.1) 保留位不为 0, 即: bits 51:M 为保留位, 这个 M 值等于 MAXPHYADDR 值
        ;;      3.2) page frame 的 memory type 不支持, 为 2, 3 或者 7
        ;;
        
        mov eax, MAPPING_UNSUCCESS
        
        ;;
        ;; 如果为 not present, 直接返回
        ;;        
        test esi, 7
        jz do_ept_entry_misconf_fixing32.done
        
        
        mov eax, esi
        and eax, 7

        ;;
        ;; ### 检查1: access right 是否为 100B(execute-only)
        ;;
        cmp eax, EPT_EXECUTE
        jne do_ept_entry_misconf_fixing32.@1
        
        ;;
        ;; 检查 VMX 是否支持 execute-only
        ;;
        test DWORD [gs: PCB.EptVpidCap], 1
        jnz do_ept_entry_misconf_fixing32.@2
        
do_ept_entry_misconf_fixing32.@1:
        ;;
        ;; 这里不检查 access right 是否为 010B(write-only) 或者 110B(write/execute)
        ;; 我们直接添加 read 权限
        ;;
        or esi, EPT_READ
        
                
do_ept_entry_misconf_fixing32.@2:
        ;;
        ;; 这里不检查保留位
        ;; 1) 我们直接将 bits 51:M 位清 0
        ;; 2) 保留 bits 63:52(忽略位)的值
        ;;
        mov eax, 0FFF00000h                                     ; bits 63:52
        or eax, [gs: PCB.MaxPhyAddrSelectMask + 4]              ; bits 63:52, bits M-1:0
        and edi, eax
        
        
        
do_ept_entry_misconf_fixing32.@3:
        ;;
        ;; 当属于 PML4E 时, 清 bits 7:3, 否则清 bits 6:3
        ;;
        mov eax, ~78h                                           ; ~ bits 6:3
        
        shld ecx, edi, 12
        and ecx, 7                                              ; 取 bits 54:52, 页表 level 值
        cmp ecx, 1
        jne do_ept_entry_misconf_fixing32.@31
        
        mov eax, ~0F8h                                          ; ~ bits 7:3
        
        
do_ept_entry_misconf_fixing32.@31:        

        ;;
        ;; 如果属于 PTE 时, 保留 bit6(IPAT位), 并将 memory type 置为 PCB.EptMemoryType 值
        ;;
        cmp ecx, 4
        jne do_ept_entry_misconf_fixing32.@32

        or eax, EPT_IPAT
        and esi, eax                                            ; 去掉 bits 5:3        
        mov eax, [gs: PCB.EptMemoryType]
        shl eax, 3                                              ; ept memory type
        or esi, eax
        mov eax, MAPPING_SUCCESS
        jmp do_ept_entry_misconf_fixing32.done       
                
                
do_ept_entry_misconf_fixing32.@32:
        
        and esi, eax

        mov eax, MAPPING_SUCCESS                            
        
do_ept_entry_misconf_fixing32.done:   
        pop ecx
        ret




;---------------------------------------------------------------
; do_ept_entry_violation_fixing32()
; input:
;       edi:esi - table entry
;       ebx - attribute
; output:
;       eax - 0 = successful,  otherwise = error code
; 描述: 
;       1) 修复表项的 EPT violation 错误
; 参数说明: 
;       1) rsi 提供需要修复的表项
;       2) edi 提供的属性值: 
;       [0]    - read access
;       [1]    - write access
;       [2]    - execute access
;       [3]    - readable
;       [4]    - writeable
;       [5]    - excutable
;       [6]    - 忽略
;       [7]    - valid of guest-linear address
;       [8]    - translation
;       [27:9] - 忽略
;       [26]   - FIX_ACCESS, 置位时, 进行 access right 修复工作
;       [27]   - FIX_MISCONF, 置位时, 进行 misconfiguration 修复工作
;       [28]   - EPT_FIXING, 置位时, 需要进行修复工作, 而不是映射工作
;              - EPT_FIXING 清位时, 进行映射工作
;       [29] - FORCE, 置位时, 强制进行映射
;       [31:30] - 忽略
;---------------------------------------------------------------        
do_ept_entry_violation_fixing32:
        push ebx
        

        ;;
        ;; EPT violation 的产生:
        ;; 1) 访问 guest-physical address 时, 出现 not-present
        ;; 2) 对 guest-physical address 进行读访问, 而 EPT paging-structure 表项的 bit0 为 0
        ;; 3) 对 guest-physical address 进行写访问, 而 EPT paging-structure 表项的 bit1 为 0
        ;; 4) EPTP[6] = 1 时, 在更新 guest paging-structure 表项的 accessed 或 dirty 位时被作为"写访问"
        ;;                    此时 EPT paging-structure 表项的 bit1 为 0
        ;; 5) 对 guest-physical address 进行 fetch操作(execute), 而 EPT paging-structure 表项的 bit2 为 0
        ;;
        
        mov eax, MAPPING_UNSUCCESS
        
        test esi, 7
        jz do_ept_entry_violation_fixing32.done
        
        ;;
        ;; 修复处理:
        ;; 1) 这里不修复 not-present 现象
        ;; 2) 添加相应的访问权限: 将表项值 或上 attribute[2:0] 值
        ;;
        and ebx, 7
        or esi, ebx

        mov eax, MAPPING_SUCCESS
                
do_ept_entry_violation_fixing32.done:
        pop ebx
        ret
        
        
        
        
        
;---------------------------------------------------------------
; check_fix_misconfiguration()
; input:
;       edi:esi - table entry
;       ebp - address of table entry
; output:
;       0 - Ok, otherwisw - misconfiguration code
; 描述: 
;       1) 检查表项是否有 misconfiguration, 并修复
;---------------------------------------------------------------
check_fix_misconfiguration:
        push ecx
        push ebx
        
        ;;
        ;; misconfiguration 原因: 
        ;; 1) [2:0] = 010B(write-only) 或 110B(execute/write)时. 
        ;; 2) [2:0] = 100B(execute-only), 但 VMX 并不支持 execute-only 时. 
        ;; 3) [2:0] = 000B(not present)时, 下面的保留位不为 0
        ;;    3.1) 表项内的物理地址宽度不能超过 MAXPHYADDR 位(即在 MAXPHYADDR 范围内)
        ;;    3.2) EPT memory type 为保留的类型(即 2,3 或 7)
        ;;
        
        xor ecx, ecx
        mov eax, esi
        and eax, 07h                                            ; 读取 access right

check_fix_misconfiguration.@1:
        ;;
        ;; 检查 access right
        ;;        
        cmp eax, EPT_WRITE
        je check_fix_misconfigurate.AccessRight
        cmp eax, EPT_WRITE | EPT_EXECUTE
        je check_fix_misconfigurate.AccessRight
        cmp eax, EPT_EXECUTE
        je check_fix_misconfigurate.ExecuteOnly

check_fix_misconfiguration.@2:
        cmp eax, 0                                              ; not present ?
        je check_fix_misconfiguration.done
        
        ;;
        ;; 确保物理地址在 MAXPHYADDR 值内 
        ;;
        and edi, [gs: PCB.MaxPhyAddrSelectMask + 4]             ; 清掉 MAXPHYADDR 外的值
        
        ;;
        ;; 注意: 这里统一处理！
        ;; 1) 所有 memory type 都设为 WB(支持时)或 UC(不支持 WB 时)类型
        ;; 2) 忽略所有其他情景(不管是否为保留还是其它内存类型)
        ;; 3) 因此, 无需检查内存类型
        ;;
        and esi, 0FFFFFFC7h                                     ; 清原 memory type
        mov eax, [gs: PCB.EptMemoryType]
        shl eax, 3
        or esi, eax                                             ; 添加 memory type
        
        jmp check_fix_misconfiguration.done
        
check_fix_misconfigurate.ExecuteOnly:
        ;;
        ;; 属于 execute-only 访问权限时, 需要检查 VMX 是否支持 execute-only
        ;; 1) 如果支持, 则无需更改
        ;; 2) 不支持时, 需添加 read 权限
        ;;
        test DWORD [gs: PCB.EptVpidCap], 1
        jnz check_fix_misconfiguration.@2
        
check_fix_misconfigurate.AccessRight:
        ;;
        ;; 修复由于 write-only, execute-only 或 execute/write 访问权限
        ;; 1) 在这种情况下, 添加 read 权限
        ;;
        or esi, EPT_READ
        jmp check_fix_misconfiguration.@2
       

check_fix_misconfiguration.done:                
        ;;
        ;; 写回 table entry
        ;;                
        mov [ebp], esi
        mov [ebp + 4], edi
        pop ebx                
        pop ecx
        ret




;---------------------------------------------------------------
; do_ept_page_fault()
; input:
;       none
; output:
;       0 - succssful, otherwise - error code
; 描述:
;       1) 这是 EPT 的 page fualt 处理例程
;---------------------------------------------------------------
do_ept_page_fault:
        push ebp
        push ebx
        push ecx
        
        ;;
        ;; EPT page fault 产生原因为: 
        ;; 1) EPT misconfiguration(EPT 的 tage enties 设置不合法)
        ;; 2) EPT violation(EPT 的访问违例)
        ;;
        
        ;;
        ;; 从 VM-exit information 里读 guest physical address
        ;;
        mov esi, [gs: PCB.ExitInfoBuf + EXIT_INFO.GuestPhysicalAddress]
        mov edi, [gs: PCB.ExitInfoBuf + EXIT_INFO.GuestPhysicalAddress + 4]
        

        ;;
        ;; 读 exit reason 值, 检查由哪种原因产生 VM-exit
        ;;
        mov eax, [gs: PCB.ExitInfoBuf + EXIT_INFO.ExitReason]
        cmp eax, EXIT_NUMBER_EPT_MISCONFIGURATION
        je do_ept_page_fault.EptMisconfiguration
        
        ;;
        ;; 下面是由于 EPT violation 产生 VM exit
        ;;
        mov ebx, [gs: PCB.ExitInfoBuf + EXIT_INFO.ExitQualification]
        
        ;;
        ;; EPT violation 的两类处理说明: 
        ;; 1) 由于 entry 是 not present 而引起的, 需要进行映射该 guest physical address
        ;; 2) 由于 access right 不符而引起的, 则添加相应的权限
        ;;

        ;;
        ;; 检查是否为 not present 引起
        ;;
        test ebx, 38h                                           ; execute/write/read = 0 ?
        jz do_ept_page_fault.NotPresent

        ;;
        ;; 下面属于 access right 违例
        ;; 1) 读取 Exit Qualification [2:0] 值, 确定是何种 access 引发 VM exit
        ;;
        mov ecx, ebx
        and ecx, 07h                                            ; access 值
        or ecx, EPT_FIXING | FIX_ACCESS                         ; 修复权限问题
        
        ;;
        ;; 转去执行修复工作
        ;; 1) edi:esi - guest physcial address
        ;; 2) ecx - page attribute
        ;;
        jmp do_ept_page_fault.Fixing

 
do_ept_page_fault.NotPresent:        
        ;;
        ;; 属于 not present
        ;; 1) 分配一个 4K 空间(从 kernel pool 里)
        ;;
        call get_ept_page                                       ; edx:eax 返回 pa:va
        mov eax, edx
        xor edx, edx
        mov ecx, EPT_READ | EPT_WRITE | EPT_EXECUTE
        
        ;;
        ;; 转去执行修复工作
        ;; 将 guest physical address 映射到新分配的 page
        ;; 1) edi:esi - guest physical address
        ;; 2) edx:eax - physical address(page frame)
        ;; 3) ecx - R/W/E 权限
        ;;
        jmp do_ept_page_fault.Fixing
        
        
do_ept_page_fault.EptMisconfiguration:
        ;;
        ;; 如果是由于 EPT misconfiguration 引发 VM exit, 
        ;; 则根据 guest physical address 进行 walk, 修复 misconfiguration 现象！
        ;;        
        mov ecx, EPT_FIXING | FIX_MISCONF                       ; 进行修复 misconfiguration 工作
        
        ;;
        ;; 下面调用 do_guest_physical_address_mapping() 进行修复工作
        ;;
do_ept_page_fault.Fixing:        
        call do_guest_physical_address_mapping32
        
do_ept_page_fault.done:
        pop ecx
        pop ebx
        pop ebp
        ret
        
        


;-----------------------------------------------------------------------
; GetGpaHte()
; input:
;       esi - GPA
; output:
;       eax - GPA HTE(handler table entry)地址
; 描述: 
;       1) 返回 GPA 对应的 HTE 表项地址
;       2) 不存在相应的 GPA Hte 时, 返回 0 值
;-----------------------------------------------------------------------
GetGpaHte:
        push ebp
        push ebx
                
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif  

        REX.Wrxb
        mov ebx, [ebp + PCB.CurrentVmbPointer]
        cmp DWORD [ebx + VMB.GpaHteCount], 0
        je GetGpaHte.NotFound
        
        REX.Wrxb
        mov eax, [ebx + VMB.GpaHteBuffer]               
        
GetGpaHte.@1:                
        REX.Wrxb
        cmp esi, [eax]                                  ; 检查 GPA 地址值
        je GetGpaHte.Done
        REX.Wrxb
        add eax, GPA_HTE_SIZE                           ; 指向下一条 entry
        REX.Wrxb
        cmp eax, [ebx + VMB.GpaHteIndex]
        jb GetGpaHte.@1
GetGpaHte.NotFound:        
        xor eax, eax
GetGpaHte.Done:        
        pop ebx
        pop ebp
        ret



;-----------------------------------------------------------------------
; AppendGpaHte()
; input:
;       esi - GPA 地址值
;       edi - handler
; output:
;       eax - HTE 地址
; 描述: 
;       1) 根据 GPA 值向 GpaHteBuffer 里写入 HTE
;-----------------------------------------------------------------------
AppendGpaHte:
        push ebp
        push ebx
                
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif  

        REX.Wrxb
        mov ebp, [ebp + PCB.CurrentVmbPointer]     
        mov ebx, edi
        call GetGpaHte
        REX.Wrxb
        test eax, eax
        jnz AppendGpaHte.WriteHte
        
        mov eax, GPA_HTE_SIZE
        REX.Wrxb
        xadd [ebp + VMB.GpaHteIndex], eax
        inc DWORD [ebp + VMB.GpaHteCount]
                
AppendGpaHte.WriteHte:
        ;;
        ;; 写入 HTE 内容
        ;;
        REX.Wrxb
        mov [eax + GPA_HTE.GuestPhysicalAddress], esi
        REX.Wrxb
        mov [eax + GPA_HTE.Handler], ebx
        pop ebx
        pop ebp
        ret
        