;*************************************************
;* dump_page32.asm                               *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************



;-------------------------------------------
; dump_pae_page(): 打印 PAE paging 模式页转换表信息
; input:
;                esi: virtual address(linear address)
; 注意: 
;                这个函数是在一对一映射的情况下(virtual address和physical address 一致)
;-------------------------------------------
dump_pae_page:
        push ecx
        push edx
        push ebx
        mov DWORD [pdpt_base], PDPT_BASE
        call get_maxphyaddr_select_mask
        mov ecx, esi
; 输出 PDPTE
        mov esi, pdpte_msg
        call puts
        mov eax, ecx
        shr eax, 30
        and eax, 0x3
        mov edi, [PDPT_BASE + eax * 8 + 4]
        mov esi, [PDPT_BASE + eax * 8]        
        mov edx, esi
        mov ebx, edi
        bt edx, 0
        jc pdpte_next
        mov esi, not_available
        call puts
        call println
        jmp dump_pae_page_done
pdpte_next:
        and esi, [maxphyaddr_select_mask]
        and esi, 0xfffff000
        and edi, [maxphyaddr_select_mask + 4]
        mov [pdt_base], esi
        mov [pdt_base + 4], edi
        call print_qword_value
        call printblank
        mov esi, attr_msg
        call puts
        mov esi, edx
        shl esi, 19
        call reverse
        mov esi, eax
        mov edi, pdpte_pae_flags
        call dump_flags
        call println
        mov eax, [maxphyaddr_select_mask + 4]   ; select mask 高位
        not eax
        test ebx, eax                           ; 检测高32位保留位是否为 0
        jnz print_reserved_error
        test edx, 1E6h                          ; 检测低32位保留位是否为 0 
print_reserved_error:
        mov esi, 0
        mov edi, reserved_error
        cmovnz esi, edi
        call puts

; 输出 PDE        
        mov esi, pde_msg
        call puts
        mov eax, ecx
        and eax, 0x3fe00000
        shr eax, 21
        mov ebx, [pdt_base]
        mov edi, [ebx + eax * 8 + 4]
        mov esi, [ebx + eax * 8]        
        mov edx, esi
        mov ebx, edi
        bt edx, 0
        jc pde_next
        mov esi, not_available
        call puts
        call println
        jmp dump_pae_page_done
pde_next:        
        bt edx, 7                                                ; PS=1 ?
        jnc dump_pae_4k_pde
        and esi, [maxphyaddr_select_mask]
        and esi, 0xffe00000
        and edi, [maxphyaddr_select_mask + 4]
;        and edi, 0x7fffffff                                ; 清XD位
        call print_qword_value
        call printblank
        mov esi, attr_msg
        call puts
        mov esi, edx
;        shl esi, 19
        ;; 新加入 xd 标志
        shl esi, 18
        btr esi, 31
        and ebx, 0x80000000
        or esi, ebx     
        call reverse
        mov esi, eax
        mov edi, pde_pae_2m_flags
        call dump_flags
        call println
        test edx, 0FE000h                       ; 检测保留位是否为 0
        mov esi, 0
        mov edi, reserved_error
        cmovnz esi, edi
        call puts
        jmp dump_pae_page_done                                
dump_pae_4k_pde:                
        and esi, 0xfffff000
        and edi, 0x7fffffff
        mov [pt_base], esi
        mov [pt_base + 4], edi
        call print_qword_value
        call printblank
        mov esi, attr_msg
        call puts
        mov esi, edx
;        shl esi, 19        
        ;新加入xd标志
        shl esi, 18
        btr esi, 31
        and ebx, 0x80000000
        or esi, ebx
        
        call reverse
        mov esi, eax
        mov edi, pde_pae_4k_flags
        call dump_flags
        call println
;; 输出 pte        
        mov esi, pte_msg
        call puts
        mov eax, ecx
        and eax, 0x1ff000
        shr eax, 12
        mov ebx, [pt_base]
        mov edi, [ebx + eax * 8 + 4]
        mov esi, [ebx + eax * 8]        
        mov edx, esi
        mov ebx, edi
        bt edx, 0
        jc pte_next
        mov esi, not_available
        call puts
        call println
        jmp dump_pae_page_done
pte_next:        
        and esi, 0xfffff000
        and edi, 0x7fffffff
        call print_qword_value
        call printblank
        mov esi, attr_msg
        call puts
        mov esi, edx
;        shl esi, 19        
        ; 新加入 xd 标志
        shl esi, 18
        btr esi, 31
        and ebx, 0x80000000
        or esi, ebx
        
        call reverse
        mov esi, eax
        mov edi, pte_pae_4k_flags
        call dump_flags
        call println        
dump_pae_page_done:        
        pop ebx
        pop edx
        pop ecx
        ret

;-------------------------------------------
; dump_page(): 打印页转换表信息
; input:
;                esi: virtual address(linear address)
; 注意: 
;                这个函数是在一对一映射的情况下(virtual address和physical address 一致)
;-------------------------------------------        
dump_page:
        push ecx
        push edx
        mov ecx, esi
        mov esi, pde_msg
        call puts
        mov esi, ecx
        call __get_32bit_paging_pde_index
        mov eax, [PDT32_BASE + eax * 4]
        mov edx, eax
        bt eax, 7                                        ; PS = ?
        jnc dump_4k_page
;; 输出 4M 页面的 PDE
        mov edi, eax
        mov esi, eax
        and esi, 0xffc00000                        ; 4M page frame
        shr edi, 13                                        ; base[39:32]
        and edi, 0xff                                ; base[39:32]
        call print_qword_value
        call printblank
        mov esi, attr_msg
        call puts
        mov esi, edx
        shl esi, 19
        call reverse
        mov esi, eax
        mov edi, pde_4m_flags
        call dump_flags
        call println
        jmp do_dump_page_done

dump_4k_page:        
;; 4K页面

; 1) PDE
        mov esi, edx
        and esi, 0xfffff000
        mov [pt_base], esi
        mov edi, 0
        call print_qword_value
        call printblank
        mov esi, attr_msg
        call puts
        mov esi, edx
        shl esi, 19
        call reverse
        mov esi, eax
        mov edi, pde_4k_flags
        call dump_flags
        call println
;; 2) PTE
        mov esi, pte_msg
        call puts
        mov esi, ecx
        call __get_32bit_paging_pte_index
        lea eax, [eax * 4]
        add eax, [pt_base]
        mov ecx, [eax]
        mov esi, ecx
        and esi, 0xfffff000
        mov edi, 0
        call print_qword_value
        call printblank
        mov esi, attr_msg
        call puts
        mov esi, ecx
        shl esi, 19
        call reverse
        mov esi, eax
        mov edi, pte_4k_flags
        call dump_flags
        call println
do_dump_page_done:        
        pop edx
        pop ecx
        ret        

       

;------------ 数据区 ------------
        

maxphyaddr_select_mask  dq 0








;********* page table base *******
pml4t_base      dq 0
pdpt_base       dq 0
pdt_base        dq 0
pt_base         dq 0

pml4t_msg       db 'PML4T: base=0x', 0
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
pdpte_pae_flags         dd blank_flags, ignore_flags, ignore_flags, ignore_flags, reserved_flags, reserved_flags
                        dd reserved_flags, reserved_flags, pcd_flags, pwt_flags, reserved_flags, reserved_flags
                        dd p_flags, -1
pde_pae_2m_flags        dd xd_flags                                                
pde_4m_flags            dd pat_flags, ignore_flags, ignore_flags, ignore_flags, g_flags, ps_flags
                        dd d_flags, a_flags, pcd_flags, pwt_flags, us_flags, rw_flags, p_flags, -1
pde_pae_4k_flags        dd xd_flags        
pde_4k_flags            dd blank_flags, ignore_flags, ignore_flags, ignore_flags, ignore_flags, ps_flags
                        dd ignore_flags, a_flags, pcd_flags, pwt_flags, us_flags, rw_flags, p_flags, -1
pte_pae_4k_flags        dd xd_flags
pte_4k_flags            dd blank_flags, ignore_flags, ignore_flags, ignore_flags, g_flags, pat_flags
                        dd d_flags, a_flags, pcd_flags, pwt_flags, us_flags, rw_flags, p_flags, -1
