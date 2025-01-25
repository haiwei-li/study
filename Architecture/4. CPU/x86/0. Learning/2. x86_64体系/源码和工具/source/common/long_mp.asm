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

; BSP 处理器进行初始化页表
        call bsp_init_page

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

; 设置 long-mode 的系统数据结构
        call bsp_init_system_struct

;; 下面重新加载 64-bit 环境下的 GDT 和 IDT 表
        mov rax, SYSTEM_DATA64_BASE + (__gdt_pointer - __system_data64_entry)
        lgdt [rax]
        mov rax, SYSTEM_DATA64_BASE + (__idt_pointer - __system_data64_entry)
        lidt [rax]


;*
;* 设置多处理器环境
;*
        inc DWORD [processor_index]                             ; 增加处理器 index
        inc DWORD [processor_count]                             ; 增加处理器计数
        mov eax, [APIC_BASE + APIC_ID]                          ; 读 APIC ID
        mov ecx, [processor_index]
        mov [apic_id + rcx * 4], eax                            ; 保存 APIC ID
        mov eax, 01000000h
        shl eax, cl
        mov [APIC_BASE + LDR], eax                              ; logical ID

;*
;* 为每个处理器设置 kernel stack pointer
;*
        ; 计数 stack size
        mov eax, PROCESSOR_STACK_SIZE                           ; 每个处理器的 stack 空间大小
        mul ecx                                                 ; stack_offset = STACK_SIZE * index

        ; 计算 stack pointer
        mov rsp, PROCESSOR_KERNEL_RSP
        add rsp, rax                                            ; 得到 RSP
        mov r8, PROCESSOR_IDT_RSP    
        add r8, rax                                             ; 得到 TSS RSP0
        mov r9, PROCESSOR_IST1_RSP                              ; 得到 TSS IDT1
        add r9, rax  

;*
;* 为每个处理器设置 TSS 结构
;*
        ; 计算 TSS 基址
        mov eax, 104                                            ; TSS size
        mul ecx                                                 ; index * 104
        mov rbx, __processor_task_status_segment - __system_data64_entry + SYSTEM_DATA64_BASE
        add rbx, rax

        ; 设置 TSS 块
        mov [rbx + 4], r8                                       ; 设置 RSP0
        mov [rbx + 36], r9                                      ; 设置 IST1


        ; 计算 TSS selector 值       
        mov edx, processor_tss_sel                             
        shl ecx, 4                                              ; 16 * index
        add edx, ecx                                            ; TSS selector                                            

        ; 设置 TSS 描述符
        mov esi, edx                                            ; TSS selector
        mov edi, 67h                                            ; TSS size
        mov r8, rbx                                             ; TSS base address
        mov r9, TSS64                                           ; TSS type
        call set_system_descriptor

;*
;* 下面加载加载 TSS 和 LDT
;*
        ltr dx
        mov ax, ldt_sel
        lldt ax


;; 设置 sysenter/sysexit, syscall/sysret 使用环境
        call set_sysenter
        call set_syscall

; 设 FS.base = 0xfffffff800000000        
        mov ecx, IA32_FS_BASE
        mov eax, 0x0
        mov edx, 0xfffffff8
        wrmsr

; 提取 x2APIC ID
        call extrac_x2apic_id


; 检测是否为 bootstrap processor
        mov ecx, IA32_APIC_BASE
        rdmsr
        bt eax, 8
        jnc application_processor_long_enter

;-------------------------------------
; 下面是 BSP 处理器代码
;-------------------------------------

bsp_processsor_enter:

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

;; 设置 int 40h 使用环境
        mov rsi, 40h
        mov rdi, user_system_service_call
        call set_user_interrupt_handler
  
; 开启开断许可
	NMI_ENABLE
	sti
        
        mov DWORD [20100h], 0           ; lock 信号有效

        
;======== long-mode 环境设置代码结束=============

        mov rsi, BP_IPI_VECTOR
        mov rdi, bp_ipi_handler
        call set_interrupt_handler

        mov rsi, APIC_TIMER_VECTOR
        mov rdi, bp_timer_handler
        call set_interrupt_handler

        mov rsi, AP_IPI_VECTOR
        mov rdi, ap_ipi_handler
        call set_interrupt_handler

        mov DWORD [APIC_BASE + LVT_TIMER], APIC_TIMER_VECTOR

        mov esi, msg
        LIB32_PUTS_CALL

        ;*
        ;* 下面发送 IPIs, 使用 INIT-SIPI-SIPI 序列
        ;* 发送 SIPI 时, 发送 startup routine 地址位于 200000h
        ;*
        mov DWORD [APIC_BASE + ICR0], 000c4500h                ; 发送 INIT IPI, 使所有 processor 执行 INIT
        DELAY
        DELAY
        mov DWORD [APIC_BASE + ICR0], 000C4620H                ; 发送 Start-up IPI
        DELAY
        mov DWORD [APIC_BASE + ICR0], 000C4620H                ; 再次发送 Start-up IPI

        ;*
        ;* 等待 AP 处理器完成初始化
        ;*
wait_for_done:
        cmp DWORD [ap_init_done], 1
        je next
        nop
        pause
        jmp wait_for_done 

next:   ; 触发 apic timer 中断
        mov DWORD [APIC_BASE + TIMER_ICR], 10
        DELAY

        ; 开放 lock 信号
        ; 发送 IPI 到所有 AP 处理器, 让它们执行测试函数
        mov DWORD [vacant], 0   
        mov DWORD [APIC_BASE + ICR1], 0E000000h
        mov DWORD [APIC_BASE + ICR0], LOGICAL_ID | AP_IPI_VECTOR

        jmp $

msg     db '<BSP>: now, send INIT-SIPI-SIPI message', 10, 10
        db '       waiting for application processsor...', 10  
        db '---------------------------------------------------------------', 10, 0
msg1    db 'this is a test message...', 0


;-----------------------------
; 测试信息
;-----------------------------
test_func:
        mov esi, msg1
        LIB32_PUTS_CALL
        ret

;-----------------------------------
; bootstarp processor IPI hanlder
;-----------------------------------
bp_ipi_handler:
        jmp do_bp_ipi_handler
bimsg   db '--- AP<ID:', 0
bimsg1  db '> Initialization done ! --- ', 10, 0
do_bp_ipi_handler:
        mov esi, bimsg
        LIB32_PUTS_CALL
        mov r8d, [processor_index]
        mov esi, [apic_id + r8 * 4]
        LIB32_PRINT_DWORD_VALUE_CALL
        mov esi, bimsg1
        LIB32_PUTS_CALL

        ;*
        ;* 测试所有的 application processor 是否完成
        ;*
        cmp DWORD [20100h], 0
        sete al
        movzx eax, al
        mov [ap_init_done], eax
bp_ipi_handler_done:
        mov DWORD [APIC_BASE + EOI], 0
        iret64

;--------------------------------
; BSP apic timer handler
;--------------------------------
bp_timer_handler:
        jmp do_ap_timer_handler
ap_msg0 db 'system bus processor :', 0
do_ap_timer_handler:
        mov esi, ap_msg0
        LIB32_PUTS_CALL
        mov esi, [processor_count]
        LIB32_PRINT_DWORD_DECIMAL_CALL
        LIB32_PRINTLN_CALL
        LIB32_PRINTLN_CALL
        mov DWORD [APIC_BASE + EOI], 0
        iret64

;------------------------------
; AP IPI handler
;------------------------------
ap_ipi_handler:
        jmp do_ap_ipi_handler
aih_msg db ' <CPI>: ', 0
aih_msg1 db 'AP<', 0
aih_msg2 db '>: ', 0
do_ap_ipi_handler:
        lock bts DWORD [vacant], 0
        jc get_lock
        mov esi, aih_msg1
        LIB32_PUTS_CALL
        mov esi, [APIC_BASE + APIC_ID]
        LIB32_PRINT_DWORD_VALUE_CALL
        mov esi, aih_msg2
        LIB32_PUTS_CALL
        mov rsi, test_func
        call get_unhalted_cpi
        mov r8, rax
        mov esi, aih_msg
        LIB32_PUTS_CALL
        mov rsi, r8
        LIB32_PRINT_DWORD_DECIMAL_CALL
        LIB32_PRINTLN_CALL
        jmp ap_ipi_handler_done
get_lock:
        pause
        jmp do_ap_ipi_handler

ap_ipi_handler_done:
        lock btr DWORD [vacant], 0
        mov DWORD [APIC_BASE + EOI], 0
        iret64



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
        mov esi, address_msg2
        LIB32_PUTS_CALL                        
        mov rsi, 0x200000
        mov rax, SYSTEM_SERVICE_USER0
        int 40h
        LIB32_PRINTLN_CALL
                
; 3)下面打印 virtual address 0x800000 各级 table entry 信息        
        mov esi, address_msg3
        LIB32_PUTS_CALL                        
        mov rsi, 0x800000
        mov rax, SYSTEM_SERVICE_USER0
        int 40h
        LIB32_PRINTLN_CALL

; 3)下面打印 virtual address 0 各级 table entry 信息        
        mov esi, address_msg4
        LIB32_PUTS_CALL                        
        mov rsi, 0
        mov rax, SYSTEM_SERVICE_USER0
        int 40h
        
                        
        
         jmp $
         
;        mov rsi, msg1
;        call strlen

        call QWORD far [conforming_callgate_pointer]        ; 测试 call-gate for conforming 段                
;        call QWORD far [conforming_pointer]                ; 测试 conforming 代码

        jmp $

conforming_callgate_pointer:
        dq 0
        dw conforming_callgate_sel

       

address_msg1 db '---> dump virtual address 0xfffffff8_00000000 <---', 10, 0
address_msg2 db '---> dump virtual address 0x200000 <---', 10, 0
address_msg3 db '---> dump virtual address 0x800000 <---', 10, 0
address_msg4 db '---> dump virtual address 0 <---', 10, 0


;;; ###### 下面是 32-bit compatibility 模块 ########                
        
        bits 32

;; 0 级的 compatibility 代码入口        
compatibility_kernel_entry:
        mov ax, data32_sel
        mov ds, ax
        mov es, ax
        mov ss, ax        
        mov esp, COMPATIBILITY_USER_ESP
        jmp compatibility_entry

;; 3 级的 compatibility 代码入口        
compatibility_user_entry:
        mov ax, user_data32_sel | 3
        mov ds, ax
        mov es, ax
        mov ss, ax        
        mov esp, COMPATIBILITY_USER_ESP
        
compatibility_entry:
;; 通过 stub 函数从compaitibility模式调用call gate 进入64位模式
        mov esi, cmsg1
        mov eax, LIB32_PUTS
        call compatibility_lib32_service                 ;; stub 函数形式


        mov eax, [fs:100]
        
        mov esi, cmsg1
        mov eax, LIB32_PUTS
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
        
cmsg1        db '---> Now: call sys_service() from compatibility mode with sysenter instruction', 10, 0
                
compatibility_entry_end:
 



        bits 64


%define MP
%define AP_LONG_ENTER

;** AP 处理器代码 ***
%include "..\common\application_processor.asm"

        bits 64
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
                