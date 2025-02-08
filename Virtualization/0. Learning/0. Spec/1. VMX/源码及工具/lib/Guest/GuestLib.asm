;*************************************************
; GuestLib.asm                                   *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************


        bits 32


        
;-----------------------------------------
; ZeroMemory()
; input:
;       esi - size
;       edi - buffer address
; 描述: 
;       将内存块清 0
;-----------------------------------------
ZeroMemory:
        push ecx
        
        test edi, edi
        jz ZeroMemory.done
        
        xor eax, eax
        
        ;;
        ;; 检查 count > 4 ?
        ;;
        cmp esi, 4
        jb ZeroMemory.@1
        
        ;;
        ;; 先写入首 4 字节
        ;;
        mov [edi], eax
        
        ;;
        ;; 计算调整到 DWORD 边界上的差额, 原理等于 4 - dest & 03
        ;; 1) 例如: [2:0] = 011B(3)
        ;; 2) 取反后 = 100B(4)
        ;; 3) 加1后 = 101B(5)        
        ;; 4) 在32位下与03后 = 001B(1), 即差额为 1
        ;;
        mov ecx, esi                                    ; 原 count        
        mov esi, edi                                    ; 原 dest
        not esi
        inc esi
        and esi, 03                                     ; 在 32 位下与 03h
        sub ecx, esi                                    ; count = 原 count - 差额

        ;;
        ;; dest 向上调整到 DWORD 边界
        ;;
        add edi, esi                                    ; dest = dest + 差额
        mov esi, ecx
           
        ;;
        ;; 在 32 位下, 以 DWORD 为单位
        ;; 
        shr ecx, 2
        rep stosd

ZeroMemory.@1:                     
        ;;
        ;; 一次 1 字节, 写入剩余字节数
        ;;
        mov ecx, esi
        and ecx, 03h
        rep stosb
        
ZeroMemory.done:        
        pop ecx
        ret   
        ret
        
        
;-----------------------------------------------------
; AllocPhysicalPage()
; input:
;       esi - count of page
; output:
;       eax - physical address of page
;-----------------------------------------------------        
AllocPhysicalPage:
        push ebx
        
        ;;
        ;; 分配地址
        ;;
        imul eax, esi, 4096
        xadd [Guest.PoolPhysicalBase], eax
        mov ebx, eax

        ;;
        ;; 清页面
        ;;
        mov esi, 4096
        mov edi, eax       
        call ZeroMemory
        mov eax, ebx
        
        pop ebx
        ret






%ifdef GUEST_X64



;-----------------------------------------------------
; init_longmode_page()
; intput:
;       none
; output:
;       none
; 描述: 
;       1) 在未分页下调用
;-----------------------------------------------------
init_longmode_page:
        push ebx
        push edx
        push ecx
        push ebp

        ;;
        ;;    --------------- 虚拟地址 --------------              ------ 物理地址 ------
        ;; 1) FFFF8000_C0200000h - FFFF8000_C05FFFFFh     ==>     00200000h - 005FFFFFh (2M页面)
        ;; 2) FFFF8000_80020000h - FFFF8000_8002FFFFh     ==>     00020000h - 0002FFFFh (4K页面)
        ;; 3) 00020000h - 0002FFFFh                       ==>     00020000h - 0002FFFFh (4K页面)
        ;; 4) FFFF8000_FFF00000h - FFFF8000_FFF00FFFh     ==>     AllocPhysicalPage()   (4K页面)
        ;; 5) 000B8000h - 000B8FFFh                       ==>     000B8000h - 000B8FFFh (4K页面)
        ;; 6) 00007000h - 00008FFFh                       ==>     00007000h - 00008FFFh (4K页面)
        ;; 7) FFFF8000_81000000h - FFFF8000_81000FFFh     ==>     01000000h - 01000FFFh (4K页面)
        ;;
        
        
                
        ;;
        ;; #### step 1: 设置 PML4E ####
        ;;
        
        ;;
        ;; 设置 FFFF8000_xxxxxxxx 的 PML4E
        ;;
        mov esi, 1
        call AllocPhysicalPage
        mov ebx, eax                                                    ;; ebx = PML4T[100h]
        or eax, RW | P
        mov [GUEST_PML4T_BASE + 100h * 8], eax                          ;; PML4T[100h]
        mov DWORD [GUEST_PML4T_BASE + 100h * 8 + 4], 0
        
        ;;
        ;; 设置 00000000_xxxxxxxx 的 PML4E
        ;;　
        mov esi, 1
        call AllocPhysicalPage
        mov edx, eax                                                    ;; edx = PML4T[0]
        or eax, RW | US | P
        mov [GUEST_PML4T_BASE + 0 * 8], eax                             ;; PML4T[0]
        mov DWORD [GUEST_PML4T_BASE + 0 * 8 + 4], 0
        
        
        ;;
        ;; #### step 2: 设置 PDPTE ####
        ;;
        
        ;;
        ;; 设置 FFFF8000_Cxxxxxxx 的 PDPTE
        ;; 设置 FFFF8000_8xxxxxxx 的 PDPTE  
        ;; 设置 FFFF8000_Fxxxxxxx 的 PDPTE
        ;;
        mov esi, 1
        call AllocPhysicalPage
        mov ebp, eax                                                    ;; ebp
        or eax, RW | P
        mov [ebx + 2 * 8], eax
        mov DWORD [ebx + 2 * 8 + 4], 0
        
        mov esi, 1
        call AllocPhysicalPage
        mov ecx, eax
        or eax, RW | P
        mov [ebx + 3 * 8], eax
        mov DWORD [ebx + 3 * 8 + 4], 0              
                
        ;;
        ;; 设置 00000000_0xxxxxxx 的 PDPTE
        ;;
        mov esi, 1
        call AllocPhysicalPage
        mov ebx, eax                                                    ;; ebx
        or eax, RW | US | P
        mov [edx + 0 * 8], eax
        mov DWORD [edx + 0 * 8 + 4], 0        

        
        
        ;;
        ;; #### step 3: 设置 PDE ####
        ;;
          
        ;;
        ;; 设置 FFFF8000_C02xxxxx 的 PDE
        ;;
        mov DWORD [ecx + 1 * 8], 200000h | PS | RW | P
        mov DWORD [ecx + 1 * 8 + 4], 0
        mov DWORD [ecx + 2 * 8], 400000h | PS | RW | P
        mov DWORD [ecx + 2 * 8 + 4], 0

        ;;
        ;; 设置 FFFF8000_FFFxxxxx 的 PDE
        ;;
        mov esi, 1
        call AllocPhysicalPage
        mov edi, eax
        or eax, RW | P
        mov [ecx + 1FFh * 8], eax
        mov DWORD [ecx + 1FFh * 8 + 4], 0
        mov ecx, edi
        
                
        ;;
        ;; 设置 FFFF8000_8002xxxx 的 PDE
        ;;
        mov esi, 1
        call AllocPhysicalPage
        mov edx, eax                                                    ;; edx
        or eax, RW | P
        mov [ebp + 0 * 8], eax
        mov DWORD [ebp + 0 * 8 + 4], 0
        
        ;;
        ;; 设置 FFFF8000_810xxxxx 的 PDE
        ;;
        mov esi, 1
        call AllocPhysicalPage
        or eax, RW | P
        mov [ebp + 8 * 8], eax
        mov DWORD [ebp + 8 * 8 + 4], 0 
               
        ;;
        ;; 设置 FFFF8000_81000000h 映射的 PTE
        ;;
        and eax, ~0FFFh
        mov DWORD [eax + 0 * 8], 01000000h | RW | P
        mov DWORD [eax + 0 * 8 + 4], 0
       
        ;;
        ;; 设置 00000000_00020xxx 的 PDE
        ;;
        mov esi, 1
        call AllocPhysicalPage
        mov ebp, eax
        or eax, RW | US | P
        mov [ebx + 0 * 8], eax
        mov DWORD [ebx + 0 * 8 + 4], 0
        
       
        
     
        ;;
        ;; #### step 4: 设置 PTE ####
        ;;
        
        ;;
        ;; 设置 FFFF8000_FFF00000 的 PTE
        ;;
        mov esi, 1
        call AllocPhysicalPage
        or eax, RW | P
        mov [ecx + 100h * 8], eax
        mov DWORD [ecx + 100h * 8 + 4], 0
        
        ;;
        ;; 设置 FFFF8000_80020000h, 00020000h 的 PTE
        ;;
        mov ecx, 20h
        mov esi, 20000h | RW | P
init_longmode_page.loop:
        mov [ebp + ecx * 8], esi
        mov DWORD [ebp + ecx * 8 + 4], 0
        or DWORD [ebp + ecx * 8], PAGE_USER                     ; 20000h 具有 USER 权限
        mov [edx + ecx * 8], esi
        mov DWORD [edx + ecx * 8 + 4], 0
        add esi, 1000h
        inc ecx
        cmp ecx, 2Fh
        jbe init_longmode_page.loop
        
        ;;
        ;; 设置 0B8000h 的 PTE
        ;;
        mov DWORD [ebp + 0B8h * 8], 0B8000h | RW | US | P
        mov DWORD [ebp + 0B8h * 8 + 4], 0      

        ;;
        ;; 设置 7000h - 8FFFh 的 PTE
        ;;
        mov DWORD [ebp + 7 * 8], 7000h | RW | US | P
        mov DWORD [ebp + 7 * 8 + 4], 0     
        mov DWORD [ebp + 8 * 8], 8000h | RW | US | P
        mov DWORD [ebp + 8 * 8 + 4], 0     
        
        pop ebp
        pop ecx
        pop edx
        pop ebx
        ret


        bits 64
        
;----------------------------------------------------------
; update_tss_longmode()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 更新 TSS 为 64-bit 下的 TSS
;----------------------------------------------------------
update_tss_longmode:       
        ret
        
        
        
;----------------------------------------------------------
; do_virtual_address_mapping()
; input:
;       rsi - guest physical address
;       rdi - physical address
;       eax - page attribute
; output:
;       0 - successful, otherwise - error code
; 描述: 
;       1) 将虚拟地址映射到物理地址
;----------------------------------------------------------
do_virtual_address_mapping:
        push rbp
        push rbx
        push rcx
        push r10
        push r11

        
               
        
        mov r10, rsi                                    ; r10 = VA
        mov r11, rdi                                    ; r11 = PA
        mov ebx, eax                                    ; ebx = page attribute
        mov ecx, (32 - 4)                               ; ecx = 表项 index 左移位数(shld)
        mov rbp, PML4T_BASE                             ; rbp = PML4T 虚拟基址


do_virtual_address_mapping.Walk:
        ;;
        ;; paging structure walk 处理
        ;;
        shld rax, r10, cl
        and eax, 0FF8h
        
        ;;
        ;; 读取表项
        ;;
        add rbp, rax                                    ; rbp 指向表项
        mov rsi, [rbp]                                  ; rsi = 表项值
        
        
        ;;
        ;; 检查表项是否为 not present
        ;;
        test esi, PAGE_P
        jnz do_virtual_address_mapping.NextWalk
        

do_virtual_address_mapping.NotPrsent:     
        ;;
        ;; 检查是否为 PDE
        ;;
        cmp ecx, (32 - 4 + 9 + 9)
        jne do_virtual_address_mapping.CheckPte

        test ebx, PAGE_2M
        jz do_virtual_address_mapping.CheckPte

        ;;
        ;; 使用 2M 页面
        ;;
        mov eax, ebx
        and eax, 0FFh
        and r11, ~1FFFFFh
        or rax, r11
        mov [rbp], rax

        jmp do_virtual_address_mapping.Done

do_virtual_address_mapping.CheckPte:
        ;;
        ;; 检查是否为 PTE
        ;;
        cmp ecx, (32 - 4 + 9 + 9 + 9)
        jne do_virtual_address_mapping.WriteEntry

        ;;
        ;; 使用 4K 页面
        ;;
        mov eax, ebx
        and eax, 07Fh
        and r11, ~0FFFh
        or rax, r11
        mov [rbp], rax

        jmp do_virtual_address_mapping.Done

        
do_virtual_address_mapping.WriteEntry:             
        ;;
        ;; 分配页面
        ;;
        mov esi, 1
        call AllocPhysicalPage
        
        mov esi, eax
        or rax, PAGE_USER | PAGE_WRITE | PAGE_P          
        
        ;;
        ;; 写入表项内容
        ;;
        mov [rbp], rax

do_virtual_address_mapping.NextWalk:
        and esi, ~0FFFh
        mov rbp, POOL_BASE
        sub esi, GUEST_POOL_PHYSICAL_BASE
        add rbp, rsi

        ;;
        ;; 执行继续 walk 流程
        ;;
        add ecx, 9
        jmp do_virtual_address_mapping.Walk
               
do_virtual_address_mapping.Done:
        mov eax, MAPPING_SUCCESS
        pop r11                
        pop r10
        pop rcx
        pop rbx
        pop rbp
        ret

        bits 32
%else


;-----------------------------------------------------
; init_page_page()
; intput:
;       none
; output:
;       none
; 描述: 
;       1) 在未分页下调用
;-----------------------------------------------------
init_pae_page:
        push ebx
        push edx
        push ecx
        
        ;;
        ;;    ----- 虚拟地址 ------              ----- 物理地址 ------
        ;; 1) C0200000h - C05FFFFFh     ==>     00200000h - 005FFFFFh (2M页面)
        ;; 2) 80020000h - 8002FFFFh     ==>     00020000h - 0002FFFFh (4K页面)
        ;; 3) 00020000h - 0002FFFFh     ==>     00020000h - 0002FFFFh (4K页面)
        ;; 4) FFF00000h - FFF00FFFh     ==>     AllocPhysicalPage()   (4K页面)
        ;; 5) 000B8000h - 000B8000h     ==>     000B8000h - 000B8000h (4K页面)
        ;; 6) 00007000h - 00008FFFh     ==>     00007000h - 00008FFFh (4K页面)
        ;; 7) 81000000h - 81000FFFh     ==>     01000000h - 01000FFFh (4K页面)        
        ;;
        
        ;;
        ;; ### step 0: PAE paging 分页模式下的 4 个 PDPTE 已经被设置 ###
        ;;
        
        
        ;;
        ;; ### step 1: 设置 PDE 值 ###
        ;;
        mov eax, 200000h | PS | RW | P                          ;; 使用 2M 页面
        mov [GUEST_PDT3_BASE + 1 * 8], eax                      ;; 映射 C0200000h 虚拟地址到物理地址 200000h
        mov DWORD [GUEST_PDT3_BASE + 1 * 8 + 4], 0
        mov eax, 400000h | PS | RW | P                          ;; 使用 2M 页面
        mov [GUEST_PDT3_BASE + 2 * 8], eax                      ;; 映射 C0400000h 虚拟地址到物理地址 400000h
        mov DWORD [GUEST_PDT3_BASE + 2 * 8 + 4], 0
                
        mov esi, 1
        call AllocPhysicalPage                                  ;; 分配 4K 页面作为下一级 PT 基址
        or eax, RW | P
        mov [GUEST_PDT2_BASE + 0 * 8], eax                      ;; 映射 80020000h 虚拟地址
        mov DWORD [GUEST_PDT2_BASE + 0 * 8 + 4], 0              
        
        mov esi, 1
        call AllocPhysicalPage                                  ;; 分配 4K 页面作为下一级 PT 基址
        or eax, RW | P
        mov [GUEST_PDT2_BASE + 8 * 8], eax                      ;; 映射 81000000h 虚拟地址
        mov DWORD [GUEST_PDT2_BASE + 8 * 8 + 4], 0            
        
        mov esi, 1
        call AllocPhysicalPage                                  ;; 分配 4K 页面作为下一级 PT 基址
        or eax, RW | P
        mov [GUEST_PDT3_BASE + 01FFh * 8], eax                  ;; 映射 FFF00000h 虚拟地址
        mov DWORD [GUEST_PDT3_BASE + 01FFh * 8 + 4], 0
        
        mov esi, 1
        call AllocPhysicalPage                                  ;; 分配 4K 页页作为下一级 PT 基址
        or eax, RW | US | P
        mov [GUEST_PDT0_BASE + 0 * 8], eax                      ;; 映射 00020000h 虚拟地址
        mov DWORD [GUEST_PDT0_BASE + 0 * 8 + 4], 0
        
        ;;
        ;; ### step 2: 设置 PTE 值 ###
        ;;
        mov ebx, [GUEST_PDT2_BASE + 0 * 8]
        mov edx, [GUEST_PDT0_BASE + 0 * 8]
        and ebx, ~0FFFh                                         ; 读取 80020000h 虚拟地址对应的 PT 地址
        and edx, ~0FFFh                                         ; 读取 00020000h 虚拟地址对应的 PT 地址
        mov ecx, 20h                                            ; 起始 PTE index 为 20h(对应 80020 page frame)
        mov eax, 20000h                                         ; 起始物理地址为 20000h
        or eax, RW | P
       
        ;;
        ;; 映射虚拟地址:
        ;; 1) 80020000 - 8002FFFFh 到物理地址 00020000 - 0002FFFFh
        ;; 2) 00020000 - 0002FFFFh 到物理地址 00020000 - 0002FFFFh
        ;;
init_pae_page.loop1:
        mov [ebx + ecx * 8], eax
        mov DWORD [ebx + ecx * 8 + 4], 0
        mov [edx + ecx * 8], eax
        mov DWORD [edx + ecx * 8 + 4], 0
        or DWORD [edx + ecx * 8], PAGE_USER
        add eax, 1000h                                          ; 指向下一页面
        inc ecx
        cmp ecx, 2Fh                                            ; page frmae 从 80020 到 8002F(00020 到 0002F)
        jbe init_pae_page.loop1
        
        ;;
        ;; 映射虚拟地址 FFF00000 - FFF00FFFh 到物理地址由 AllocPhysicalPage() 分配而来
        ;;
        mov ebx, [GUEST_PDT3_BASE + 01FFh * 8]
        and ebx, ~0FFFh                                         ; 读取 FFF00000h 虚拟地址对应的 PT 基址
        mov esi, 1
        call AllocPhysicalPage
        or eax, RW | P
        mov [ebx + 100h * 8], eax
        mov DWORD [ebx + 100h * 8 + 4], 0

        ;;
        ;; 映射 81000000h 虚拟地址
        ;;
        mov esi, [GUEST_PDT2_BASE + 8 * 8]
        and esi, ~0FFFh
        mov DWORD [esi + 0 * 8], 01000000h | RW | P
        mov DWORD [esi + 0 * 8 + 4], 0
        
                
        ;;
        ;; 映射虚拟地址 000B8000h - 000B8000h 到物理地址 000B8000h - 000B8000h
        ;;
        mov ebx, [GUEST_PDT0_BASE + 0 * 8]
        and ebx, ~0FFFh
        mov DWORD [ebx + 0B8h * 8], 0B8000h | RW | US | P
        mov DWORD [ebx + 0B8h * 8 + 4], 0
        
        ;;
        ;; 映射虚拟地址 00007000h - 00008FFFh  到物理地址 00007000h - 00008FFFh 
        ;; 
        mov DWORD [ebx + 7 * 8], 7000h | RW | US | P
        mov DWORD [ebx + 7 * 8 + 4], 0
        mov DWORD [ebx + 8 * 8], 8000h | RW | US | P
        mov DWORD [ebx + 8 * 8 + 4], 0
        
        pop ecx
        pop edx
        pop ebx
        ret


%endif




;-----------------------------------------------------
; do_virtual_address_mapping32()
; input:
;       esi - virtual address
;       edi - physical address
;       eax - page attribute
; output:
;       eax - status code
;-----------------------------------------------------
do_virtual_address_mapping32:
        ret