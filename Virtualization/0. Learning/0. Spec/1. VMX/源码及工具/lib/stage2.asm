;*************************************************
; stage2.asm                                     *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************
   
   
   


;----------------------------------------------------------------------------------------------
; init_global_page(): 初始化设置 PAE-paging 模式的页转换表结构
; input:
;       none
; output:
;       none
; 
; 系统页表结构:
;       * 0xc0000000-0xc07fffff(共8M)映射到物理页面 0x200000-0x9fffff 上, 使用 4K 页面
;
; 初始化区域描述:
;       1) 0x7000-0x1ffff 分别映射到 0x8000-0x1ffff 物理页面, 用于一般的运作
;       2) 0xb8000 - 0xb9fff 分映射到　0xb8000-0xb9fff 物理地址, 使用 4K 页面, 用于 VGA 显示区域
;       3) 0x80000000-0x8000ffff(共64K)映射到物理地址 0x100000-0x10ffff 上, 用于系统数据结构        
;       4) 0x400000-0x400fff 映射到 1000000h page frame 使用 4K 页面, 用于 DS store 区域
;       5) 0x600000-0x7fffff 映射到 0FEC00000h 物理页面上, 使用 2M 页面, 用于 LPC 控制器区域(I/O APIC)
;       6) 0x800000-0x9fffff 映射到 0FEE00000h 物理地址上, 使用 2M 页面, 用于 local APIC 区域
;       7) 0xb0000000 开始映射到物理地址 0x1100000 开始, 使用 4K 页面, 用于 VMX 数据空间
;---------------------------------------------------------------------------------------------
init_global_page:
        push ecx

        ;;
        ;; 0x7000-0x9000 分别映射到 0x7000-0x9000 物理页面, 使用 4K 页面               
        ;;
        mov esi, 7000h
        mov edi, 7000h
        mov ecx, (10000h - 7000h) / 1000h        
        mov eax, PHY_ADDR | US | RW | P
        call do_virtual_address_mapping_n


%ifdef GUEST_ENABLE        
        mov esi, GUEST_BOOT_SEGMENT
        mov edi, GUEST_BOOT_SEGMENT
        mov eax, PHY_ADDR | US | RW | P
        call do_virtual_address_mapping
        
        mov esi, GUEST_KERNEL_SEGMENT
        mov edi, GUEST_KERNEL_SEGMENT
        mov eax, PHY_ADDR | US | RW | P
        mov ecx, [GUEST_KERNEL_SEGMENT]        
        add ecx, 0FFFh
        shr ecx, 12
        call do_virtual_address_mapping_n
%endif        
        
        ;;
        ;; 映射 protected 模块区域, 使用 4K 页
        ;;
        mov esi, PROTECTED_SEGMENT
        mov edi, PROTECTED_SEGMENT
        mov eax, PHY_ADDR | US | RW | P
        
%ifdef __STAGE2
        mov ecx, (PROTECTED_LENGTH + 0FFFh) / 1000h
%endif        
        call do_virtual_address_mapping_n
        
        ;;
        ;; 0xb8000 - 0xb9fff 分映射到　0xb8000-0xb9fff 物理地址, 使用 4K 页面
        ;;
        mov esi, 0B8000h
        mov edi, 0B8000h
        mov eax, XD | PHY_ADDR | US | RW | P
        call do_virtual_address_mapping
        mov esi, 0B9000h
        mov edi, 0B9000h
        mov eax, XD | PHY_ADDR | US | RW | P
        call do_virtual_address_mapping

        ;;
        ;; 映射所有 PCB 块
        ;;
        mov esi, PCB_BASE
        mov edi, PCB_PHYSICAL_POOL
        mov ecx, PCB_POOL_SIZE / 1000h
        mov eax, PHY_ADDR | XD | RW | P
        call do_virtual_address_mapping_n

        ;;
        ;; 映射 System Data Area 区域
        ;;
        mov esi, [fs: SDA.Base]                                 ; SDA virtual address
        mov edi, [fs: SDA.PhysicalBase]                         ; SDA physical address
        mov ecx, [fs: SDA.Size]                                 ; SDA size
        add ecx, 0FFFh
        shr ecx, 12                                             
        mov eax, XD | PHY_ADDR | RW | P
        call do_virtual_address_mapping_n

       
        ;;
        ;; 映射 System service routine table 区域(4K)
        ;;
        mov esi, [fs: SRT.Base]
        mov edi, [fs: SRT.PhysicalBase]
        mov eax, XD | PHY_ADDR | RW | P
        call do_virtual_address_mapping
        
        
        ;;
        ;; 映射 stack
        ;;
        mov esi, KERNEL_STACK_BASE
        mov edi, KERNEL_STACK_PHYSICAL_BASE
        mov ecx, KERNEL_STACK_SIZE/1000h
        mov eax, PHY_ADDR | XD | RW | P
        call do_virtual_address_mapping_n
        mov esi, USER_STACK_BASE
        mov edi, USER_STACK_PHYSICAL_BASE
        mov ecx, USER_STACK_SIZE/1000h
        mov eax, PHY_ADDR | XD | US | RW | P
        call do_virtual_address_mapping_n

        ;;
        ;; 映射 pool
        ;;
        mov esi, KERNEL_POOL_BASE
        mov edi, KERNEL_POOL_PHYSICAL_BASE
        mov ecx, KERNEL_POOL_SIZE/1000h 
        mov eax, PHY_ADDR | RW | P
        call do_virtual_address_mapping_n
        mov esi, USER_POOL_BASE
        mov edi, USER_POOL_PHYSICAL_BASE
        mov ecx, USER_POOL_SIZE/1000h
        mov eax, PHY_ADDR | US | RW | P
        call do_virtual_address_mapping_n

        
        ;;
        ;; 映射 VM domain pool
        ;;
        mov esi, DOMAIN_BASE
        mov edi, DOMAIN_PHYSICAL_BASE
        mov ecx, DOMAIN_POOL_SIZE/1000h
        mov eax, PHY_ADDR | US | RW | P
        call do_virtual_address_mapping_n

       
        ;;
        ;; 0x400000-0x400fff 映射到 1000000h page frame 使用 4K 页面
        ;;
        mov esi, 400000h
        mov edi, 1000000h
        mov eax, XD | PHY_ADDR | RW | P
        call do_virtual_address_mapping
        
        ;;              
        ;; 0x600000-0x600fff 映射到 0FEC00000h 物理地址上, 使用 4K 页面
        ;;
        mov esi, IOAPIC_BASE
        mov edi, 0FEC00000h
        mov eax, XD | PHY_ADDR | PCD | PWT | RW | P
        call do_virtual_address_mapping
        
        ;;
        ;; 0x800000-0x800fff 映射到 0FEE00000h 物理地址上, 使用 4k 页面
        ;;
        mov esi, LAPIC_BASE
        mov edi, 0FEE00000h
        mov eax, XD | PHY_ADDR | PCD | PWT | RW | P
        call do_virtual_address_mapping
           
        
        ;;
        ;; 0xb0000000 开始映射到物理地址 0x1100000 开始, 使用 4K 页面
        ;;
        mov esi, VMX_REGION_VIRTUAL_BASE                        ; VMXON region virtual address
        mov edi, VMX_REGION_PHYSICAL_BASE                       ; VMXON region physical address
        mov eax, XD | PHY_ADDR | RW | P
        call do_virtual_address_mapping
        
        pop ecx
        ret
        
        

;-----------------------------------------------------------------------
; init_global_environment()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 初始环 stage2 环境
;-----------------------------------------------------------------------
init_global_environment:
        call init_pae_page
        call init_global_page

        ;; 更新 IDT pointer
        mov DWORD [fs: SDA.IdtBase], SDA_BASE+SDA.Idt
        mov DWORD [fs: SDA.IdtBase+4], 0FFFFF800h
        mov WORD [fs: SDA.IdtLimit], 256*16-1
        mov DWORD [fs: SDA.IdtTop], SDA_BASE+SDA.Idt+0FFFh
        mov DWORD [fs: SDA.IdtTop+4], 0FFFFF800h        
        ret

        
;-----------------------------------------------------------------------
; enter_stage2()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 切入 stage2 阶段运行环境
;-----------------------------------------------------------------------
enter_stage2:
        pop edi
        call init_pae_ppt
        mov esi, [gs: PCB.GdtPointer]
        mov eax, [gs: PCB.PptPhysicalBase]
        mov cr3, eax
        mov eax, CR0_PG | CR0_PE | CR0_NE | CR0_ET
        mov cr0, eax
        lgdt [esi]
        mov ax, FsSelector
        mov fs, ax
        mov ax, GsSelector
        mov gs, ax
        mov ax, TssSelector32
        ltr ax
        lidt [fs: SDA.IdtPointer]
        mov esp, [gs: PCB.KernelStack]
        jmp edi
        


;-----------------------------------------------------
; wait_for_stage2_done()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 发送 INIT-SIPI-SIPI 消息序给 AP
;       2) 等待 AP 完成第2阶段工作
;-----------------------------------------------------
wait_for_ap_stage2_done:             
        ;;
        ;; 开放第2阶段 AP Lock
        ;;
        xor eax, eax
        mov ebx, [fs: SDA.Stage2LockPointer]
        xchg [ebx], eax
        
        ;;
        ;; BSP 已完成工作, 计数值为 1 
        ;;
        mov DWORD [fs: SDA.ApInitDoneCount], 1

        ;;
        ;; 等待 AP 完成 stage2 工作:
        ;; 检查处理器计数 ApInitDoneCount 是否等于 LocalProcessorCount 值
        ;; 1)是, 所有 AP 完成 stage2 工作
        ;; 2)否, 继续等待
        ;;
wait_for_ap_stage2_done.@0:        
        xor eax, eax
        lock xadd [fs: SDA.ApInitDoneCount], eax
        cmp eax, CPU_COUNT_MAX
        jae wait_for_ap_stage2_done.ok 
        cmp eax, [gs: PCB.LogicalProcessorCount]
        jae wait_for_ap_stage2_done.ok
        pause
        jmp wait_for_ap_stage2_done.@0

wait_for_ap_stage2_done.ok:
        ;;
        ;;  AP 处于 stage2 状态
        ;;
        mov DWORD [fs: SDA.ApStage], 2
        ret



                
;-----------------------------------------------------
; put_processor_to_vmx()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 将所有处理器放入 VMX root 状态
;-----------------------------------------------------                
put_processor_to_vmx:
        push ecx

        ;;
        ;; BSP 进入 VMX 环境
        ;;
        call vmx_operation_enter
        
        ;;
        ;; 剩余的 APs 进入 VMX 环境
        ;;
        mov ecx, 1
put_processor_to_vmx.@0:
        mov esi, ecx
        mov edi, vmx_operation_enter
        call dispatch_to_processor_with_waitting
        ;;
        ;; 读 Status Code 检查是否成功
        ;;
        mov eax, [fs: SDA.LastStatusCode]
        cmp eax, STATUS_SUCCESS
        jne put_processor_to_vmx.done

        inc ecx
        cmp ecx, [fs: SDA.ProcessorCount]
        jb put_processor_to_vmx.@0
        
put_processor_to_vmx.done:        
        pop ecx
        ret

