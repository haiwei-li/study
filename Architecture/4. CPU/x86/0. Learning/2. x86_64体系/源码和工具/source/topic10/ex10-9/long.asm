; long.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.

;;
;; 这段代码将切换到 long mode 运行

%include "..\inc\support.inc"
%include "..\inc\long.inc"
        
        bits 32

LONG_LENGTH:        dw        LONG_END - $
        
        org LONG_SEG - 2
        
        NMI_DISABLE
        cli

; 关闭 PAE paging        
        mov eax, cr0
        btr eax, 31
        mov cr0, eax
        
        mov esp, 9FF0h

        call init_page

; 加载 GDT 表
        lgdt [__gdt_pointer]
        
; 设置 CR3 寄存器        
        mov eax, PML4T_BASE
        mov cr3, eax
        
; 设置 CR4 寄存器
        mov eax, cr4
        bts eax, 5                                ; CR4.PAE = 1
        mov cr4, eax

; 设置 EFER 寄存器
        mov ecx, IA32_EFER
        rdmsr 
        bts eax, 8                                ; EFER.LME = 1
        wrmsr

; 激活 long mode
        mov eax, cr0
        bts eax, 31
        mov cr0, eax                              ; EFER.LMA = 1
        
; 转到 64 位代码
        jmp KERNEL_CS : entry64


; 下面是 64 位代码
        
        bits 64
                
entry64:
        mov ax, KERNEL_SS
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov rsp, PROCESSOR0_KERNEL_RSP

;; 下面将 GDT 表定位在 SYSTEM_DATA64_BASE 的线性地址空间上
        mov rdi, SYSTEM_DATA64_BASE
        mov rsi, __system_data64_entry
        mov rcx, __system_data64_end - __system_data64_entry
        rep movsb

;; 下面重新加载 64-bit 环境下的 GDT 和 IDT 表
        mov rbx, SYSTEM_DATA64_BASE + (__gdt_pointer - __system_data64_entry)
        mov rax, SYSTEM_DATA64_BASE + (__global_descriptor_table - __system_data64_entry)
        mov [rbx + 2], rax
        lgdt [rbx]
        
        mov rbx, SYSTEM_DATA64_BASE + (__idt_pointer - __system_data64_entry)
        mov rax, SYSTEM_DATA64_BASE + (__interrupt_descriptor_table - __system_data64_entry)
        mov [rbx + 2], rax
        lidt [rbx]

;; 设置 TSS descriptor        
        mov rsi, tss64_sel
        mov edi, 0x67
        mov r8, SYSTEM_DATA64_BASE + (__task_status_segment - __system_data64_entry)
        mov r9, TSS64
        call set_system_descriptor

; 设置 LDT 描述符
        mov rsi, ldt_sel
        mov edi, __local_descriptor_table_end - __local_descriptor_table - 1
        mov r8, SYSTEM_DATA64_BASE + (__local_descriptor_table - __system_data64_entry)
        mov r9, LDT64
        call set_system_descriptor

;; 加载 TSS 与 LDT 表
        mov ax, tss64_sel
        ltr ax
        mov ax, ldt_sel
        lldt ax
                
;; 设置 call gate descriptor
        mov rsi, call_gate_sel
        mov rdi, __lib32_service                ; call-gate 设在 __lib32_srvice() 函数上
        mov r8, 3                               ; call-gate 的 DPL = 3
        mov r9, KERNEL_CS                       ; code selector = KERNEL_CS
        call set_call_gate

        mov rsi, conforming_callgate_sel
        mov rdi, __lib32_service                 ; call-gate 设在 __lib32_srvice() 函数上
        mov r8, 3                               ; call-gate 的 DPL = 0
        mov r9, conforming_code_sel             ; code selector = conforming_code_sel
        call set_call_gate

;; 设置 system service routine
        mov rsi, SYSTEM_SERVICE_VECTOR          ; 0x40
        mov rdi, __lib32_service
        call set_user_interrupt_handler
        
; 设置 #GP handler
        mov rsi, GP_HANDLER_VECTOR
        mov rdi, GP_handler
        call set_interrupt_descriptor
                        
; 设置 #DB handler
        mov rsi, DB_HANDLER_VECTOR
        mov rdi, DB_handler
        call set_interrupt_descriptor
                                        

;; 设置 conforming code segment descriptor        
        MAKE_SEGMENT_ATTRIBUTE 13, 0, 1, 0      ; type=conforming code segment, DPL=0, G=1, D/B=0
        mov r9, rax                             ; attribute
        mov rsi, conforming_code_sel            ; selector
        mov rdi, 0xFFFFF                        ; limit
        mov r8, 0                               ; base
        call set_segment_descriptor

;============================================================


;; 从 64 位切换到 compatibility mode(权限不改变, 0 级)　        
        jmp QWORD far [compatibility_pointer]

compatibility_pointer:
                dq compatibility_kernel_entry              ; 64 bit offset on Intel64
                dw code32_sel


;;        call QWORD far [conforming_pointer]           ; 测试conforimg 代码

        
;; 切换到 compatibility mode(进入 3 级)
;        push user_data32_sel | 3
;        push COMPATIBILITY_USER_ESP
;        push user_code32_sel | 3
;        push compatibility_entry     
;        retf64
        
;; 切换到用户代码　
;        push USER_SS | 3
;        push ROCESSOR0_USER_RSP
;        push USER_CS | 3
;        push user_entry
;        retf64
                


;;; ###### 下面是 32-bit compatibility 模块 ########                
        
        bits 32

;; 0 级的 compatibility 代码入口        
compatibility_kernel_entry:
        mov ax, data32_sel
        mov ss, ax
        mov ds, ax
        mov es, ax
        mov esp, COMPATIBILITY_KERNEL_ESP
        jmp compatibility_entry

;; 3 级的 compatibility 代码入口        
compatibility_user_entry:
        mov ax, user_data32_sel
        mov ds, ax
        mov ss, ax
        mov es, ax
        mov esp, COMPATIBILITY_USER_ESP
        
        
compatibility_entry:
;; 通过 stub 函数从compaitibility模式调用call gate 进入64位模式
        mov esi, cmsg1
        mov eax, LIB32_PUTS
        call compatibility_lib32_service                ;; stub 函数形式


;; 现在切换到 3级 64-bit 模式代码
        push USER_SS | 3
        push COMPATIBILITY_USER_ESP
        push USER_CS | 3
        push user_entry
        retf
        
cmsg1        db '---> Now: enter compatibility mode', 10, 0
                
compatibility_entry_end:




;;; ##### 64-bit 用户代码 #########

        bits 64
        
user_entry:
        
        mov rsp, USER_RSP

        mov esi, msg1
        mov eax, LIB32_PUTS
        call lib32_service

;        mov rsi, msg1
;        call strlen
        
;        call QWORD far [conforming_pointer]                ; 测试 conforming 代码
;        call QWORD far [gate_pointer]                        ; 测试 conforming gate
        jmp $
;conforming_pointer:
;        dq puts64
;        dw 0x78        
gate_pointer:
        dq 0
        dw call_gate_sel        
;        jmp $

msg1        db 'enter 64-bit user code', 10, 0





        


        bits 64

;*** include 64-bit 模式的 interrupt handler ****
%include "..\common\handler64.asm"


;*** include 64-bit 模式下的系统数据 *****
%include "..\lib\system_data64.asm"


;*** include 其它 64 位库 *****
%include "..\lib\lib64.asm"
%include "..\lib\page64.asm"
%include "..\lib\debug64.asm"
%include "..\lib\apic64.asm"
%include "..\lib\perfmon64.asm"


puts:           jmp LIB32_SEG + LIB32_PUTS * 5    
      


LONG_END:
                