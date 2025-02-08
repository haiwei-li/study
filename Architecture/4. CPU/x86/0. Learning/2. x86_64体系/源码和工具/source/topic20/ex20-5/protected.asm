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
        
;; 为了完成实验, 关闭时间中断和键盘中断
        call disable_timer
        
;; 设置 #PF handler
        mov esi, PF_HANDLER_VECTOR
        mov edi, PF_handler
        call set_interrupt_handler        

;; 设置 #GP handler
        mov esi, GP_HANDLER_VECTOR
        mov edi, GP_handler
        call set_interrupt_handler

; 设置 #DB handler
        mov esi, DB_HANDLER_VECTOR
        mov edi, DB_handler
        call set_interrupt_handler


;; 设置 sysenter/sysexit 使用环境
        call set_sysenter

;; 设置 system_service handler
        mov esi, SYSTEM_SERVICE_VECTOR
        mov edi, system_service
        call set_user_interrupt_handler 

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

        mov esi, PIC8259A_TIMER_VECTOR
        mov edi, timer_handler
        call set_interrupt_handler        

        mov esi, KEYBOARD_VECTOR
        mov edi, keyboard_handler
        call set_interrupt_handler                
        
        call init_8259A
        call init_8253        
;        call disable_8259
        call disable_timer
        call disable_keyboard
        sti
        
;========= 初始化设置完毕 =================


;; 实验　ex20-5: 测试DOS compatibility模式

        mov esi, FPU_VECTOR
        mov edi, fpu_handler
        call set_interrupt_handler

; 未开启 CR0.NE 位, 使用 DOS compatibility 模式处理
;        mov eax, cr0
;        bts eax, 5                        ; CR0.NE = 1
;        mov cr0, eax

        finit

       
; 清 mask 位
        call clear_mask
        
        fld1
        fdiv DWORD [a]
        mov esi, msg
        call puts
        fst DWORD [result]        
        mov esi, msg1
        call puts
        mov esi, result
        call print_dword_float

        jmp $
                                
a       dd 3.0
result  dd 0
msg     db 'test DOS compatibility mode...', 10, 0
msg1    db '1/3 = ', 0
fh_msg1 db 10, '>>> now: enter floating-point exception handler, occur at 0x',  0
fh_msg2 db 'exit the floating-point exception handler <<<', 10, 10, 0

;-----------------------------------
; FPU ERROR (DOS compatibility)
;-----------------------------------
fpu_handler:
        push ebp
        mov ebp, esp
        sub esp, 32
        mov esi, fh_msg1
        call puts
        mov esi, [ebp + 4]
        call print_dword_value
        call println        
        
; 置 IGNNE #        
        mov al, 00
        out 0xf0, al
        fstenv [esp]        
        fclex
        call dump_8259_isr       
        call dump_x87_status       
        call dump_data_register

; 清image中status 寄存器
        or WORD [esp], 0x3f              ;mask all
        and WORD [esp + 4], 0x7f00      ; 清异常标志, B 标志
        fldenv [esp]

; EOI 命令                
        call write_slave_EOI
        call write_master_EOI
        mov esi, fh_msg2
        call puts        
        mov esp, ebp
        pop ebp
        iret


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






%define APIC_PERFMON_HANDLER

;******** include 中断 handler 代码 ********
%include "..\common\handler32.asm"


;********* include 模块 ********************
%include "..\lib\creg.asm"
%include "..\lib\cpuid.asm"
%include "..\lib\msr.asm"
%include "..\lib\pci.asm"
%include "..\lib\apic.asm"
%include "..\lib\debug.asm"
%include "..\lib\perfmon.asm"
%include "..\lib\page32.asm"
%include "..\lib\pic8259A.asm"
%include "..\lib\x87.asm"

;;************* 函数导入表  *****************

; 这个 lib32 库导入表放在 common\ 目录下, 
; 供所有实验的 protected.asm 模块使用

%include "..\common\lib32_import_table.imt"


PROTECTED_END: