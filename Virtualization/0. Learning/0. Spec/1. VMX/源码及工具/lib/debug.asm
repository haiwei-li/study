;*************************************************
;* debug.asm                                     *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************

;*
;* 这是为支持 debug 功能定义的函数库
;*

LBR_FORMAT32                    EQU             0
LBR_FORMAT64_LIP                EQU             1
LBR_FORMAT64_EIP                EQU             2
LBR_FORMAT64_MISPRED            EQU             3
PEBS_FORMAT_ENH                 EQU             1

;;
;; 定义 debug 单元状态码
;;
STATUS_BTS_SUCCESS                      EQU     0
STATUS_BTS_ERROR                        EQU     1
STATUS_BTS_UNAVAILABLE                  EQU     2
STATUS_BTS_NOT_READY                    EQU     4
STATUS_BTINT_NOT_READY                  EQU     8
STATUS_DS_NOT_READY                     EQU     10h



;-------------------------------------------------
; init_debug_store_unit()
; input:
;       none
; output:
;       none
; 描述: 
;       初始化处理器的 debug store 功能单元
;-------------------------------------------------
init_debug_store_unit:
        push ebx
        push ecx
        push edx
        
        mov ebx, [gs: PCB.Base]       
        
        ;;
        ;; 如果属于 AMD 平台则退出
        ;;
        mov eax, [gs: PCB.Vendor]
        cmp eax, VENDOR_AMD
        je init_debug_unit.done
                

        ;;
        ;; 检查是否支持 64 位 DS 
        ;;
        mov eax, [gs: PCB.DebugCapabilities]
        test eax, DEBUG_DS64_AVAILABLE
        jnz init_debug_unit.ds64
        
        ;;
        ;; 设置 DS 管理记录指针
        ;;
        xor ecx, ecx
        lea eax, [ebx + PCB.DSManageRecord]                     ; DS 管理记录基址
init_debug_unit.loop1:        
        mov [ebx + PCB.BtsBasePointer + ecx * 8], eax
        mov DWORD [ebx + PCB.BtsBasePointer + ecx * 8 + 4], 0
        add eax, 4
        inc ecx
        cmp ecx, 12
        jb init_debug_unit.loop1
        
        ;;
        ;; 32 位格式的 DS Size 值
        ;; 1) 每条 BTS 记录为 12 字节
        ;; 2) 每条 PEBS 记录为 40 字节
        ;;
        mov DWORD [gs: PCB.BtsRecordSize], 12
        mov DWORD [gs: PCB.PebsRecordSize], 40
                
        jmp init_debug_unit.next

        
init_debug_unit.ds64:
        ;;
        ;; 64 位格式的 DS size 值
        ;; 1) 每条 BTS 记录为 24 字节
        ;; 2) 增强的 PEBS 记录为 176 字节
        ;; 3) 普通的 PEBS 记录为 144 字节
        ;;
        mov DWORD [gs: PCB.BtsRecordSize], 24
        
        ;;
        ;; 检查是否支持增强的 PEBS 记录
        ;;
        test eax, DEBUG_PEBS_ENH_AVAILABLE
        mov ecx, 144
        mov edx, 176
        cmovnz ecx, edx
        mov [gs: PCB.PebsRecordSize], ecx
      
        ;;
        ;; 设置 DS 管理记录指针
        ;;         
        xor ecx, ecx
        lea eax, [ebx + PCB.DSManageRecord]                     ; DS 管理记录基址
init_debug_unit.loop2:        
        mov [ebx + PCB.BtsBasePointer + ecx * 8], eax
        mov DWORD [ebx + PCB.BtsBasePointer + ecx * 8 + 4], 0
        add eax, 8
        inc ecx
        cmp ecx, 12
        jb init_debug_unit.loop2
        
        
init_debug_unit.next:
        ;;
        ;; 设置 DS 区域
        ;;
        call set_debug_store_area
        
init_debug_unit.done:        
        pop ecx
        pop edx
        pop ebx
        ret


;-------------------------------------------------
; get_bts_buffer_base()
; input:
;       none
; output:
;       成功时返回 Bts buffer, 　失败时返回 0
; 描述: 
;       得到 BTS buffer 基址(在开启 paging 后使用)
;-------------------------------------------------
get_bts_buffer_base:
        push ecx
        xor ecx, ecx
        mov eax, [fs: SDA.BtsBufferSize]                ; bts buffer 长度
        lock xadd [fs: SDA.BtsPoolBase], eax            ; 得到 bts buffer 地址
        cmp eax, [fs: SDA.BtsPoolTop]
        cmovae eax, ecx
        pop ecx
        ret


;-------------------------------------------------
; get_pebs_buffer_base()
; input:
;       none
; output:
;       成功时返回 PEBS buffer, 　失败时返回 0
; 描述: 
;       得到 PEBS buffer 基址(在开启 paging 后使用)
;-------------------------------------------------
get_pebs_buffer_base:
        push ecx
        xor ecx, ecx
        mov eax, [fs: SDA.PebsBufferSize]               ; pebs buffer 长度
        lock xadd [fs: SDA.PebsPoolBase], eax           ; 得到 pebs buffer 地址
        cmp eax, [fs: SDA.PebsPoolTop]
        cmovae eax, ecx
        pop ecx
        ret





;------------------------------------------------------
; enable_bts()
; input:
;       none
; output:
;       0 - succssful, error code - failure
; 描述:
;       开启 bts 机制, 成功后返回 0, 失败返回错误码
;-----------------------------------------------------
enable_bts:
enable_branch_trace_store:
        push ecx
        push edx
        push ebx
        
        mov eax, STATUS_BTS_SUCCESS
        
        ;;
        ;; 检查是否已经开启
        ;; 
        mov ebx, [gs: PCB.DebugStatus]
        test ebx, DEBUG_STATUS_BTS_ENABLE
        jnz enable_branch_trace_store.done
        
        ;;
        ;; 检查 BTS 是否可用
        ;;
        mov eax, [gs: PCB.DebugCapabilities]
	test eax, DEBUG_BTS_AVAILABLE
        mov eax, STATUS_BTS_UNAVAILABLE
	jz enable_branch_trace_store.done
        
        ;;
        ;; 检查 BTS 区域是否设置好
        ;;
        test ebx, DEBUG_STATUS_BTS_READY
        mov eax, STATUS_BTS_NOT_READY
        jz enable_branch_trace_store.done
        
        ;;
        ;; 开启 IA32_DEBUGCTL[6].TR 和 IA32_DEBUGCTL[7].BTS 位
        ;;
	mov ecx, IA32_DEBUGCTL
	rdmsr
	or eax, 0C0h					; TR=1, BTS=1
	wrmsr
        ;;
        ;; 更新 debug 状态
        ;;
        or ebx, DEBUG_STATUS_BTS_ENABLE
        mov [gs: PCB.DebugStatus], ebx
        mov eax, STATUS_BTS_SUCCESS
        
enable_branch_trace_store.done:	
        pop ebx
        pop edx
        pop ecx
	ret
	

;---------------------------------------------------
; enable_btint()
; input:
;       none
; output:
;       eax - status
; 描述: 
;       开启 BTINT 机制, 应在 enable_bts() 之后调用
; 示例: 
;       call enable_bts                 ; 开启 BTS 机制
;       ...
;       call enable_btint               ; 启用 BTINT
;----------------------------------------------------
enable_btint:
        push ecx
        push edx
        push ebx
        
        mov eax, STATUS_BTS_SUCCESS
        
        ;;
        ;; 检查 BTINT 是否已经开启
        ;; 
        mov ebx, [gs: PCB.DebugStatus]
        test ebx, DEBUG_STATUS_BTINT_ENABLE
        jnz enable_bts_with_int.done
        
        ;;
        ;; 检查 BTS 是否准备好
        ;;
        test ebx, DEBUG_STATUS_BTS_READY
        mov eax, STATUS_BTS_NOT_READY
        jz enable_bts_with_int.done
        
        ;;
        ;; 检查 BTINT 机制是否准备好
        ;;
        test ebx, DEBUG_STATUS_BTINT_READY
        jnz enable_bts_with_int.next
        
        ;;
        ;; 更新 DS 管理记录的设置: BTS threadold <= BTS maximum
        ;;
        mov eax, [gs: PCB.BtsMaximumPointer]
        mov eax, [eax]
        mov ebx, [gs: PCB.BtsThresholdPointer]
        cmp [ebx], eax                                  ; bts thresold >  bts maximum
        cmovb eax, [ebx]
        mov [ebx], eax        
        
        or DWORD [gs: PCB.DebugStatus], DEBUG_STATUS_BTINT_READY
        
enable_bts_with_int.next:        
        ;;
        ;; 开启 IA32_DEBUGCTL[8].BTINT 位
        ;;
	mov ecx, IA32_DEBUGCTL
	rdmsr
	or eax, 0100h                                   ; BTINT = 1
	wrmsr

        ;;
        ;; 更新 Debug 状态
        ;; 
        or DWORD [gs: PCB.DebugStatus], DEBUG_STATUS_BTINT_ENABLE
        
enable_bts_with_int.done:        
        pop ebx
        pop edx
        pop ecx
        ret
	
	
	
;--------------------------------
; disable_bts(): 关闭 BTS 功能
;--------------------------------
disable_bts:
        push ecx
        push edx
        push ebx
        ;;
        ;; 检查是否已开启
        ;;
        mov ebx, [gs: PCB.DebugStatus]
        test ebx, DEBUG_STATUS_BTS_ENABLE
        jz disable_bts.done
        
	mov ecx, IA32_DEBUGCTL
	rdmsr
	and eax, 0FF3Fh                                 ; TR=0, BTS=0
	wrmsr
       
        ;;
        ;; 更新 debug 状态
        ;;
        and ebx, ~DEBUG_STATUS_BTS_ENABLE
        mov [gs: PCB.DebugStatus], ebx
disable_bts.done:        
        pop ebx
        pop edx
        pop ecx
	ret



;--------------------------------
; disable_btint(): 关闭 BTINT 功能
;--------------------------------
disable_btint:
        push ecx
        push edx
        push ebx
        mov ebx, [gs: PCB.DebugStatus]
        test ebx, DEBUG_STATUS_BTINT_ENABLE
        jz disable_btint.done
        
        mov ecx, IA32_DEBUGCTL
        rdmsr
        btr eax, 8                                      ; BTINT = 0
        wrmsr
        
        ;;
        ;; 更新 DS 管理记录设置
        ;;
        mov ebx, [gs: PCB.BtsThresholdPointer]
        mov eax, [gs: PCB.BtsMaximumPointer]
        mov eax, [eax]
        add eax, [gs: PCB.BtsRecordSize]
        cmp [ebx], eax                                  ; bts thresold >  bts maximum
        cmovae eax, [ebx]
        mov [ebx], eax
        
        ;;
        ;; 更新 debug 状态
        ;;
        and DWORD [gs: PCB.DebugStatus], ~DEBUG_STATUS_BTINT_ENABLE
        and DWORD [gs: PCB.DebugStatus], ~DEBUG_STATUS_BTINT_READY
disable_btint.done:
        pop ebx
        pop edx
        pop ecx
        ret



;------------------------
; support_debug_store(): 查询是否支持 DS 区域
; output:
;       1-support, 0-no support
;------------------------
support_ds:
support_debug_store:
        push edx
        ;;
        ;; 检查 CPUID.01H:EDX[21].Branch_Trace_Store 位
        ;;
        mov edx, [gs: PCB.FeatureEdx]
	bt edx, 21
	setc al
	movzx eax, al
        pop edx
	ret

;---------------------------------------------
; support_ds64: 查询是否支持 DS save 64 位格式
; output:
;       1-support, 0-no support
;---------------------------------------------
support_ds64:
        push ecx
        ;;
        ;; 检查 CPUID.01H.ECX[2].DS64 位
        ;;
        mov ecx, [gs: PCB.FeatureEcx]
	bt ecx, 2                               ; 64-bit DS AREA
	setc al
	movzx eax, al
        pop ecx
	ret


;-------------------------------------------------
; available_branch_trace_store()
; input:
;       none
; output:
;       1 - available, 0 - unavailable
;-------------------------------------------------
available_bts:
available_branch_trace_store:
        push edx
        push ecx
        ;;
        ;; 检查 CPUID.01H:EDX[21].Branch_Trace_Store 位
        ;;
        mov edx, [gs: PCB.FeatureEdx]
        bt edx, 21
	setc al
	jnc available_branch_trace_store.done
        
        ;;
        ;; 检查 IA32_MISC_ENABLE[11].BTS_Unavailable 位
        ;;
	mov ecx, IA32_MISC_ENABLE
	rdmsr
	bt eax, 11
	setnc al
available_branch_trace_store.done:	
	movzx eax, al
        pop ecx
        pop edx
	ret


;--------------------------------------
; avaiable_pebs(): 是否支持 PEBS 机制
; output:
;       1-available, 0-unavailable
;--------------------------------------
available_pebs:
        push edx
        push ecx

        ;;
        ;; 检查 CPUID.01H:EDX[21].Branch_Trace_Store 位
        ;;
        mov edx, [gs: PCB.FeatureEdx]
        bt edx, 21
	setc al
	jnc available_pebs.done
        
        ;;
        ;; 检查 IA32_MISC_ENABLE[12].PEBS_Unavailable 位
        ;;
	mov ecx, IA32_MISC_ENABLE
	rdmsr
	bt eax, 12
	setnc al
available_pebs.done:
	movzx eax, al
        pop ecx
        pop edx
	ret


;------------------------------------------------------------
; support_enhancement_pebs(): 检测是否支持增强的 PEBS 记录
; output:
;       1-support, 0-no support
;-----------------------------------------------------------
support_enhancement_pebs:
        ;;
        ;; 检查 PerfCapabilities[8] 位
        ;;        
        mov eax, [gs: PCB.PerfCapabilities]
	test eax, PERF_PEBS_ENH_AVAILABLE
	sete al
	movzx eax, al
	ret
        

;----------------------------------------------
; init_debug_capabilities_info()
; input:
;       none
; output:
;       none
; 描述: 
;       更新处理器 debug 相关的功能记录
;----------------------------------------------
init_debug_capabilities_info:
        push ebx
        mov ebx, [gs: PCB.DebugCapabilities]
        call available_bts
        test eax, eax
        jz init_debug_capabilities_info.@1
        or ebx, DEBUG_BTS_AVAILABLE
        
init_debug_capabilities_info.@1:        
        call support_ds64
        test eax, eax
        jz init_debug_capabilities_info.@2
        or ebx, DEBUG_DS64_AVAILABLE
        
init_debug_capabilities_info.@2:                
        call available_pebs
        test eax, eax
        jz init_debug_capabilities_info.@3
        or ebx, DEBUG_PEBS_AVAILABLE
        
init_debug_capabilities_info.@3:        
        call support_enhancement_pebs
        test eax, eax
        jz init_debug_capabilities_info.@4
        or ebx, DEBUG_PEBS_ENH_AVAILABLE

init_debug_capabilities_info.@4:        
        ;;
        ;; 检查受限的 BTS, CPUID.01H:ECX[4].DS_CPL 位
        ;;
        mov eax, [gs: PCB.FeatureEcx]
        bt eax, 4
        jnc init_debug_capabilities_info.done
        or ebx, DEBUG_DS_CPL_AVAILABLE
        
init_debug_capabilities_info.done:        
        mov [gs: PCB.DebugCapabilities], ebx
        pop ebx
        ret



;----------------------------------------------
; get_lbr_format()
; input:
;       none
; output:
;       eax - lbr format
;----------------------------------------------
get_lbr_format:
        mov eax, [gs: PCB.PerfCapabilities]
        and eax, 3Fh
        ret



;-------------------------------------------
; set_debug_store_area(): 设置 DS 区域基地址
; input:
;       none
; output:
;       status code
;-------------------------------------------
set_debug_store_area:
        push ecx
        push edx
        
        ;;
        ;; 设置 IA32_DS_AERA 寄存器
        ;;
	mov ecx, IA32_DS_AREA
        mov eax, [gs: PCB.Base]
        add eax, PCB.DSManageRecord                     ; DS 管理记录基址
	xor edx, edx
	wrmsr
        
        ;;
        ;; 更新 debug 状态
        ;;
        or DWORD [gs: PCB.DebugStatus], DEBUG_STATUS_DS_READY
        
        ;;
        ;; 设置 DS 管理记录
        ;;
        call set_ds_management_record
        pop edx
        pop ecx
	ret


;----------------------------------------------------------------
; set_ds_management_record() 设置管理区记录
; input:
;       none
; output:
;       status code
; 描述:
;       缺省情况下, 配置为环形回路 buffer 形式, 
;       threshold 值大于 maximum, 避免产生 DS buffer 溢出中断
;--------------------------------------------------------------------
set_ds_management_record:
	push ebx
        push ecx
        push edx
             
        ;;
        ;; 初始 debug 状态
        ;;
        mov edx, [gs: PCB.DebugStatus]
        and edx, ~(DEBUG_STATUS_BTS_READY | DEBUG_STATUS_PEBS_READY)
        mov [gs: PCB.DebugStatus], edx
        
        ;;
        ;; 分配一个 BTS buffer, 设置 BTS buffer Base 值
        ;;
        call get_bts_buffer_base
        mov esi, eax
        test eax, eax
        mov eax, STATUS_NO_RESOURCE
        jz set_ds_management_record.done                                ; 分配 BTS buffer 失败

        ;;
        ;; 设置 bts 管理记录, 初始状态下: 
        ;; 1) BTS base = BTS buffer
        ;; 2) BTS index = BTS buffer
        ;; 3) BTS maximum = BTS record size * maximum
        ;; 4) BTS threshold = BTS maximum + BTS record size(即 BtsMaximum 下一条记录)
        ;;
        mov ebx, [gs: PCB.BtsBasePointer]
        mov [ebx], esi
        mov ebx, [gs: PCB.BtsIndexPointer]
        mov [ebx], esi
        mov eax, [gs: PCB.BtsRecordSize]
        imul eax, [fs: SDA.BtsRecordMaximum]
        add eax, [ebx]
        mov ebx, [gs: PCB.BtsMaximumPointer]
        mov [ebx], eax
        add eax, [gs: PCB.BtsRecordSize]                                ; Bts threshold 值 = Bts maximum + 1
        mov ebx, [gs: PCB.BtsThresholdPointer]
        mov [ebx], eax
      
        ;;
        ;; 设置 pebs 管理记录, 初始状态下: 
        ;; 1) PEBS base = PEBS buffer
        ;; 2) PEBS index = PEBS buffer
        ;; 3) PEBS maximum = PEBS record size * maximum
        ;; 4) PEBS threshold = PEBS maximum
        ;;
        call get_pebs_buffer_base
        mov ebx, [gs: PCB.PebsBasePointer]
        mov [ebx], eax
        mov ebx, [gs: PCB.PebsIndexPointer]
        mov [ebx], eax
        mov eax, [gs: PCB.PebsRecordSize]
        imul eax, [fs: SDA.PebsRecordMaximum]
        add eax, [ebx]
        mov ebx, [gs: PCB.PebsMaximumPointer]
        mov [ebx], eax
        mov ebx, [gs: PCB.PebsThresholdPointer]
        mov [ebx], eax        

        ;;
        ;; 更新 debug 状态
        ;;
        test edx, DEBUG_STATUS_DS_READY
        mov eax, STATUS_DS_NOT_READY
        jz set_ds_management_record.done
        
        or edx, DEBUG_STATUS_BTS_READY | DEBUG_STATUS_PEBS_READY
        and edx, ~DEBUG_STATUS_BTINT_READY
        mov [gs: PCB.DebugStatus], edx
        
set_ds_management_record.done:	
        ;;
        ;; 清 PEBS buffer 溢出指示位 OvfBuffer
        ;;
        RESET_PEBS_BUFFER_OVERFLOW
        
        pop ebx
        pop edx
        pop ecx
	ret





;--------------------------------------------------------------
; check_bts_buffer_overflow(): 检查是否发生 BTS buffer 溢出
; input:
;       none
; output:
;       1 - yes, 0 - no
;--------------------------------------------------------------
test_bts_buffer_overflow:
check_bts_buffer_overflow:
        mov eax, [gs: PCB.BtsIndexPointer]
        mov eax, [eax]                          ; 读 BTS index 值
        mov esi, [gs: PCB.BtsThresholdPointer]
        cmp eax, [esi]                          ; 比较 index >= threshold ?
        setae al
        movzx eax, al
        ret


;-----------------------------------------
; set_bts_buffer_size(): 设置 BTS buffer 记录数
; input:
;       esi - BTS buffer 容纳的记录数
;-----------------------------------------
set_bts_buffer_size:
        push ecx
        push edx

        mov ecx, [gs: PCB.BtsRecordSize]
        
        ;;
        ;; 设置 bts maximum 值
        ;;                
        imul esi, ecx                           ; count * sizeof(bts_record)
        mov edx, [gs: PCB.BtsMaximumPointer]
        mov ebx, [gs: PCB.BtsBasePointer]
        mov eax, [ebx]                          ; 读取 BTS base 值
        add esi, eax                            ; base + buffer size
        mov [edx], esi                          ; 设置 bts maximum 值

        ;;
        ;; 检查 bts index 值
        ;;
        mov edi, [gs: PCB.BtsIndexPointer]
        mov eax, [edi]
        cmp eax, esi                          ; 如果 index > maximum 
        cmovae eax, [ebx]
        mov [edi], eax
        
        ;;
        ;; 设置 bts threshold 值
        ;;
        add esi, ecx
        mov eax, [gs: PCB.DebugStatus]
        test eax, DEBUG_STATUS_BTINT_ENABLE
        mov edi, [gs: PCB.BtsThresholdPointer]
        cmovnz esi, [edx]
        mov [edi], esi

        pop edx
        pop ecx
        ret




;--------------------------------------------------
; set_pebs_buffer_size(): 设置 PEBS buffer 可容纳数
; input:
;       esi - PEBS buffer 容纳的记录数
;---------------------------------------------------
set_pebs_buffer_size:
        push ecx
        mov ecx, [gs: PCB.PebsRecordSize]
        imul esi, ecx
        mov eax, [gs: PCB.PebsBasePointer]
        add esi, [eax]
        mov ecx, [eax]
        mov eax, [gs: PCB.PebsMaximumPointer]
        mov [eax], esi
        mov eax, [gs: PCB.PebsThresholdPointer]
        mov [eax], esi
        mov eax, [gs: PCB.PebsIndexPointer]
        cmp [eax], esi
        cmovb ecx, [eax]
        mov [eax], ecx
        pop ecx
        ret


;----------------------------------------------
; reset_bts_index(): 重置 BTS index 为 base 值
; input:
;       none
; output:
;       none
;----------------------------------------------
reset_bts_index:
        mov edi, [gs: PCB.BtsIndexPointer]
        mov esi, [gs: PCB.BtsBasePointer]
        mov esi, [esi]                                  ; 读取 BTS base 值
        mov [edi], esi                                  ; BTS index = BTS base
        ret


;----------------------------------------------
; reset_pebs_index(): 重置 PEBS index 值为 base
; input:
;       none
; output:
;       none
;----------------------------------------------
reset_pebs_index:
        mov edi, [gs: PCB.PebsIndexPointer]       
        mov esi, [gs: PCB.PebsBasePointer]
        mov esi, [esi]                                  ; 读取 PEBS base 值
        mov [edi], esi                                  ; PEBS index = PEBS base
        mov [gs: PCB.PebsBufferIndex], esi              ; 更新保存的 PEBS index 值
        ret


;------------------------------------------------------------
; update_pebs_index_track(): 更新PEBS index 的轨迹
; input:
;       none
; output:
;       none
; 描述: 
;       更新 [gs: PCB.PebsBufferIndex]变量的值, 保持检测 PEBS 中断
;       [gs: PCB.PebsBufferIndex] 记录着"当前"的 PEBS index 值
;------------------------------------------------------------
update_pebs_index_track:
        mov eax, [gs: PCB.PebsIndexPointer]
        mov eax, [eax]                                  ; 读当前 pebs index 值
        mov [gs: PCB.PebsBufferIndex], eax              ; 更新保存的 pebs index 值        
        ret


;------------------------------------------
; get_bts_base(): 读取 BTS buffer base 值
; output:
;       eax - BTS base
;-------------------------------------------
get_bts_base:
	mov eax, [gs: PCB.BtsBasePointer]
	mov eax, [eax]
	ret


;------------------------------------------
; get_bts_index(): 读取 BTS buffer index 值
; output:
;       eax - BTS index
;-------------------------------------------
get_bts_index:
	mov eax, [gs: PCB.BtsIndexPointer]
	mov eax, [eax]
	ret

;------------------------------------------
; get_bts_maximum(): 读取 BTS buffer maximum 值
; output:
;       eax - BTS maximum
;-------------------------------------------
get_bts_maximum:
	mov eax, [gs: PCB.BtsMaximumPointer]
	mov eax, [eax]
	ret

;----------------------------------------------------
; get_bts_threshold(): 读取 BTS buffer threshold值
; output:
;       eax - BTS threshold
;----------------------------------------------------
get_bts_threshold:
	mov eax, [gs: PCB.BtsThresholdPointer]
	mov eax, [eax]
	ret


;-------------------------------------------
; set_bts_index(): 设置 BTS index 值
; input:
;       esi - BTS index
;-------------------------------------------
set_bts_index:
	mov eax, [gs: PCB.BtsIndexPointer]
	mov [eax], esi
	ret


;---------------------------------------------------------
; get_last_pebs_record_pointer()
; output:
;       eax - PEBS 记录的地址值, 返回 0 时表示无 PEBS 记录
;----------------------------------------------------------
get_last_pebs_record_pointer:
        mov eax, [gs: PCB.PebsIndexPointer]
        mov esi, [eax]
        mov eax, [gs: PCB.PebsBasePointer]
        cmp esi, [eax]                          ; index > base ?
        seta al
        movzx eax, al
        jbe get_last_pebs_record_pointer.done
        sub esi, [gs: PCB.PebsRecordSize]
        mov eax, esi
get_last_pebs_record_pointer.done:
        ret

