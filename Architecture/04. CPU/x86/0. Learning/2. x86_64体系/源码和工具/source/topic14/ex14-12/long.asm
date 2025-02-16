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


;===== 下面是 long-mode 环境的设置代码 ==========


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

;; 设置 conforming code segment descriptor        
        MAKE_SEGMENT_ATTRIBUTE 13, 0, 1, 0      ; type=conforming code segment, DPL=0, G=1, D/B=0
        mov r9, rax                             ; attribute
        mov rsi, conforming_code_sel            ; selector
        mov rdi, 0xFFFFF                        ; limit
        mov r8, 0                               ; base
        call set_segment_descriptor        

; 设置 #GP handler
        mov rsi, GP_HANDLER_VECTOR
        mov rdi, GP_handler
        call set_interrupt_handler

; 设置 #PF handler
        mov rsi, PF_HANDLER_VECTOR
        mov rdi, PF_handler
        call set_interrupt_handler

; 设置 #DB handler
        mov rsi, DB_HANDLER_VECTOR
        mov rdi, DB_handler
        call set_interrupt_handler
                                        
;; 设置 sysenter/sysexit 使用环境
        call set_sysenter

;; 设置 syscall/sysret 使用环境
        call set_syscall

;; 设置 int 40h 使用环境
        mov rsi, 40h
        mov rdi, user_system_service_call
        call set_user_interrupt_handler

; 设 FS.base = 0xfffffff800000000        
        mov ecx, IA32_FS_BASE
        mov eax, 0x0
        mov edx, 0xfffffff8
        wrmsr  

; 开启开断许可
	NMI_ENABLE
	sti
        
;======== long-mode 环境设置代码结束=============


; 1) 开启APIC
        call enable_xapic        
        
; 2) 设置 APIC interrupt handler
        mov rsi, APIC_TIMER_VECTOR
        mov rdi, apic_timer_handler
        call set_interrupt_descriptor

        mov rsi, APIC_PERFMON_VECTOR
        mov rdi, apic_perfmon_handler
        call set_interrupt_descriptor

        
; 4) 设置 performance monitor 寄存器
        mov DWORD [APIC_BASE + LVT_PERFMON], FIXED | APIC_PERFMON_VECTOR
        


;
;* 实验 14-12: 测试 64-bit 模式下的 BTS 机制
;*

        ; 复制测试函数到 0FFFFFFF8_10000000h 地址里
        mov rsi, test_func
        mov rdi, 0FFFFFFF810000000h
        mov rcx, test_func_end - test_func
        rep movsb
        
        SET_DS_AREA64                           ; 设置 DS 存储区域
        ENABLE_BTS                              ; 开启 BTS, 使用环形的 BTS buffer

        ;* 调用测试函数
        ;* 函数的地址在 0FFFFFFF8_10000000h 位置上
        mov rax, 0FFFFFFF810000000h                
        call rax

        DISABLE_BTS                              ; 关闭 BTS
        DUMP_BTS64                               ; 打印 BTS buffer 信息
                     
                
        jmp $

;*
;** 下面是测试函数 test_func()
;*
test_func:
        jmp l1
l1:     jmp l2
l2:     jmp l3
l3:     jmp l4
l4:     jmp l5
l5:     jmp l6
l6:
        ret
test_func_end:

        
        ;call QWORD far [conforming_callgate_pointer]        ; 测试 call-gate for conforming 段
        
        ;call QWORD far [conforming_pointer]                        ; 测试conforimg 代码
        
;; 从 64 位切换到 compatibility mode(权限不改变, 0 级)　        
        ;jmp QWORD far [compatibility_pointer]

;compatibility_pointer:
;                dq compatibility_kernel_entry              ; 64 bit offset on Intel64
;                dw code32_sel

;; 切换到 compatibility mode(进入 3 级)
;        push user_data32_sel | 3
;        push COMPATIBILITY_USER_ESP
;        push user_code32_sel | 3
;        push compatibility_user_entry
;        retf64

;; 使用 iret 切换到 compatibility mode(进入 3 级)
;        push user_data32_sel | 3
;        push COMPATIBILITY_USER_ESP
;        push 02h
;        push user_code32_sel | 3
;        push compatibility_user_entry
;        iretq

;        mov rsi, USER_CS
;        call read_segment_descriptor
;        btr rax, 47                                ; p=0
;        btr rax, 43                                ; code/data=0
;        btr rax, 41                                ; R=0
;        btr rax, 42                                ; c=1
;        btr rax, 45
;        mov rsi, 0x78
;        mov rdi, rax
;        call write_segment_descriptor
        

;; 切换到用户代码　
;        push USER_SS | 3
;        mov rax, USER_RSP
;        push rax
;        push USER_CS | 3
;        push user_entry
;        retf64

;; 使用 iret 切换到用户代码　                
;        push USER_SS | 3
;        mov rax, USER_RSP        
;        push rax
;        push 02h
;        push USER_CS | 3
;        push user_entry
;        iretq                                       ; 返回到 3 级权限
        



;;; ##### 64-bit 用户代码 #########

        bits 64
        
user_entry:

;##### 下面是测试实验 ########
; 1)下面打印 virtual address 0xfffffff800000000 各级 table entry 信息
        mov esi, address_msg1
        LIB32_PUTS_CALL                        
        mov rsi, 0xfffffff800000000
        mov rax, SYSTEM_SERVICE_USER0
        int 40h
        LIB32_PRINTLN_CALL

; 2)下面打印 virtual address 0x200000 各级 table entry 信息        
        mov esi,  address_msg2
        LIB32_PUTS_CALL                        
        mov rsi,  0x200000
        mov rax,  SYSTEM_SERVICE_USER0
        int 40h
        LIB32_PRINTLN_CALL
                
; 3)下面打印 virtual address 0x800000 各级 table entry 信息        
        mov esi,  address_msg3
        LIB32_PUTS_CALL                        
        mov rsi,  0x800000
        mov rax,  SYSTEM_SERVICE_USER0
        int 40h
        LIB32_PRINTLN_CALL

; 3)下面打印 virtual address 0 各级 table entry 信息        
        mov esi,  address_msg4
        LIB32_PUTS_CALL                        
        mov rsi,  0
        mov rax,  SYSTEM_SERVICE_USER0
        int 40h
        
                        
        
         jmp $
         
;        mov rsi,  msg1
;        call strlen

        call QWORD far [conforming_callgate_pointer]        ; 测试 call-gate for conforming 段                
;        call QWORD far [conforming_pointer]                ; 测试 conforming 代码

        jmp $

conforming_callgate_pointer:
        dq 0
        dw conforming_callgate_sel

       

address_msg1 db '---> dump virtual address 0xfffffff8_00000000 <---',  10,  0
address_msg2 db '---> dump virtual address 0x200000 <---',  10,  0
address_msg3 db '---> dump virtual address 0x800000 <---',  10,  0
address_msg4 db '---> dump virtual address 0 <---',  10,  0


;;; ###### 下面是 32-bit compatibility 模块 ########                
        
        bits 32

;; 0 级的 compatibility 代码入口        
compatibility_kernel_entry:
        mov ax,  data32_sel
        mov ds,  ax
        mov es,  ax
        mov ss,  ax        
        mov esp,  COMPATIBILITY_USER_ESP
        jmp compatibility_entry

;; 3 级的 compatibility 代码入口        
compatibility_user_entry:
        mov ax,  user_data32_sel | 3
        mov ds,  ax
        mov es,  ax
        mov ss,  ax        
        mov esp,  COMPATIBILITY_USER_ESP
        
compatibility_entry:
;; 通过 stub 函数从compaitibility模式调用call gate 进入64位模式
        mov esi,  cmsg1
        mov eax,  LIB32_PUTS
        call compatibility_lib32_service                 ;; stub 函数形式


        mov eax,  [fs:100]
        
        mov esi,  cmsg1
        mov eax,  LIB32_PUTS
        call compatibility_sys_service_enter            ; compatibility 模式下的 sys_service() stub 函数

;; 现在切换到 3级 64-bit 模式代码
        push USER_SS | 3
        push COMPATIBILITY_USER_ESP
        push USER_CS | 3                                ; 在 4G范围内
        push user_entry
        retf

;; 使用 iret指令从 compatibility 模式切换到 3 级 64-bit 模式
;        push USER_SS | 3
;        push USER_RSP
;        pushf
;        push USER_CS | 3                                ; 在 4G 范围内
;        push user_entry
;        iret                                            ; 使用 32 位操作数
        
        jmp $
        
cmsg1        db '---> Now: call sys_service() from compatibility mode with sysenter instruction',  10,  0
                
compatibility_entry_end:
 



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



LONG_END:
                