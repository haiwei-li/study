;*************************************************
;* mem.asm                                       *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************


;;
;; 说明: 
;;      1) 实现 64/32 位下的 kernel/user stack 以及 kernel/user pool 分配函数
;;      2) 使用 32 位编译
;;


;-----------------------------------------------------------------------
; alloc_user_stack_4k_base()
; input:
;       none
; output:
;       eax - 4K stack base(虚拟地址)
; 描述: 
;       1)分配一个4K页面大小的 user stack base的可用值         
;       2)并更新当前 user stack base 记录
;       3) 在 x64 下 rax 返回 64 位 user stack base
;-----------------------------------------------------------------------
alloc_user_stack_4k_base:
alloc_user_stack_base:
        mov esi, SDA.UserStackBase                                      ; User stack 分配记录
        jmp do_alloc_4k_base



;-----------------------------------------------------------------------
; alloc_user_stack_4k_physical_base()
; input:
;       none
; output:
;       eax - 4K stack base(物理地址)
; 描述: 
;       1)分配一个4K页面大小的 user stack base的可用值         
;       2)并更新当前 user stack base 记录
;       3) X64 下 rax 返回 64 位 user stack base 值
;-----------------------------------------------------------------------
alloc_user_stack_4k_physical_base:
alloc_user_stack_physical_base:
        mov esi, SDA.UserStackPhysicalBase                              ; User stack physical 空间分配记录
        jmp do_alloc_4k_base



;-----------------------------------------------------------------------
; alloc_kernel_stack_4k_base()
; input:
;       none
; output:
;       eax - 4K stack base(虚拟地址) 
; 描述: 
;       1)分配一个4K页面大小的 kernel stack base的可用值         
;       2)并更新当前 kernel stack base 记录
;       3) X64 下返回 64 位值
;-----------------------------------------------------------------------
alloc_kernel_stack_4k_base:
alloc_kernel_stack_base:
        mov esi, SDA.KernelStackBase                                    ; kernel stack 空间分配记录
        jmp do_alloc_4k_base




;-----------------------------------------------------------------------
; alloc_kernel_stack_4k_physical_base()
; input:
;       none
; output:
;       eax - 4K stack base(物理地址)   
; 描述: 
;       1)分配一个4K页面大小的 kernel stack base的可用值         
;       2)并更新当前 kernel stack base 记录
;       3) X64 下返回 64 位值
;-----------------------------------------------------------------------
alloc_kernel_stack_4k_physical_base:
alloc_kernel_stack_physical_base:
        mov esi, SDA.KernelStackPhysicalBase                            ; kernel stack 物理空间分配记录
        jmp do_alloc_4k_base


        

;-----------------------------------------------------------------------
; alloc_user_pool_4k_base()
; input:
;       none
; output:
;       eax - 4K pool base(虚拟地址)
;-----------------------------------------------------------------------
alloc_user_pool_4k_base:      
alloc_user_pool_base:
        mov esi, SDA.UserPoolBase                                       ; user pool 空间分配记录
        jmp do_alloc_4k_base
        


;-----------------------------------------------------------------------
; alloc_user_pool_4k_physical_base()
; input:
;       none
; output:
;       eax - 4K pool base(物理地址) 
;-----------------------------------------------------------------------
alloc_user_pool_4k_physical_base:      
alloc_user_pool_physical_base:
        mov esi, SDA.UserPoolPhysicalBase                               ; user pool 物理空间分配记录
        jmp do_alloc_4k_base
        
                        

;-----------------------------------------------------------------------
; alloc_kernel_pool_4k_base()
; input:
;       none
; output:
;       eax - 4K pool base(虚拟地址)
;-----------------------------------------------------------------------
alloc_kernel_pool_4k_base:      
alloc_kernel_pool_base:
        mov esi, SDA.KernelPoolBase                                     ; kernel pool 空间分配记录
        jmp do_alloc_4k_base
        
       
        

;-----------------------------------------------------------------------
; alloc_kernel_pool_4k_physical_base()
; input:
;       none
; output:
;       eax - 4K pool base(物理地址) 
;-----------------------------------------------------------------------
alloc_kernel_pool_4k_physical_base:      
alloc_kernel_pool_physical_base:
        mov esi, SDA.KernelPoolPhysicalBase                             ; kernel pool 物理空间分配记录
        jmp do_alloc_4k_base


;-----------------------------------------------------------------------
; alloc_kernel_pool_base_n()
; input:
;       esi - size
; output:
;       eax - vritual address of kernel pool
; 描述: 
;       1) 在 kernel pool 里分配 n 页空间
;-----------------------------------------------------------------------
alloc_kernel_pool_base_n:
        mov eax, esi
        shl eax, 12
        mov esi, SDA.KernelPoolBase                                     ; kernel pool 空间分配记录
        jmp do_alloc_base
        
;-----------------------------------------------------------------------
; alloc_kernel_pool_physical_base_n()
; input:
;       esi - size
; output:
;       eax - physical address of pool
; 描述: 
;       1)在 pool 里分配 n 页物理空间
;-----------------------------------------------------------------------
alloc_kernel_pool_physical_base_n:
        mov eax, esi
        shl eax, 12
        mov esi, SDA.KernelPoolPhysicalBase                             ; kernel pool 物理空间分配记录
        jmp do_alloc_base
        



;-----------------------------------------------------------------------
; do_alloc_4k_base()
; input:
;       esi - 空间分配记录号
; output:
;       eax - 返回一个 4k 空间 base 值
; 描述:
;       1) 这是内部使用的实现函数, 用来在空间分配记录进行分配空间
;-----------------------------------------------------------------------
do_alloc_4k_base:

        mov eax, 4096                                                   ; 分配粒度为 4K 

do_alloc_base:

%ifdef __STAGE1
        lock xadd [fs: esi], eax
%elifdef __X64
        DB 0F0h, 64h, 48h, 0Fh, 0C1h, 06h                               ; lock xadd [fs: rsi], rax
%else
        lock xadd [fs: esi], eax
%endif        
        ret







;-----------------------------------------------------------------------
; get_kernel_stack_4k_pointer(): 动态获得取一个 kernel stack pointer 值
; input:
;       none
; output:
;       eax - stack pointer
; 描述: 
;       1) 分配一个 4K 的 kernel stack 空间, 映射到物理地址
;       2) eax 返回 stack 空间的顶部(16字节边界)
;-----------------------------------------------------------------------
get_kernel_stack_4k_pointer:
get_kernel_stack_pointer:
        push ebx
        ;;
        ;; 分配 stack 空间
        ;;
        call alloc_kernel_stack_4k_base                         ; 分配虚拟地址
        REX.Wrxb
        mov ebx, eax
        call alloc_kernel_stack_4k_physical_base                ; 分配物理地址


        ;;
        ;; 下面映射虚拟地址
        ;;
        REX.Wrxb
        mov esi, ebx                                            ; 虚拟地址
        REX.Wrxb
        mov edi, eax                                            ; 物理地址
        REX.wrxB
        mov eax, XD | RW | P                                    ; 页属性
        call do_virtual_address_mapping

        REX.Wrxb
        add ebx, 0FF0h                                          ; 返回 stack 顶部
        REX.Wrxb
        mov eax, ebx
        pop ebx
        ret
        

        

;-----------------------------------------------------------------------
; get_user_stack_4k_pointer(): 动态获得取一个 user stack pointer 值
; input:
;       none
; output:
;       eax - stack pointer
; 描述: 
;       1) 分配一个 4K 的 user stack 空间, 映射到物理地址
;       2) eax 返回 stack 空间的顶部(16字节边界)
;-----------------------------------------------------------------------
get_user_stack_4k_pointer:
get_user_stack_pointer:
        push ebx
        
        ;;
        ;; 分配 stack 空间
        ;;
        call alloc_user_stack_4k_base                                   ; 分配虚拟地址
        REX.Wrxb
        mov ebx, eax
        call alloc_user_stack_4k_physical_base                          ; 分配物理地址
        
        ;;
        ;; 映射虚拟地址
        ;;
        REX.Wrxb
        mov esi, ebx                                                    ; 虚拟地址
        REX.Wrxb
        mov edi, eax                                                    ; 物理地址
        REX.wrxB
        mov eax, XD | US | RW | P   
        call do_virtual_address_mapping

        REX.Wrxb
        add ebx, 0FF0h                                                  ; 返回 stack 顶部
        REX.Wrxb
        mov eax, ebx
        pop ebx
        ret




        
;----------------------------------------------------------------------------
; alloc_kernel_pool_4k()
; input:
;       none
; output:
;       pool if successful, 0 if failure
; 描述: 
;       1) 动态分配一个 4K 的 pool 空间
;----------------------------------------------------------------------------        
alloc_kernel_pool_4k:
alloc_kernel_pool:
        push ebx
        
        call alloc_kernel_pool_4k_physical_base                 ; 分配 pool 物理地址空间
        REX.Wrxb
        mov edi, eax
        call alloc_kernel_pool_4k_base                          ; 分配 pool virtual address
        REX.Wrxb
        mov ebx, eax

        REX.Wrxb
        mov esi, eax
        REX.wrxB
        mov eax, RW | P                                         ; read/write, present
        call do_virtual_address_mapping
        
        ;;
        ;; 清 kernel pool 
        ;;
        REX.Wrxb
        mov esi, ebx
        call clear_4k_buffer
        
        REX.Wrxb       
        mov eax, ebx                                            ; 返回 kernel pool 空间
        pop ebx
        ret



;----------------------------------------------------------------------------
; alloc_kernel_pool_n()
; input:
;       esi - n
; output:
;       eax - 虚拟地址
;       edx - 物理地址
; 描述: 
;       1) 动态分配 n 页的 pool 空间
;----------------------------------------------------------------------------        
alloc_kernel_pool_n:
        push ebx
        push ecx
        mov ecx, esi

        call alloc_kernel_pool_physical_base_n                  ; 分配 N 页物理地址空间
        REX.Wrxb
        mov edx, eax                                            ; edi = physical address
        mov esi, ecx                                            ; N 页        
        call alloc_kernel_pool_base_n                           ; 分配 N 页虚拟地址空间
        REX.Wrxb
        mov ebx, eax                                            ; ebx = virtual address

        REX.Wrxb
        mov esi, eax                                            ; esi = VA
        REX.Wrxb
        mov edi, edx                                            ; edi = PA
        REX.wrxB
        mov eax, RW | P                                         ; read/write, present        
%ifdef __X64
        DB 41h, 89h, 0C9h                                       ; mov r9d, ecx
%endif        
        call do_virtual_address_mapping_n
        
        ;;
        ;; 清 kernel pool 
        ;;
        REX.Wrxb
        mov esi, ebx
        mov edi, ecx
        call clear_4k_buffer_n
        
        REX.Wrxb       
        mov eax, ebx                                            ; 返回 kernel pool 空间
        pop ecx
        pop ebx
        ret
        
        


;-----------------------------------------------------------------------
; alloc_user_pool_4k()
; input:
;       none
; output:
;       pool if successful, 0 if failure
; 描述: 
;        1) 动态获得取一个 user pool
;-----------------------------------------------------------------------
alloc_user_pool_4k:
alloc_user_pool:
        push ebx
        
        call alloc_user_pool_4k_physical_base                   ; physical address
        REX.Wrxb
        mov edi, eax
        call alloc_user_pool_4k_base                            ; virtual address
        REX.Wrxb
        mov ebx, eax
               
        REX.Wrxb
        mov esi, eax
        REX.wrxB
        mov eax, US | RW | P                            ; read/write, user, present
        call do_virtual_address_mapping

        ;;
        ;; 清 pool 
        ;;
        REX.Wrxb
        mov esi, ebx
        call clear_4k_buffer
        
        REX.Wrxb
        mov eax, ebx                                    ; 返回 pool
        pop ebx
        ret
        
        

%if 0        
        
        
;--------------------------------------------------------------------------
; free_kernel_pool_4k_map_to_physical_address(): 
; input:
;       esi - pool pointer
; output:
;       0 if successful, otherwis failure
; 描述: 
;       1) 提供的 pool 地址, 来自于 alloc_kernel_pool_4k_map_to_physical_address 的分配
;       2) 与 alloc_kernel_pool_4k_map_to_physical_address 配套使用
;--------------------------------------------------------------------------
free_kernel_pool_4k_map_to_physical_address:
        ;;
        ;; 进行解映射
        call do_virtual_address_unmapped
        cmp eax, UNMAPPED_SUCCESS
        je free_kernel_pool_4k.next
        
        ;;
        ;; 解映射失败, 直接返回
        ret


;--------------------------------------------------------------------------
; free_kernel_pool_4k()
; input:
;       esi - pool pointer
; output:
;       0 if successful, otherwis failure
;--------------------------------------------------------------------------
free_kernel_pool_4k:
        ;;
        ;; 进行解映射
        call do_virtual_address_unmapped
        cmp eax, UNMAPPED_SUCCESS
        jne free_kernel_pool_4k.done
        
        ;;
        ;; 释放物理空间
        mov eax, -4096
        lock xadd [fs: SDA.KernelPoolPhysicalBase], eax         ; 更新物理 pool base


free_kernel_pool_4k.next:
        ;;
        ;; 释放 pool 空间
        mov eax, -4096
        lock xadd [fs: SDA.KernelPoolBase], eax                 ; 更新可用 pool base
        mov eax, UNMAPPED_SUCCESS
                
free_kernel_pool_4k.done:        
        ret

        

;----------------------------------------------------------------------------
; alloc_user_pool_4k_map_to_physical_address()
; input:
;       esi - physical address
; output:
;       pool if successful, 0 if failure
; 描述: 
;       1) 分配一个 4k 的 user pool 空间
;       2) 将 pool 空间映射到提供的物理地址上
;       3) 返回 pool 空间
;----------------------------------------------------------------------------
alloc_user_pool_4k_map_to_physical_address:
        push ebx
        mov edi, esi                            ; physical address
        and edi, 0FFFFF000h
        jmp alloc_user_pool_4k.next
        


        
        


;--------------------------------------------------------------------------
; free_user_pool_4k_map_to_physical_address()
; input:
;       esi - pool pointer
; output:
;       0 if successful, otherwis failure
; 描述: 
;       1) 提供的 pool 地址, 来自于 alloc_user_pool_4k_map_to_physical_address 的分配
;       2) 与 alloc_user_pool_4k_map_to_physical_address 配套使用
;--------------------------------------------------------------------------
free_user_pool_4k_map_to_physical_address:
        ;;
        ;; 进行解映射
        call do_virtual_address_unmapped
        cmp eax, UNMAPPED_SUCCESS
        je free_user_pool_4k.next
        
        ;;
        ;; 解映射失败, 直接返回
        ret


;--------------------------------------------------------------------------
; free_user_pool_4k()
; input:
;       esi - pool pointer
; output:
;       0 if successful, otherwis failure
;--------------------------------------------------------------------------
free_user_pool_4k:
        ;;
        ;; 进行解映射
        call do_virtual_address_unmapped
        cmp eax, UNMAPPED_SUCCESS
        jne free_user_pool_4k.done
        
        ;;
        ;; 释放物理空间
        mov eax, -4096
        lock xadd [fs: SDA.UserPoolPhysicalBase], eax         ; 更新物理 pool base


free_user_pool_4k.next:
        ;;
        ;; 释放 pool 空间
        mov eax, -4096
        lock xadd [fs: SDA.UserPoolBase], eax                 ; 更新可用 pool base
        mov eax, UNMAPPED_SUCCESS
                
free_user_pool_4k.done:        
        ret        
        
%endif        