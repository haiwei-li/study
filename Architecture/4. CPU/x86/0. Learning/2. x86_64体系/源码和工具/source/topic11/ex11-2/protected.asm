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
protected_length        dw        PROTECTED_END - PROTECTED_BEGIN       ; protected 模块长度

entry:
        
;; 为了完成实验，关闭时间中断和键盘中断
        call disable_timer

;; 设置 #PF handler
        mov esi, PF_HANDLER_VECTOR
        mov edi, page_fault_handler
        call set_interrupt_handler        

;; 设置 #GP handler
        mov esi, GP_HANDLER_VECTOR
        mov edi, GP_handler
        call set_interrupt_handler        

; 处理器编号
        inc DWORD [index]

;; 设置 sysenter/sysexit 使用环境
        call set_sysenter
        
        
; 初始化 paging 环境
        call init_32bit_paging
        
;设置 PDT 表地址        
        mov eax, PDT32_BASE
        mov cr3, eax

;设置 CR4.PSE
        call pse_enable
                
; 打开　paging
        mov eax, cr0
        bts eax, 31
        mov cr0, eax                
        
; 转到 long 模块
        ;jmp LONG_SEG
        
;测试二：在 CR0.WP=0时，在0级代码里写0x400000地址
;        mov DWORD [0x400000], 0                        

;测试三：CR0.WP=1时，写0x400000
;        mov eax, cr0
;        bts eax, WP_BIT
;        mov cr0, eax        
;        mov DWORD [0x400000], 0                                
                                
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

        mov esi, msg1
        call puts
        
        mov esi, 0x200000                ; dump virtual address 0x200000
        call dump_page
        
        mov esi, msg3
        call puts
        
        mov esi, 0x400000                ; dump virtual address 0x400000
        call dump_page
        
;; 测试一：在用户代码里往 0x400000 地址写数据将产生 #PF异常
;        mov DWORD [0x400000], 0

;        mov esi, msg3
;        call puts
        
;        mov esi, 0x400000                ; dump virtual address 0x400000
;        call dump_page
        
        
        jmp $

                        
msg1        db  'now: enable paging with 32-bit paging '
msg2        db  10, 10, '---> dump vritual address: 0x200000 ---', 10, 0
msg3        db  10, 10, '---> dump vritual address: 0x400000 ---', 10, 0





;;; 初始化 32-bit paging 模式使用环境

pse_enable:
        mov eax, 1
        cpuid
        bt edx, 3                                ; PSE support?
        jnc pse_enable_done
        mov eax, cr4
        bts eax, 4                                ; CR4.PSE = 1
        mov cr4, eax
pse_enable_done:        
        ret
        

;---------------------------------------------
; init_32bit_paging(): 建立 32-bit paging 环境
;---------------------------------------------
init_32bit_paging:
; 1) 0x000000-0x3fffff 映射到 0x0 page frame, 使用 4M 页面
; 2) 0x400000-0x400fff 映射到 0x400000 page frame 使用 4K 页面

;; PDT 表物理地址设在 0x200000 位置上, PT表物理地址在 0x201000位置上
; 1) 设置 PDT[0]（映射 0 page frame)
        mov DWORD [PDT32_BASE + 0], 0000h | PS | RW | US | P              ; base=0, PS=1,  P=1,R/W=1,U/S=1, 
        
; 2) 设置 PDT[1]
        ; PT表的地址在0x201000位置上，设置为supervisor,only-read 权限
        mov DWORD [PDT32_BASE + 1 * 4], 201000h | P                       ; PT base=0x201000, P=1

; 3) 设置 PT[0]（映射0x400000 page frame),设置为supervisor,only-read 权限
        mov DWORD [201000h + 0], 400000h | P                            ; page frame在0x400000, P=1
        ret





;--------------------------------------
; #PF handler
;-------------------------------------
page_fault_handler:
        jmp do_page_fault_handler
page_fault_msg db '---> now, enter #PF handler', 10, 0
do_page_fault_handler:        
        mov esi, pf_msg
        call puts
        jmp $
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