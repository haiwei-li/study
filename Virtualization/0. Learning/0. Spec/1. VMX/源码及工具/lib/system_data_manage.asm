;*************************************************
;* system_data_manage.asm                        *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************

%include "..\inc\system_manage_region.inc"


;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
; 物理地址空间说明:
;; 1) 8000h - FFFFh: setup 模块使用
;; 2) 1_0000h - 1_FFFFh: 保留未用
;; 3) 2_0000h - 2_FFFFh: preccted/long 模块使用
;; 4) 10_0000h - 11_FFFFh: PCB 区域(共128K)
;; 5) 12_0000h - 14_FFFFh: SDA 区域(共192K)
;; 6) 20_0000h - 9F_FFFFh: Legacy 模式下的 PT 区域(共8M)
;; 7) 200_0000h - 21F_FFFFh: Longmode 下的 PPT 区域(共2M)
;; 8) 220_0000h - 2FF_FFFFh: PT pool 区域(共14M)
;; 9) 101_0000h ~ : User Stack Base 区域
;; 10) 104_0000h ~: Kernel Stack Base 区域
;; 11) 300_1000h ~: User Pool Base 区域
;; 12) 320_0000h ~: Kernel Pool Base 区域
;; 13) A0_0000h ~ BF_FFFFh : EPT PPT 区域
;; 14) C0_0000h ~ FF_FFFFh : 保留未用
;;
;;
;; 假设物理内存为256M, 地址从 0000_0000h - 0FFF_FFFFh
;;
;; VM 内存 domain 分配说明: 
;; 1) VM 0: 0000_0000h - 087F_FFFFh
;; 2) VM 1: 0880_0000 - 08FF_FFFFh (8M)
;; 3) VM 2: 0900_0000 - 097F_FFFFh (8M)
;; 4) VM 3: 0980_0000 - 09FF_FFFFh (8M)
;; 5) VM 4: 0A00_0000 - 0A7F_FFFFh (8M)
;; 6) VM 5: 0A80_0000 - 0AFF_FFFFh (8M)
;; 7) VM 6: 0B00_0000 - 0B7F_FFFFh
;; 8) VM 7: 0B80_0000 - 0BFF_FFFFh
;; 9) VM 8: 0C00_0000 - 0C7F_FFFFh
;; 10) ... ...
;;

;; 虚拟地址空间说明: 
;; 一. legacy 模式下: 
;; 1) 8000h - FFFFh: setup 模块使用
;; 2) 1_0000h - 1_FFFFh: 保留未用
;; 3) 2_0000h - 2_FFFFh: protected/long 模块使用
;; 4) 8000_0000h - 8001_FFFFh: PCB 区域(映射到 10_0000h - 11_FFFFh)
;; 5) 8002_0000h - 8003_FFFFh: SDA 区域(映射到 12_0000h - 13_FFFFh)
;; 6) 7FE0_0000h ~: User Stack Base 区域
;; 7) FFE0_0000h ~: Kernel Stack Base 区域
;; 8) 8320_0000h ~: Kernel Pool Base 区域
;; 9) 7300_1000h ~: User Pool Base  区域
;; 10) C000_0000h - C07F_FFFFh: PT 表区域(8M)
;; 11) C0A0_0000h - C0BF_FFFFh: EPT PPT 区域(2M)
;; 12) 8800_0000h ~ 8xxxx_xxxx: VM domain 区域
;;
;; 二. longmode 下: 
;; 1) 8000h - FFFFh: setup 模块使用
;; 2) 1_0000h - 1_FFFFh: 保留未用
;; 3) 2_0000h - 2_FFFFh: long 模块使用
;; 4) FFFF_F800_8000_0000h ~: PCB 区域
;; 5) FFFF_F800_8002_0000h ~: SDA 区域
;; 6) 7FE0_0000h ~: User Stack Base 区域
;; 7) FFFF_FF80_FFE0_0000h ~: Kernel Stack Base 区域
;; 8) FFFF_F800_8320_0000h ~: Kernel Pool Base 区域
;; 9) 7300_1000h ~: User Pool Base  区域
;; 10) FFFF_F6FB_7DA0_0000h ~: PPT 表区域(8M)
;; 11) FFFF_F800_8220_0000h ~: PT Pool 区域
;; 12) FFFF_F800_8020_0000h ~: 备用 PT Pool 区域
;; 13) FFFF_F800_C0A0_0000h ~ FFFF_F800_C0BF_FFFFh: EPT PXT 区域(2M)
;; 14) FFFF_F800_8800_0000h ~ FFFF_F800_8xxx_xxxx: VM domain 区域
;;
;;
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$



;;
;; 支持处理器数量
;;
PROCESSOR_MAX           EQU     16


;;
;; PCB(Processor Control Block)可分配使用的 pool 长度
;;
PCB_SIZE                EQU     PROCESSOR_CONTROL_BLOCK_SIZE
PCB_POOL_SIZE           EQU     (PCB_SIZE * PROCESSOR_MAX)

;;
;; PCB pool 物理基址, 每个处理器的 PCB 块从这里分配
;;
PCB_PHYSICAL_POOL       EQU     100000h


;;
;; PCB 与 SDA 虚拟基址
;; 在 32 位下: 
;; 1) PCB_BASE  =  8000_0000h
;; 2) SDA_BASE  =  8002_0000h (PCB_BASE + PCB_POOL_SIZE)
;;
;; 在 64 位下: 
;; 1) PCB_BASE64  = ffff_f800_8000_0000h
;; 2) SDA_BASE64  = ffff_f800_8002_0000h (PCB_BASE64 + PCB_POOL_SIZE)
;;
PCB_BASE                EQU     80000000h
SDA_BASE                EQU     (PCB_BASE + PCB_POOL_SIZE)
PCB_BASE64              EQU     0FFFFF80080000000h
SDA_BASE64              EQU     (PCB_BASE64 + PCB_POOL_SIZE)


;;
;; PCB 与 SDA 物理基址:
;; 1) PCB_PHYSICAL_BASE  =  100000h (PCB_PHYSICAL_POOL)
;; 2) SDA_PHYSICAL_BASE  =  120000h (PCB_PHYSICAL_POOL + PCB_POOL_SIZE)
;;
PCB_PHYSICAL_BASE       EQU     PCB_PHYSICAL_POOL
SDA_PHYSICAL_BASE       EQU     (PCB_PHYSICAL_POOL + PCB_POOL_SIZE)





      
;---------------------------------------------------
; init_apic()
; input:
;       none
; output:
;       none
; 描述: 
;       通过 apic 的开启, 否则处理器进入 HLT 状态
;---------------------------------------------------
init_apic:
        push ecx
        push edx
        mov eax, 1
        cpuid
        bt edx, 9                               ; 检查是否支持 APIC on Chip
        jnc init_apic.error
        
        ;;
        ;; 开启 global enable 位
        ;;
        mov ecx, IA32_APIC_BASE
        rdmsr
        bts eax, 11                             ; enable
        wrmsr
        
        ;;
        ;; 开启 software enable 位
        ;;
        and eax, 0FFFFF000h                     ; local APIC base
        mov ebx, [eax + LAPIC_SVR]
        bts ebx, 8                              ; SVR.Enable = 1
        mov [eax + LAPIC_SVR], ebx
        
init_apic.done:
        pop edx
        pop ecx
        ret
        
init_apic.error:
        mov esi, SDA.ErrMsg1
        call puts
        hlt
        RESET_CPU
        
        

;-------------------------------------------------------------------
; append_gdt_descriptor(): 往 GDT 表添加一个描述符
; input:
;       edx:eax - 64 位描述符
; output:
;       eax - 返回 selector 值
; 描述: 
;       1) 添加一个描述符, 并更新 GDTR 
;-------------------------------------------------------------------
append_gdt_descriptor:
        mov esi, [fs: SDA.GdtTop]                       ; 读取 GDT 顶端原值
        add esi, 8                                      ; 指向下一条 entry
        mov [esi], eax
        mov [esi + 4], edx
        mov [fs: SDA.GdtTop], esi                       ; 更新 gdt_top 记录
        add DWORD [fs: SDA.GdtLimit], 8                 ; 更新 gdt_limit 记录
        sub esi, [fs: SDA.GdtBase]                      ; 得到 selector 值
        ;;
        ;; 下面刷新 gdtr 寄存器
        ;;
        lgdt [fs: SDA.GdtPointer]
        mov eax, esi                                    ; 返回添加的 selector
        ret



;-------------------------------------------------------------------
; remove_gdt_descriptor(): 移除 GDT 表的一个描述符
; input:
;       none
; output:
;       edx:eax - 返回移除的描述符
;-------------------------------------------------------------------
remove_gdt_descriptor:
        push ebx
        xor edx, edx
        xor eax, eax
        mov ebx, [fs: SDA.GdtTop]
        cmp ebx, [fs: SDA.GdtBase]
        jbe remove_gdt_descriptor.done
        mov edx, [ebx + 4]
        mov eax, [ebx]                                  ; 读原描述符值
        mov DWORD [ebx], 0
        mov DWORD [ebx + 4], 0                          ; 清描述符值
        sub ebx, 8
        mov [fs: SDA.GdtTop], ebx
        sub DWORD [fs: SDA.GdtLimit], 8
remove_gdt_descriptor.done:        
        pop ebx
        ret




;-------------------------------------------------------------------
; set_gdt_descriptor(): 根据提供的 selector 值在 GDT 表写入一个描述符
; input:
;       esi - selector 
;       edx:eax - 64 位描述符值
; output:
;       eax - 返回描述符地址
;-------------------------------------------------------------------        
set_gdt_descriptor:
        push ebx
        and esi, 0FFF8h
        mov ebx, esi
        add ebx, [fs: SDA.GdtBase]
        mov [ebx], eax
        mov [ebx + 4], edx
        
        ;;
        ;; 检测及更新 GDT 的 limit 和 top
        ;;
        add esi, 7
        cmp ebx, [fs: SDA.GdtTop]
        jbe set_gdt_descriptor.next
        mov [fs: SDA.GdtTop], ebx  
             
set_gdt_descriptor.next:
        ;;
        ;; 如果设置的 GDT entry 位置超出了 GDT limit
        ;; 就更新 limit, 并刷新 gdtr 寄存器
        ;;
        cmp esi, [fs: SDA.GdtLimit]
        jbe set_gdt_descriptor.done
        mov [fs: SDA.GdtLimit], esi
        lgdt [fs: SDA.GdtPointer]               ; 刷新 gdtr 寄存器
set_gdt_descriptor.done:        
        mov eax, ebx
        pop ebx
        ret


;-------------------------------------------------------------------
; get_gdt_descriptor(): 读取 GDT 描述符
; input:
;       esi - selector 
; output:
;       edx:eax - 成功时, 返回 64 位描述符, 失败时, 返回 -1 值
;------------------------------------------------------------------- 
get_gdt_descriptor:
        push ebx
        xor eax, eax
        inc eax
        mov edx, eax
        and esi, 0FFF8h
        mov ebx, esi
        add esi, 7
        
        ;; 
        ;; 检查是否超 limit
        cmp esi, [fs: SDA.GdtLimit]
        ja get_gdt_descriptor.done
        
        add ebx, [fs: SDA.GdtBase]
        mov eax, [ebx]
        mov edx, [ebx + 4]
        
get_gdt_descriptor.done:        
        pop ebx
        ret        


;-------------------------------------------------------------------
; get_idt_descriptor(): 读取 IDT 描述符
; input:
;       esi - vector  
; output:
;       edx:eax - 成功时, 返回 64 位描述符, 失败时, 返回 -1 值
;------------------------------------------------------------------- 
get_idt_descrptor:
        push ebx
        xor eax, eax
        inc eax
        mov edx, eax                            ; edx:eax = -1
        and esi, 0FFh
        shl esi, 3                              ; vector * 8
        mov ebx, esi
        add esi, 7
        
        ;;
        ;; 检查是否超 limit
        cmp esi, [fs: SDA.IdtLimit]
        ja get_idt_descriptor.done
        
        ;;
        ;; 读 IDT entry
        add ebx, [fs: SDA.IdtBase]
        mov eax, [ebx]
        mov edx, [ebx + 4]
        
get_idt_descriptor.done:        
        pop ebx
        ret


;-------------------------------------------------------------------
; set_idt_descriptor(): 根据提供的 vector 值在 IDT 表写入一个描述符
; input:
;       esi - vector
;       edx:eax - 64 位描述符值
; output:
;       eax - 返回描述符地址
;-------------------------------------------------------------------  
set_idt_descriptor:
        push ebx
        and esi, 0FFh
        shl esi, 3                              ; vector * 8
        mov ebx, [fs: SDA.IdtBase]
        add ebx, esi
        mov [ebx], eax
        mov [ebx + 4], edx
        mov eax, ebx
        pop ebx
        ret





;-------------------------------------------------------------------
; mask_io_port_access(): 屏蔽对某个端口的访问
; input:
;       esi - 端口值
; output:
;       none
;-------------------------------------------------------------------
mask_io_port_access:
set_iomap_bit:
        push ebp
        push ebx
        
%ifdef __X64        
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        
        REX.Wrxb
        mov ebx, [ebp + PCB.IomapBase]                          ; 读当前 Iomap 基址
        test DWORD [ebp + PCB.ProcessorStatus], CPU_STATUS_PG
        REX.Wrxb
        cmovz ebx, [ebp + PCB.IomapPhysicalBase]
        mov eax, esi
        shr eax, 3                                              ; port / 8
        and esi, 7                                              ; 取 byte 内位置
        bts DWORD [ebx + eax], esi                              ; 置位
        pop ebx
        pop ebp
        ret


;-------------------------------------------------------------------
; unmask_io_port_access(): 屏蔽对某个端口的访问
; input:
;       esi - 端口值
; output:
;       none
;-------------------------------------------------------------------
unmask_io_port_access:
clear_iomap_bit:
        push ebp
        push ebx

%ifdef __X64        
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif

        REX.Wrxb
        mov ebx, [ebp + PCB.IomapBase]                          ; 读当前 Iomap 基址
        test DWORD [ebp + PCB.ProcessorStatus], CPU_STATUS_PG
        REX.Wrxb
        cmovz ebx, [ebp + PCB.IomapPhysicalBase]        
        mov eax, esi
        shr eax, 3                                              ; port / 8
        and esi, 7                                              ; 取 byte 内位置
        btr DWORD [ebx + eax], esi                              ; 清位
        pop ebx
        pop ebp
        ret
        
        
        
;-------------------------------------------------------------------
; init_processor_basic_info(): 更新基本的处理器信息
; input:
;       none
; output:
;       none
;
; 注意: 
;       此函数在开启 paging 前调用
;-------------------------------------------------------------------
init_processor_basic_info:
        push ebx
        push ecx
        push edx

        ;;
        ;; 设置处理器 index 与 count 值
        ;;
        mov eax, [LoaderBase+LOADER_BLOCK.CpuIndex]     ; CpuIndex
        mov [gs: PCB.ProcessorIndex], eax               
        lock inc DWORD [fs: SDA.ProcessorCount]         ; count
        
        
        ;;
        ;; 读取 basic 和 extended 的最大 CPUID leaf
        ;;
        xor eax, eax
        cpuid
        mov [gs: PCB.MaxBasicLeaf], eax
        mov eax, 80000000h
        cpuid
        mov [gs: PCB.MaxExtendedLeaf], eax
                                                  
        ;;
        ;; 得到  vendor ID 值
        ;;
        call get_vendor_id
        mov [gs: PCB.Vendor], eax        
        
        ;;
        ;; 得到基本 CPUID 信息
        ;;
        call update_cpuid_info
        
        mov ebx, [gs: PCB.CpuidLeaf01Ebx]
        mov ecx, ebx
        and ecx, 0FF00h
        shr ecx, 5                                      ; cache line = EBX[15:08] * 8(bytes)
        mov [gs: PCB.CacheLineSize], ecx       
        mov ecx, ebx
        shr ecx, 16
        and ecx, 0FFh
        mov [gs: PCB.MaxLogicalProcessor], ecx          ; 最大逻辑处理器数        
        shr ebx, 24
        mov [gs: PCB.InitialApicId], ebx                ; 初始 APIC ID       
        mov esi, [gs: PCB.CpuidLeaf01Eax]
        call get_display_family_model
        mov [gs: PCB.DisplayModel], ax                  ; DisplayFamily_DiplayModel
        
        ;;
        ;; 检查是否支持 SMT
        ;;
        call check_multi_threading_support
        mov [gs: PCB.IsMultiThreading], al
                
        ;;
        ;; 检查 SSE 指令支持度
        ;;
        call get_sse_level
        mov [gs: PCB.SSELevel], eax
       
        ;;
        ;; 更新 cache 信息
        ;;
        call update_cache_info

        
        ;;
        ;; 更新基本的扩展信息
        ;; 
        mov eax, 80000001h
        cpuid
        mov [gs: PCB.ExtendedFeatureEcx], ecx           ; 保存 CPUID.80000001H 叶信息
        mov [gs: PCB.ExtendedFeatureEdx], edx
        mov eax, 80000008h
        cmp [gs: PCB.MaxExtendedLeaf], eax              ; 是否支持 8000000h leaf
        mov ecx, 2020h                                  ; 32 位
        jb init_processor_basic_info.@1
        cpuid
        mov ecx, eax
        
init_processor_basic_info.@1:        
        ;;
        ;; 更新 MAXPHYADDR 值
        ;;
        mov [gs: PCB.MaxPhysicalAddr], cl
        mov [gs: PCB.MaxVirtualAddr], ch
        
        ;;
        ;; 计算 MAXPHYADDR MASK 值
        ;;
        call get_maxphyaddr_select_mask
        mov [gs: PCB.MaxPhyAddrSelectMask], eax
        mov [gs: PCB.MaxPhyAddrSelectMask + 4], edx
        
     
        ;;
        ;; IA32_PERF_CAPABILITIES 寄存器是否可用
        ;; 检查 CPUID.01H:ECX[15].PDCM (Perfmon and Debug Capability)
        ;;
        xor edx, edx
        mov eax, [gs: PCB.FeatureEcx]
        bt eax, 15
        mov eax, edx
        jnc init_processor_basic_info.@2
        mov ecx, IA32_PERF_CAPABILITIES
        rdmsr
init_processor_basic_info.@2:        
        mov [gs: PCB.PerfCapabilities], eax
        mov [gs: PCB.PerfCapabilities + 4], edx

      
        ;;
        ;; APIC 基本信息
        ;;
        mov ecx, IA32_APIC_BASE
        rdmsr
        mov ebx, eax
        bt eax, 8                                       ; 检查是否为 BSP
        setc BYTE [gs: PCB.IsBsp]
        and eax, 0FFFFF000h
        mov [gs: PCB.LapicPhysicalBase], eax            ; local APIC 物理基址
        mov DWORD [gs: PCB.LapicBase], LAPIC_BASE       ; local APIC 基址(virutal address)
        mov ecx, [gs: PCB.ProcessorIndex]
        mov edx, 01000000h
        shl edx, cl                                     ; 生成处理器逻辑 ID
        mov [gs: PCB.LogicalId], edx
        mov [eax + LAPIC_LDR], edx                      ; 设置 local APIC 的逻辑 ID
         
        ;; 
        ;; 更新 loacal APIC 信息
        ;;
        mov BYTE [gs: PCB.IsLapicEnable], 1
        mov BYTE [gs: PCB.IsLx2ApicEnable], 0
        mov ebx, [eax + LAPIC_ID]
        mov [gs: PCB.ApicId], ebx                       ; 更新 Lapic ID
        mov ebx, [eax + LAPIC_VERSION]
        mov [gs: PCB.LapicVersion], ebx                 ; 更新 Lapic version        
        
        ;;
        ;; 设置处理器的初始 TPR 值 
        ;;
        movzx ebx, BYTE [gs: PCB.CurrentTpl]
        shl ebx, 4
        mov [eax + LAPIC_TPR], ebx
        
        ;;
        ;; 初始化 local LVT 寄存器
        ;;
        mov DWORD [eax + LVT_PERFMON], FIXED_DELIVERY | LAPIC_PERFMON_VECTOR
        mov DWORD [eax + LVT_TIMER], TIMER_ONE_SHOT | LAPIC_TIMER_VECTOR | LVT_MASKED
        mov DWORD [eax + TIMER_ICR], 0    
        mov DWORD [eax + LVT_ERROR], LAPIC_ERROR_VECTOR
        mov DWORD [eax + LVT_THERMAL], SMI_DELIVERY 
        mov DWORD [eax + LVT_CMCI], LVT_MASKED        
        mov DWORD [eax + LVT_LINT0], EXTINT_DELIVERY
        mov DWORD [eax + LVT_LINT1], NMI_DELIVERY        


init_processor_basic_info.@3:

        cmp BYTE [gs: PCB.IsBsp], 1
        jne init_processor_basic_info.@4
        
        ;;
        ;; 初始化 IOAPIC
        ;;
        call init_ioapic_unit    

        ;;
        ;; 测量处理器频率
        ;;
        call init_processor_frequency
        jmp init_processor_basic_info.@5
        
init_processor_basic_info.@4:
        ;;
        ;; 屏蔽 APs LINT0 和 LINT1
        ;;
        mov DWORD [eax + LVT_LINT0], LVT_MASKED | EXTINT_DELIVERY
        mov DWORD [eax + LVT_LINT1], LVT_MASKED | NMI_DELIVERY
                
        ;;
        ;; 读取 BSP 的 PCB 块
        ;;
        mov ebx, [fs: SDA.PcbPhysicalBase]
        
        ;;
        ;; 复制 BSP 的频率数据
        ;;        
        mov eax, [ebx + PCB.ProcessorFrequency]
        mov [gs: PCB.ProcessorFrequency], eax
        mov eax, [ebx + PCB.TicksFrequency]
        mov [gs: PCB.TicksFrequency], eax
        
        ;;
        ;; 复制 BSP 的 lapic timer 计数频率
        ;;
        mov eax, [ebx + PCB.LapicTimerFrequency]
        mov [gs: PCB.LapicTimerFrequency], eax
               
init_processor_basic_info.@5:
        ;;
        ;; 设置 Ioapic enable 状态
        ;;
        mov BYTE [gs: PCB.IsIapicEnable], 1
        mov DWORD [gs: PCB.IapicPhysicalBase], 0FEC00000h
        mov DWORD [gs: PCB.IapicBase], IOAPIC_BASE   
        
        
        ;;
        ;; 启用相关处理器功能和指令支持
        ;; 1) 开启 PAE 
        ;; 2) 启用 XD 支持
        ;; 3) 启用 SMEP 功能
        ;;
        call pae_enable
        call xd_page_enable
        call smep_enable
        
        ;;
        ;; 开启 CR4.OSFXSR 位, 允许执行 SSE 指令        
        ;;
        mov eax, cr4
        bts eax, 9                                      ; CR4.OSFXSR = 1
        mov cr4, eax 
        or DWORD [gs: PCB.InstructionStatus], INST_STATUS_SSE

        ;;
        ;; 开启 Read/Write FS/GS base 功能, 允许使用 RD/WR FS/GS base 指令
        ;;
        test DWORD [gs: PCB.FeatureAddition], 1         ; 检查 RWFSBASE 功能位
        jz init_processor_basic_info.@6
        mov eax, cr4
        bts eax, 16                                     ; CR4.RWFSBASE = 1
        mov cr4, eax
        or DWORD [gs: PCB.InstructionStatus], INST_STATUS_RWFSBASE
        
init_processor_basic_info.@6:
        ;;
        ;; 支持 VMX 时, 读取 VMX capabilities MSR
        ;;                
        test DWORD [gs: PCB.FeatureEcx], CPU_FLAGS_VMX
        jz init_processor_basic_info.@7
                
        call get_vmx_global_data
        
init_processor_basic_info.@7:
        
init_processor_basic_info.done:
        pop edx
        pop ecx
        pop ebx
        ret
        
        
;-------------------------------------------------------------------
; get_vendor_id(): 返回 vendor ID
; input:
;       none
; output:
;       eax - vendor ID
;-------------------------------------------------------------------
get_vendor_id:
        xor eax, eax
        cpuid
        mov eax, VENDOR_UNKNOWN
        
        ;;
        ;; 检查: 
        ;; 1) Intel: "GenuineIntel"
        ;; 2) AMD: "AuthenticAMD"
        ;;
check_for_intel:        
        cmp ebx, 756E6547h                      ; "Genu"
        jne check_for_amd
        cmp edx, 49656E69h                      ; "ineI"
        jne check_for_amd
        cmp ecx, 6C65746Eh                      ; "ntel"
        jne check_for_amd
        mov eax, VENDOR_INTEL
        ret
check_for_amd:
        cmp ebx, 68747541h                      ; "htuA"
        jne get_vendor_id.unknown
        cmp edx, 69746E65h                      ; "itne"
        jne get_vendor_id.unknown
        cmp ecx, 444D4163h                      ; "DMAc"
        jne get_vendor_id.unknown
        mov eax, VENDOR_AMD
get_vendor_id.unknown:
        ret



;-------------------------------------------------------------------
; update_cpuid_info()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 读取处理器 CPUID 信息
;-------------------------------------------------------------------
update_cpuid_info:
        push ecx
        push edx
        push ebx
              
        ;;
        ;; 最大读取 0B leaf
        ;;
        mov edi, 0Bh
        mov esi, [gs: PCB.MaxBasicLeaf]
        cmp esi, edi
        cmova esi, edi
        
        mov eax, esi        
        mov edi, [gs: PCB.PhysicalBase]
        shl eax, 4                                      ; MaxBasicLeaf * 16
        lea edi, [edi + PCB.CpuidLeaf01Eax + eax]       ; Cpuid Leaf 顶部
        
update_cpuid_info.@0:
        sub edi, 16
        mov eax, esi
        xor ecx, ecx
        cpuid
        mov [edi], eax
        mov [edi + 4], ebx
        mov [edi + 8], ecx
        mov [edi + 12], edx
        dec esi
        ja update_cpuid_info.@0
        
        pop ebx
        pop edx
        pop ecx
        ret




;-----------------------------------------------------------------
; get_maxphyaddr_select_mask(): 计数出 MAXPHYADDR 值的 SELECT MASK
; output:
;       edx:eax - maxphyaddr select mask
; 描述: 
;       select mask 值用于取得 MAXPHYADDR 对应的物理地址值
; 例如: 
;       MAXPHYADDR = 32 时: select mask = 00000000_FFFFFFFFh
;       MAXPHYADDR = 36 时: select mask = 0000000F_FFFFFFFFh
;       MAXPHYADDR = 40 时: select mask = 000000FF_FFFFFFFFh
;       MAXPHYADDR = 52 时: select mask = 000FFFFF_FFFFFFFFh
;-----------------------------------------------------------------
get_maxphyaddr_select_mask:
        push ecx
        movzx ecx, BYTE [gs: PCB.MaxPhysicalAddr]       ; 得到 MAXPHYADDR 值
        xor eax, eax
        xor edx, edx
        and ecx, 1Fh                                    ; 取除 32 的余数
        dec eax                                         ; eax = -1(FFFFFFFFh)
        shld edx, eax, cl                               ; edx = n1
        pop ecx
        ret
        
        
;---------------------------------------------------------------------
; get_sse_level(): 获得 SSE 指令支持级别
; input:
;       none
; output:
;       eax - sse level
;---------------------------------------------------------------------
get_sse_level:
        push ecx
        mov eax, 0402h
        mov ecx, [gs: PCB.FeatureEcx]
        bt ecx, 20                              ; SSE4.2
        jc get_sse_level.done
        mov eax, 0401h
        bt ecx, 19                              ; SSE4.1
        jc get_sse_level.done
        mov eax, 0301h
        bt ecx, 9                               ; SSSE3
        jc get_sse_level.done
        mov eax, 0300h               
        bt ecx, 0                               ; SSE3
        jc get_sse_level.done
        mov ecx, [gs: PCB.FeatureEdx]
        mov eax, 0200h
        bt ecx, 26                              ; SSE2
        jc get_sse_level.done
        mov eax, 0100h
        bt ecx, 25                              ; SSE
        jc get_sse_level.done
        xor eax, eax
get_sse_level.done:        
        pop ecx
        ret        


        
;---------------------------------------------------------------------
; get_display_family_model(): 获得 DisplayFamily 与 DisplayModel
; input:
;       esi - processor version(from CPUID.01H)
; output:
;       ax - DisplayFamily_DisplayModel
;--------------------------------------------------------------------
get_display_family_model:
	push ebx
	push edx
	push ecx
        mov eax, esi
	mov ebx, eax
	mov edx, eax
	mov ecx, eax
	shr eax, 4
	and eax, 0Fh                                    ; eax = bits 7:4 (得到 model 值)
	shr edx, 8
	and edx, 0Fh                                    ; edx = bits 11:8 (得到 family 值)
	

	cmp edx, 0Fh
	jne test_family_06
	;;
        ;; 如果是 Pentium 4 家族: DisplayFamily = ExtendedFamily + Family
        ;;
	shr ebx, 20                                     
	add edx, ebx                                    ; edx = ExtendedFamily + Family
	jmp get_displaymodel
        
test_family_06:	
	cmp edx, 06h
	jne get_display_family_model.done
        
get_displaymodel:	
        ;;
        ;; DisplayModel = ExtendedMode << 4 + Model
        ;;
	shr ecx, 12                                     ; ecx = ExtendedMode << 4
	and ecx, 0xf0
	add eax, ecx                                    ; 得到 DisplayModel
        
get_display_family_model.done:	
	mov ah, dl
	pop ecx
	pop edx
	pop ebx
	ret

;-----------------------------------------------------------------------
; check_multi_threading_support():
; input:
;       none
; output:
;       1 - yes, 0 - no
; 描述: 
;       检查处理器是否支持多线程
;-----------------------------------------------------------------------
check_multi_threading_support:
        ;;
        ;; 需要检查 CPUID.01H:EDX[28] 以及 CPUID.01H:EBX[23:16] 的值
        ;; 
        xor eax, eax
        bt DWORD [gs: PCB.FeatureEdx], 28               ; 检查 CPUID.01H:EDX[28] 位
        jnc check_multi_threading_support.done
        ;;
        ;; 然后检查支持最大逻辑处理器数
        ;;
        cmp DWORD [gs: PCB.MaxLogicalProcessor], 1
        jb check_multi_threading_support.done
        inc eax
check_multi_threading_support.done:        
        ret



;-----------------------------------------------------------------------
; update_cache_info()
; input:
;       none
; output:
;       none
; 描述: 
;       获取处理器 Cache 信息(在开启 paging 前调用)
;-----------------------------------------------------------------------
update_cache_info:
        push ecx
        push ebx
        push edx
        push ebp
        
        ;;
        ;; 通过枚举 CPUID.04H leaf 来获取 cache 信息
        ;;
        mov esi, 0                                      ; 初始子叶
        mov ebp, [gs: PCB.PhysicalBase]                 ; 使用物理地址
        
update_cache_info.loop:
        mov eax, 04h
        mov ecx, esi
        cpuid
        mov edi, eax
        
        ;;
        ;; 没有 cache 信息
        ;;
        and eax, 1Fh
        cmp eax, CACHE_NONE
        je update_cache_info.done
        
        mov eax, edi        
        call get_cache_level_base                       ; 获取 cache 信息结构地址
        add ebp, eax                                    ; ebp 存放 cache 信息结构地址
        mov eax, edi
        shr eax, 5
        and eax, 3                                      ; EAX[7:5] = cache level
        and edi, 1Fh                                    ; EAX[4:0] = cache type
        mov [ebp + CacheInfo.Type], di
        mov [ebp + CacheInfo.Level], ax
        mov eax, ebx
        shr eax, 22
        inc eax                                         ; ways
        mov [ebp + CacheInfo.Ways], ax
        mov eax, ebx
        shr eax, 12
        and eax, 3FFh                                   ; line partitions
        inc eax
        mov [ebp + CacheInfo.Partitions], ax
        mov eax, ebx
        and eax, 0FFFh                                  ; line size
        inc eax
        mov [ebp + CacheInfo.LineSize], ax
        inc ecx
        mov [ebp + CacheInfo.Sets], ecx                 ; sets
        call get_cache_size
        mov [ebp + CacheInfo.Size], eax                 ; cache size 
        inc esi                                         ; 
        jmp update_cache_info.loop

update_cache_info.done:                
        pop ebp
        pop edx
        pop ebx
        pop ecx
        ret



;-----------------------------------------------------------------------
; get_cache_level_base()
; input:
;       eax - CPUID.01H:EAX 值
; output:
;       eax - 相应的 cache 信息结构地址
; 描述:
;       此函数在 update_cache_info() 内部使用
;-----------------------------------------------------------------------
get_cache_level_base:
        push ecx
        push ebx
        mov ecx, eax
        and eax, 01Fh                                   ; EAX[4:0] = cache type 值
        shr ecx, 5
        and ecx, 3                                      ; EAX[7:5] = cache level 值
        
        ;;
        ;; 下面检查 level 级和 cache 类型
        ;;
        cmp eax, CACHE_L1D                              ; 是否为 level-1 data cache
        mov ebx, PCB.L1D
        je get_cache_level_base.done
        cmp eax, CACHE_L1I                              ; 是否为 level-1 instruction cache
        mov ebx, PCB.L1I
        je get_cache_level_base.done

        ;;
        ;; 如果是 unified cache 则, 检查 level 级
        ;;
        mov ebx, PCB.L2
        cmp ecx, 2                                      ; 是否为 level-2
        mov ecx, PCB.L3
        cmovne ebx, ecx                                 ; 否则为 level-3
        
get_cache_level_base.done:
        mov eax, ebx                                    ; 返回相应的 cache 信息结构地址
        pop ebx                   
        pop ecx
        ret


;-----------------------------------------------------------------------
; get_cache_size()
; input:
;       ebp - cache 结构地址
; output:
;       eax - cache size
; 描述:
;       此函数在 update_cache_info() 内部使用
;-----------------------------------------------------------------------
get_cache_size:
        push edx
        push ecx
        xor edx, edx
        
        ;;
        ;; Cache size(bytes)   
        ;;      = Ways * Partions * LineSize * Sets
        ;;      = (EBX[31:22] + 1) * (EBX[21:12] + 1) * (EBX[11:0] + 1) * (ECX + 1)
        ;;
        
        movzx eax, WORD [ebp + CacheInfo.Ways]
        movzx ecx, WORD [ebp + CacheInfo.Partitions]
        mul ecx
        movzx ecx, WORD [ebp + CacheInfo.LineSize]
        mul ecx
        mov ecx, [ebp + CacheInfo.Sets]
        mul ecx
        pop ecx
        pop edx
        ret




;-----------------------------------------------------------------------
; init_processor_frequency()
; input:
;       none
; output:
;       none
; 描述:
;       1) 计数处理器频率
; 权限说明: 
;       1) 该函数来自 Intel 的 CPUFREQ.ASM 代码

; Filename: CPUFREQ.ASM
; Copyright(c) 2003 - 2009 by Intel Corporation
;
; This program has been developed by Intel Corporation. Intel
; has various intellectual property rights which it may assert
; under certain circumstances, such as if another
; manufacturer's processor mis-identifies itself as being
; "GenuineIntel" when the CPUID instruction is executed.
;
; Intel specifically disclaims all warranties, express or
; implied, and all liability, including consequential and other
; indirect damages, for the use of this program, including
; liability for infringement of any proprietary rights,
; and including the warranties of merchantability and fitness
; for a particular purpose. Intel does not assume any
; responsibility for any errors which may appear in this program
; nor any responsibility to update it.
;-----------------------------------------------------------------------        
init_processor_frequency:
        push ecx
        push edx
        push ebx
        push ebp
        mov ebp, esp
        sub esp, 14
        
%define UPF.TscHi32             ebp - 4
%define UPF.TscLow32            ebp - 8
%define UPF.Nearest66Mhz        ebp - 10
%define UPF.Nearest50Mhz        ebp - 12
%define UPF.Delta66Mhz          ebp - 14

;;
;; 测量间隔为 5 秒
;; 1) 默认为 18.2 * 5 = 91
;; 2) 现在修改为 18 次
;;
INTERVAL_IN_TICKS               EQU     18
        
        
        ;;
        ;; 开启 PIT timer 及中断许可
        ;;
        call init_8253
        call enable_8259_timer
        sti

%ifdef REAL
        ;;
        ;; 检查是否支持 IA32_MPERF
        ;; 1) 支持时, 使用 IA32_MPERF 来计数
        ;; 2) 否则, 使用 time stamp 来计数
        ;;
        test DWORD [gs: PCB.CpuidLeaf06Ecx], 1                  ; 检查 CPUID.06H:ECX[0]
        jnz init_processor_frequency.enh
%endif
        
        ;;
        ;; 读前一次时间中断计数值
        ;;
        mov ebx, [fs: SDA.TimerCount]                           

        ;;
        ;; 等待下一个 timer 中断到来
        ;;
init_processor_frequency.@0:        
        cmp ebx, [fs: SDA.TimerCount]
        je init_processor_frequency.@0
      
        ;;
        ;; 读 time stamp 值, 作为计数开始值
        ;;
        rdtsc
        mov [UPF.TscLow32], eax                                 ; BeginTscLow32 值
        mov [UPF.TscHi32], edx                                  ; BeginTscHi32 值
        
        ;;
        ;; 设置 lapic timer count 初始值为 0FFFFFFFFh
        ;; 用来测量 lapic timer 每秒计数
        ;;
        mov DWORD [0FEE00000h + TIMER_ICR], 0FFFFFFFFh
        
        
        ;;
        ;; 设置 timer 中断延时计数值
        ;; 1) 设置 5 秒的延时值: 18.2 * 5 = 91(PIT 每秒中断18.2次, 5秒内产生91次中断)
        ;; 2) 增加 1 次的延时
        ;;
        
        ;;
        ;; 修改: 
        ;; 1)现在修改为 1 秒的延时值: 约为 19 次
        ;;
        add ebx, INTERVAL_IN_TICKS + 1
        
        ;;
        ;; 下面等待测量时间到来, 即等待 1 秒钟
        ;;
init_processor_frequency.@1:        
        cmp ebx, [fs: SDA.TimerCount]
        ja init_processor_frequency.@1
        
        ;;
        ;; 读取结束的 TSC 值, 计算两段 TSC 差值
        ;;
        rdtsc
        sub eax, [UPF.TscLow32]
        sbb edx, [UPF.TscHi32]
        
        ;;
        ;; 读取 lapic timer count 计数值
        ;;
        mov ecx, [0FEE00000h + TIMER_CCR]                       ; 读 lapic timer 当前计数值
        mov DWORD [0FEE00000h + TIMER_ICR], 0                   ; 清 lapic timer 初始计数值
        
        neg ecx
        dec ecx                                                 ; 得到 lapic timer 1秒的计数次数
        jmp init_processor_frequency.next
        
        ;;
        ;; 下面使用增强的方式
        ;;
init_processor_frequency.enh:
        ;;
        ;; 清 IA32_MPERF 计数器
        ;;
        mov ecx, IA32_MPERF
        xor eax, eax
        xor edx, edx

        ;;
        ;; 读前一次时间中断计数值
        ;;
        mov ebx, [fs: SDA.TimerCount]                           

        ;;
        ;; 等待下一个 timer 中断到来
        ;;
init_processor_frequency.@2:        
        cmp ebx, [fs: SDA.TimerCount]
        je init_processor_frequency.@2
        
        ;;
        ;; 清 C0_MCNT 值, 从 0 开始计数
        ;;
        wrmsr
        
        ;;
        ;; 设置 timer 中断延时计数值
        ;; 1) 设置 5 秒的延时值: 18.2 * 5 = 91(PIT 每秒中断18.2次)
        ;; 2) 增加 1 次的延时
        ;;
        add ebx, INTERVAL_IN_TICKS + 1
        
        ;;
        ;; 下面等待测量时间到来, 即等待 5 秒钟
        ;;
init_processor_frequency.@3:        
        cmp ebx, [fs: SDA.TimerCount]
        ja init_processor_frequency.@3
   
        ;;
        ;; 读 C0_MCNT 作为结束值
        ;;
        rdmsr

                
init_processor_frequency.next:       
        ;;
        ;; 下面计算 CPU 频率
        ;; 1) MHz 单位值: 54945 = (1 / 18.2) * 1,000,000, 即: 55ms产生一次中断, 100万次中断需要54945秒
        ;; 2) tick_interval = 54945 * INTERVAL_IN_TICKS
        ;; 3) CpuFreq = TSC / tick_interval
        ;;
        mov ebx, 54945 * INTERVAL_IN_TICKS
        div ebx 
        
        ;;
        ;; eax = 处理器频率
        ;;
        mov [gs: PCB.TicksFrequency], eax
        
        ;;
        ;; Find nearest full/half multiple of 66/133 MHz
        ;;
        xor dx, dx
        mov ax, [gs: PCB.TicksFrequency]
        mov bx, 3
        mul bx
        add ax, 100
        mov bx, 200
        div bx
        mul bx
        xor dx, dx
        mov bx, 3
        div bx
        
        ;;        
        ;; ax contains nearest full/half multiple of 66/100 MHz
        ;;
        mov [UPF.Nearest66Mhz], ax
        sub ax, [gs: PCB.TicksFrequency]
        jge delta66
        neg ax                                  ; ax = abs(ax)
delta66:
        ;;
        ;; ax contains delta between actual and nearest 66/133 multiple
        ;;
        mov [UPF.Delta66Mhz], ax
        ;;
        ;; Find nearest full/half multiple of 100 MHz
        ;;
        xor dx, dx
        mov ax, [gs: PCB.TicksFrequency]
        add ax, 25
        mov bx, 50
        div bx
        mul bx
        ;;
        ;; ax contains nearest full/half multiple of 100 MHz
        ;;
        mov [UPF.Nearest50Mhz], ax
        sub ax, [gs: PCB.TicksFrequency]
        jge delta50
        neg ax                                  ; ax = abs(ax)
delta50:
        ;;
        ;; ax contains delta between actual and nearest 50/100 MHz
        ;; multiple
        ;;
        mov bx, [UPF.Nearest50Mhz]
        cmp ax, [UPF.Delta66Mhz]
        jb useNearest50Mhz
        mov bx, [UPF.Nearest66Mhz]
        ;;
        ;; Correction for 666 MHz (should be reported as 667 MHZ)
        ;;
        cmp bx, 666
        jne correct666
        inc bx        
        
correct666:
useNearest50Mhz:
        ;;
        ;; 计算出处理器报告的频率
        ;;
        movzx eax, bx
        mov [gs: PCB.ProcessorFrequency], eax

        ;;
        ;; 计数 1微秒 lapic timer 计数次数
        ;;
        xor edx, edx
        mov eax, ecx
        mov ecx, 1000000                                ; 单位为 us
        div ecx
        cmp edx, 500000                                 ; 如果余数大于 1000000/2 的话
        seta cl
        movzx ecx, cl
        add eax, ecx
        mov [gs: PCB.LapicTimerFrequency], eax
        
        ;;
        ;; 关闭 timer 和中断许可
        ;;
        cli
        call disable_8259_timer
        
        ;;
        ;; 清 timer 计数值
        ;;
        mov DWORD [fs: SDA.TimerCount], 0
        
        mov esp, ebp
        pop ebp
        pop ebx
        pop edx
        pop ecx
        ret


        
          

             

;------------------------------------------------------
; get_vmx_global_data()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 读取 VMX 相关信息
;       2) 在 stage1 阶段调用
;------------------------------------------------------
get_vmx_global_data:
        push ecx
        push edx
        
        ;;
        ;; VmxGlobalData 区域
        ;;
        mov edi, [gs: PCB.PhysicalBase]
        add edi, PCB.VmxGlobalData

        ;;
        ;; ### step 1: 读取 VMX MSR 值 ###
        ;; 1) 当 CPUID.01H:ECX[5]=1时, IA32_VMX_BASIC 到 IA32_VMX_VMCS_ENUM 寄存器有效
        ;; 2) 首先读取 IA32_VMX_BASIC 到 IA32_VMX_VMCS_ENUM 寄存器值
        ;;
        
        mov esi, IA32_VMX_BASIC
                
get_vmx_global_data.@1:        
        mov ecx, esi
        rdmsr
        mov [edi], eax
        mov [edi + 4], edx
        inc esi
        add edi, 8
        cmp esi, IA32_VMX_VMCS_ENUM
        jbe get_vmx_global_data.@1
        
        ;;
        ;; ### step 2: 接着读取 IA32_VMX_PROCBASED_CTLS2 ###
        ;; 1) 当 CPUID.01H:ECX[5]=1, 并且 IA32_VMX_PROCBASED_CTLS[63] = 1时, IA32_VMX_PROCBASED_CTLS2 寄存器有效
        ;;
        test DWORD [gs: PCB.ProcessorBasedCtls + 4], ACTIVATE_SECONDARY_CONTROL
        jz get_vmx_global_data.@5
        
        mov ecx, IA32_VMX_PROCBASED_CTLS2
        rdmsr
        mov [gs: PCB.ProcessorBasedCtls2], eax
        mov [gs: PCB.ProcessorBasedCtls2 + 4], edx

        ;;
        ;; ### step 3: 接着读取 IA32_VMX_EPT_VPID_CAP
        ;; 1) 当 CPUID.01H:ECX[5]=1, IA32_VMX_PROCBASED_CTLS[63]=1, 并且 IA32_PROCBASED_CTLS2[33]=1 时, IA32_VMX_EPT_VPID_CAP 寄存器有效
        ;;
        test edx, ENABLE_EPT
        jz get_vmx_global_data.@5        
        
        mov ecx, IA32_VMX_EPT_VPID_CAP
        rdmsr
        mov [gs: PCB.EptVpidCap], eax
        mov [gs: PCB.EptVpidCap + 4], edx
        
        ;;
        ;; ### step 4: 读取 IA32_VMX_VMFUNC　###
        ;; 1) IA32_VMX_VMFUNC 寄存器仅在支持 "enable VM functions" 1-setting 时有效, 因此需要检测是否支持!
        ;; 2) 检查 IA32_VMX_PROCBASED_CTLS2[45] 是否为 1 值
        ;;
        test DWORD [gs: PCB.ProcessorBasedCtls2 + 4], ENABLE_VM_FUNCTION
        jz get_vmx_global_data.@5
        
        mov ecx, IA32_VMX_VMFUNC
        rdmsr
        mov [gs: PCB.VmFunction], eax
        mov [gs: PCB.VmFunction + 4], edx


get_vmx_global_data.@5:        

        ;;
        ;; ### step 5: 读取 4 个 VMX TRUE capability 寄存器 ###
        ;;
        ;; 如果 bit55 of IA32_VMX_BASIC 为 1 时, 支持 4 个 capability 寄存器: 
        ;; 1) IA32_VMX_TRUE_PINBASED_CTLS  = 48Dh
        ;; 2) IA32_VMX_TRUE_PROCBASED_CTLS = 48Eh
        ;; 3) IA32_VMX_TRUE_EXIT_CTLS      = 48Fh   
        ;; 4) IA32_VMX_TRUE_ENTRY_CTLS     = 490h
        ;;
        bt DWORD [gs: PCB.VmxBasic + 4], 23
        jnc get_vmx_global_data.@6

        mov BYTE [gs: PCB.TrueFlag], 1                                  ; 设置 TrueFlag 标志位
        ;;
        ;; 如果支持 TRUE MSR 的话, 那么就更新下面 MSR:
        ;; 1) IA32_VMX_PINBASED_CTLS
        ;; 2) IA32_VMX_PROCBASED_CTLS
        ;; 3) IA32_VMX_EXIT_CTLS
        ;; 4) IA32_VMX_ENTRY_CTLS
        ;; 用 TRUE MSR 的值替代上面 MSR!
        ;;
        mov ecx, IA32_VMX_TRUE_PINBASED_CTLS
        rdmsr
        mov [gs: PCB.PinBasedCtls], eax
        mov [gs: PCB.PinBasedCtls + 4], edx
        mov ecx, IA32_VMX_TRUE_PROCBASED_CTLS
        rdmsr
        mov [gs: PCB.ProcessorBasedCtls], eax
        mov [gs: PCB.ProcessorBasedCtls + 4], edx
        mov ecx, IA32_VMX_TRUE_EXIT_CTLS
        rdmsr
        mov [gs: PCB.ExitCtls], eax
        mov [gs: PCB.ExitCtls + 4], edx
        mov ecx, IA32_VMX_TRUE_ENTRY_CTLS
        rdmsr
        mov [gs: PCB.EntryCtls], eax
        mov [gs: PCB.EntryCtls + 4], edx                
                
                
get_vmx_global_data.@6:
        ;;
        ;; ### step 6: 设置 CR0 与 CR4 的 mask 值(固定为1值)
        ;; 1) Cr0FixedMask = Cr0Fixed0 & Cr0Fixed1
        ;; 2) Cr4FixedMask = Cr4Fixed0 & Cr4Fxied1
        ;;
        mov eax, [gs: PCB.Cr0Fixed0]
        mov edx, [gs: PCB.Cr0Fixed0 + 4]
        and eax, [gs: PCB.Cr0Fixed1]
        and edx, [gs: PCB.Cr0Fixed1 + 4]
        mov [gs: PCB.Cr0FixedMask], eax                                 ; CR0 固定为 1 值
        mov [gs: PCB.Cr0FixedMask + 4], edx
        mov eax, [gs: PCB.Cr4Fixed0]
        mov edx, [gs: PCB.Cr4Fixed0 + 4]
        and eax, [gs: PCB.Cr4Fixed1]
        and edx, [gs: PCB.Cr4Fixed1 + 4]
        mov [gs: PCB.Cr4FixedMask], eax                                 ; CR4 固定为 1 值
        mov [gs: PCB.Cr4FixedMask + 4], edx
        
        ;;
        ;; 关于 IA32_FEATURE_CONTROL.lock 位: 
        ;; 1) 当 lock = 0 时, 执行 VMXON 产生 #GP 异常
        ;; 2) 当 lock = 1 时, 写 IA32_FEATURE_CONTROL 寄存器产生 #GP 异常
        ;;
        
        ;;
        ;; 下面将检查 IA32_FEATURE_CONTROL 寄存器
        ;; 1) 当 lock 位为 0 时, 需要进行一些设置, 然后锁上 IA32_FEATURE_CONTROL
        ;;        
        mov ecx, IA32_FEATURE_CONTROL
        rdmsr
        bts eax, 0                                                      ; 检查 lock 位, 并上锁
        jc get_vmx_global_data.@7
        
        ;; lock 未上锁时: 
        ;; 1) 对 lock 置位(锁上 IA32_FEATURE_CONTROL 寄存器)
        ;; 2) 对 bit 2 置位(启用 enable VMXON outside SMX)
        ;; 3) 如果支持 enable VMXON inside SMX 时, 对 bit 1 置位!
        ;; 
        mov esi, 6                                                      ; enable VMX outside SMX = 1, enable VMX inside SMX = 1
        mov edi, 4                                                      ; enable VMX outside SMX = 1, enable VMX inside SMX = 0
        
        ;;
        ;; 检查是否支持 SMX 模式
        ;;
        test DWORD [gs: PCB.FeatureEcx], CPU_FLAGS_SMX
        cmovz esi, edi        
        or eax, esi
        wrmsr
        
                
get_vmx_global_data.@7:        

        ;;
        ;; 假如使用 enable VMX inside SMX 功能, 则根据 IA32_FEATURE_CONTROL[1] 来决定是否必须开启 CR4.SMXE
        ;; 1) 本书例子中没有开启 CR4.SMXE
        ;;
%ifdef ENABLE_VMX_INSIDE_SMX
        ;;
        ;; ### step 7: 设置 Cr4FixedMask 的 CR4.SMXE 位 ###
        ;;
        ;; 再次读取 IA32_FEATURE_CONTROL 寄存器
        ;; 1) 检查 enable VMX inside SMX 位(bit1)
        ;;    1.1) 如果是 inside SMX(即 bit1 = 1), 则设置 CR4FixedMask 位的相应位
        ;; 
        rdmsr
        and eax, 2                                                      ; 取 enable VMX inside SMX 位的值(bit1)
        shl eax, 13                                                     ; 对应在 CR4 寄存器的 bit 14 位(即 CR4.SMXE 位)
        or DWORD [ebp + PCB.Cr4FixedMask], eax                          ; 在 Cr4FixedMask 里设置 enable VMX inside SMX 位的值　        
        
%endif

get_vmx_global_data.@8:        
        ;;
        ;; ### step 8: 查询 Vmcs 以及 access page 的内存 cache 类型 ###
        ;; 1) VMCS 区域内存类型
        ;; 2) VMCS 内的各种 bitmap 区域, access page 内存类型
        ;;
        mov eax, [gs: PCB.VmxBasic + 4]
        shr eax, 50-32                                                  ; 读取 IA32_VMX_BASIC[53:50]
        and eax, 0Fh
        mov [gs: PCB.VmcsMemoryType], eax


get_vmx_global_data.@9:        
        ;;
        ;; ### step 9: 检查 VMX 所支持的 EPT page memory attribute ###
        ;; 1) 如果支持 WB 类型则使用 WB, 否则使用 UC
        ;; 2) 在 EPT 设置 memory type 时, 直接或上 [gs: PCB.EptMemoryType]
        ;;
        mov esi, MEM_TYPE_WB                                            ; WB 
        mov eax, MEM_TYPE_UC                                            ; UC        
        bt DWORD [gs: PCB.EptVpidCap], 14
        cmovnc esi, eax        
        mov [gs: PCB.EptMemoryType], esi
        
get_vmx_global_data.done:
        pop edx
        pop ecx        
        ret
        


;---------------------------------------------
; pag_enable()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 开启 CR4.PAE
;---------------------------------------------
pae_enable:
        ;;
        ;; 检查 CPUID.01H.EDX[6] 标志位
        ;;
        mov eax, [gs: PCB.CpuidLeaf01Edx]        
        bt eax, 6                                       ; PAE support?
        jnc pae_enable_done
        mov eax, cr4
        or eax, CR4_PAE                                 ; CR4.PAE = 1        
        mov cr4, eax
        or DWORD [gs: PCB.ProcessorStatus], CPU_STATUS_PAE
pae_enable_done:        
        ret



;-------------------------------------------------
; xd_page_enable()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 开启 XD 位
;-------------------------------------------------
xd_page_enable:
        ;;
        ;; 检查 CPUID.80000001H:EDX[20].XD
        ;;
        mov eax, [gs: PCB.ExtendedFeatureEdx]
        bt eax, 20                                      ; XD support ?
        mov eax, 0
        jnc xd_page_enable.done
        mov ecx, IA32_EFER
        rdmsr 
        bts eax, 11                                     ; EFER.NXE = 1
        wrmsr        
        mov eax, XD
xd_page_enable.done:        
        mov DWORD [fs: SDA.XdValue], eax                ; 写 XD 标志值
        ret




;----------------------------------------------
; semp_enable()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 开启 SEMP 功能
;----------------------------------------------
smep_enable:
        ;;
        ;; 检查 CPUID.07H:EBX[7].SMEP 位
        ;;
        mov eax, [gs: PCB.CpuidLeaf07Ebx]
        bt eax, 7                                       ; SMEP suport ?
        jnc smep_enable_done
        mov eax, cr4
        or eax, CR4_SMEP                                ; enable SMEP
        mov cr4, eax
        or DWORD [gs: PCB.ProcessorStatus], CPU_STATUS_SMEP
smep_enable_done:        
        ret          
