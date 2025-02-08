;*************************************************
; page64.asm                                     *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************



%include "..\inc\page.inc"



;;
;; page64 模块说明: 
;; 1) page64 模块代码前半部分为 legacy 下的 32 位而写, 在未进入 long mode 之前使用
;; 2) 后半部分为 64-bit 代码而写, 在进入 64-bit 环境后使用
;; 3) legacy 代码后缀使用 "32", 64-bit 代码后缀使用 "64"
;;





;;
;; 定义 page table entry 标志位, 对应 entry[11:9]
;;

PTE_INVALID                     EQU             0
PTE_VALID                       EQU             800h

;;
;; pte 检查有效性标志(PTE_VALID | P)
;;
VALID_FLAGS                     EQU             801h



        bits 32

        

;---------------------------------------------------------------
; clear_2m_for_longmode_ppt()
; input:
;       none
; output:
;       none
; 注意: 
;       1) 在初始化页转换表结构前调用
;       2) 在 legacy 模式下执行
;       3) 在 init_longmode_basic_page() 内部使用
;---------------------------------------------------------------
clear_2m_for_longmode_ppt:
        push ecx
        ;;
        ;; 清 PPT 表区域, 共 2M 空间
        ;;
        mov esi, [fs: SDA.PptPhysicalBase64]
        mov edi, 200000h / 1000h
        call clear_4k_page_n32
        pop ecx
        ret




;---------------------------------------------------------------
; get_pt_physical_base()
; intput:
;       none
; output:
;       edx:eax - physical address of PT 
; 描述: 
;       1) 在 PT Pool 里分配一个 4K 的物理块, 作为 PT 或 PDT　
;       2) 此函数在 legacy 模式下使用
;---------------------------------------------------------------
get_pt_physical_base32:
        push ebx  
        ;;
        ;; 在 PtPoolPhysicalBase 池里分配 PT 物理地址
        ;; 1) 现在处于 stage1 阶段, 使用PtPool物理地址
        ;;    
        mov esi, SDA_PHYSICAL_BASE + SDA.PtPoolPhysicalBase
        xor edx, edx                                            ; 分配粒度为 4K
        mov eax, 4096
        call locked_xadd64                                      ; edx:eax = Pt pool address
        mov ebx, eax
        mov esi, eax
        call clear_4k_page32                                    ; 清空区域
        mov eax, ebx
        pop ebx
        ret



        
        
;---------------------------------------------------------------
; get_pte_virtual_address():
; input:
;       edx:eax - virtual address
; output:
;       edx:eax - PTE address
; 描述: 
;       在 legacy 模式下使用
;---------------------------------------------------------------
get_pte_virutal_address32:
        push ecx
        push ebx
        
        and edx, 0FFFFh                                         ; 清地址高 16 位
        and eax, 0FFFFF000h                                     ; 清地址低 12 位

        ;;
        ;; offset = va >> 12 * 8
        ;;
        mov ecx, (12 - 3)
        call shr64
        
        ;;
        ;; offset + PtBase64
        ;;
        mov ecx, [fs: SDA.PtBase64 + 4]
        mov ebx, [fs: SDA.PtBase64]
        call addition64
        
        pop ebx
        pop ecx
        ret
        


;---------------------------------------------------------------
; get_pxe_offset32():
; input:
;       edx:eax - va
; output:
;       edx:eax - offset
; 描述: 
;       得到 PXT entry 的 offset 值
; 注意: 
;       在 legacy 模式下使用
;---------------------------------------------------------------
get_pxe_offset32:
        push ecx
        and edx, 0FFFFh                                         ; 清 va 高 16 位
        mov ecx, (12 + 9 + 9 + 9)                               ; index = va >> 39
        call shr64
        mov ecx, 3
        call shl64                                              ; offset = index << 3
        pop ecx
        ret

;---------------------------------------------------------------
; get_ppe_offset32():
; input:
;       edx:eax - va
; output:
;       edx:eax - offset
; 描述: 
;       得到 PPT entry 的 offset 值
;       在 legacy 下使用
;---------------------------------------------------------------
get_ppe_offset32:
        push ecx
        and edx, 0FFFFh                                         ; 清 va 高 16 位
        mov ecx, (12 + 9 + 9)                                   ; index = va >> 30
        call shr64
        mov ecx, 3
        call shl64                                              ; offset = index << 3
        pop ecx
        ret

        


;---------------------------------------------------------------
; get_pde_offset32():
; input:
;       edx:eax - va
; output:
;       edx:eax - offset
; 描述: 
;       得到 PDT entry 的 offset 值
;       在 legacy 下使用
;---------------------------------------------------------------
get_pde_offset32:
        push ecx
        and edx, 0FFFFh                                         ; 清 va 高 16 位
        mov ecx, (12 + 9)                                       ; index = va >> 21
        call shr64
        mov ecx, 3
        call shl64                                              ; offset = index << 3
        pop ecx
        ret

;---------------------------------------------------------------
; get_pde_index()
; input:
;       edx:eax - va
; output:
;       eax - index
; 描述: 
;       1) 在 legacy 下使用
;---------------------------------------------------------------
get_pde_index32:
        shr eax, (12 + 9)
        and eax, 1FFh
        shl eax, 3                                              ; (va & PDE_MASK) >> 21 << 3
        ret




;---------------------------------------------------------------
; get_pte_offset32():
; input:
;       edx:eax - va
; output:
;       edx:eax - offset
; 描述: 
;       得到 PT entry 的 offset 值
;       在 legacy 下使用
;---------------------------------------------------------------
get_pte_offset32:
        push ecx
        and edx, 0FFFFh                                         ; 清 va 高 16 位
        and eax, 0FFFFF000h                                     ; 清 va 低 12 位
        mov ecx, 12 - 3                                         ; va >> 12 << 3
        call shr64
        pop ecx
        ret

;---------------------------------------------------------------
; get_pte_index32()
; input:
;       edx:eax - va
; output:
;       eax - index
; 描述: 
;       1) 在 legacy 下使用
;---------------------------------------------------------------
get_pte_index32:
        shr eax, 12
        and eax, 1FFh
        shl eax, 3                                              ; (va & PTE_MASK) >> 12 << 3
        ret




        
        
        
;---------------------------------------------------------------
; map_longmode_page_transition_table32()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 此函数用来映射 PXT, PPT, PDT 区域
;       2) init_longmode_page() 执行其它映射前调用
;       3) 此函数使用在 legacy 模式下
;---------------------------------------------------------------
map_longmode_page_transition_table32:
        push ecx
        push ebx
        push edx
        
        ;;
        ;; 清 2M 的 PPT 表物理区域
        ;;
        call clear_2m_for_longmode_ppt

        ;;
        ;; 需要写入的PPT 物理地址值(200_0000h)
        ;;
        mov eax, [fs: SDA.PptPhysicalBase64]
        mov edx, [fs: SDA.PptPhysicalBase64 + 4]
        and eax, ~0FFFh
        and edx, [gs: PCB.MaxPhyAddrSelectMask + 4]
                
        ;;
        ;; 4K 的 PXT 表物理区域(21ed000h - 21edfffh)
        ;;
        mov ebx, [fs: SDA.PxtPhysicalBase64]

        ;;
        ;; 从高往下写入 21ff000h - 2000000h
        ;;
        add eax, (200000h - 1000h)                      ; 起始写入 21ff000h 值
        mov ecx, (1000h - 8)                            ; 从 21edff8h 开始写
        or eax, VALID_FLAGS | RW                        ; Supervisor, Read/Write, Present, PTE valid
        mov esi, VALID_FLAGS | US | RW                  ; User, Read/Write, Prsent, PTE valid
        
map_longmode_page_transition_table32.loop:
        cmp ecx, 800h
        jae map_longmode_page_transition_table32.@1
        ;;
        ;; 21ed000h - 21ed7f8 之间写入 User 权限
        ;;
        or eax, esi

        ;;
        ;; 21ed800h - 21edff8 之间写入 Supervisor 权限
        ;;        
map_longmode_page_transition_table32.@1:        
        mov [ebx + ecx], eax
        mov [ebx + ecx + 4], edx
        sub eax, 1000h        
        sub ecx, 8
        jns map_longmode_page_transition_table32.loop
        
        ;;
        ;; 更新 PPT 表区域管理标志为有效
        ;;
        mov BYTE [fs: SDA.PptValid], 1
        
        pop edx
        pop ebx
        pop ecx
        ret






;---------------------------------------------------------------
; do_prev_stage3_virtual_address_mapping32():
; input:
;       edi:esi - virtual address
;       edx:eax - physical address
;       ecx - page attribute
; output:
;       0 - succssful, otherwise - error code
; 描述:
;       1) 执行 64 位的虚拟地址映射操作
;       2) 成功返回 0, 出错返回错误码
;       3) 在 legacy 模式下使用
;
; attribute 描述: 
;       ecx 传递过来的 attribute 由下面标志位组成: 
;       [0] - P
;       [1] - R/W
;       [2] - U/S
;       [3] - PWT
;       [4] - PCD
;       [5] - A
;       [6] - D
;       [7] - PS
;       [8] - G
;       [12] - PAT
;       [28] - INGORE
;       [29] - FORCE, 置位时, 强制进行映射
;       [30] - PHYSICAL, 置位时, 表示基于物理地址进行映射(用于初始化时)
;       [31] - XD
;---------------------------------------------------------------
do_prev_stage3_virtual_address_mapping32:
        push eax
        push ecx
        push edx
        push ebx
        push ebp
        push esi
        push edi
        
        ;;
        ;; 检查映射的虚拟地址是否在 PPT 表区域内: 
        ;; ffff_f6fb_7da0_0000h - ffff_f6fb_7dbf_ffffh(2M 空间)
        ;; 1) 是的话, 忽略眏射
        ;;
        mov eax, esi
        mov edx, edi
        mov ebx, 7DA00000h
        mov ecx, 0FFFFF6FBh
        call cmp64
        mov ebx, 7DBFFFFFh
        jb do_prev_stage3_virtual_address_mapping32.next
        call cmp64
        jbe do_prev_stage3_virtual_address_mapping32.done
        
do_prev_stage3_virtual_address_mapping32.next:        
        
        ;;
        ;; 读 PPE 值
        ;;        
        mov eax, esi
        mov edx, edi
        call get_ppe_offset32
        add eax, [fs: SDA.PptPhysicalBase64]
        mov ebp, eax                                            ; PPE 地址
        mov eax, [eax]                                          ; eax = PPE 低 32 位　
        
        ;;
        ;; 检查 PPE 是否有效
        ;;
        and eax, VALID_FLAGS
        cmp eax, VALID_FLAGS
        jne do_prev_stage3_virtual_address_mapping32.write_ppe
        
        ;;
        ;; PPE 有效时, 读 PDT 表地址, 下一步继续检查 PDE
        ;;
        mov eax, [ebp]
        and eax, 0FFFFF000h
        mov ebp, eax                                            ; PDT 表地址
        
        jmp do_prev_stage3_virtual_address_mapping32.check_pde
        
        
do_prev_stage3_virtual_address_mapping32.write_ppe:
        ;;
        ;; PPE 无效时:
        ;; 1) 需要分配4K空间作为下一级的 PDT 表区域
        ;; 2) 写入 PPE 中
        ;;
        call get_pt_physical_base32                             ; edx:eax - 4K空间物理地址
        mov ecx, [esp + 20]                                     ; page attribute
        and ecx, 07h                                            ; 保留 U/S, R/W 及 P 属性, PCD/PWT 属性不设置
        or ecx, VALID_FLAGS                                     ; 加上 VALAGS_FLAGS 标志　
        or ecx, eax
        ;;
        ;; 写入 PPE
        ;;
        mov [ebp], ecx
        mov [ebp + 4], edx
        mov ebp, eax                                            ; PDT 表地址
        
do_prev_stage3_virtual_address_mapping32.check_pde:        
        ;;
        ;; 检查 PDE 项
        ;;
        mov eax, [esp + 4]
        mov edx, [esp]
        call get_pde_index32
        add ebp, eax                                            ; PDE 地址
        mov eax, [ebp]                                          ; PDE 值
        ;;
        ;; 检查 PDE 是否有效
        ;; 
        and eax, VALID_FLAGS
        cmp eax, VALID_FLAGS
        jne do_prev_stage3_virtual_address_mapping32.write_pde
        ;;
        ;; PDE 有效时, 读取 PT 表地址, 下一步继续检查 PTE 项
        ;;
        mov eax, [ebp]
        and eax, 0FFFFF000h
        mov ebp, eax                                            ; PT 表地址
        
        jmp do_prev_stage3_virtual_address_mapping32.check_pte
        
do_prev_stage3_virtual_address_mapping32.write_pde:
        ;;
        ;; PDE 无效时, 需要写入 PDE: 
        ;; 注意: 
        ;; 1) 首先, 检查是否使用 2M 页映射
        ;; 2) 属于 2M 页映射, 则不需要分配 PT 表
        ;; 3) 属于 4K 页映射, 则需要分配 PT 表　
        ;; 
        
        ;;
        ;; 检查 page 属性
        ;;
        mov ecx, [esp + 20]                                     ; 属性
        test ecx, PS                                            ; PS 位
        jnz do_prev_stage3_virtual_address_mapping32.write_pde.@1
        ;;
        ;; 属于 4K 页映射
        ;; 1) 分配 4K 空间, 作为 PT 表地址
        ;; 2) 写入 PDE 中
        ;;
        call get_pt_physical_base32
        and ecx, 07                                             ; 保留 U/S, R/W 及 P 位
        or ecx, eax                                             ; 合成 page attribute
        or ecx, VALID_FLAGS                                     ; 有效标志位
        
        ;;
        ;; 写入 PDE
        ;; 
        mov [ebp], ecx
        mov [ebp + 4], edx
        mov ebp, eax                                            ; PT 表地址
        
        jmp do_prev_stage3_virtual_address_mapping32.check_pte
        
        
do_prev_stage3_virtual_address_mapping32.write_pde.@1:        
        ;;
        ;; 属于 2M 页映射, 写入 page frame 地址值
        ;;
        mov eax, [esp + 24]
        mov edx, [esp + 16]                                     ; edx:eax = page frame 地址
        and eax, 0FFE00000h                                     ; 2M 边界
        ;;
        ;; 保证在处理器支持的最大物理地址内
        ;;
        and eax, [gs: PCB.MaxPhyAddrSelectMask]
        and edx, [gs: PCB.MaxPhyAddrSelectMask + 4]
        
        ;;
        ;; 保留 page attribute 的 [12:0] 位
        ;;
        mov ecx, [esp + 20]                                     ; 读 page attribute
        mov esi, ecx
        
        ;;
        ;; 生成 XD 标志位, attribute & XdValue
        ;;
        and esi, [fs: SDA.XdValue]                              ; 是否开启 XD 功能
        or edx, esi                                             ; 合成 XD 标志
        and ecx, 1FFFh                                          ; 保留 12:0
        or ecx, VALID_FLAGS                                     ; 加上 VALAGS_FLAGS 标志　
        or ecx, eax
        
        ;;
        ;; 写入 PDE, 完成映射
        ;;
        mov [ebp], ecx
        mov [ebp + 4], edx
        
        mov eax, MAPPING_SUCCESS
        jmp do_prev_stage3_virtual_address_mapping32.done


do_prev_stage3_virtual_address_mapping32.check_pte:
        mov edx, [esp]
        mov eax, [esp + 4]                                      ; edx:eax = va
        call get_pte_index32
        add ebp, eax                                            ; PTE 地址
        mov eax, [ebp]
        
        ;;
        ;; 检查 PTE 是否有效
        ;;
        and eax, VALID_FLAGS
        cmp eax, VALID_FLAGS
        je do_prev_stage3_virtual_address_mapping32.check_mapping

do_prev_stage3_virtual_address_mapping32.write_pte:
        
        ;;
        ;; 无效时, 写入 page frame 地址值
        ;;
        
        mov eax, [esp + 24]
        mov edx, [esp + 16]                                     ; edx:eax = page frame 地址
        and eax, 0FFFFF000h                                     ; 4K 边界
        ;;
        ;; 保证在处理器支持的最大物理地址内
        ;;
        and eax, [gs: PCB.MaxPhyAddrSelectMask]
        and edx, [gs: PCB.MaxPhyAddrSelectMask + 4]
        
        ;;
        ;; 合成 page attribute
        ;;
        mov ecx, [esp + 20]
        btr ecx, 12                                             ; 取 PAT 位
        setc bl
        shl bl, 7                                               ; PTE.PAT 位
        or cl, bl
        mov esi, ecx
        and esi, [fs: SDA.XdValue]
        or edx, esi                                             ; 合成 XD 标志位
        and ecx, 0FFh                                           ; 保留 8:0 位
        or eax, ecx
        or eax, VALID_FLAGS                                     ; 添加有效标志
        
        ;;
        ;; 写入 PTE 项
        ;;
        mov [ebp], eax
        mov [ebp + 4], edx
        
        mov eax, MAPPING_SUCCESS
        jmp do_prev_stage3_virtual_address_mapping32.done

do_prev_stage3_virtual_address_mapping32.check_mapping:
        ;;
        ;; 假如 PTE 是有效的, 表明 va 已经被映射
        ;; 1) 检查是否强行映射
        ;; 2) 不是的话, 忽略映射
        ;;
        mov ecx, [esp + 20]
        test ecx, FORCE
        jnz do_prev_stage3_virtual_address_mapping32.write_pte
        
        mov eax, MAPPING_USED
        
do_prev_stage3_virtual_address_mapping32.done:        
        mov [esp + 24], eax
        pop edi
        pop esi
        pop ebp
        pop ebx
        pop edx
        pop ecx        
        pop eax
        ret


;---------------------------------------------------------------
; do_prev_stage3_virtual_address_mapping32_n()
; input:
;       edi:esi - virtual address
;       edx:eax - physical address
;       ecx - page attribute
;       count - [ebp + 8]
;       
; output:
;       0 - succssful, otherwise - error code
;
;---------------------------------------------------------------
do_prev_stage3_virtual_address_mapping32_n:
        push ebp
        mov ebp, esp
        sub esp, 16
        
        mov [ebp - 8], eax
        mov [ebp - 4], edx                      ; edx:eax
        mov eax, [ebp + 8]
        mov [ebp - 12], eax                     ; count
        test eax, eax
        jz do_prev_stage3_virtual_address_mapping32_n.done
        
do_prev_stage3_virtual_address_mapping32_n.loop:        
        mov eax, [ebp - 8]
        mov edx, [ebp - 4]
        call do_prev_stage3_virtual_address_mapping32
        add esi, 1000h
        add DWORD [ebp - 8], 1000h
        dec DWORD [ebp - 12]
        jnz do_prev_stage3_virtual_address_mapping32_n.loop

do_prev_stage3_virtual_address_mapping32_n.done:        
        mov esp, ebp
        pop ebp
        ret 4










;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$                                              $
;$              64-bit page64 库                $
;$                                              $
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


        bits 64
        
        
;---------------------------------------------------------------
; get_pt_virtual_base64()
; intput:
;       rsi - physical address of PT
; output:
;       rax - virtual address of PT, 失败时返回 0 值
; 描述: 
;       1) 返回 PT pool 中物理地址对应的虚拟地址
;---------------------------------------------------------------
get_pt_virtual_base64:
        push rsi
        xor eax, eax
        
        ;;
        ;; 需要检查物理地址是在主 PT pool 内, 还是备用 PT pool 内
        ;;
        cmp rsi, PT_POOL_PHYSICAL_BASE64
        jb get_pt_virtual_base64.check_backup
        cmp rsi, PT_POOL_PHYSICAL_TOP64
        ja get_pt_virtual_base64.done
        
        sub rsi, PT_POOL_PHYSICAL_BASE64
        mov rax, PT_POOL_BASE64
        add rax, rsi
        jmp get_pt_virtual_base64.done

get_pt_virtual_base64.check_backup:        
        cmp rsi, PT_POOL2_PHYSICAL_BASE64
        jb get_pt_virtual_base64.done
        cmp rsi, PT_POOL2_PHYSICAL_TOP64
        ja get_pt_virtual_base64.done
        
        sub rsi, PT_POOL2_PHYSICAL_BASE64
        mov rax, PT_POOL2_BASE64
        add rax, rsi
        
get_pt_virtual_base64.done:        
        pop rsi
        ret
        
        
        
        
;---------------------------------------------------------------
; get_pt_physical_base64()
; intput:
;       none
; output:
;       rax - physical address of PT 
; 描述: 
;       1) 在 PT Pool 里分配一个 4K 的物理块, 作为 PT 或 PDT　
;       2) 首先在主 PT Pool 里分配, 当主 PT pool 用完后, 在备用 PT pool 分配
;       3) 当备用 PT Pool 也分配完, 返回 0 值
;---------------------------------------------------------------
get_pt_physical_base64:
        push rbx
        xor esi, esi
        mov eax, 4096                                   ; 分配粒度为 4K
        
        ;;
        ;; 检查主 PT Pool 是否空闲可用
        ;;
        cmp BYTE [fs: SDA.PtPoolFree], 1
        jne get_pt_physical_base64.check_backup
        
        ;;
        ;; 可用时, 从 Pt pool 里分配一个 4K 物理块
        ;;
        lock xadd [fs: SDA.PtPoolPhysicalBase], rax
        
        ;;
        ;; 检查主 Pt pool 是否超限
        ;;
        cmp rax, [fs: SDA.PtPoolPhysicalTop]
        jb get_pt_physical_base64.ok
        
        ;;
        ;; 超限时: 
        ;; 1) 清 PtPoolFree 标志位
        ;; 2) 尝试使用备用 Pt pool 继续分配
        ;;
        mov BYTE [fs: SDA.PtPoolFree], 0
        mov eax, 4096
                
get_pt_physical_base64.check_backup:       
        ;;
        ;; 检查备用 Pt Pool 是否空闲可用
        ;; 备用 Pt Pool 非空闲时, 返回 0 值
        ;;
        cmp BYTE [fs: SDA.PtPool2Free], 1
        cmovne eax, esi
        jne get_pt_physical_base64.done
        
        ;;
        ;; 从备用 Pt pool 里分配 4K 物理块
        ;;        
        lock xadd [fs: SDA.PtPool2PhysicalBase], rax
        
        ;;
        ;; 检查备用 Pt pool 是否超限
        ;;
        cmp rax, [fs: SDA.PtPool2PhysicalTop]
        jb get_pt_physical_base64.ok
        
        ;;
        ;; 超限时, 清 Free 标志
        ;;
        mov BYTE [fs: SDA.PtPool2Free], 0
        mov eax, esi
        ret
        
get_pt_physical_base64.ok:
        mov rbx, rax
        ;;
        ;; 清 PT Pool 块 
        ;;
        mov rsi, rax
        call get_pt_virtual_base64
        mov rsi, rax
        call clear_4k_page64
        mov rax, rbx
        
get_pt_physical_base64.done:        
        pop rbx
        ret






;---------------------------------------------------------------
; do_virtual_address_mapping64():
; input:
;       rsi - virtual address
;       rdi - physical address
;       r8 - page attribute
; output:
;       0 - succssful, otherwise - error code
; 描述:
;       1) 执行 64 位的虚拟地址映射操作
;       2) 成功返回 0, 出错返回错误码
;
; attribute 描述: 
;       r8 传递过来的 attribute 由下面标志位组成: 
;       [0] - P
;       [1] - R/W
;       [2] - U/S
;       [3] - PWT
;       [4] - PCD
;       [5] - A
;       [6] - D
;       [7] - PAT
;       [8] - G
;       [12] - 忽略
;       [26:13] - 忽略
;       [27] - GET_PHY_PAGE_FRAME
;       [28] - INGORE
;       [29] - FORCE, 置位时, 强制进行映射
;       [30] - PHYSICAL, 置位时, 表示基于物理地址进行映射(用于初始化时)
;       [31] - XD
;---------------------------------------------------------------
do_virtual_address_mapping64:
        push rbx
        push rbp
        push r12
        push r15
        mov rbx, rsi
        mov r12, r8
        mov r15, rdi
        
        ;;
        ;; 检查映射的虚拟地址是否在 PPT 表区域内(PPT_BASE - PPT_TOP64): 
        ;; 1) 是的话, 由于已经映射, 需要忽略眏射
        ;;
        mov rax, PPT_BASE64
        cmp rsi, rax
        jb do_virtual_address_mapping64.next
        mov rax, PPT_TOP64
        cmp rsi, rax
        jbe do_virtual_address_mapping64.done
        
do_virtual_address_mapping64.next:        
        ;;
        ;; 读 PPE 值
        ;;
        call get_ppe_offset64
        add rax, [fs: SDA.PptBase64]
        mov rbp, rax                                            ; PPE 地址
        mov rax, [rax]                                          ; PPE 值
        
        ;;
        ;; 检查 PPE 是否有效
        ;;
        and eax, VALID_FLAGS
        cmp eax, VALID_FLAGS
        jne do_virtual_address_mapping64.write_ppe

        ;;
        ;; 读 PDT 表地址, 下一步继续检查 PDE
        ;;
        mov rax, [rbp]
        and rax, ~0FFFh                                         ; 清 bits 11:0
        and rax, [gs: PCB.MaxPhyAddrSelectMask]                 ; 
        
        ;;
        ;; PDT 表物理地址转换为对应的虚拟地址
        ;;
        mov rsi, rax
        call get_pt_virtual_base64
        mov rbp, rax                                            ; PDT 表地址
        
        jmp do_virtual_address_mapping64.check_pde
        
        
do_virtual_address_mapping64.write_ppe:
        ;;
        ;; PPE 无效时:
        ;; 1) 需要分配4K空间作为下一级的 PDT 表区域
        ;; 2) 写入 PPE 中
        ;;
        ;; page 属性设置说明: 
        ;; 1) 从不使用 1G 页面映射, 因此需去掉 PS 标志位
        ;; 2) XD 标志不加在 PPE 上
        ;; 3) 传递过来的 User 和 Writable 属性, 必须要加上!
        ;; 4) PAT,PCD,PWT 以及 G 属性忽略!(这些属性只加在 page frame 上)
        ;;
        call get_pt_physical_base64                             ; rax - 4K空间物理地址
        
        ;;
        ;; 检查是分配 4K 物理地址是否成功:
        ;; 1) 不成功时, 返回状态码为: MAPPING_NO_RESOURCE
        ;;
        test rax, rax
        mov esi, MAPPING_NO_RESOURCE
        cmovz eax, esi
        jz do_virtual_address_mapping64.done
        
        mov rsi, rax
        or rax, VALID_FLAGS | PAGE_P | PAGE_WRITE | PAGE_USER
        
        ;;
        ;; 写入 PPE 项
        ;;
        mov [rbp], rax
        call get_pt_virtual_base64                              ; 取 PDT 对应的虚拟地址
        mov rbp, rax                                            ; PDT 表地址
        
do_virtual_address_mapping64.check_pde:        
        ;;
        ;; 读取 PDE 项
        ;;
        mov rsi, rbx
        call get_pde_index64
        add rbp, rax                                            ; PDE 地址
        mov rax, [rbp]                                          ; PDE 值
        ;;
        ;; 检查 PDE 是否有效
        ;; 
        and eax, VALID_FLAGS
        cmp eax, VALID_FLAGS
        jne do_virtual_address_mapping64.write_pde
        
        ;;
        ;; PDE 有效时, 检查映射是否有效
        ;;
        mov rsi, [rbp]
        mov rdi, r12
        call check_valid_for_mapping
        cmp eax, MAPPING_VALID
        jne do_virtual_address_mapping64.done
                
        ;;
        ;; 映射有效检查通过: 读取 PT 表地址, 下一步继续检查 PTE 项
        ;;
        mov rax, [rbp]
        and rax, ~0FFFh
        and rax, [gs: PCB.MaxPhyAddrSelectMask]
        mov rsi, rax
        call get_pt_virtual_base64
        mov rbp, rax                                            ; PT 表地址
        
        jmp do_virtual_address_mapping64.check_pte
        
do_virtual_address_mapping64.write_pde:
        ;;
        ;; PDE 无效时, 需要写入 PDE: 
        ;; 注意: 
        ;; 1) 首先, 检查是否使用 2M 页映射
        ;; 2) 属于 2M 页映射, 则不需要分配 PT 表
        ;; 3) 属于 4K 页映射, 则需要分配 PT 表　
        ;; 
        ;; page 属性设置说明: 
        ;; 1) 属于 2M page frame 时, 参数中的所有 page 属性都要加上
        ;; 2) 属于 4K 页面映射时, 只取 page 属性中的 U/S, R/W 和 P
        ;;
        
        ;;
        ;; 检查是否为 2M 页面映射
        ;;
        mov r8, r12
        test r8d, PAGE_2M                                       ; PS 位
        jnz do_virtual_address_mapping64.write_pde.@1
        ;;
        ;; 属于 4K 页映射
        ;; 1) 分配 4K 空间, 作为 PT 表地址
        ;; 2) 写入 PDE 中
        ;;
        call get_pt_physical_base64
        ;;
        ;; 检查是分配 4K 物理地址是否成功:
        ;; 1) 不成功时, 返回状态码为: MAPPING_NO_RESOURCE
        ;;
        test rax, rax
        mov esi, MAPPING_NO_RESOURCE
        cmovz eax, esi
        jz do_virtual_address_mapping64.done

        mov rsi, rax                
        or rax, VALID_FLAGS | PAGE_P | PAGE_WRITE | PAGE_USER
        
        ;;
        ;; 写入 PDE
        ;; 
        mov [rbp], rax
        call get_pt_virtual_base64
        mov rbp, rax                                            ; PT 表地址
        
        jmp do_virtual_address_mapping64.check_pte
        
        
do_virtual_address_mapping64.write_pde.@1:        
        ;;
        ;; 属于 2M 页映射, 写入 page frame 地址值
        ;;
        mov rax, r15
        and rax, ~1FFFFFh                                       ; 保证 2M page frame 边界
        and rax, [gs: PCB.MaxPhyAddrSelectMask]                 ; 保证在处理器的最大物理地址范围内
        
        ;;
        ;; 保留 page attribute 参数中的 [12] 位, 以及 [8:0]
        ;; 生成最终 page frame 的属性
        ;;
        mov r8, r12
        and r8, 11FFh
        or rax, r8
        
        ;;
        ;; 生成 XD 标志位: 由属性参数 AND [fs: SDA.XdValue]
        ;;
        and r12d, [fs: SDA.XdValue]                             ; 取决于是否开启 XD 功能
        shl r12, 32                                             ; 生成 XD 标志
        or rax, r12                                             ; 加上 XD 标志值
        or rax, VALID_FLAGS                                     ; 加上 VALAGS_FLAGS 标志　
        
        ;;
        ;; 写入 PDE, 完成映射
        ;;
        mov [rbp], rax

        ;;
        ;; 返回成功状态码
        ;;
        mov eax, MAPPING_SUCCESS
        
        jmp do_virtual_address_mapping64.done


do_virtual_address_mapping64.check_pte:
        ;;
        ;; 读取 PTE 项
        ;;
        mov rsi, rbx
        call get_pte_index64
        add rbp, rax                                            ; PTE 地址
        mov rax, [rbp]
        
        ;;
        ;; 检查 PTE 是否有效
        ;; 1) 如果原来的 PTE 是有效的, 那么需要检查映射是否合法
        ;; 2) 如果 PTE 无效, 则写入 PTE 值
        ;;
        and eax, VALID_FLAGS
        cmp eax, VALID_FLAGS
        je do_virtual_address_mapping64.check_mapping

do_virtual_address_mapping64.write_pte:
        
        ;;
        ;; 无效时, 写入 page frame 地址值
        ;;
        mov rax, r15
        and rax, ~0FFFh                                         ; 保证 4K page frame 边界
        and rax, [gs: PCB.MaxPhyAddrSelectMask]                 ; 保证在处理器的最大物理地址范围内
        
        ;;
        ;; 保留 page attribute 参数中的 [8:0] 位, 并取 PAT 标志(bit12)
        ;; 生成最终 page frame 的属性
        ;;
        mov r8, r12
        mov rsi, r12
        and r8, 1FFh
        and r12, PAT                                            ; 取 PAT 标志值
        shr r12, 5                                              ; 生成 PTE 的 PAT 标志值
        or r8, r12
        or rax, r8

        ;;
        ;; 生成 XD 标志位: 由属性参数 AND [fs: SDA.XdValue]
        ;;
        and esi, [fs: SDA.XdValue]                              ; 取决于是否开启 XD 功能
        shl rsi, 32                                             ; 生成 XD 标志
        or rax, rsi                                             ; 加上 XD 标志值
        or rax, VALID_FLAGS                                     ; 加上 VALAGS_FLAGS 标志　
                       
        ;;
        ;; 写入 PTE 项
        ;;
        mov [rbp], rax
        
        mov eax, MAPPING_SUCCESS
        jmp do_virtual_address_mapping64.done

do_virtual_address_mapping64.check_mapping:
        ;;
        ;; 假如 PTE 是有效的, 表明 va 已经被映射
        ;; 1) 检查是否强行映射, 如果是强行映射则直接写入新的 PTE 值
        ;; 2) 不是的话, 检查映射是否有效
        ;;
        mov r8, r12
        test r8d, FORCE
        jnz do_virtual_address_mapping64.write_pte

        ;;
        ;; 检查映射是否有效: 
        ;; 1) 如果检查能过, 则返回 MAPPING_USED, 指示已经被使用
        ;; 2) 否则, 返回相应的错误码
        ;;
        mov rsi, [rbp]
        mov rdi, r12
        call check_valid_for_mapping
        cmp eax, MAPPING_VALID
        jne do_virtual_address_mapping64.done
        
        ;;
        ;; 返回"已经在使用"状态码
        ;;
        mov eax, MAPPING_USED          
        
        ;;
        ;; 假如 page attribute [27] = 1 时, 返回物理页 frame
        ;;          
        test r12, GET_PHY_PAGE_FRAME
        jz do_virtual_address_mapping64.done
        
        mov rax, [rbp]
        and rax, ~0FFFh
        and rax, [gs: PCB.MaxPhyAddrSelectMask]

do_virtual_address_mapping64.done: 
        pop r15
        pop r12
        pop rbp
        pop rbx
        ret
        


;---------------------------------------------------------------
; do_virtual_address_mapping64_n()
; input:
;       rsi - va
;       rdi - physical address
;       r8 - page attribute
;       r9 - count of pages
; output:
;       rax - status code
; 描述: 
;       1) 进行 n 个页面的映射
;---------------------------------------------------------------
do_virtual_address_mapping64_n:
        push rcx
        push rbx
        push rdx
        push r12
        push r15
        mov r12, r8
        mov r15, rdi
        mov rdx, rsi
        
        ;;
        ;; 检查映射页面 size
        ;;
        mov rcx, 200000h
        mov rbx, 1000h
        test r8d, PAGE_2M
        cmovnz rbx, rcx
        mov rcx, r9
        
do_virtual_address_mapping64_n.loop:
        mov rsi, rdx
        mov rdi, r15
        mov r8, r12        
        call do_virtual_address_mapping64
        cmp eax, MAPPING_SUCCESS
        jne do_virtual_address_mapping64_n.done
        add rdx, rbx
        add r15, rbx
        dec rcx
        jnz do_virtual_address_mapping64_n.loop

do_virtual_address_mapping64_n.done:        
        pop r15
        pop r12
        pop rdx
        pop rbx
        pop rcx
        ret        
        


;---------------------------------------------------------------
; get_physical_address_of_virtual_address()
; input:
;       rsi - virtual address
; output:
;       rax - physical address
; 描述: 
;       1) 返回虚拟地址映射的物理地址
;---------------------------------------------------------------
get_physical_address_of_virtual_address:
        push rbx
        mov rbx, rsi
        mov r8d, GET_PHY_PAGE_FRAME
        call do_virtual_address_mapping64
        and ebx, 0FFFh
        add rax, rbx
        pop rbx
        ret



;---------------------------------------------------------------
; check_valid_for_mapping()
; input:
;       rsi - pt entry attribute
;       rdi - page attribute
; output:
;       rax - status code
; 描述:
;       1) 当 PPE, PDE, PTE 有效时, 说明已经被映射
;       2) 需要检查提交的映射是否有效
;       3) 函数返回状态码, 为 MAPPING_VALID 时, 表明映射有效
;---------------------------------------------------------------
check_valid_for_mapping:
        push rcx
        ;;
        ;; 检查内容说明: 
        ;; 1) 如果 entry 的 PS = 1 时, 而参数中的 PS 为 0 时, 返回出错码: MAPPING_PS_MISMATCH
        ;; 2) 如果 entry 的 R/W = 0, 而参数中的 R/W = 1 时, 返回出错码: MAPPING_RW_MISMATCH
        ;; 3) 如果 entry 的 U/S = 0, 而参数中的 U/S = 1 时, 返回出错码: MAPPING_US_MISMATCH
        ;; 4) 如果 entry 的 XD = 1, 而参数中的 XD = 0 时, 返回出错码: MAPPING_XD_MISMATCH
        ;; 5) PAT, G, PCD, PWT, A 属性将忽略！
        
        mov eax, esi
        
        ;;
        ;; 检查 PS 标志
        ;; 1) 如果 PS 标志不同, 则返回 MAPPING_PS_MISMATCH
        ;;
        xor eax, edi
        test eax, PS
        mov ecx, MAPPING_PS_MISMATCH
        cmovnz eax, ecx
        jnz check_valid_for_mapping.done
        
        ;;
        ;; 检查 R/W 标志:
        ;; 1) 如果 entry 的 R/W = 1 时, 通过！继续往下检查
        ;; 2) 如果 entry 的 R/W = 0 并且参数的 R/W = 1 时, 返回 MAPPING_RW_MISMATCH
        ;;
        mov rax, rsi
        test eax, RW
        jnz check_valid_for_mapping.check_us
        test edi, RW
        mov ecx, MAPPING_RW_MISMATCH
        cmovnz eax, ecx
        jnz check_valid_for_mapping.done

check_valid_for_mapping.check_us:
        ;;
        ;; 检查 U/S 标志: 
        ;; 1) 如果 entry 的 U/S = 1 时, 通过！继续往下检查
        ;; 2) 如果 entry 的 U/S = 0 并且参数的 U/S = 1 时, 返回 MAPPING_US_MISMATCH
        ;;
        test eax, US
        jnz check_valid_for_mapping.check_xd
        test edi, US
        mov ecx, MAPPING_US_MISMATCH
        cmovnz eax, ecx
        jnz check_valid_for_mapping.done

check_valid_for_mapping.check_xd:
        ;;
        ;; 检查 XD 标志: 
        ;; 1) 如果 entry 的 XD = 0 时, 通过！继续往下检查
        ;; 2) 如果 entry 的 XD = 1 并且参数的 U/S = 0 时, 返回 MAPPING_XD_MISMATCH
        ;;
        bt rax, 63
        mov eax, MAPPING_VALID
        jnc check_valid_for_mapping.done
        test edi, XD
        mov ecx, MAPPING_XD_MISMATCH
        cmovz eax, ecx

check_valid_for_mapping.done:        
        pop rcx
        ret



        

;---------------------------------------------------------------
; get_pxe_offset64():
; input:
;       rsi - va
; output:
;       rax - offset
; 描述: 
;       得到 PXT entry 的 offset 值
; 注意: 
;       在 64-bit 下使用
;---------------------------------------------------------------
get_pxe_offset64:
        mov rax, rsi
        shl rax, 16                                             ; 清 va 高 16 位
        shr rax, (16 + 12 + 9 + 9 + 9)                          ; index = va >> 39
        shl rax, 3                                              ; offset = index << 3
        ret
        
        

;---------------------------------------------------------------
; get_ppe_offset64():
; input:
;       rsi - va
; output:
;       rax - offset
; 描述: 
;       得到 PPT entry 的 offset 值
; 注意: 
;       在 64-bit 下使用
;---------------------------------------------------------------
get_ppe_offset64:
        mov rax, rsi
        shl rax, 16                                             ; 清 va 高 16 位
        shr rax, (16 + 12 + 9 + 9)                              ; index = va >> 30
        shl rax, 3                                              ; offset = index << 3
        ret
                        




;---------------------------------------------------------------
; get_pde_index64()
; input:
;       rsi - va
; output:
;       rax - index of PDE
; 描述:
;       1) 得到 VA 中 PDE 的 index 值
;       2) 这个 index 值基于 PDT 基址
;---------------------------------------------------------------
get_pde_index64:
        mov rax, rsi
        shr eax, (12 + 9)
        and eax, 1FFh
        shl eax, 3
        ret
        


;---------------------------------------------------------------
; get_pte_index64():
; input:
;       rsi - va
; output:
;       rax - index of PTE
; 描述: 
;       1) 得到 PTE 的 index 值
;       2) 这个 index 值基于 PT 基址
;---------------------------------------------------------------
get_pte_index64:
        mov rax, rsi
        shr eax, 12
        and eax, 1FFh
        shl eax, 3
        ret                        
        
        
        
        
%if 0

;-----------------------------------------------------------------------
; alloc_kernel_stack_4k_base64()
; input:
;       none
; output:
;       rax - 4K stack base(虚拟地址) 
; 描述: 
;       1)分配一个4K页面大小的 kernel stack base的可用值         
;       2)并更新当前 kernel stack base 记录
;-----------------------------------------------------------------------
alloc_kernel_stack_4k_base64:
        mov eax, 4096
        lock xadd [fs: SDA.KernelStackBase], rax
        ret        
        
%endif
