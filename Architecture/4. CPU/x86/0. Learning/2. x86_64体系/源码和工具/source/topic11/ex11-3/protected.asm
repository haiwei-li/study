; protected.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


%define NON_PAGING
%include "..\inc\support.inc"
%include "..\inc\protected.inc"

; 这是 protected 模块

        bits 32
        
        org PROTECTED_SEG - 2

PROTECTED_BEGIN:
protected_length        dw        PROTECTED_END - PROTECTED_BEGIN        ; protected 模块长度

entry:
        
;; 关闭8259中断
        call disable_8259

;; 设置 #PF handler
        mov esi, PF_HANDLER_VECTOR
        mov edi, page_fault_handler
        call set_interrupt_handler        

;; 设置 #GP handler
        mov esi, GP_HANDLER_VECTOR
        mov edi, GP_handler
        call set_interrupt_handler

        inc DWORD [index]
        
;; 设置 sysenter/sysexit 使用环境
        call set_sysenter

; 允许执行 SSE 指令        
        mov eax, cr4
        bts eax, 9                                ; CR4.OSFXSR = 1
        mov cr4, eax
        
        
;设置 CR4.PAE
        call pae_enable
        
; 开启 XD 功能
        call execution_disable_enable
                
; 初始化 paging 环境
        call init_pae32_paging
        
;设置 PDPT 表地址        
        mov eax, PDPT_BASE
        mov cr3, eax
                                
; 打开　paging
        mov eax, cr0
        bts eax, 31
        mov cr0, eax                
        
;=======================================


; 测试一：在XD页里执行代码
;        mov esi, user_start
;        mov edi, 0x400000                                ; 将 user代码复制到 0x400000 位置上
;        mov ecx, user_end - user_start
;        rep movsb
        
;        jmp DWORD 0x400000                                ; 跳转到 0x400000 上

                
; 转到 long 模块
        ;jmp LONG_SEG
                                
                                
; 进入 ring 3 代码
        push DWORD user_data32_sel | 0x3
        push DWORD USER_ESP
        push DWORD user_code32_sel | 0x3        
        push DWORD user_entry
        retf

        
;; 用户代码

user_entry:
        mov ax, user_data32_sel
        mov ds, ax
        mov es, ax

user_start:

;; 使用 puts()和 dump_pae_page() 的绝对地址形式        
        mov edx, puts
        mov ebx, dump_pae_page        
        
        mov esi, msg1
        call edx
        mov esi, 0x200000                ; dump virtual address 0x200000
        call ebx
        
        mov esi, msg3
        call edx        
        mov esi, 0x400000                ; dump virtual address 0x400000
        call ebx

        mov esi, msg4
        call edx        
        mov esi, 0x401000                ; dump virtual address 0x401000
        call ebx        
        
        mov esi, msg5
        call edx        
        mov esi, 0x600000                ; dump virtual address 0x600000
        call ebx
                
;        mov esi, msg6
;        call puts        
;        mov esi, 0x40000000                ; dump virtual address 0x40000000
;        call dump_pae_page
                        

        jmp $

user_end:

                        
msg1        db  'now: enable paging with PAE paging '
msg2        db  10, 10, '---> dump vritual address: 0x200000 <---', 10, 0
msg3        db  10, 10, '---> dump vritual address: 0x400000 <---', 10, 0
msg4        db  10, 10, '---> dump vritual address: 0x401000 <---', 10, 0
msg5        db  10, 10, '---> dump vritual address: 0x600000 <---', 10, 0
msg6        db  10, 10, '---> dump vritual address: 0x40000000 <---', 10, 0




;-------------------------------------------------------------
; init_page32_paging(): 初始化 32 位环境的 PAE paging 分页模式
;-------------------------------------------------------------
init_pae32_paging:
; 1) 0x000000-0x3fffff 映射到 0x0 page frame, 使用 2个 2M 页面
; 2) 0x400000-0x400fff 映射到 0x400000 page frame 使用 4K 页面


;; 清内存页面（解决一个很难查的 bug）
        mov esi, PDPT_BASE
        call clear_4k_page
        mov esi, 201000h
        call clear_4k_page
        mov esi, 202000h
        call clear_4k_page


;* PDPT_BASE 定义在 page.inc 
;; 1) 设置 PDPTE[0]
        mov DWORD [PDPT_BASE + 0 * 8], 201000h | P        ; base=0x201000, P=1
        mov DWORD [PDPT_BASE + 0 * 8 + 4], 0

        
;; 2) 设置 PDE[0], PDE[1] 以及 PDE[2]
        ;* PDE[0] 对应 virtual address: 0 到 1FFFFFh (2M页)
        ;* 使用 PS=1, R/W=1, U/S=1, P=1 属性
        ;** PDE[1] 对应 virtual address: 200000h 到 3FFFFFh (2M页）
        ;** 使用 PS=1,R/W=1, U/S=1, P=1 属性
        ;*** PDE[2] 对应 virtual address: 400000h 到 400FFFh (4K页）
        ;*** 使用 R/W=1, U/S=1, P=1
        mov DWORD [201000h + 0 * 8], 0000h | PS | RW | US | P 
        mov DWORD [201000h + 0 * 8 + 4], 0
        mov DWORD [201000h + 1 * 8], 200000h | PS | RW | US | P
        mov DWORD [201000h + 1 * 8 + 4], 0
        mov DWORD [201000h + 2 * 8], 202000h | RW | US | P
        mov DWORD [201000h + 2 * 8 + 4], 0
        
;; 3) 设置 PTE[0]
        ;** PTE[0] 对应 virtual address: 0x400000 到 0x400fff (4K页）
        ; 400000h 使用 Execution disable 位
        mov DWORD [202000h + 0 * 8], 400000h | P                      ; base=0x400000, P=1, R/W=U/S=0
        mov eax, [xd_bit]
        mov DWORD [202000h + 0 * 8 + 4], eax                          ; 设置 XD　位
        ret
                








;----------------------------------------------
; #PF handler;
;----------------------------------------------
page_fault_handler:
        jmp do_page_fault_handler
pfmsg   db '---> now, enter #PF handler', 10
        db 'occur at: 0x', 0
pfmsg2  db 10, 'fixed the error', 10, 0                
do_page_fault_handler:        
        add esp, 4                              ; 忽略 Error code
        push ecx
        push edx
        mov esi, pfmsg
        call puts
        
        mov ecx, cr2                            ; 发生#PF异常的virtual address
        mov esi, ecx
        call print_dword_value
        
        mov esi, pfmsg2
        call puts

;; 下面修正错误
        mov eax, ecx
        shr eax, 30
        and eax, 0x3                            ; PDPTE index
        mov eax, [PDPT_BASE + eax * 8]
        and eax, 0xfffff000
        mov esi, ecx
        shr esi, 21
        and esi, 0x1ff                          ; PDE index
        mov eax, [eax + esi * 8]
        btr DWORD [eax + esi * 8 + 4], 31       ; 清 PDE.XD
        bt eax, 7                               ; PDE.PS=1 ?
        jc do_pf_handler_done
        mov esi, ecx
        shr esi, 12
        and esi, 0x1ff                          ; PTE index
        and eax, 0xfffff000
        btr DWORD [eax + esi * 8 + 4], 31       ; 清 PTE.XD
do_page_fault_handler_done:        
        pop edx
        pop ecx
        iret

        

        
;******** include 中断 handler 代码 ********
%include "..\common\handler32.asm"


;********* include 模块 ********************
%include "..\lib\creg.asm"
%include "..\lib\cpuid.asm"
%include "..\lib\msr.asm"
%include "..\lib\pci.asm"
%include "..\lib\debug.asm"
%include "..\lib\page32.asm"
%include "..\lib\apic.asm"
%include "..\lib\pic8259A.asm"



;;************* 函数导入表  *****************

; 这个 lib32 库导入表放在 common\ 目录下，
; 供所有实验的 protected.asm 模块使用

%include "..\common\lib32_import_table.imt"


PROTECTED_END: