;*************************************************
;* apic.asm                                      *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************


%include "..\inc\apic.inc"


LAPIC_BASE64                    EQU     0FFFFF800FEE00000h      
IAPIC_BASE64                    EQU     0FFFFF800FEC00000h





;-----------------------------------------------------
; support_apic(): 检测是否支持 APIC on Chip的 local APIC
;----------------------------------------------------
support_apic:
        push edx
        mov edx, [gs: PCB.FeatureEdx]
        bt edx, 9				; 检查 CPUID.01H:EDX[9] 位 
        setc al
        movzx eax, al
        pop edx
        ret


;--------------------------------------------
; support_x2apic(): 检则是否支持 x2apic
;--------------------------------------------
support_x2apic:
        push ecx
        mov ecx, [gs: PCB.FeatureEcx]
        bt ecx, 21
        setc al					; 检查 CPUID.01H:ECX[21] 位
        movzx eax, al
        pop ecx
        ret	


;-------------------------------------
; enable_apic(): 开启 apic
; input:
;       none
;------------------------------------
enable_apic:
        ;;
        ;; 检查是否已经开启了 local apic
        ;;
        movzx eax, BYTE [gs: PCB.IsLapicEnable]
        test eax, eax
        jnz enable_apic.done
        
        ;;
        ;; 检查是否开启 paging, 没开启下 apic 使用物理基址
        ;; 
        mov eax, [gs: PCB.ProcessorStatus]
        test eax, CPU_STATUS_PG
        mov esi, [gs: PCB.LapicBase]
        cmovz esi, [gs: PCB.LapicPhysicalBase]
        
        ;;
        ;; 开启 local apic
        ;;
        mov eax, [esi + SVR]
        bt eax, 8
        mov [esi + SVR], eax
        mov eax, 1
        ;;
        ;; 更新 PCB.IsLapicEnable 值
        ;;
        mov [gs: PCB.IsLapicEnable], al
enable_apic.done:        
        ret


;-------------------------------------
; disable_apic(): 关闭 apic
; input:
;       none
;------------------------------------
disable_apic:
        movzx eax, BYTE [gs: PCB.IsLapicEnable]
        test eax, eax
        jz disable_apic.done
        
        ;;
        ;; 检查是否开启 paging, 没开启下 apic 使用物理基址
        ;; 
        mov eax, [gs: PCB.ProcessorStatus]
        test eax, CPU_STATUS_PG
        mov esi, [gs: PCB.LapicBase]
        cmovz esi, [gs: PCB.LapicPhysicalBase]
                
        ;;
        ;; 关闭 apic
        ;;
        mov eax, [esi + SVR]
        btr eax, 8		                ; SVR.enable = 0
        mov [esi + SVR], eax
        ;;
        ;; 更新 apic
        ;;
        mov BYTE [gs: PCB.IsLapicEnable], 0
disable_apic.done:        
        ret





;-------------------------------
; enable_x2apic():
;------------------------------
enable_x2apic:
        mov ecx, IA32_APIC_BASE
        rdmsr
        or eax, 0xc00						; bit 10, bit 11 置位
        wrmsr
        ret
	
;-------------------------------
; disable_x2apic():
;-------------------------------
disable_x2apic:
        mov ecx, IA32_APIC_BASE
        rdmsr
        and eax, 0xfffff3ff					; bit 10, bit 11 清位
        wrmsr
        ret	


;------------------------------
; reset_apic(): 清掉 local apic
;------------------------------
reset_apic:
        mov ecx, IA32_APIC_BASE
        rdmsr
        btr eax, 11							; clear xAPIC enable flag
        wrmsr
        ret

;---------------------------------
; set_apic(): 开启 apic
;---------------------------------
set_apic:
        mov ecx, IA32_APIC_BASE
        rdmsr
        bts eax, 11							; enable = 1
        wrmsr
        ret
	
	
;------------------------------------------------
; set_apic_physical_base()
; input:
;       esi: 低 32 位,  edi: 高半部分
; output:
;       none
; 描述: 
;       设置 apic 的物理基址(在 MAXPHYADDR 值内)
;------------------------------------------------
set_apic_physical_base:
        push edx
        push ecx
        ;;
        ;; 确保地址在处理器支持的 MAXPHYADDR 范围内
        ;;
        and esi, [gs: PCB.MaxPhyAddrSelectMask]
        and edi, [gs: PCB.MaxPhyAddrSelectMask + 4]
        mov ecx, IA32_APIC_BASE
        rdmsr
        and esi, 0FFFFF000h                                             ; 去掉低 12 位
        and eax, 0FFFh                                                  ; 保持原来的 IA32_APIC_BASE 寄存器低 12 位
        or eax, esi
        mov edx, edi
        wrmsr
        ;;
        ;; 更新 apic 信息
        mov [gs: PCB.LapicPhysicalBase], eax
        mov [gs: PCB.LapicPhysicalBase + 4], edx
        pop ecx
        pop edx
        ret

;-----------------------------------------------------
; get_apic_physical_base()
; input:
;       none
; output:
;       edx:eax - 64 位地址值
; 描述:
;       得到 apic 的物理基址
;----------------------------------------------------
get_apic_physical_base:
        mov eax, [gs: PCB.LapicPhysicalBase]
        mov edx, [gs: PCB.LapicPhysicalBase + 4]
        ret



;----------------------------------------------------
; get_logical_processor_count()
; input:
;       none
; output:
;       eax - 最大逻辑处理器数
; 描述: 
;       获得 package(处理器)中的逻辑 processor 数量
;----------------------------------------------------
get_logical_processor_count:
        mov eax, [gs: PCB.MaxLogicalProcessor]
        ret



get_processor_core_count:
        mov eax, 4					; main-leaf
        mov ecx, 0					; sub-leaf
        cpuid
        shr eax, 26
        inc eax						; EAX[31:26] + 1
        ret
		

;---------------------------------------------------
; get_apic_initial_id() 
; input:
;       none
; output:
;       eax - inital apic id
; 描述: 
;       得到 initial apic id
;---------------------------------------------------
get_apic_id:
        mov eax, [gs: PCB.InitialApicId]
        ret


;---------------------------------------
; get_x2apic_id()
; output:
;       eax - 32 位的 apic id 值
;---------------------------------------
get_x2apic_id:
        push edx
        mov eax, 0Bh            ; 使用 0B leaf
        cpuid
        mov eax, edx			; 返回 x2APIC ID
        pop edx
        ret     
        
        

;-----------------------------------------------------------------
; init_processor_topology_info()
; input:
;       none
; output:
;       none
; 描述: 
;       枚举 CPUID 0B leaf, 来得到处理器拓扑信息, 更新 PCB 内的拓扑记录
;-------------------------------------------------------------------
init_processor_topology_info:
        push ecx
        push edx
        push ebx
        push ebp
        
        ;;
        ;; 检查是否支持 CUPID OB leaf
        ;;
        mov eax, [gs: PCB.MaxBasicLeaf]
        xor edx, edx
        cmp eax, 0Bh
        jb init_processor_topology_info.done

        ;;
        ;; 检查是否开启 paging, 没开启下 PCB 使用物理基址
        ;;
        mov eax, [gs: PCB.ProcessorStatus]
        test eax, CPU_STATUS_PG
        mov ebp, [gs: PCB.Base] 
        cmovz ebp, [gs: PCB.PhysicalBase]
        add ebp, PCB.ProcessorTopology

        xor edi, edi                                            ; edi = -1
        dec edi
                        
        ;;
        ;; 开始枚举: EAX = 0Bh, ECX = 0
        ;; 然后, 每次递增 ECX 值, 再执行 CPUID.0BH leaf
        ;;
        xor esi, esi                                            ; 开始的 sub-leaf 为 0
        
init_processor_topology_info.loop:	
        mov ecx, esi
        mov eax, 0Bh
        cpuid
        inc esi                                                 ; 递增 sub-leaf       
                
        ;;
        ;; 执行 CPUID.0BH/ECX 时, 返回 ECX[15:8] 为 level type
        ;;
        ;; 1) 输入 ECX = 0 时, 返回: ECX[7:0] = 0, ECX[15:8] = 1
        ;; 2) 输入 ECX = 1 时, 返回: ECX[7:0] = 1, ECX[15:8] = 2
        ;; 3) 输入 ECX = 2 时, 返回: ECX[7:0] = 2, ECX[15:8] = 0
        ;;        
        shr ecx, 8
        and ecx, 0FFh
        jz init_processor_topology_info.next                  ; 如果 level = 0, 停止枚举
        
        ;;
        ;; EAX[4:0] 返回 level 的 mask width 值
        ;;
        and eax, 01Fh                                           ; mask width
        
        ;;
        ;; 根据 level type 来进行处理:
        ;; 1) ECX[15:8] = 1 时, 属于 thread level
        ;; 2) ECX[15:8] = 2 时, 属于 core level
        ;; 
        cmp ecx, LEVEL_THREAD
        je @@1
        cmp ecx, LEVEL_CORE
        jne init_processor_topology_info.loop
        
        ;;
        ;; 属于 core level
        ;; 注意: 
        ;; 1) CoreMaskWidth 值包含了 ThreadMaskWidth 在内
        ;; 2) CoreSelectMask 值包启了 ThreadSelectMask 在内
        ;; 3) APIC ID 剩余的域归为 PackageId, 因此: PackageId = APIC ID >> CoreMaskWidth
        ;;　
        mov [ebp + TopologyInfo.CoreMaskWidth], al
        mov ecx, eax
        mov eax, edx
        shr eax, cl                                             ; PackageId = APIC ID >> CoreMaskWidth
        mov [ebp + TopologyInfo.PackageId], eax                 ; 更新 PackageId 值
        xor eax, eax
        shld eax, edi, cl                                       ; 初始 CoreSelectMask = -1 << CoreMaskWidth
        sub eax, [ebp + TopologyInfo.ThreadSelectMask]          ; CoreSelectMask = 初始 CoreSelectMask - ThreadSelectMask
        mov [ebp + TopologyInfo.CoreSelectMask], eax            ; 更新 CoreSelectMask 值
        and eax, edx                                            ; 初始 CoreId = CoreSelectMask & APIC ID
        mov cl, BYTE [ebp + TopologyInfo.ThreadMaskWidth]
        shr eax, cl                                             ; CoreId = 初始 CoreId >> ThreadMaskWidth
        mov [ebp + TopologyInfo.CoreId], al                     ; 更新 CoreId 值
        sub [ebp + TopologyInfo.CoreMaskWidth], cl              ; 更新 CoreMaskWidth 值
        
        ;;
        ;; 检测 logical processor 数量:
        ;; 1) 当属于 Core Level(ECX[15:8] = 2)时, EBX[15:0] 返回处理器物理 package 内有的 logical processor 数量
        ;;
        and ebx, 0FFFFh
        mov [ebp + TopologyInfo.LogicalProcessorPerPackage], ebx
        
        jmp init_processor_topology_info.loop
        
@@1:
        ;;
        ;; 属于 thread level
        ;;
        mov [ebp + TopologyInfo.ThreadMaskWidth], al            ; 更新 TheadMaskWidth 值
        mov ecx, eax
        xor eax, eax
        shld eax, edi, cl                                       ; ThreadSelectMask = -1 << ThreadMaskWidth
        mov [ebp + TopologyInfo.ThreadSelectMask], eax          ; 更新 ThreadSelectMask 值
        and eax, edx                                            ; ThreadId = APIC ID & ThreadSelectMask
        mov [ebp + TopologyInfo.ThreadId], al                   ; 更新 TheadId 值
        
        ;;
        ;; 检测 logical processor 数量:
        ;; 1) 当属于 Thread Level(ECX[15:8] = 1)时, EBX[15:0] 返回 core 内有的 logical processor 数量
        ;;
        and ebx, 0FFFFh
        mov [ebp + TopologyInfo.LogicalProcessorPerCore], ebx   ; 更新 logical Processor per core 值
        
        jmp init_processor_topology_info.loop
        
        
init_processor_topology_info.next:
        ;;
        ;; 更新剩余信息: 
        ;; 1) 32 位 Processor ID 值
        ;; 2) 处理器 logical processor 与 core 计数值
        ;;
        mov [ebp + TopologyInfo.ProcessorId], edx               ; 更新 ProcessorId(32 位的扩展 APIC ID 值)
        ;;
        ;; 处理器 logical processor 与 core 数量的计算方法: 
        ;; 1) LogicalProcessorCount = LogicalProcessorPerPackage
        ;; 2) ProcessorCoreCount = LogicalProcessorPerPackage / LogicalProcessorPerCore
        ;;
        mov eax, [ebp + TopologyInfo.LogicalProcessorPerPackage]
        mov [gs: PCB.LogicalProcessorCount], eax
        xor edx, edx
        mov ecx, [ebp + TopologyInfo.LogicalProcessorPerCore]
        ;div ecx
        mov [gs: PCB.ProcessorCoreCount], eax

init_processor_topology_info.done:        
        pop ebp
        pop ebx
        pop edx
        pop ecx
        ret

	
	
;-----------------------------------------------------
; send_eoi_command()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 发送 EOI 命令给 local apic
;-----------------------------------------------------
send_eoi_command:
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif 

        REX.Wrxb
        mov ebp, [ebp + PCB.LapicBase]
        mov DWORD [ebp + EOI], 0
        pop ebp
        ret

	
	
	
	
%if 0


;-----------------------------------------------------
; get_mask_width(): 得到 mask width, 使用于 xAPIC ID中
; input:
;       esi - maximum count(SMT 或 core 的最大 count 值)
; output:
;       eax - mask width
;-------------------------------------------------------
get_mask_width:
	xor eax, eax			; 清目标寄存器, 用于MSB不为1时
	bsr eax, esi			; 查找 count 中的 MSB 位
	ret
	
	
;------------------------------------------------------------------
; extrac_xapic_id(): 从 8 位的 xAPIC ID 里提取 package, core, smt 值
;-------------------------------------------------------------------	
extrac_xapic_id:
	jmp do_extrac_xapic_id
current_apic_id		dd	0	
do_extrac_xapic_id:	
	push ecx
	push edx
	push ebx

	call get_apic_id						; 得到 xAPIC ID 值
	mov [current_apic_id], eax				; 保存 xAPIC ID

;; 计算 SMT_MASK_WIDTH 和 SMT_SELECT_MASK	
	call get_logical_processor_count		; 得到 logical processor 最大计数值
	mov esi, eax
	call get_mask_width						; 得到 SMT_MASK_WIDTH
	mov edx, [current_apic_id]
	mov [xapic_smt_mask_width + edx * 4], eax
	mov ecx, eax
	mov ebx, 0xFFFFFFFF
	shl ebx, cl								; 得到 SMT_SELECT_MASK
	not ebx
	mov [xapic_smt_select_mask + edx * 4], ebx
	
;; 计算 CORE_MASK_WIDTH 和 CORE_SELECT_MASK 
	call get_processor_core_count
	mov esi, eax
	call get_mask_width						; 得到 CORE_MASK_WIDTH
	mov edx, [current_apic_id]	
	mov [xapic_core_mask_width + edx * 4], eax
	mov ecx, [xapic_smt_mask_width + edx * 4]
	add ecx, eax							; CORE_MASK_WIDTH + SMT_MASK_WIDTH
	mov eax, 32
	sub eax, ecx
	mov [xapic_package_mask_width + edx * 4], eax		; 保存 PACKAGE_MASK_WIDTH
	mov ebx, 0xFFFFFFFF
	shl ebx, cl
	mov [xapic_package_select_mask + edx * 4], ebx		; 保存 PACKAGE_SELECT_MASK
	not ebx									; ~(-1 << (CORE_MASK_WIDTH + SMT_MASK_WIDTH))
	mov eax, [xapic_smt_select_mask + edx * 4]
	xor ebx, eax							; ~(-1 << (CORE_MASK_WIDTH + SMT_MASK_WIDTH)) ^ SMT_SELECT_MASK
	mov [xapic_core_select_mask + edx * 4], ebx
	
;; 提取 SMT_ID, CORE_ID, PACKAGE_ID
	mov ebx, edx							; apic id
	mov eax, [xapic_smt_select_mask]
	and eax, edx							; APIC_ID & SMT_SELECT_MASK
	mov [xapic_smt_id + edx * 4], eax
	mov eax, [xapic_core_select_mask]
	and eax, edx							; APIC_ID & CORE_SELECT_MASK
	mov cl, [xapic_smt_mask_width]
	shr eax, cl								; APIC_ID & CORE_SELECT_MASK >> SMT_MASK_WIDTH
	mov [xapic_core_id + edx * 4], eax
	mov eax, [xapic_package_select_mask]
	and eax, edx							; APIC_ID & PACKAGE_SELECT_MASK
	mov cl, [xapic_package_mask_width]
	shr eax, cl
	mov [xapic_package_id + edx * 4], eax

	pop ebx
	pop edx
	pop ecx
	ret
	
		
;-------------------------------------------------------------
; extrac_x2apic_id(): 从 x2APIC_ID 里提取 package, core, smt 值
;-------------------------------------------------------------
extrac_x2apic_id:
	push ecx
	push edx
	push ebx

; 测试是否支持 leaf 11
	mov eax, 0
	cpuid
	cmp eax, 11
	jb extrac_x2apic_id_done
	
	xor esi, esi
	
do_extrac_loop:	
	mov ecx, esi
	mov eax, 11
	cpuid	
	mov [x2apic_id + edx * 4], edx				; 保存 x2apic id
	shr ecx, 8
	and ecx, 0xff								; level 类型
	jz do_extrac_subid
	
	cmp ecx, 1									; SMT level
	je extrac_smt
	cmp ecx, 2									; core level
	jne do_extrac_loop_next

;; 计算 core mask	
	and eax, 0x1f
	mov [x2apic_core_mask_width + edx * 4], eax	; 保存 CORE_MASK_WIDTH
	mov ebx, 32
	sub ebx, eax
	mov [x2apic_package_mask_width + edx * 4], ebx	; 保存 package_mask_width
	mov cl, al
	mov ebx, 0xFFFFFFFF							;
	shl ebx, cl									; -1 << CORE_MASK_WIDTH
	mov [x2apic_package_select_mask + edx * 4], ebx		; 保存 package_select_mask
	not ebx										; ~(-1 << CORE_MASK_WIDTH)
	xor ebx, [x2apic_smt_select_mask + edx * 4]					; ~(-1 << CORE_MASK_WIDTH) ^ SMT_SELECT_MASK
	mov [x2apic_core_select_mask + edx * 4], ebx					; 保存 CORE_SELECT_MASK
	jmp do_extrac_loop_next

;; 计算 smt mask	
extrac_smt:
	and eax, 0x1f
	mov [x2apic_smt_mask_width + edx * 4], eax					; 保存 SMT_MASK_WIDTH
	mov cl, al
	mov ebx, 0xFFFFFFFF
	shl ebx, cl									; (-1) << SMT_MASK_WIDTH
	not ebx										; ~(-1 << SMT_MASK_WIDTH)
	mov [x2apic_smt_select_mask + edx * 4], ebx					; 保存 SMT_SELECT_MASK

do_extrac_loop_next:
	inc esi
	jmp do_extrac_loop
	
;; 提取 SMT_ID, CORE_ID 以及 PACKAGE_ID
do_extrac_subid:
	mov eax, [x2apic_id + edx * 4]
	mov ebx, [x2apic_smt_select_mask]
	and ebx, eax								; x2APIC_ID & SMT_SELECT_MASK
	mov [x2apic_smt_id + eax * 4], ebx
	mov ebx, [x2apic_core_select_mask]
	and ebx, eax								; x2APIC_ID & CORE_SELECT_MASK
	mov cl, [x2apic_smt_mask_width]
	shr ebx, cl									; (x2APIC_ID & CORE_SELECT_MASK) >> SMT_MASK_WIDTH
	mov [x2apic_core_id + eax * 4], ebx
	mov ebx, [x2apic_package_select_mask]
	and ebx, eax								; x2APIC_ID & PACKAGE_SELECT_MASK
	mov cl, [x2apic_core_mask_width]
	shr ebx, cl									; (x2APIC_ID & PACKAGE_SELECT_MASK) >> CORE_MASK_WIDTH
	mov [x2apic_package_id + eax * 4], ebx		; 
	
extrac_x2apic_id_done:	
	pop ebx
	pop edx
	pop ecx
	ret
			

%endif	
		
;-----------------------------------
; read_esr(): 读 ESR 寄存器
;-----------------------------------
read_esr:
        push ebp
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif        
        REX.Wrxb
        mov eax, [ebp + PCB.LapicBase]
        mov DWORD [eax + ESR], 0		        ; 写 ESR 寄存器
        mov eax, [eax + ESR]
        pop ebp
	ret






