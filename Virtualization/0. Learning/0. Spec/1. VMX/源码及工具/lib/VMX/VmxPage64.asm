;*************************************************
;* VmxPage64.asm                                 *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************




;---------------------------------------------------------------
; get_ept_pxe_offset64():
; input:
;       rsi - guest physical address
; output:
;       eax - offset
; 描述: 
;       得到 PXT entry 的 offset 值
; 注意: 
;       在 legacy 模式下使用
;---------------------------------------------------------------
get_ept_pxe_offset64:
        shld rax, rsi, (32-4)                   
        and eax, 0FF8h                          ; bits 47:39 << 3
        ret
        

;---------------------------------------------------------------
; get_ept_ppe_offset64():
; input:
;       rsi - GPA
; output:
;       eax - offset
; 描述: 
;       1) 得到 PPT entry 的 offset 值
;---------------------------------------------------------------        
get_ept_ppe_offset64:
        shld rax, rsi, (32-4+9)                 
        and eax, 0FF8h                          ; bits 38:30 << 3
        ret
        


;---------------------------------------------------------------
; get_ept_pde_offset64():
; input:
;       rsi - GPA
; output:
;       eax - offset
; 描述: 
;       1) 得到 PDT entry 的 offset 值
;---------------------------------------------------------------
get_ept_pde_offset64:
        shld rax, rsi, (32-4+9+9)
        and eax, 0FF8h                          ; bits 29:21
        ret
        

;---------------------------------------------------------------
; get_ept_pte_offset64():
; input:
;       rsi - GPA
; output:
;       eax - offset
; 描述: 
;       1) 得到 PT entry 的 offset 值
;---------------------------------------------------------------  
get_ept_pte_offset64:
        shld rax, rsi, (32-4+9+9+9)
        and eax, 0FF8h                          ; bits 20:12
        ret
        
        
;----------------------------------------------------------
; get_ept_entry_level_attribute()
; input:
;       esi - shld count
; output:
;       esi - level number
;----------------------------------------------------------
get_ept_entry_level_attribute:
        cmp esi, (32 - 4)
        je get_ept_entry_level_attribute.@1
        
        cmp esi, (32 - 4 + 9)
        je get_ept_entry_level_attribute.@2
        
        cmp esi, (32 - 4 + 9 + 9)
        je get_ept_entry_level_attribute.@3
        
        cmp esi, (32 - 4 + 9 + 9 + 9)
        je get_ept_entry_level_attribute.@4
        
        xor esi, esi
        jmp get_ept_entry_level_attribute.Done
        
get_ept_entry_level_attribute.@1:
        mov rsi, EPT_PML4E
        jmp get_ept_entry_level_attribute.Done

get_ept_entry_level_attribute.@2:
        mov rsi, EPT_PDPTE
        jmp get_ept_entry_level_attribute.Done
        
get_ept_entry_level_attribute.@3:
        mov rsi, EPT_PDE
        jmp get_ept_entry_level_attribute.Done
        
get_ept_entry_level_attribute.@4:
        mov rsi, (EPT_PTE | EPT_MEM_WB)                         ;; PTE 使用 WB 内存类型
                                        
get_ept_entry_level_attribute.Done:                
        ret


;----------------------------------------------------------
; do_guest_physical_address_mapping64()
; input:
;       rsi - guest physical address
;       rdi - physical address
;       eax - page attribute
; output:
;       0 - successful, otherwise - error code
; 描述: 
;       1) 如果进行映射工作, 则映射 guest-physical address 到 physical addrss
;       2) 如果进行修复工作, 则修复 EPT violation 及 EPT misconfiguration
;
; page attribute 说明: 
;       eax 传递过来的 attribute 由下面标志位组成: 
;       [0]    - Read
;       [1]    - Write
;       [2]    - Execute
;       [23:3] - 忽略
;       [24]   - GET_PTE
;       [25]   - GET_PAGE_FRAME
;       [26]   - FIX_ACCESS, 置位时, 进行 access right 修复工作
;       [27]   - FIX_MISCONF, 置位时, 进行 misconfiguration 修复工作
;       [28]   - EPT_FIXING, 置位时, 需要进行修复工作, 而不是映射工作
;              - EPT_FIXING 清位时, 进行映射工作
;       [29]   - EPT_FORCE, 置位时, 强制进行映射
;       [31:30] - 忽略
;----------------------------------------------------------
do_guest_physical_address_mapping64:
        push rbp
        push rdx
        push rbx
        push rcx
        push r10
        push r11

        
        
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
        
        
        mov r10, rsi                                    ; r10 = GPA
        mov r11, rdi                                    ; r11 = HPA
        mov ebx, eax                                    ; ebx = page attribute
        mov ecx, (32 - 4)                               ; ecx = EPT 表项 index 左移位数(shld)
        
        ;;
        ;; 读取当前 VMB 的 EP4TA 值
        ;;
        mov rbp, [gs: PCB.CurrentVmbPointer]
        mov rbp, [rbp + VMB.Ep4taBase]                  ; rbp = EPT PML4T 虚拟基址


do_guest_physical_address_mapping64.Walk:
        ;;
        ;; EPT paging structure walk 处理
        ;;
        shld rax, r10, cl
        and eax, 0FF8h
        
        ;;
        ;; 读取 EPT 表项
        ;;
        add rbp, rax                                    ; rbp 指向 EPT 表项
        mov rsi, [rbp]                                  ; rsi = EPT 表项值
        
        
        ;;
        ;; 检查 EPT 表项是否为 not present, 包括: 
        ;; 1) access right 不为 0
        ;; 2) EPT_VALID_FLAG
        ;;
        test esi, 7                                             ; access right = 0 ?
        jz do_guest_physical_address_mapping64.NotPrsent
        test esi, EPT_VALID_FLAG                                ; 有效标志位 = 0 ?
        jz do_guest_physical_address_mapping64.NotPrsent

        ;;
        ;; 当 EPT 表项为 Present 时
        ;;
        test ebx, FIX_MISCONF
        jz do_guest_physical_address_mapping64.CheckFix
        
        ;;
        ;; 进行修复 EPT misconfiguration 故障
        ;;        
        mov rax, ~EPT_LEVEL_MASK
        and rax, rsi                                            ; 清掉错误 level 类型
        mov esi, ecx
        call get_ept_entry_level_attribute
        or rsi, rax                                             ; 设置 level 属性
        call do_ept_entry_misconf_fixing64
        cmp eax, MAPPING_SUCCESS
        jne do_guest_physical_address_mapping64.Done
        mov [rbp], rsi                                          ; 写回表项值　
                
do_guest_physical_address_mapping64.CheckFix:        
        test ebx, FIX_ACCESS
        jz do_guest_physical_address_mapping64.CheckGetPageFrame
        
        ;;
        ;; 进行修复 EPT violation 故障
        ;; 
        mov edi, ebx                                            ; rsi = 表项, ebx = page attribute
        call do_ept_entry_violation_fixing64
        cmp eax, MAPPING_SUCCESS
        jne do_guest_physical_address_mapping64.Done
        mov [rbp], rsi                                          ; 写回表项值
        
do_guest_physical_address_mapping64.CheckGetPageFrame:              
        ;;
        ;; 读取表项内容
        ;;
        and rsi, ~0FFFh                                         ; 清 bits 11:0
        and rsi, [gs: PCB.MaxPhyAddrSelectMask]                 ; 取地址值
        
        ;;
        ;; 检查是否属于 PTE
        ;;
        cmp ecx, (32 - 4 + 9 + 9 + 9)
        jne do_guest_physical_address_mapping64.Next
        
        ;;
        ;; 如果需要返回 PTE 表项内容
        ;;
        test ebx, GET_PTE
        mov rax, [rbp]        
        jnz do_guest_physical_address_mapping64.Done
        
        ;;
        ;; 如果需要返回 page frame 值 
        ;;
        test ebx, GET_PAGE_FRAME
        mov rax, rsi
        jnz do_guest_physical_address_mapping64.Done
        
        ;;
        ;; 如果属于强制映射
        ;;
        test ebx, EPT_FORCE
        jnz do_guest_physical_address_mapping64.BuildPte
        
        mov eax, MAPPING_USED
        jmp do_guest_physical_address_mapping64.Done
        
        
do_guest_physical_address_mapping64.Next:
        ;;
        ;; 继续向下 walk 
        ;;
        call get_ept_pt_virtual_address
        mov rbp, rax                                            ; rbp = EPT 页表基址
        jmp do_guest_physical_address_mapping64.NextWalk
        
        
        
do_guest_physical_address_mapping64.NotPrsent:     
        ;;
        ;; 当 EPT 表项为 not present 时
        ;; 1) 检查 FIX_MISCONF 标志位, 如果尝试修复 EPT misconfiguration 时, 错误返回
        ;; 2) 如果尝试读取 page frame 值, 错误返回
        ;;
        test ebx, (FIX_MISCONF | GET_PAGE_FRAME)
        mov eax, MAPPING_UNSUCCESS
        jnz do_guest_physical_address_mapping64.Done


do_guest_physical_address_mapping64.BuildPte:
        ;;
        ;; 生成 PTE 表项值
        ;;
        mov edx, ebx
        and edx, 07                                             ; 提供的 page frame 访问权限
        or edx, EPT_VALID_FLAG                                  ; 有效标志位
        or rdx, r11                                             ; 提供的 HPA 
        
        ;;
        ;; 检查是否属于 PTE 层级
        ;; 1)是: 写入生成的 PTE 值
        ;; 2)否: 分配 EPT 页面
        ;;
        cmp ecx, (32 - 4 + 9 + 9 + 9)
        je do_guest_physical_address_mapping64.WriteEptEntry

        ;;
        ;; 下面分配 EPT 页面, 作为下一级页表
        ;;        
        call get_ept_page                                       ; rdx:rax = pa:va                
        or rdx, EPT_VALID_FLAG | EPT_READ | EPT_WRITE | EPT_EXECUTE
        
do_guest_physical_address_mapping64.WriteEptEntry:
        ;;
        ;; 生成表项值, 写入页表
        ;;
        mov esi, ecx
        call get_ept_entry_level_attribute                      ; 得到 EPT 表项层级属性
        or rdx, rsi
                                
        ;;
        ;; 写入 EPT 表项内容
        ;;
        mov [rbp], rdx
        mov rbp, rax                                            ; rbp = EPT 表基址      

do_guest_physical_address_mapping64.NextWalk:
        ;;
        ;; 执行继续 walk 流程
        ;;
        cmp ecx, (32 - 4 + 9 + 9 + 9)
        lea rcx, [rcx + 9]                                      ; 下一级页表的 shld count
        jne do_guest_physical_address_mapping64.Walk
        
        mov eax, MAPPING_SUCCESS
        
do_guest_physical_address_mapping64.Done:
        pop r11                
        pop r10
        pop rcx
        pop rbx
        pop rdx
        pop rbp
        ret

        
        

;---------------------------------------------------------------
; do_guest_physical_address_mapping64_n()
; input:
;       rsi - guest physical address
;       rdi - physical address
;       eax - page attribute
;       ecx - count
; output:
;       0 - succssful, otherwise - error code
; 描述:
;       1) 进行 n 页的 guest physical address 映射
;---------------------------------------------------------------
do_guest_physical_address_mapping64_n:
        push rbx
        push rcx
        push r10
        push r11
        
        mov r10, rsi
        mov r11, rdi
        mov ebx, eax

do_guest_physical_address_mapping64_n.Loop:
        mov rsi, r10
        mov rdi, r11
        mov eax, ebx
        call do_guest_physical_address_mapping64
        cmp eax, MAPPING_SUCCESS
        jne do_guest_physical_address_mapping64_n.done
        
        add r10, 1000h
        add r11, 1000h
        dec ecx
        jnz do_guest_physical_address_mapping64_n.Loop
        
        mov eax, MAPPING_SUCCESS

do_guest_physical_address_mapping64_n.done:        
        pop r11
        pop r10
        pop rcx
        pop rbx
        ret
        
        


;---------------------------------------------------------------
; do_ept_page_fault64()
; input:
;       none
; output:
;       0 - succssful, otherwise - error code
; 描述:
;       1) 这是 EPT 的 page fualt 处理例程
;---------------------------------------------------------------        
do_ept_page_fault64:
        push rbx
        push rcx
        
        ;;
        ;; EPT page fault 产生原因为: 
        ;; 1) EPT misconfiguration(EPT 的 tage enties 设置不合法)
        ;; 2) EPT violation(EPT 的访问违例)
        ;;
        
        ;;
        ;; 从 VM-exit information 里读 guest physical address
        ;;
        mov rsi, [gs: PCB.ExitInfoBuf + EXIT_INFO.GuestPhysicalAddress]
        
        
        ;;
        ;; 读 exit reason, 确定哪种原因产生 VM-exit
        ;;
        mov eax, [gs: PCB.ExitInfoBuf + EXIT_INFO.ExitReason]
        cmp ax, EXIT_NUMBER_EPT_MISCONFIGURATION
        je do_ept_page_fault64.EptMisconf
        
        ;;
        ;; Exit qualification 字段保存明细信息: 
        ;; 1) bits 8:7 = 0 时, 执行 MOV to CR3 指令引起 EPT violation
        ;; 2) bits 8:7 = 1 时, 在访问 guest paging-structure 时引起 EPT violation
        ;; 3) bits 8:7 = 3 时, 由 guest-physical address 引起 EPT violation
        ;;
        ;; 修复 EPT violation 说明: 
        ;; 1) 由"MOV to CR3" 及 guest paging-structure 引起的 EPT violation, 修复时 GPA 与 HPA 一一对应
        ;; 2) 由 guest-physical address 引起的 EPT violation, 修复时动态分配 EPT 页面
        ;;       
        mov ebx, [gs: PCB.ExitInfoBuf + EXIT_INFO.ExitQualification]
        mov ecx, ebx
        and ecx, 18h                                            ; 取 bits 8:7
        jz do_ept_page_fault64.EptViolation1
        cmp ecx, 08h
        jz do_ept_page_fault64.EptViolation1
        
        ;;
        ;; 执行一般修复
        ;;
        mov eax, EPT_READ | EPT_WRITE | EPT_EXECUTE | EPT_FIXING | FIX_ACCESS
        
do_ept_page_fault64.EptViolation1:
        ;;
        ;; 实现一一对应重新映射
        ;;
        mov rdi, rsi
        mov eax, EPT_READ | EPT_WRITE | EPT_EXECUTE
        
        
        
do_ept_page_fault64.EptMisconf:


        call do_guest_physical_address_mapping64

do_ept_page_fault64.done:
        pop rcx
        pop rbx
        ret
        
        
        

;---------------------------------------------------------------
; do_ept_entry_misconf_fixing64()
; input:
;       rsi - table entry of EPT_MISCONFIGURATION
; output:
;       eax - 0 = successful,  otherwise = error code
; 描述: 
;       1) 修复提供的 EPT table entry 值
; 参数: 
;       rsi - 提供发生 EPT misconfiguration 的 EPT 表项, 修复后返回 EPT 表项
;       eax - 为 0 时表示成功, 否则为错误码
;---------------------------------------------------------------
do_ept_entry_misconf_fixing64:
        push rcx

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
        ;; 如果为 not present, 则直接返回
        ;;
        test esi, 7
        jz do_ept_entry_misconf_fixing64.done
        
        
        mov rax, rsi
        and eax, 7
        
        ;;
        ;; ### 检查1: access right 是否为 100B(execute-only)
        ;;
        cmp eax, EPT_EXECUTE
        jne do_ept_entry_misconf_fixing64.@1
        
        ;;
        ;; 检查 VMX 是否支持 execute-only
        ;;
        test DWORD [gs: PCB.EptVpidCap], 1
        jnz do_ept_entry_misconf_fixing64.@2
        
do_ept_entry_misconf_fixing64.@1:
        ;;
        ;; 这里不检查 access right 是否为 010B(write-only) 或者 110B(write/execute)
        ;; 我们直接添加 read 权限
        ;;
        or rsi, EPT_READ                                
        


do_ept_entry_misconf_fixing64.@2:
        ;;
        ;; 这里不检查保留位
        ;; 1) 我们直接将 bits 51:M 位清 0
        ;; 2) 保留 bits 63:52(忽略位)的值
        ;;
        mov rax, 0FFF0000000000000h                             ; bits 63:52
        or rax, [gs: PCB.MaxPhyAddrSelectMask]                  ; bits 63:52, bits M-1:0
        and rsi, rax

        
do_ept_entry_misconf_fixing64.@3:
        ;;
        ;; 当属于 PML4E 时, 清 bits 7:3, 否则清 bits 6:3
        ;;
        mov rax, ~78h                                           ; ~ bits 6:3
        
        shld rcx, rsi, 12
        and ecx, 7                                              ; 取 bits 54:52, 页表级别
        cmp ecx, 1
        jne do_ept_entry_misconf_fixing64.@31
        
        mov rax, ~0F8h                                          ; ~ bits 7:3
        
do_ept_entry_misconf_fixing64.@31:        

        ;;
        ;; 如果属于 PTE 时, 保留 bit6(IPAT位), 并将 memory type 置为 PCB.EptMemoryType 值
        ;;
        cmp ecx, 4
        jne do_ept_entry_misconf_fixing64.@32

        or rax, EPT_IPAT
        and rsi, rax                                            ; 去掉 bits 5:3        
        mov eax, [gs: PCB.EptMemoryType]
        shl eax, 3                                              ; ept memory type
        or rsi, rax
        mov eax, MAPPING_SUCCESS
        jmp do_ept_entry_misconf_fixing64.done             
                    
                    
do_ept_entry_misconf_fixing64.@32:
        
        and rsi, rax       

        mov eax, MAPPING_SUCCESS                            
        
do_ept_entry_misconf_fixing64.done:            
        pop rcx
        ret
        





;---------------------------------------------------------------
; do_ept_entry_violation_fixing64()
; input:
;       rsi - table entry
;       edi - attribute
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
do_ept_entry_violation_fixing64:
        push rcx
        
        

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
        jz do_ept_entry_violation_fixing64.done
        
        ;;
        ;; 修复处理:
        ;; 1) 这里不修复 not-present 现象
        ;; 2) 添加相应的访问权限: 将表项值 或上 attribute[2:0] 值
        ;;
        mov ecx, edi
        and ecx, 7
        or rsi, rcx
       
        mov eax, MAPPING_SUCCESS
                
do_ept_entry_violation_fixing64.done:
        pop rcx
        ret




;---------------------------------------------------------------
; dump_ept_paging_structure64()
; input:
;       rsi - guest-physical address
; output:
;       none
; 描述: 　
;       1) 打印 EPT paging structure 表项
;---------------------------------------------------------------
dump_ept_paging_structure64:
        push rbp
        push rbx
        push rcx
        push rdx
        push r10

        
        mov r10, rsi                                    ; r10 = GPA
        mov ecx, (32 - 4)                               ; ecx = EPT 表项 index 左移位数(shld)
        
        ;;
        ;; 读取当前 VMB 的 EP4TA 值
        ;;
        mov rbp, [gs: PCB.CurrentVmbPointer]
        mov rbp, [rbp + VMB.Ep4taBase]                  ; rbp = EPT PML4T 虚拟基址

        ;;
        ;; 检查是否属于嵌套打印
        ;;
        mov edx, Ept.NestEntryMsg
        test DWORD [Ept.DumpPageFlag], DUMP_PAGE_NEST
        jnz dump_ept_paging_structure64.Walk
        
        mov edx, Ept.EntryMsg
        mov esi, Ept.DumpMsg1
        call puts
        mov rsi, r10
        call print_qword_value64
        mov esi, Ept.DumpMsg2
        call puts

dump_ept_paging_structure64.Walk:
        ;;
        ;; EPT paging structure walk 处理
        ;;
        shld rax, r10, cl
        and eax, 0FF8h
        
        ;;
        ;; 读取 EPT 表项
        ;;
        add rbp, rax                                    ; rbp 指向 EPT 表项
        mov rbx, [rbp]                                  ; rbx = EPT 表项值

        shld rax, rbx, 12
        and eax, 07h
        mov esi, [rdx + rax * 4]
        call puts
        mov rsi, rbx
        call print_qword_value64
        call println
        
        ;;
        ;; 检查 EPT 表项是否为 not present, 包括: 
        ;; 1) access right 不为 0
        ;; 2) EPT_VALID_FLAG
        ;;
        test ebx, 7                                             ; access right = 0 ?
        jz dump_ept_paging_structure64.Done
        test ebx, EPT_VALID_FLAG                                ; 有效标志位 = 0 ?
        jz dump_ept_paging_structure64.Done
     
        ;;
        ;; 读取表项内容
        ;;
        and rbx, ~0FFFh                                         ; 清 bits 11:0
        and rbx, [gs: PCB.MaxPhyAddrSelectMask]                 ; 取地址值       

        ;;
        ;; 继续向下 walk 
        ;;
        mov rsi, rbx
        call get_ept_pt_virtual_address
        mov rbp, rax                                            ; rbp = EPT 页表基址

        cmp ecx, (32 - 4 + 9 + 9 + 9)
        lea rcx, [rcx + 9]                                      ; 下一级页表的 shld count
        jne dump_ept_paging_structure64.Walk

dump_ept_paging_structure64.Done:     
        pop r10
        pop rdx
        pop rcx
        pop rbx
        pop rbp
        ret




;---------------------------------------------------------------
; dump_guest_longmode_paging_structure64()
; input:
;       rsi - guest-linear address
;       rdi - dump page flag
; output:
;       none
; 描述: 　
;       1) 打印 EPT paging structure 表项
;---------------------------------------------------------------
dump_guest_longmode_paging_structure64:
        push rbp
        push rbx
        push rcx
        push r10

        
        mov r10, rsi                                    ; r10 = GPA
        mov ecx, (32 - 4)                               ; ecx = EPT 表项 index 左移位数(shld)
        
        mov [Ept.DumpPageFlag], edi
        
        ;;
        ;; 读取当前 guest 的 CR3 值
        ;;
        GetVmcsField    GUEST_CR3
        mov rsi, rax
        call get_system_va_of_guest_pa 
        test rax, rax
        jz dump_guest_longmode_paging_structure64.Done
        mov rbp, rax                                    ; rbp = guest-paging structure
        

        mov esi, Ept.DumpGuestMsg1
        call puts
        mov rsi, r10
        call print_qword_value64
        mov esi, Ept.DumpGuestMsg2
        call puts

dump_guest_longmode_paging_structure64.Walk:
        ;;
        ;; guest-paging structure walk 处理
        ;;
        shld rax, r10, cl
        and eax, 0FF8h
        
        ;;
        ;; 读取 guest 表项
        ;;
        add rbp, rax                                    ; rbp 指向 guest 表项
        mov rbx, [rbp]                                  ; rbx = guest 表项值

        mov eax, ecx
        sub eax, (32 - 4)
        and eax, 07h
        mov esi, [Ept.GuestEntryMsg + rax * 4]
        call puts
        mov rsi, rbx
        call print_qword_value64
        call println
        
        ;;
        ;; 是否为 PDE
        ;;
        cmp ecx, (32 - 4 + 9 + 9)
        jne dump_guest_longmode_paging_structure64.Walk.@0
        test ebx, PAGE_2M
        jnz dump_guest_longmode_paging_structure64.Done


dump_guest_longmode_paging_structure64.Walk.@0:        
        ;;
        ;; 检查表项是否为 not present
        ;;
        test ebx, PAGE_P                                        ; access right = 0 ?
        jz dump_guest_longmode_paging_structure64.Done

        ;;
        ;; 读取表项内容
        ;;
        and rbx, ~0FFFh                                         ; 清 bits 11:0
        and rbx, [gs: PCB.MaxPhyAddrSelectMask]                 ; 取地址值       

        test DWORD [Ept.DumpPageFlag], DUMP_PAGE_NEST
        jz dump_guest_longmode_paging_structure64.Walk.@1
        
        mov rsi, rbx
        call dump_ept_paging_structure64
        
dump_guest_longmode_paging_structure64.Walk.@1:

        ;;
        ;; 继续向下 walk 
        ;;
        mov rsi, rbx
        call get_system_va_of_guest_pa
        mov rbp, rax                                            ; rbp = guest 页表基址

        cmp ecx, (32 - 4 + 9 + 9 + 9)
        lea rcx, [rcx + 9]                                      ; 下一级页表的 shld count
        jne dump_guest_longmode_paging_structure64.Walk

dump_guest_longmode_paging_structure64.Done:     
        pop r10
        pop rcx
        pop rbx
        pop rbp
        ret