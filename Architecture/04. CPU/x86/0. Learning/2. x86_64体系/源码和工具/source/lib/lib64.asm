; lib64.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.

;; long mode 下的库

%include "..\inc\long.inc"


        bits 64
        
set_system_descriptor:                  jmp DWORD __set_system_descriptor
set_segment_descriptor:                 jmp DWORD __set_segment_descriptor
set_call_gate:                          jmp DWORD __set_call_gate
set_interrupt_handler:
set_interrupt_descriptor:               jmp DWORD __set_interrupt_handler
read_segment_descriptor:                jmp DWORD __read_segment_descriptor
write_segment_descriptor:               jmp DWORD __write_segment_descriptor
read_idt_descriptor:                    jmp DWORD __read_idt_descriptor
write_idt_descriptor:                   jmp DWORD __write_idt_descriptor
set_user_interrupt_handler:             jmp DWORD __set_user_interrupt_handler
get_tss_base:                           jmp DWORD __get_tss_base
get_tr_base:                            jmp DWORD __get_tr_base
set_sysenter:                           jmp DWORD __set_sysenter
sys_service_enter:                      jmp DWORD __sys_service_enter
compatibility_sys_service_enter:        jmp DWORD __compatibility_sys_service_enter
set_syscall:                            jmp DWORD __set_syscall
sys_service_call:                       jmp DWORD __sys_service_call
set_user_system_service:                jmp DWORD __set_user_system_service
user_system_service_call:               jmp DWORD __user_system_service_call

;-----------------------------------------------------
; strlen(): 得取字符串长度
; input:
;                rsi: string
; output:
;                rax: length of string
;
; 描述: 
;                这个函数放置在 conforming 段里由任意权限执行(使用 far pointer指针形式)　
;-----------------------------------------------------
__strlen:
        mov rax, -1
        test rsi, rsi
        jz strlen_done
strlen_loop:
        inc rax
        cmp BYTE [rsi + rax], 0
        jnz strlen_loop
strlen_done:        
        db 0x48
        retf


;-------------------------------------------------------
; lib32_service(): 对外接口
; input:
;                rax: 库函数编号
; 描述: 
;                通过 call-gate 进行调用实际工作的 lib32_service()
;-------------------------------------------------------
lib32_service:
        jmp lib32_service_next
CALL_GATE_POINTER:      dq 0
                        dw call_gate_sel
lib32_service_next:                                        
        call QWORD far [CALL_GATE_POINTER]      ;; 从 64 位模式里调用 call gate                                        
        ret



;; **** 使用 32 位编译 ****
        bits 32
;---------------------------------------------------------------------------
; compatibility_lib32_service(): 对外接口, 用于 32-bit compatibility模式下
; input:
;                eax: 库函数编号
; 描述: 
;; 下面是兼容模式下的调用 lib32_service() stub 函数
;---------------------------------------------------------------------------
compatibility_lib32_service:
        jmp compatibility_lib32_service_next
CALL_GATE_POINTER32:    dd 0
                        dw call_gate_sel
compatibility_lib32_service_next:                                        
        call DWORD far [CALL_GATE_POINTER32]    ;; 从 compatibility 模式里调用 call gate                                        
        ret
                



;; **** 转回 64 位编译 *****                
        bits 64



;****************************************************************************************
;* Bug或设计缺陷说明:                                                                   *
;*      lib32_service() 设计上的有"不可重入"的缺陷！                                    *
;*      当在64-bit模式通过 lib32_service()调用lib32库函数时,                            *
;*      lib32_service()转入compatibility模式前重设stack指针esp为LIB32_ESP值             *
;*      如果执行lib32库函数期间发生被异常或其它中断抢占时, 如果这个异常或中断           *
;*      再次调用lib32_service()来执行lib32库函数时, 发生严重后果.                       *
;*      结果是: stack指针又被重置为LIB32_ESP值, 导致stack发生错乱!                      *
;*                                                                                      *
;* 解决办法:                                                                            *
;*      1)在无法预知否会在lib32库函数执行期间产生中断情况下, 可以使用中断调用方式       *
;*        避免使用 call-gate 方式调用lib32_service()来转入compatibility模式.            *
;*        这样: 可以避免被中断触发时抢占情况的产生, 但不能避免被异常抢占！              *
;*                                                                                      *
;*      2)设计在64-bit代码下的stack区域与compatibility模式的stack区域重合,              *
;*        当转入compaibility模式后的32位ESP值由于RSP的高32位清0后, 还能保持有效性.      *
;*        在这种方法下, 在进入lib32_service()后无须对ESP进行重设！                      *
;*        但必须确保RSP的低32位值, 在无须修改的情况下保持正确性(RSP与ESP值相对应)     *
;*                                                                                      *
;*      3)重新编写lib32库对应的64位版本的函数库, 避免在64-bit代码下使用lib32库!      　 *
;*      　显然, 这是最根本, 最正确的解决方法, 但是lib32库函数不用被重用.                *
;****************************************************************************************


;-------------------------------------------------------
; lib32_service(): 在64位的代码下使用32位的库函数
; input:
;                rax: 库函数编号, rsi...相应的函数参数
; 描述:
;                (1) rax 是32位库函数号, 类似于系统服务例程的功能号
;                (2) 代码会先切换到 compaitibility 模式调用 32 位模式的函数
;                (3) 32 位例程执行完毕, 切换回 64 位模式
;                (4) 从 64 位模式中返回调用者
;                (5) lib32_service() 函数使用 call-gate 进行调用
;-------------------------------------------------------
__lib32_service:
;*
;* changlog: 使用 r15 代替 rbp 保存 rsp 指针
;*           目的: 使用 lib32 库里可以使用 ebp 指针！   
;*                 如果使用 rbp 保存 rsp 指针, 那么当lib32 库函数使用 ebp 时将刷掉 rbp 寄存器值
;*
        push r15
        mov r15, rsp
        push rbp
        push rbx  
        push rcx
        push rdx

        ; 保存参数
        mov rcx, rsi
        mov rdx, rdi
        mov rbx, rax                            ; 功能号

        mov rsi, [r15 + 16]                     ; 读 CS selector
        call read_segment_descriptor
        shr rax, 32

        ; 恢复参数
        mov rsi, rcx
        mov rdi, rdx

        jmp QWORD far [lib32_service_compatiblity_pointer]      ; 从 64 位切换到 compatibility模式
;; 定义 far pointer        
lib32_service_compatiblity_pointer:     dq        lib32_service_compatibility
                                        dw        code32_sel
lib32_service_64_pointer:               dd        lib32_service_done
                                        dw        KERNEL_CS

        bits 32                                                                        
lib32_service_compatibility:
        bt eax, 21                              ; 测试 CS.L
        jc reload_sreg                          ; 调用者是 64 位代码
        shr eax, 13
        and eax, 0x03                           ; 取 RPL
        cmp eax, 0
        je call_lib32                           ; 权限不变
reload_sreg:
;; 重新设置 32 位环境
        mov ax, data32_sel
        mov ds, ax
        mov es, ax        
        mov ss, ax
;*
;* 对 compatibility 的stack结构进行设置
;* 这个导致不可重入 ==> mov esp, LIB32_ESP
;*
;* chang log: 去掉 mov esp, LIB32_ESP 这条指令, 无需设置 compatibility 模式下的 esp 值
;*            使用 compatibility 模式的 esp 与 64-bit rsp 低 32 位相同的映射方式
;*


;*
;* 下面的代码将调用 lib32.asm 库内的函数, 运行在 compatibility 模式下
;*
call_lib32:
        lea eax, [LIB32_SEG + ebx * 4 + ebx]            ; rbx * 5 + LIB32_SEG 得到 lib32 库函数地址
        call eax                                        ;; 执行 32位例程
        jmp DWORD far [lib32_service_64_pointer]        ;; 切换回 64 位模式

        bits 64
lib32_service_done:   
        lea rsp, [r15 - 32]                             ; 取回原 RSP 值
        pop rdx
        pop rcx
        pop rbx
        pop rbp
        pop r15
        retf64                                          ; 使用宏 ref64 



;------------------------------------------------------------------------
; set_system_descriptor(int selector, int limit, long long base, int type)
; input:
;                rsi: selector,  rdi: limit, r8: base, r9: type
;--------------------------------------------------------------------------
__set_system_descriptor:
        sgdt [gdt_pointer]
        mov rax, [gdt_pointer + 2]
        and esi, 0FFF8h                         ; selector
        mov [rax + rsi + 4], r8                 ; base[63:24]
        mov [rax + rsi + 2], r8d                ; base[23:0]
        or r9b, 80h
        mov [rax + rsi + 5], r9b                ; DPL=0, type=r9

        ;* 下面设置 limit 值
        ;* 如果 limit 大于 4K 的话
        mov r8, rdi
        shr r8, 12                              ; 除 4K
        cmovz r8d, edi                          ; 为 0 使用原值
        setnz dil                                ; 不为 0 置 G 位
        mov [rax + rsi], r8w                    ; limit[15:0]
        shl r8w, 5
        shrd r8w, di, 17                        ; 设置 G 位
        mov [rax + rsi + 6], r8b                ; limit[19:16]
        ret
        
;------------------------------------------------------------------------
; set_call_gate(int selector, long long address)
; input:
;                rsi: selector,  rdi: address, r8: DPL, r9: code_selector
; 注意: 
;                这里将 call gate 的权限设为 3 级, 从用户代码可以调用
;--------------------------------------------------------------------------
__set_call_gate:
        sgdt [gdt_pointer]
        mov rax, [gdt_pointer + 2]
        and esi, 0FFF8h
        mov [rax + rsi], rdi                    ; offset[15:0]
        mov [rax + rsi + 4], rdi                ; offset[63:16]
        mov DWORD [rax + rsi + 12], 0           ; 清高位
        mov [rax + rsi + 2], r9d                ; selector
        and r8b, 0Fh
        shl r8b, 5
        or r8b, 80h | CALL_GATE64
        mov [rax + rsi + 5], r8b                ; attribute
        ret        



        
;------------------------------------------------------
; set_interrupt_handler(int vector, void(*)()handler)
; input:
;                rsi: vector,  rdi: handler
;------------------------------------------------------
__set_interrupt_handler:
        sidt [idt_pointer]        
        mov rax, [idt_pointer + 2]                              ; IDT base
        shl rsi, 4                                              ; vector * 16
        mov [rax + rsi], rdi                                    ; offset [15:0]
        mov [rax + rsi + 4], rdi                                ; offset [63:16]
        mov DWORD [rax + rsi + 2], kernel_code64_sel            ; set selector
        mov BYTE [rax + rsi + 5], 80h | INTERRUPT_GATE64        ; Type=interrupt gate, P=1, DPL=0
        ret
        
;------------------------------------------------------
; set_user_interrupt_handler(int vector, void(*)()handler)
; input:
;                rsi: vector,  rdi: handler
;------------------------------------------------------
__set_user_interrupt_handler:
        sidt [idt_pointer]        
        mov rax, [idt_pointer + 2]                              ; IDT base
        shl rsi, 4                                              ; vector * 16
        mov [rax + rsi], rdi                                    ; offset [15:0]
        mov [rax + rsi + 4], rdi                                ; offset [63:16]
        mov DWORD [rax + rsi + 2], kernel_code64_sel            ; set selector
        mov BYTE [rax + rsi + 5], 0E0h | INTERRUPT_GATE64       ; Type=interrupt gate, P=1, DPL=3
        ret
                
;-----------------------------------------------------
; read_idt_descriptor(): 读 IDT 表里的 gate descriptor
; input:
;                rsi: vector
; output:
;                rdx:rax - 16 bytes gate descriptor
;------------------------------------------------------
__read_idt_descriptor:
        sidt [idt_pointer]        
        mov rax, [idt_pointer + 2]                              ; IDT base
        shl rsi, 4                                              ; vector * 16
        mov rdx, [rax + rsi + 8]
        mov rax, [rax + rsi]
        ret

;-----------------------------------------------------
; write_idt_descriptor(): 写入 IDT 表
; input:
;                rsi: vector,  rdx:rax - gate descriptor
;------------------------------------------------------
__write_idt_descriptor:
        sidt [idt_pointer]        
        mov rdi, [idt_pointer + 2]                              ; IDT base
        shl rsi, 4                                              ; vector * 16
        mov [rdi + rsi + 8], rdx
        mov [rdi + rsi], rax
        ret
        
                        
;------------------------------------------------------
; read_segment_descriptor(): 读段描述符
; input:
;                rsi: selector
; output:
;                rax: segment descriptor 
;------------------------------------------------------
__read_segment_descriptor:
        sgdt [gdt_pointer]
        mov rax, [gdt_pointer + 2]
        and esi, 0FFF8h
        mov rax, [rax + rsi]
        ret
        
;-------------------------------------------------------
; write_segment_descriptor():
; input:
;                rsi: selector,  rdi: descriptor
;--------------------------------------------------------        
__write_segment_descriptor:
        sgdt [gdt_pointer]
        mov rax, [gdt_pointer + 2]
        and esi, 0FFF8h
        mov [rax + rsi], rdi
        ret        

;------------------------------------------------------
; read_system_descriptor(): 读系统描述符
; input:
;                rsi: selector
; output:
;                rdx:rax: system descriptor
;------------------------------------------------------
__read_system_descriptor:
        sgdt [gdt_pointer]
        mov rax, [gdt_pointer + 2]
        and esi, 0FFF8h
        mov rdx, [rax + rsi + 8]
        mov rax, [rax + rsi]        
        ret
        
;-----------------------------------------------------
; get_tss_base();
; input:
;                rsi: tss selector
; output:
;                rax: base
;-----------------------------------------------------
__get_tss_base:
        call __read_system_descriptor                   ; rdx:rax
        shld rdx, rax, 32                               ; base[63:24]
        mov rdi, 0FFFFFFFFFF000000h
        and rdx, rdi
        shr rax, 16
        and eax, 0FFFFh
        or rax, rdx
        ret

        
__get_tr_base:
        str esi
        call __get_tss_base
        ret        
        
        
        
;---------------------------------------------------------
; set_segment_descriptor(): 设置段描述符
; input:
;                rsi: selector, rdi: limit, r8: base, r9: attribute
;---------------------------------------------------------
__set_segment_descriptor:
        sgdt [gdt_pointer]
        mov rax, [gdt_pointer + 2]
        and esi, 0FFF8h
        and edi, 0FFFFFh
        mov [rax + rsi], di                       ; limit[15:0]
        mov [rax + rsi + 2], r8w                ; base[15:0]
        shr r8, 16
        mov [rax + rsi + 4], r8b                ; base[23:16]
        shr edi, 16
        shl edi, 8
        or edi, r9d
        mov [rax + rsi + 5], di                   ; attribute
        shr r8, 8
        mov [rax + rsi + 7], r8b                ; base[31,24]
        ret


;----------------------------------------------------------------
; set_sysenter():       long-mode 模式的 sysenter/sysexit使用环境
;----------------------------------------------------------------
__set_sysenter:
        xor edx, edx
        mov eax, KERNEL_CS
        mov ecx, IA32_SYSENTER_CS
        wrmsr                                                        ; 设置 IA32_SYSENTER_CS

%ifdef MP
;*
;* chang log: 
;       增加对多处理器环境的支持
;*      每个处理器分配不同的 RSP 值
;*
        mov ecx, [processor_index]                                      ; index 值
        mov eax, PROCESSOR_STACK_SIZE                                   ; 每个处理器的 stack 空间大小
        mul ecx                                                         ; stack_offset = STACK_SIZE * index
        mov rcx, PROCESSOR_SYSENTER_RSP                                 ; stack 基值
        add rax, rcx  
%else
        mov rax, KERNEL_RSP
%endif
        mov rdx, rax
        shr rdx, 32
        mov ecx, IA32_SYSENTER_ESP                
        wrmsr                                                        ; 设置 IA32_SYSENTER_ESP
        mov rdx, __sys_service
        shr rdx, 32
        mov rax, __sys_service
        mov ecx, IA32_SYSENTER_EIP
        wrmsr                                                        ; 设置 IA32_SYSENTER_EIP
        ret        

;----------------------------------------------------------------
; set_syscall():        long-mode 模式的 syscall/sysret使用环境 
;----------------------------------------------------------------
__set_syscall:
; enable syscall 指令
        mov ecx, IA32_EFER
        rdmsr
        bts eax, 0                                      ; SYSCALL enable bit
        wrmsr
        mov edx, KERNEL_CS | (sysret_cs_sel << 16)
        xor eax, eax
        mov ecx, IA32_STAR
        wrmsr                                           ; 设置 IA32_STAR
        mov rdx, __sys_service_routine
        shr rdx, 32
        mov rax, __sys_service_routine
        mov ecx, IA32_LSTAR
        wrmsr                                            ; 设置 IA32_LSTAR
        xor eax, eax
        xor edx, edx
        mov ecx, IA32_FMASK
        wrmsr
;;  下面设置 KERNEL_GS_BASE 寄存器
        mov rdx, kernel_data_base
        mov rax, rdx
        shr rdx, 32
        mov ecx, IA32_KERNEL_GS_BASE        
        wrmsr
        ret

;-----------------------------------------------------
; sys_service_enter():         系统服务例程接口 stub 函数
; input:
;                rax: 系统服务例程号
;-----------------------------------------------------
__sys_service_enter:
        push rcx
        push rdx
        mov rcx, rsp
        mov rdx, return_64_address
        sysenter
return_64_address:        
        pop rdx
        pop rcx
        ret

;-----------------------------------------------------
; sys_service_call():         系统服务例程接口 stub 函数, syscall 版本
; input:
;                rax: 系统服务例程号
;-----------------------------------------------------
__sys_service_call:
        push rbp
        push rcx
        mov rbp, rsp                                    ; 保存调用者的 rsp 值
        mov rcx, return_64_address_syscall              ; 返回地址
        syscall
return_64_address_syscall:        
        mov rsp, rbp
        pop rcx
        pop rbp
        ret
        
        


        bits 32
;-------------------------------------------------------------
; compatibility_sys_service_enter(): compatibility 模式下的 stub
; 描述: 
;       仅供在 compatibility模式下使用
;----------------------------------------------------------------
__compatibility_sys_service_enter:
        push ecx
        push edx
        mov ecx, esp
        mov edx, return_compatibility_address
        sysenter
return_compatibility_pointer:   dq compatibility_sys_service_enter_done
                                dw user_code32_sel | 3        
return_compatibility_address:        
        bits 64
        jmp QWORD far [return_compatibility_pointer]            ; 从64-bit切换回compatibility模式
compatibility_sys_service_enter_done:
        bits 32
        pop edx
        pop ecx
        ret


        bits 64
;---------------------------------------------------
; sys_service(): 系统服务例程, sysenter/sysexit版本
;---------------------------------------------------
__sys_service:
        push rbp
        push rcx
        push rdx
        push rbx
        mov rbp, rsp
        mov rbx, rax
        
        
        jmp QWORD far [lib32_service_enter_compatiblity_pointer]        ; 从 64 位切换到 compatibility模式
        
;; 定义 far pointer        
lib32_service_enter_compatiblity_pointer:       dq        lib32_service_enter_compatibility
                                                dw        code32_sel
lib32_service_enter_64_pointer:                 dd        lib32_service_enter_done
                                                dw        KERNEL_CS
                                                                        
lib32_service_enter_compatibility:
        bits 32
;; 重新设置 32 位环境
        mov ax, data32_sel
        mov ds, ax
        mov es, ax        
        mov ss, ax
;        mov esp, LIB32_ESP
lib32_enter:
        lea eax, [LIB32_SEG + ebx * 4 + ebx]                      ; rbx * 5 + LIB32_SEG 得到 lib32 库函数地址
        call eax                                                  ;; 执行 32位例程
        jmp DWORD far [lib32_service_enter_64_pointer]            ;; 切换回 64 位模式
        bits 64
lib32_service_enter_done:        
        mov rsp, rbp
        pop rbx
        pop rdx
        pop rcx
        pop rbp
        sysexit64                                                 ; 返回到 64-bit 模式
        
;-----------------------------------------------------
; sys_service_routine():  系统服务例程, syscall/sysret 版本
;-----------------------------------------------------        
__sys_service_routine:
        swapgs                                 ; 获取 Kernel 数据
        mov rsp, [gs:0]                        ; 得到 kernel rsp 值
        push rbp
        push r11
        push rcx
        push rbx
        mov rbp, rsp
        mov rbx, rax

        jmp QWORD far [lib32_service_call_compatiblity_pointer] ; 从 64 位切换到 compatibility模式
        
;; 定义 far pointer
lib32_service_call_compatiblity_pointer:        dq        lib32_service_call_compatibility
                                                dw         code32_sel
lib32_service_call_64_pointer:                  dd        lib32_service_call_done
                                                dw        KERNEL_CS
                                                                        
lib32_service_call_compatibility:
        bits 32
;; 重新设置 32 位环境
        mov ax, data32_sel
        mov ds, ax
        mov es, ax        
        mov ss, ax
;        mov esp, LIB32_ESP
lib32_call:
        lea eax, [LIB32_SEG + ebx * 4 + ebx]                        ; rbx * 5 + LIB32_SEG 得到 lib32 库函数地址
        call eax                                                     ;; 执行 32位例程
        jmp DWORD far [lib32_service_call_64_pointer]                ;; 切换回 64 位模式
        bits 64
lib32_service_call_done:
        
        mov rsp, rbp
        pop rbx
        pop rcx
        pop r11
        pop rbp
        swapgs                                        ; 恢得 GS.base
        sysret64                                      ; 返回 64-bit 模式
        
        

;*
;* 设置挂接系统服务表
;* 使用于在用户代码里 int 40h 调用
;*

;--------------------------------------
; set_system_service(): 设置系统服务表
; input:
;       rsi - 用户自定义系统服务例程号
;       rdi - 用户自定义系统服务例程
;-------------------------------------
__set_user_system_service:
        cmp rsi, 10
        jae set_system_service_done                     ; 假如用户例程号大于等于 10 就退出
        mov [__system_service_table + rsi * 8], rdi     ; 写入用户自定义例程
set_system_service_done:        
        ret


;------------------------------------------------------
; user_system_service_call(): 调用用户自定义的服务例程
; input:
;       rax - 用户自定义系统服务例程号
; 描述: 
;       由函数由 Int 40h 来调用
;-----------------------------------------------------
__user_system_service_call:
        cmp rax, 10
        jae user_system_service_call_done
        mov rax, [__system_service_table + rax * 8]
        call rax
user_system_service_call_done:
        iret64

                
;******** lib64 模块的变量定义 ********

video_current        dd 0B8000h


;****** 系统服务表 ***********

__system_service_table:
        times 10 dq 0                                   ; 保留 10 个自定义系统服务函数


lib64_context   times 20 dq 0


;; 系统数据表
kernel_data_base        dq        PROCESSOR_SYSCALL_RSP         ; 系统栈

                

; GDT 表指针
gdt_pointer             dw 0                        ; GDT limit 值
                        dq 0                        ; GDT base 值

; IDT 表指针
idt_pointer             dw 0                        ; IDT limit 值
                        dq 0                        ; IDT base 值
                        
                        
LIB64_END:                