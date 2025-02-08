;*************************************************
;* dump_page64.asm                                *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************


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
; 使用 r10来保存 virtual address, 以防在调用 32位 lib32 库里冲掉寄存器值        
        mov r10, rsi                                
        
        call get_maxphyaddr_select_mask

; 打印 PML4E        
        mov esi, pml4e_msg
        LIB32_PUTS_CALL
        
        mov rbx, [pml4t_base]                ; PML4T base
        mov rax, r10
        shr rax, 39                                
        and rax, 1FFh                       ; PML4E index
        
; 使用 r12 来保存 table entry, 以防在调用 32位 lib32 库里冲掉64位的寄存器
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
        bt rsi, 63                              ; XD标志位
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
        bt rsi, 63                               ; XD标志位
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
        bt rsi, 63                                 ; XD标志位
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
        bt rsi, 63                                 ; XD标志位
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
        bt rsi, 63                                 ; XD标志位
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
        bt rsi, 63                                 ; XD标志位
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
                                        