;*************************************************
;* mtrr.asm                                      *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************


;;
;; 这个模块是 mtrr 寄存器的例程
;;


;-----------------------------------------------------
; update_memory_type_manage_info()
; input:
;       none
; output:
;       none
; 描述: 
;       更新内存类型管理信息
;-----------------------------------------------------
update_memory_type_manage_info:
        push ecx
        push edx
        ;;
        ;; 检查 Memory Type Range Register 功能
        ;;
        mov ecx, IA32_MTRRCAP
        rdmsr
        and eax, 0FFh
        mov [gs: PCB.MemTypeRecordMaximum], eax
        pop edx
        pop ecx
        ret


;-----------------------------------------------------
; enable_mtrr()
; input:
;       none
; output:
;       none
;-----------------------------------------------------
enable_mtrr:
        push ecx
        push edx
        mov ecx, IA32_MTRR_DEF_TYPE
        rdmsr
        or eax, 0C00h                   ; MTRR enable, Fixed-Range MTRR enable
        wrmsr
        pop edx
        pop ecx
        ret




;-----------------------------------------------------
; init_memory_type_manage_record()
; input:
;       none
; output:
;       none
; 描述: 
;       初始化内存类型管理记录
;-----------------------------------------------------
init_memory_type_manage_record:
        push ebx
        push ecx
        mov eax, [gs: PCB.ProcessorStatus]
        test eax, CPU_STATUS_PG
        mov ebx, [gs: PCB.Base]
        cmovz ebx, [gs: PCB.PhysicalBase]
        mov DWORD [gs: PCB.MemTypeRecordTop], 0
        add ebx, PCB.MemTypeRecord
        
        xor eax, eax
        xor ecx, ecx
        mov [gs: PCB.MemTypeRecordTop], eax
init_memory_type_manage_record.loop:
        mov [ebx + MTMR.InUsed], al
        mov [ebx + MTMR.Type], al
        mov [ebx + MTMR.Start], eax
        mov [ebx + MTMR.Start + 4], eax
        mov [ebx + MTMR.Length], eax
        inc ecx
        cmp ecx, [gs: PCB.MemTypeRecordMaximum]
        jb init_memory_type_manage_record.loop
        pop ecx
        pop ebx
        ret



;-----------------------------------------------------
; init_memory_type_manane()
; input:
;       none
; output:
;       none
; 描述: 
;       初始化内存类型管理功能
;-----------------------------------------------------
init_memory_type_manage:
        call update_memory_type_manage_info
        call enable_mtrr
        call init_memory_type_manage_record
        ret



;-----------------------------------------------------------
; set_memory_range_type()
; input:
;       edx:eax - 内存起始位置
;       esi - 内存范围长度
;       edi - 内存类型
; output:
;       1 - successful, 0 - failure
; 描述: 
;       设置某个内存范围的 cache 类型
;-----------------------------------------------------------
set_memory_range_type:
        push ecx
        and eax, 0FFFFF000h                             ; 4K 边界
        and edx, [gs: PCB.MaxPhyAddrSelectMask + 4]
        and edi, 07h                                    ; 确保内存类型值 <= 7 
        mov ecx, [gs: PCB.MemTypeRecordTop]
        cmp ecx, [gs: PCB.MemTypeRecordMaximum]
        jae set_memory_range_type.done
        shl ecx, 1                                      ; ecx * 2
        or eax, edi
        add ecx, IA32_MTRR_PHYSBASE0
        wrmsr
        
        ;;
        ;; 将内存区域向上调整到以 4K 为单位的长度
        ;;
        add esi, 0FFFh
        and esi, 0FFFFF000h
        
        ;;
        ;; Rang Mask 的计算方法(以 8K 长度例)
        ;;
        ;; 1) 长度值(8k) - 1 = 2000h - 1 = 1FFFh
        ;; 2) MaxPhyAddrSelectMask 低 32 位 - 1FFFh = FFFFE000h
        ;; 3) MaxPhyAddrSelectMask[63:32]:FFFFE000h 就是最终的 Rang Mask 值
        ;;
        dec esi                                         ; 求长度 mask 位
        mov eax, [gs: PCB.MaxPhyAddrSelectMask]         ; select mask 低 32 位
        mov edx, [gs: PCB.MaxPhyAddrSelectMask + 4]     ; select mask 高 32 位
        sub eax, esi                                    ; 得出 Rang Mask 值
        bts eax, 11                                     ; valid = 1
        mov ecx, [gs: PCB.MemTypeRecordTop]
        shl ecx, 1                                      ; ecx * 2
        add ecx, IA32_MTRR_PHYSMASK0
        wrmsr
        
        ;;
        ;; 更新 Top 指针值
        ;;
        inc DWORD [gs: PCB.MemTypeRecordTop]
        mov al, 1
set_memory_range_type.done:        
        movzx eax, al
        pop ecx
        ret


        
