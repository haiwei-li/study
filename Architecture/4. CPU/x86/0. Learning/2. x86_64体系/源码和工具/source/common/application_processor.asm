; application_processor.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


;*
;* Application Processors 代码
;*

%ifdef AP_PROTECTED_ENTER

;------------------------------------------------
; 下面是 application processor 初始化代码
;-----------------------------------------------

application_processor_enter:
        bits 32

        ;*
        ;* 当前处于保护模式下
        ;* 

; 设置 PDPT 基址        
        mov eax, PDPT_BASE
        mov cr3, eax

; 开启分页
        mov eax, cr0
        bts eax, 31
        mov cr0, eax  

;开启APIC
        call enable_apic        

        inc DWORD [processor_index]                             ; 增加 index 值
        inc DWORD [processor_count]                             ; 增加 logical processor 数量
        mov ecx, [processor_index]                              ; 取 index 值
        mov edx, [APIC_BASE + APIC_ID]                          ; 读 APIC ID
        mov [apic_id + ecx * 4], edx                            ; 保存 APIC ID 
;*
;* 分配 stack 空间
;*
        mov eax, PROCESSOR_STACK_SIZE                           ; 每个处理器的 stack 空间大小
        mul ecx                                                 ; stack_offset = STACK_SIZE * index
        mov esp, PROCESSOR_KERNEL_ESP                           ; stack 基值
        add esp, eax  

; 设置 logical ID
        mov eax, 01000000h
        shl eax, cl
        mov [APIC_BASE + LDR], eax

; 提取 APIC ID
        call extrac_x2apic_id

; 设置 LVT timer
        mov DWORD [APIC_BASE + LVT_ERROR], APIC_ERROR_VECTOR

;============= Ap 处理器 protected-mode 初始化完成 ============

        ;*
        ;* 下面检查是否需要进入 long-mode
        ;*
        cmp DWORD [long_flag], 1
        je LONG_SEG

;释放 lock, 允许其它 AP 进入
        lock btr DWORD [20100h], 0

;发送 IPI 消息通知 bsp
        mov DWORD [APIC_BASE + ICR1], 0
        mov DWORD [APIC_BASE + ICR0], PHYSICAL_ID | BP_IPI_VECTOR

        sti
        hlt
        jmp $

%endif



%ifdef AP_LONG_ENTER

;-------------------------------------------------
; 下面是 application processor 转入到 long-mode
;-------------------------------------------------
application_processor_long_enter:

        bits 64


; 设置 LVT error
        mov DWORD [APIC_BASE + LVT_ERROR], APIC_ERROR_VECTOR

        ;释放 lock, 允许其它 AP 进入
     ;   lock btr DWORD [20100h], 0

;============== Ap 处理器 long-mode 初始化完成 ======================

        ;*
        ;* 向 BSP 处理器回复 IPI 消息
        ;*
;        mov DWORD [APIC_BASE + ICR1], 0h
;        mov DWORD [APIC_BASE + ICR0], PHYSICAL_ID | BP_IPI_VECTOR


; 设置用户有权执行0级的例程
        mov rsi, SYSTEM_SERVICE_USER8
        mov rdi, user_hlt_routine
        call set_user_system_service

        mov rsi, SYSTEM_SERVICE_USER9
        mov rdi, user_send_ipi_routine
        call set_user_system_service

; 计算 user stack pointer
        mov ecx, [processor_index]
        mov eax, PROCESSOR_STACK_SIZE
        mul ecx
        mov rcx, PROCESSOR_USER_RSP
        add rax, rcx


;; 切换到用户代码　
        push USER_SS | 3
        push rax
        push USER_CS | 3
        push application_processor_user_enter
        retf64

        sti
        hlt
        jmp $



application_processor_user_enter:
        mov esi, ap_msg
        mov rax, LIB32_PUTS
        call sys_service_enter        

        ; 发送消息给 BSP, 回复完成初始化
        mov esi, PHYSICAL_ID | BP_IPI_VECTOR
        mov edi, 0
        mov eax, SYSTEM_SERVICE_USER9
        int 40h

        ;释放 lock, 允许其它 AP 进入
        lock btr DWORD [20100h], 0

        mov eax, SYSTEM_SERVICE_USER8
        int 40h

        jmp $

ap_msg  db '>>> enter 64-bit user code', 0

;---------------------------------
; user_send_ipi_routine()
; input:
;       rsi - ICR0, rdi - ICR1
;---------------------------------
user_send_ipi_routine:
        mov DWORD [APIC_BASE + ICR1], edi
        mov DWORD [APIC_BASE + ICR0], esi
        ret

;---------------------------------
; 在用户级代码里开启中断, 和停机
;---------------------------------
user_hlt_routine:
        sti
        hlt
        ret

%endif



;*------------------------------------------------------
;* 下面是 starup routine 代码
;* 引导 AP 处理器执行 setup模块, 执行 protected 模块
;* 使所有 AP 处理器进入protected模式
;*------------------------------------------------------
startup_routine:
        ;*
        ;* 当前处理器处理 16 位实模式
        ;*
        bits 16

        mov ax, 0
        mov ds, ax
        mov es, ax
        mov ss, ax

;*
;* 测试 lock, 只允许 1 个 local processor 访问
;*

test_ap_lock:        
        ;*
        ;* 测试 lock, lock 信号在 20100h 位置上
        ;* 以 CS + offset 值的形式使用 lock
        ;*
        lock bts DWORD [cs:100h], 0
        jc get_ap_lock

;*
;* 获得 lock 后, 转入执行 setup --> protected --> long 序列
;*
        jmp WORD 0:SETUP_SEG

get_ap_lock:
        pause
        jmp test_ap_lock

        bits 32
startup_routine_end: 




        bits 32

;-----------------------------------
; bootstarp processor IPI hanlder
;-----------------------------------
bp_ipi_handler:
        ;*
        ;* 测试所有的 application processor 是否完成
        ;*
        cmp DWORD [20100h], 0
        sete al
        movzx eax, al
        mov [ap_init_done], eax
bp_ipi_handler_done:
        mov DWORD [APIC_BASE + EOI], 0

%ifdef BP_IPI_HANDLER64
        iret64
%else
        iret
%endif




;******** 数据区 **************

;* 
;* 这个变量指示, 是否进入 long-mode 
;* 由 bsp 处理器设置, 当置1时, ap处理器转入到 long-mode
;* 
long_flag       dd      0


