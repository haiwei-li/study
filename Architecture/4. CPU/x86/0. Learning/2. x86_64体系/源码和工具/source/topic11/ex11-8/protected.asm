; protected.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


%include "..\inc\support.inc"
%include "..\inc\protected.inc"

; 这是 protected 模块

        bits 32
        
        org PROTECTED_SEG - 2

PROTECTED_BEGIN:
protected_length        dw        PROTECTED_END - PROTECTED_BEGIN       ; protected 模块长度

entry:
        
;; 关闭8259中断
        call disable_8259

;; 设置 #PF handler
        mov esi, PF_HANDLER_VECTOR
        mov edi, PF_handler
        call set_interrupt_handler        

;; 设置 #GP handler
        mov esi, GP_HANDLER_VECTOR
        mov edi, GP_handler
        call set_interrupt_handler
        
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
        call init_pae_paging
        
;设置 PDPT 表地址        
        mov eax, PDPT_BASE
        mov cr3, eax
                                
; 打开　paging
        mov eax, cr0
        bts eax, 31
        mov cr0, eax               
                  
                
        
; 实验 ex11-8：测试 XD标志由 0 改为 1时的情形

; 1) 将测试函数复制到 0x400000位置上
        mov esi, func
        mov edi, 0x400000                                ; 将 user代码复制到 0x400000 位置上
        mov ecx, func_end - func
        rep movsb

        ; 设置0x400000地址最初为可执行
        mov DWORD [PT1_BASE + 0 * 8 + 4], 0

; 2）第 1 次执行 0x400000处的代码（此时是可执行的,XD=0），目的是：在 TLB 中建立相应的 TLB entry
        call DWORD 0x400000
        
; 3）将 0x400000 改为不可执行的，但是此时没刷新 TLB
        mov DWORD [PT1_BASE + 0 * 8 + 4], 0x80000000
        
; 4）第 2 次执行 0x400000 处的代码，仍然是正常的（此时，XD=1）
        call DWORD 0x400000                                

        mov esi, msg4
        call puts

; 5）主动刷新 TLB, 使 0x400000 的 TLB 失效
        invlpg [0x400000]

; 6) 第3次执行 0x400000 处的代码，将产生 #PF 异常
        call DWORD 0x400000
                
        jmp $
        
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

        jmp $



;; 测试函数
func:
        mov edx, puts
        mov ebx, dump_pae_page        
                
        mov esi, msg2
        call edx                
        mov esi, msg3
        call edx        
        mov esi, 0x400000                ; dump virtual address 0x400000
        call ebx
        ret
func_end:        

                        
msg1        db  'now: enable paging with PAE paging '
msg2        db   10, 'now: enter the 0x400000 address<---', 10, 0
msg3        db  '---> dump vritual address: 0x400000 <---', 10, 0
msg4        db  10, 'now: execution INVLPG instruction flush TLB !', 10, 10, 0




        
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