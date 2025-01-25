; page64.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.



%include "..\inc\page.inc"


        bits 32
;-----------------------------------------
; void clear_4K_page(): 清 4K 页面
; input:  
;                esi: address
;------------------------------------------        
clear_4k_page:
clear_4K_page:
        pxor xmm1, xmm1
        mov eax, 4096
clear_4K_page_loop:        
        movdqu [esi + eax - 16], xmm1
        movdqu [esi + eax - 32], xmm1
        movdqu [esi + eax - 48], xmm1
        movdqu [esi + eax - 64], xmm1
        movdqu [esi + eax - 80], xmm1
        movdqu [esi + eax - 96], xmm1
        movdqu [esi + eax - 112], xmm1
        movdqu [esi + eax - 128], xmm1
        sub eax, 128
        jnz clear_4K_page_loop
        ret

;----------------------------------
; clear_4K_pages(): 清数个 4K 页
; input:
;                esi: address,        edi: number
;----------------------------------
clear_4k_pages:
clear_4K_pages:
        test edi, edi
        jz clear_4K_pages_done
clear_4K_pages_loop:        
        call clear_4K_page
        add esi, 0x1000
        dec edi
        jnz clear_4K_pages_loop        
clear_4K_pages_done:        
        ret        
        

;---------------------------------------------------------------
; init_page(): 初始化 long mode 的页结构
; 描述: 
;        在进入 long-mode 模式之前进行页表初始化
;----------------------------------------------------------------        

;*
;* changlog: 加入 BSP 处理器检测, 只有 BSP 有权进行页表初始化
;*
bsp_init_page:
init_page:
        mov ecx, IA32_APIC_BASE
        rdmsr
        bt eax, 8
        jnc init_page_done

; lib32  :      virtual address 0xf000 map to physicall address 0xf000 with 4k-page
; code32 :      virtual address 0x10000-0x13000 map to physicall address 0x10000-0x13000 with 4K-page
; video  :      virtual address 0xb8000 map to physicall address 0xb8000 with 4K-page
; data   :      virtual address 0x200000 map to physicall address 0x200000 with 2M-page
; code64 :      virtual address 0xfffffff800000000 to physicall address 0x600000 with 4K-page
; apic:         virtual address 0x800000 map to physica address 0xFEE00000(Local APIC 区域)
; DS save:      virtual address 400000h map to physical address 400000h
; user code64 : virtual address 00007FFF_00000000 map to physical address 800000h

        mov esi, 200000h
        mov edi, 15
        call clear_4k_pages
        mov esi, 201000h
        mov edi, 3
        call clear_4k_pages
        mov esi, 300000h
        mov edi, 5
        call clear_4K_pages


; 设置 PML4T 表, PML4T 的地址在 200000H
        mov DWORD [200000h], 201000h | RW | US | P                  ; PML4T[0]
        mov DWORD [200004h], 0

        ;; 由 0FFFFFF8X_XXXXXXXXX 的 virutal address 均是用户不可访问
        mov DWORD [200000h + 1FFh * 8], 202000h | RW | P     ; PML4T[0x1ff]
        mov DWORD [200000h + 1FFh * 8 + 4], 0

        mov DWORD [200000h + 0FFh * 8], 300000h | RW | US | P
        mov DWORD [200000h + 0FFh * 8 + 4], 0

; 设置 PDPT 表,  第 0 个 PDPT 表在 201000H, 第 511 个 PDPT 表在 202000H
        mov DWORD [201000h], 203000h | RW | US | P                 ; PDPT[0] for PML4T[0]
        mov DWORD [201004h], 0

        ; 为了 00000000_FFE00000 - 00000000_FFE01FFFh 而映射
        mov DWORD [201000h + 3 * 8], 210000h | RW | US | P
        mov DWORD [201000h + 3 * + 4], 0

        mov DWORD [202000h + 1E0h * 8], 204000h | RW | P      ; PDPT[0x1e0] for PML4T[0x1ff]
        mov DWORD [202000h + 1E0h * 8 + 4], 0
        ; 0FFFFFFFF_CXXXXXXX ...
        mov DWORD [202000h + 1FFh * 8], 209000h | RW | P
        mov DWORD [202000h + 1FFh * 8 + 4], XD
        
        mov DWORD [300000h + 1FCh * 8], 301000h | RW | US | P
        mov DWORD [300000h + 1FCh * 8 + 4], 0
        mov DWORD [300000h + 1FFh * 8], 302000h | RW | US | P
        mov DWORD [300000h + 1FFh * 8 + 4], 0

; set PDT
        mov DWORD [203000h], 205000h | RW | US | P                 ; PDT[0] for PDPT[0] for PML4T[0]
        mov DWORD [203004h], 0

        ; virtual address 200000h - 3FFFFFh 映射到 200000h - 3FFFFFh 上
        ; 不可执行, 用户不可访问
        ; 系统数据区
        mov DWORD [203000h + 1 * 8], 200000h | PS | RW | P
        mov DWORD [203000h + 1 * 8 + 4], XD

        mov DWORD [203000h + 2 * 8], 207000h | RW | P
        mov DWORD [203000h + 2 * 8 + 4], XD

        ; virutal address 800000h - 9FFFFFh 映射到 0FEE00000h - 0FEFFFFFFh(2M 页面)
        ; 不可执行, 用户不可访问, PCD = PWT = 1
        ; 用于 local APIC 区域
        mov DWORD [203000h + 4 * 8], 0FEE00000h | PCD | PWT | PS | RW | P
        mov DWORD [203000h + 4 * 8 + 4], XD

        ; PDT[0] for PDPT[0x1e0] for PML4T[0x1ff]
        mov DWORD [204000h], 206000h | RW | P
        mov DWORD [204004h], 0
        mov DWORD [204000h + 80h * 8], 208000h | RW | P
        mov DWORD [204000h + 80h * 8 + 4], 0

        ;*
        ;* 64-bit 模式下的 stack pointer 区域
        ;* 从 0FFFFFFFF_FFE00000 - 0FFFFFFFF_FFFFFFFF
        ;* 使用 2M 页映射到 0A00000h 地址
        ;* 使用于 kernel stack, IDT stack, sysenter stack, syscall stack ...
        ;*
        mov DWORD [209000h + 1FFh * 8], 0A00000h | PS | RW | P
        mov DWORD [209000h + 1FFh * 8 + 4], XD

        ; virutal address 00007FFF_00000000h - 00007FFF_001FFFFFh(2M 页)
        ; 映射到物理地址 800000h
        ; 可执行, 64 位用户代码执行区域
        mov DWORD [301000h], 800000h | PS | RW | US | P
        mov DWORD [301004h], 0
        mov DWORD [302000h + 1FFh * 8], 303000h | RW | US | P
        mov DWORD [302000h + 1FFh * 8 + 4], XD

        ;*
        ;* compatibility mode 下与 64-bit 对应的 stack pointer 区域
        ;* 从 00000000_FFE00000 - 00000000_FFFFFFFFh
        ;* 使用 2M 页映射到 600000h 地址
        ;* 
        mov DWORD [210000h + 1FFh * 8], 600000h | PS | RW | US | P
        mov DWORD [210000h + 1FFh * 8 + 4], XD

; set PT
        ; virutal address 0 - 0FFFh 映射到物理地址 0 - 0FFFh 上(4K 页)
        ; no present!(保留未映射)
        mov DWORD [205000h + 0 * 8], 0000h | RW | US
        mov DWORD [205000h + 0 * 8 + 4], 0

        ; virtual address 0B000 - 0BFFFh 映射到物理地址 0B000 - 0BFFFFh 上(4K 页)
        ; r/w = u/s = p = 1
        mov DWORD [205000h + 0Bh * 8], 0B000h | RW | US | P
        mov DWORD [205000h + 0Bh * 8 + 4], 0
        
        ; virtual address 9000h - 0FFFFh 映射到物理地址 09000h - 0FFFFh 上
        mov DWORD [205000h + 09h * 8], 09000h | RW | US | P
        mov DWORD [205000h + 09h * 8 + 4], 0
        mov DWORD [205000h + 0Ah * 8], 0A000h | RW | US | P
        mov DWORD [205000h + 0Ah * 8 + 4], 0
        mov DWORD [205000h + 0Bh * 8], 0B000h | RW | US | P
        mov DWORD [205000h + 0Bh * 8 + 4], 0
        mov DWORD [205000h + 0Ch * 8], 0C000h | RW | US | P
        mov DWORD [205000h + 0Ch * 8 + 4], 0
        mov DWORD [205000h + 0Dh * 8], 0D000h | RW | US | P
        mov DWORD [205000h + 0Dh * 8 + 4], 0
        mov DWORD [205000h + 0Eh * 8], 0E000h | RW | US | P
        mov DWORD [205000h + 0Eh * 8 + 4], 0
        mov DWORD [205000h + 0Fh * 8], 0F000h | RW | US | P
        mov DWORD [205000h + 0Fh * 8 + 4], 0

        ; virtual address 10000h - 13FFFh 映射到物理地址 10000h - 18FFFh 上(8 共个 4K 页)
        ; 可执行, r/w = u/s = p = 1
        ; 用于 long.asm 模块执行空间
        mov DWORD [205000h + 10h * 8], 10000h | RW | US | P
        mov DWORD [205000h + 10h * 8 + 4], 0
        mov DWORD [205000h + 11h * 8], 11000h | RW | US | P
        mov DWORD [205000h + 11h * 8 + 4], 0
        mov DWORD [205000h + 12h * 8], 12000h | RW | US | P
        mov DWORD [205000h + 12h * 8 + 4], 0
        mov DWORD [205000h + 13h * 8], 13000h | RW | US | P
        mov DWORD [205000h + 13h * 8 + 4], 0
        mov DWORD [205000h + 14h * 8], 14000h | RW | US | P
        mov DWORD [205000h + 14h * 8 + 4], 0
        mov DWORD [205000h + 15h * 8], 15000h | RW | US | P
        mov DWORD [205000h + 15h * 8 + 4], 0
        mov DWORD [205000h + 16h * 8], 16000h | RW | US | P
        mov DWORD [205000h + 16h * 8 + 4], 0
        mov DWORD [205000h + 17h * 8], 17000h | RW | US | P
        mov DWORD [205000h + 17h * 8 + 4], 0
        mov DWORD [205000h + 18h * 8], 18000h | RW | US | P
        mov DWORD [205000h + 18h * 8 + 4], 0
        mov DWORD [205000h + 20h * 8], 20000h | RW | US | P
        mov DWORD [205000h + 20h * 8 + 4], 0


        ; virtual address 0B8000h - 0B9FFFh 映射到物理地址 0B8000h - 0B9FFFh 上(2 个 4K 页)
        ; 不可执行, r/w = u/s = p = 1
        ; 用于 video 区域
        mov DWORD [205000h + 0B8h * 8], 0B8000h | RW | US | P
        mov DWORD [205000h + 0B8h * 8 + 4], XD
        mov DWORD [205000h + 0B9h * 8], 0B9000h | RW | US | P
        mov DWORD [205000h + 0B9h * 8], XD

        ; virutal address 0xfffffff800000000 - 0xfffffff800001fff (2 个 4K 页)
        ; 映射到物理地址 410000 - 411FFFh 上
        ; 不可执行, 用户不可访问
        ; kernel 数据区
        mov DWORD [206000h], 410000h | RW | P
        mov DWORD [206004h], XD
        mov DWORD [206000h + 8], 411000h | RW | P
        mov DWORD [206000h + 8 + 4], XD


        ; virtual address 0FFFFFFF8_10000000h - 0FFFFFFF8_10001FFFh(2 个 4K 页)
        ; 映射到物理地址 412000h - 412FFFh 上
        ; 用户不可访问
        ; kernel 执行区域
        mov DWORD [208000h], 412000h | RW | P
        mov DWORD [208004h], 0

        ; insterrupt IST1, 不可执行
        mov DWORD [208000h + 1 * 8], 413000h | RW | P
        mov DWORD [208000h + 1 * 8 + 4], XD
        
        ; virutal address 00007FFF_FFE00000h - 00007FFF_FFE03FFFh(4 个 4K 页)
        ; 映射到物理地址 607000h - 60AFFFh 上
        ; 用于 user stack 区
        mov DWORD [303000h], 414000h | RW | US | P                        ; 处理器 0
        mov DWORD [303000h + 4], 0
        mov DWORD [303000h + 1 * 8], 415000h | RW | US | P                ; 处理器 1
        mov DWORD [303000h + 1 * 8 + 4], 0
        mov DWORD [303000h + 2 * 8], 416000h | RW | US | P                ; 处理器 2
        mov DWORD [303000h + 2 * 8 + 4], 0
        mov DWORD [303000h + 3 * 8], 417000h | RW | US | P                ; 处理器 3
        mov DWORD [303000h + 3 * 8 + 4], 0

            ; virutal address 400000h 映射到物理地址 400000h 上(使用 4K 页)
        ; 不可执行, 用户不可访问, 用于 DS save 区域
        mov DWORD [207000h], 400000h | RW | P
        mov DWORD [207004h], XD
init_page_done:
        ret
        

        bits 64        

;-----------------------------------------
; void clear_4K_page64(long address);
; input:  rsi: address
;------------------------------------------        
clear_4k_page64:
clear_4K_page64:
        pxor xmm1, xmm1
        mov rax, 4096
clear_4K_page64_loop:        
        movdqu [rsi + rax - 16], xmm1
        movdqu [rsi + rax - 32], xmm1
        movdqu [rsi + rax - 48], xmm1
        movdqu [rsi + rax - 64], xmm1
        movdqu [rsi + rax - 80], xmm1
        movdqu [rsi + rax - 96], xmm1
        movdqu [rsi + rax - 112], xmm1
        movdqu [rsi + rax - 128], xmm1
        sub rax, 128
        jnz clear_4K_page64_loop
        ret
;----------------------------------
; clear_4K_pages64(): 清数个 4K 页
; input:
;                rsi: address,        rdi: number
;----------------------------------
clear_4k_pages64:
clear_4K_pages64:
        test rdi, rdi
        jz clear_4K_pages64_done
clear_4K_pages64_loop:        
        call clear_4K_page64
        add rsi, 0x1000
        dec rdi
        jnz clear_4K_pages64_loop
        
clear_4K_pages64_done:        
        ret        
        

;---------------------------------------------
; get_pml4e(): 得到 PML4E 值
; input:
;       rsi-virtual address
; output:
;       rax-pml4e
;--------------------------------------------
get_pml4e:
        mov rax, rsi
        shr rax, 39
        and rax, 1FFh
        mov rax, [200000h + rax * 8]
        ret

;--------------------------------------------
; get_pdpt(): 得到 PDPT 表基地址
; intpu:
;       rsi-virutal address
; output:
;       rax-PDPT base address
;--------------------------------------------
get_pdpt:
        push rbx
        call get_maxphyaddr_select_mask
        call get_pml4e
        and rax, [maxphyaddr_select_mask]
        mov rbx, 0FFFFFFFFFFFFF000h
        and rax, rbx
        pop rbx
        ret


;--------------------------------------
; get_pdpe(): 得到 PDPE 值
; input:
;       rsi-virtual address
; output:
;       rax-PDPE
;--------------------------------------
get_pdpe:
        push rbx
        mov rbx, rsi
        shr rbx, 30
        and rbx, 1FFh
        call get_pdpt
        mov rax, [rax + rbx * 8]
        pop rbx
        ret

get_pdt:
        push rbx
        call get_pdpe
        and rax, [maxphyaddr_select_mask]
        mov rbx, 0FFFFFFFFFFFFF000h
        and rax, rbx
        pop rbx
        ret

get_pde:
        push rbx
        mov rbx, rsi
        shr rbx, 21
        and rbx, 1FFh
        call get_pdt
        mov rax, [rax + rbx * 8]
        pop rbx
        ret

get_pt:
        push rbx
        call get_pde
        and rax, [maxphyaddr_select_mask]
        mov rbx, 0FFFFFFFFFFFFF000h
        and rax, rbx        
        pop rbx
        ret

get_pte:
        push rbx
        mov rbx, rsi
        shr rbx, 12
        and rbx, 1FFh
        call get_pt
        and rax, [rax + rbx * 8]
        pop rbx
        ret

;-----------------------------------------------------------------
; get_maxphyaddr_select_mask(): 计数出 MAXPHYADDR 值的 SELECT MASK
; output:
;       rax-maxphyaddr select mask
; 描述: 
;       select mask 值用于取得 MAXPHYADDR 对应的物理地址值
; 例如: 
;       MAXPHYADDR = 36 时: select mask = 0000000F_FFFFFFFFh
;       MAXPHYADDR = 40 时: select mask = 000000FF_FFFFFFFFh
;       MAXPHYADDR = 52 时: select mask = 000FFFFF_FFFFFFFFh
;-----------------------------------------------------------------
get_maxphyaddr_select_mask:
        push rcx
        push rdx
        LIB32_GET_MAXPHYADDR_CALL
        lea rcx, [rax - 64]
        neg rcx
        mov rax, -1
        shl rax, cl
        shr rax, cl                            ; 去除高位
        mov [maxphyaddr_select_mask], rax
        pop rdx
        pop rcx
        ret


;-------------------------------------------
; dump_long_page():
; input:
;                rsi: virtual address
;-------------------------------------------
dump_long_page:
        push r10
        push r12
        push rbx
        push rdx
; 使用 r10 来保存 virtual address, 以防在调用 32 位 lib32 库里冲掉寄存器值        
        mov r10, rsi                                
        
        call get_maxphyaddr_select_mask

; 打印 PML4E        
        mov esi, pml4e_msg
        LIB32_PUTS_CALL
        
        mov rbx, [pml4t_base]                ; PML4T base
        mov rax, r10
        shr rax, 39                                
        and rax, 1FFh                       ; PML4E index
        
; 使用 r12 来保存 table entry, 以防在调用 32 位 lib32 库里冲掉 64 位的寄存器
        mov r12, [rbx + rax * 8]            ; 读 pml4e
        
; 判断 P 标志        
        bt r12, 0
        jc pml4e_next
        mov esi, not_available
        LIB32_PUTS_CALL
        LIB32_PRINTLN_CALL
        jmp dump_long_page_done
        
pml4e_next:
        mov rax, 0FFFFFFFFFFFFF000h
        and rax, [maxphyaddr_select_mask] 
        and rax, r12
        mov [pdpt_base], rax
        mov rdi, rax
        mov rsi, rax
        shr rdi, 32
        LIB32_PRINT_QWORD_VALUE_CALL
        LIB32_PRINTBLANK_CALL
        mov esi, attr_msg
        LIB32_PUTS_CALL
        mov rsi, r12
        bt rsi, 63                              ; XD 标志位
        setc dil
        movzx rdi, dil
        shl rdi, 13
        and rsi, 0FFFh        
        or rsi, rdi
        shl rsi, 18
        LIB32_REVERSE_CALL                        ; 反转
        mov esi, eax
        mov edi, pml4e_flags
        LIB32_DUMP_FLAGS_CALL
        LIB32_PRINTLN_CALL
        bt r12, 7                               ; 检测保留位是否为 0
        mov edi, 0
        mov esi, reserved_error
        cmovnc esi, edi
        LIB32_PUTS_CALL

; 打印 pdpte
        mov esi, pdpte_msg
        LIB32_PUTS_CALL        
        mov rax, r10        
        shr rax, 30
        and rax, 0x1ff                          ; pdpte index
        mov rbx, [pdpt_base]
        mov r12, [rbx + rax * 8]                ; pdpte
        bt r12, 0                               ; P = 1 ?
        jc pdpte_next
        mov esi, not_available
        LIB32_PUTS_CALL
        LIB32_PRINTLN_CALL
        jmp dump_long_page_done        
pdpte_next:
        bt r12, 7                               ; PS = 1 ?
        jnc dump_pdpte_4k_2m
; 1G page 的 pdpte 结构
        ;mov rax, 0x000fffffc0000000
        mov rax, 0FFFFFFFFFFFFE000h
        and rax, [maxphyaddr_select_mask]
        and rax, r12
        mov rsi, rax
        mov rdi, rax        
        shr rdi, 32
        LIB32_PRINT_QWORD_VALUE_CALL
        LIB32_PRINTBLANK_CALL
        mov esi, attr_msg
        LIB32_PUTS_CALL
        mov rsi, r12         
        bt rsi, 63                               ; XD 标志位
        setc dil
        movzx rdi, dil
        shl rdi, 13
        and rsi, 0x1fff        
        or rsi, rdi
        shl rsi, 18
        LIB32_REVERSE_CALL                        ; 反转
        mov esi, eax
        mov edi, pdpte_long_1g_flags
        LIB32_DUMP_FLAGS_CALL
        LIB32_PRINTLN_CALL
        test r12, 3FFFE000h                     ; 检测保留位是否为 0
        mov edi, 0
        mov esi, reserved_error
        cmovz esi, edi
        LIB32_PUTS_CALL
        jmp dump_long_page_done                
;;　4K, 2M 页的 pdpte 结构                         
dump_pdpte_4k_2m:
        mov rax, 0FFFFFFFFFFFFF000h
        and rax, [maxphyaddr_select_mask]
        and rax, r12
        mov [pdt_base], rax        
        mov rsi, rax
        mov rdi, rax        
        shr rdi, 32
        LIB32_PRINT_QWORD_VALUE_CALL
        LIB32_PRINTBLANK_CALL
        mov esi, attr_msg
        LIB32_PUTS_CALL
        mov rsi, r12
        bt rsi, 63                                 ; XD 标志位
        setc dil
        movzx rdi, dil
        shl rdi, 13
        and rsi, 0x1fff
        or rsi, rdi
        shl rsi, 18
        LIB32_REVERSE_CALL                        ; 反转
        mov esi, eax
        mov edi, pdpte_long_flags
        LIB32_DUMP_FLAGS_CALL
        LIB32_PRINTLN_CALL

; 打印 PDE                 
        mov esi, pde_msg
        LIB32_PUTS_CALL        
        mov rax, r10
        shr rax, 21
        and rax, 0x1ff
        mov rbx, [pdt_base]
        mov r12, [rbx + rax * 8]
        bt r12, 0                                  ; p ?
        jc pde_next
        mov esi, not_available
        LIB32_PUTS_CALL
        LIB32_PRINTLN_CALL
        jmp dump_long_page_done                
pde_next:        
        bt r12, 7                                  ; PS = 1 ?
        jnc dump_pde_4k
; 2m page 的 pde 结构
;        mov rax, 0x000ffffffff00000
        mov rax, 0FFFFFFFFFFFFE000h
        and rax, [maxphyaddr_select_mask]
        and rax, r12
        mov rsi, rax
        mov rdi, rax        
        shr rdi, 32
        LIB32_PRINT_QWORD_VALUE_CALL
        LIB32_PRINTBLANK_CALL
        mov esi, attr_msg
        LIB32_PUTS_CALL
        mov rsi, r12
        bt rsi, 63                                 ; XD 标志位
        setc dil
        movzx rdi, dil
        shl rdi, 13
        and rsi, 0x1fff
        or rsi, rdi
        shl rsi, 18
        LIB32_REVERSE_CALL                        ; 反转
        mov esi, eax
        mov edi, pde_long_2m_flags
        LIB32_DUMP_FLAGS_CALL
        LIB32_PRINTLN_CALL
        test r12, 01FE000h                      ; 检测保留位是否为 0
        mov edi, 0
        mov esi, reserved_error
        cmovz esi, edi
        LIB32_PUTS_CALL
        jmp dump_long_page_done        
; 打印 4K page 的　pde
dump_pde_4k:
        mov rax, 0FFFFFFFFFFFFF000h
        and rax, [maxphyaddr_select_mask]
        and rax, r12
        mov [pt_base], rax        
        mov rsi, rax
        mov rdi, rax        
        shr rdi, 32
        LIB32_PRINT_QWORD_VALUE_CALL
        LIB32_PRINTBLANK_CALL
        mov esi, attr_msg
        LIB32_PUTS_CALL
        mov rsi, r12 
        bt rsi, 63                                 ; XD 标志位
        setc dil
        movzx rdi, dil
        shl rdi, 13
        and rsi, 0x1fff
        or rsi, rdi
        shl rsi, 18
        LIB32_REVERSE_CALL                        ; 反转
        mov esi, eax
        mov edi, pde_long_4k_flags
        LIB32_DUMP_FLAGS_CALL
        LIB32_PRINTLN_CALL
                
; 打印 pte
        mov esi, pte_msg
        LIB32_PUTS_CALL        
        mov rax, r10
        shr rax, 12
        and rax, 0x1ff
        mov rbx, [pt_base]
        mov r12, [rbx + rax * 8]
        bt r12, 0                                    ; p ?
        jc pte_next
        mov esi, not_available
        LIB32_PUTS_CALL
        LIB32_PRINTLN_CALL
        jmp dump_long_page_done        
        
pte_next:
        mov rax, 0FFFFFFFFFFFFF000h
        and rax, [maxphyaddr_select_mask]
        and rax, r12
        mov rsi, rax
        mov rdi, rax        
        shr rdi, 32
        LIB32_PRINT_QWORD_VALUE_CALL
        LIB32_PRINTBLANK_CALL
        mov esi, attr_msg
        LIB32_PUTS_CALL
        mov rsi, r12         
        bt rsi, 63                                 ; XD 标志位
        setc dil
        movzx rdi, dil
        shl rdi, 13
        and rsi, 0x1fff
        or rsi, rdi
        shl rsi, 18
        LIB32_REVERSE_CALL                        ; 反转
        mov esi, eax
        mov edi, pte_long_4k_flags
        LIB32_DUMP_FLAGS_CALL
        LIB32_PRINTLN_CALL        
        
dump_long_page_done:        
        pop rdx
        pop rbx
        pop r12
        pop r10
        ret


        
;********* page table base *******
pml4t_base      dq PML4T_BASE
pdpt_base       dq 0
pdt_base        dq 0
pt_base         dq 0

maxphyaddr_select_mask  dq 0

pml4e_msg       db 'PML4E: base=0x', 0
pdpte_msg       db 'PDPTE: base=0x', 0
pde_msg         db 'PDE:   base=0x', 0
pte_msg         db 'PTE:   base=0x', 0
attr_msg        db 'Attr: ',0

not_available   db '***  not available (P=0)', 0
reserved_error  db '       <ERROR: reserved bit is not zero!>', 10, 0
                

;********* entry flags **********        

p_flags         db 'p',0
rw_flags        db 'r/w',0
us_flags        db 'u/s',0
pwt_flags       db 'pwt', 0
pcd_flags       db 'pcd', 0
a_flags         db 'a',0
d_flags         db 'd', 0
ps_flags        db 'ps',0
g_flags         db 'g',0
pat_flags       db 'pat',0
ignore_flags    db '-',0
blank_flags     db '   ', 0
reserved_flags  db '0', 0
xd_flags        db 'xd', 0

;************ flags ***********
pml4e_flags             dd xd_flags, blank_flags, ignore_flags, ignore_flags, ignore_flags, ignore_flags
                        dd reserved_flags, ignore_flags, a_flags, pcd_flags, pwt_flags, us_flags, rw_flags, p_flags, -1
                                
pdpte_long_1g_flags     dd xd_flags, pat_flags, ignore_flags, ignore_flags, ignore_flags, g_flags, ps_flags
                        dd d_flags, a_flags, pcd_flags, pwt_flags, us_flags, rw_flags, p_flags, -1
                                        
pdpte_long_flags        dd xd_flags, blank_flags, ignore_flags, ignore_flags, ignore_flags, ignore_flags                
                        dd ps_flags, ignore_flags, a_flags, pcd_flags, pwt_flags, us_flags, rw_flags, p_flags, -1

pde_long_2m_flags       dd xd_flags                                                
                        dd pat_flags, ignore_flags, ignore_flags, ignore_flags, g_flags, ps_flags
                        dd d_flags, a_flags, pcd_flags, pwt_flags, us_flags, rw_flags, p_flags, -1
                                
pde_long_4k_flags       dd xd_flags        
                        dd blank_flags, ignore_flags, ignore_flags, ignore_flags, ignore_flags, ps_flags
                        dd ignore_flags, a_flags, pcd_flags, pwt_flags, us_flags, rw_flags, p_flags, -1
                                        
pte_long_4k_flags       dd xd_flags
                        dd blank_flags, ignore_flags, ignore_flags, ignore_flags, g_flags, pat_flags
                        dd d_flags, a_flags, pcd_flags, pwt_flags, us_flags, rw_flags, p_flags, -1
                                        