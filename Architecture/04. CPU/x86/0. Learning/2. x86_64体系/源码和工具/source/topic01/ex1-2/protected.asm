; protected.asm
; Copyright (c) 2009-2012 邓志
; All rights reserved.


%include "..\inc\support.inc"
%include "..\inc\protected.inc"

; 这是 protected 模块

        bits 32
        
        org PROTECTED_SEG - 2

PROTECTED_BEGIN:
protected_length dw     PROTECTED_END - PROTECTED_BEGIN         ; protected 模块长度

entry:
        
;; 为了完成实验, 关闭时间中断和键盘中断
        ;call disable_timer
        ;sti
;; 设置 #PF handler
        mov esi, PF_HANDLER_VECTOR
        mov edi, pf_handler
        call set_interrupt_handler        

;; 设置 #GP handler
        mov esi, GP_HANDLER_VECTOR
        mov edi, gp_handler
        call set_interrupt_handler        
        
;; 设置 #DB handler
        mov esi, DB_HANDLER_VECTOR
        mov edi, db_handler
        call set_interrupt_handler        

        
;; 设置 sysenter/sysexit 使用环境
        call set_sysenter

;; 设置 system_service handler
        mov esi, 0x40
        mov edi, system_service
        call set_interrupt_handler                

; 允许执行 SSE 指令        
        mov eax, cr4
        bts eax, 9                                ; CR4.OSFXSR = 1
        mov cr4, eax
                
        mov esi, ldt_sel
        mov edi, LDT
        push LDT_END-LDT-1        
        call set_ldt_descriptor
        
        mov ax, ldt_sel
        lldt ax
        
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


;; 设置 8259 的环境
        mov esi, PIC8259A_TIMER_VECTOR
        mov edi, timer_handler
        call set_interrupt_handler        

        mov esi, KEYBOARD_VECTOR
        mov edi, keyboard_handler
        call set_interrupt_handler                
        
        call init_8259A
        call init_8253        
        call disable_keyboard
        call disable_timer
        sti


;
;** 实验 20-3: 打印 status信息及 stack
;

        finit                                ; 初始化 x87 FPU
        fld TWORD [qnan]                     ; 加载 QNaN 数
        fld TWORD [snan]                     ; 加载 SNaN 数
        fld TWORD [denormal]                 ; 加载 denormal 数
        fld TWORD [infinity]                 ; 加载 infinity 数
        fld TWORD [unsupported]              ; 加载 unsupported 数
        fldz
        fld1
        call dump_data_register                

        jmp $
        


snan    dd 0                                        ; SNaN 数编码
        dd 0xb0000000
        dw 0x7fff

qnan    dd 0                                        ; QNaN 数编码
        dd 0xe0000000
        dw 0x7fff

denormal        dq 1                                ; denormal 编码
                dw 0         
                         
infinity        dd 0                                ; infinity 编码
                dd 0x80000000
                dd 0x7fff

unsupported     dq 0                                ; unsupported 
                dw 0x7fff
                        
                                                 

; 转到 long 模块
        jmp LONG_SEG
                                
                                
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




msg         db 10, 'load a single-precision denormal:', 10, 0
msg1        db 10, 'load a double extended-precision denormal:', 10, 0
msg2        db 10, 'fadd st0, st3 (for double extended-precision denormal):', 10, 0
msg3        db 10, 'fadd DWORD [denormal32]:', 10,0



;-------------------------------
; system timer handler
;-------------------------------
timer_handler:                
        jmp do_timer_handler
t_msg           db 10, '>>> now: enter 8253-timer handler', 10, 0
t_msg1          db 'exit the 8253-timer handler <<<', 10, 0
t_msg2          db 'wait for keyboard...', 10, 0
spin_lock       dd 0
keyboard_done   dd 0
do_timer_handler:
        mov esi, t_msg
        call puts
        call dump_8259_imr        
        call dump_8259_irr
        call dump_8259_isr

test_lock:        
        bt DWORD [spin_lock], 0                 ; 测试锁
        jnc get_lock
        pause
        jmp test_lock
get_lock:
        lock bts DWORD [spin_lock], 0
        jc test_lock
        
;发送 special mask mode 命令
        call enable_keyboard
        call send_smm_command

        sti
        
        mov esi, t_msg2
        call puts
        
wait_for_keyboard:        
        mov ecx, 0xffff
delay:        
        nop
        loop delay
        bt DWORD [keyboard_done], 0
        jnc wait_for_keyboard
        
        btr DWORD [spin_lock], 0                ; 释放锁        
        
        mov esi, t_msg1
        call puts
        call write_master_EOI
        call disable_timer
        iret
        
;----------------------------
; keyboard_handler:
;----------------------------        
keyboard_handler:
        jmp do_keyboard_handler
k_msg   db 10, '>>> now: entry keyboard handler', 10, 0
k_msg1  db 'exit the keyboard handler <<<', 10, 0
do_keyboard_handler:
        mov esi, k_msg
        call puts
        call dump_8259_imr
        call dump_8259_irr
        call dump_8259_isr


        bts DWORD [keyboard_done], 0                ; 完成

        mov esi, k_msg1
        call puts        
        call write_master_EOI
        iret        
        
;---------------------------------------------
; apic_timer_handler(): 这是 APIC TIMER 的 ISR
;---------------------------------------------
apic_timer_handler:
        jmp do_apic_timer_handler
at_msg  db '>>> now: enter the APIC timer handler', 10, 0
at_msg1 db 10, 'exit ther APIC timer handler <<<', 10, 0        
do_apic_timer_handler:        
        mov esi, at_msg
        call puts
        call dump_apic                        ; 打印 apic 寄存器信息
        mov esi, at_msg1
        call puts
        mov DWORD [APIC_BASE + EOI], 0
        iret



db_handler:
        jmp do_db_handler
db_msg  db '#', 0        
db_msg1 db ': #DB exception occur: 0x', 0
db_msg2 db '  ecx: 0x', 0
count   dd 0
do_db_handler:
        mov esi, db_msg
        call puts
        mov esi, [count]
        call print_dword_decimal
        mov esi, db_msg1
        call puts
        mov esi, [esp]
        call print_dword_value
        mov esi, db_msg2
        call puts
        mov esi, ecx
        call print_dword_value
        call println

; 重设 BTF        
        mov ecx, IA32_DEBUGCTL
        mov edx, 0
        mov eax, 2                           ; BTF = 1
        wrmsr
                
        bts DWORD [esp+8], 16                ; RF=1        
        inc DWORD [count]
        iret


        
gp_handler:
        jmp do_gp_handler
gp_msg1 db '---> now, enter #GP handler', 10
        db 'occur at: 0x', 0
do_gp_handler:
        mov esi, gp_msg1
        call puts
        mov esi, [esp+4]
        call print_dword_value
        jmp $
        iret

pf_handler:
        jmp do_pf_handler
pf_msg  db '---> now, enter #PF handler', 10
        db 'occur at: 0x', 0
pf_msg2 db 10, 'fixed the error', 10, 0                
do_pf_handler:        
        add esp, 4                                ; 忽略 Error code
        mov [esp], ebp
        push ecx
        push edx
        mov esi, pf_msg
        call puts
        
        mov ecx, cr2                              ; 发生#PF异常的virtual address
        mov esi, ecx
        call print_dword_value
        

do_pf_handler_done:        
        pop edx
        pop ecx
        iret



        

        
;*********** 数据 ******************        
LDT:
        times 5 dq 0
LDT_END:





;********* include 模块 ********************
;; %include "..\lib\creg.asm"
%include "..\lib\cpuid.asm"
;%include "..\lib\msr.asm"
;%include "..\lib\pci.asm"
%include "..\lib\page32.asm"
;%include "..\lib\debug.asm"
%include "..\lib\apic.asm"
%include "..\lib\pic8259A.asm"
%include "..\lib\x87.asm"


;;************* 函数导入表  *****************

putc:                           jmp LIB32_SEG + LIB32_PUTC * 5
puts:                           jmp LIB32_SEG + LIB32_PUTS * 5
println:                        jmp LIB32_SEG + LIB32_PRINTLN * 5
printblank:                     jmp LIB32_SEG + LIB32_PRINTBLANK * 5
get_dword_hex_string:           jmp LIB32_SEG + LIB32_GET_DWORD_HEX_STRING * 5
hex_to_char:                    jmp LIB32_SEG + LIB32_HEX_TO_CHAR * 5
dump_flags:                     jmp LIB32_SEG + LIB32_DUMP_FLAGS * 5
lowers_to_uppers:               jmp LIB32_SEG + LIB32_LOWERS_TO_UPPERS * 5
set_interrupt_handler:          jmp LIB32_SEG + LIB32_SET_INTERRUPT_HANDLER * 5
set_IO_bitmap:                  jmp LIB32_SEG + LIB32_SET_IO_BITMAP * 5
reverse:                        jmp LIB32_SEG + LIB32_REVERSE * 5
get_byte_hex_string:            jmp LIB32_SEG + LIB32_GET_BYTE_HEX_STRING * 5
get_MAXPHYADDR:                 jmp LIB32_SEG + LIB32_GET_MAXPHYADDR * 5
get_qword_hex_string:           jmp LIB32_SEG + LIB32_GET_QWORD_HEX_STRING * 5
subtract64:                     jmp LIB32_SEG + LIB32_SUBTRACT64 * 5
addition64:                     jmp LIB32_SEG + LIB32_ADDITION64 * 5
print_value:                    jmp LIB32_SEG + LIB32_PRINT_VALUE * 5
print_half_byte_value:		jmp LIB32_SEG + LIB32_PIRNT_HALF_BYTE_VALUE * 5
print_byte_value:               jmp LIB32_SEG + LIB32_PRINT_BYTE_VALUE * 5
print_word_value:               jmp LIB32_SEG + LIB32_PRINT_WORD_VALUE * 5
print_dword_value:              jmp LIB32_SEG + LIB32_PRINT_DWORD_VALUE * 5
print_qword_value:              jmp LIB32_SEG + LIB32_PRINT_QWORD_VALUE * 5
set_call_gate:                  jmp LIB32_SEG + LIB32_SET_CALL_GATE * 5
get_tss_base:                   jmp LIB32_SEG + LIB32_GET_TSS_BASE * 5
write_gdt_descriptor		jmp LIB32_SEG + LIB32_WRITE_GDT_DESCRIPTOR * 5
read_gdt_descriptor             jmp LIB32_SEG + LIB32_READ_GDT_DESCRIPTOR * 5
get_tr_base:                    jmp LIB32_SEG + LIB32_GET_TR_BASE * 5
system_service:                 jmp LIB32_SEG + LIB32_SYSTEM_SERVICE * 5
set_user_interrupt_handler	jmp LIB32_SEG + LIB32_SET_USER_INTERRUPT_HANDLER * 5
set_sysenter:                   jmp LIB32_SEG + LIB32_SET_SYSENTER * 5
sys_service_enter:              jmp LIB32_SEG + LIB32_SYS_SERVICE_ENTER * 5
conforming_lib32_service:	jmp LIB32_SEG + LIB32_CONFORMING_LIB32_SERVICE * 5
load_ss_reg:                    jmp LIB32_SEG + LIB32_LOAD_SS_REG * 5
set_ldt_descriptor:             jmp LIB32_SEG + LIB32_SET_LDT_DESCRIPTOR * 5
move_gdt:                       jmp LIB32_SEG + LIB32_MOVE_GDT * 5
print_dword_decimal:		jmp LIB32_SEG + LIB32_PRINT_DWORD_DECIMAL * 5
init_8253:                      jmp LIB32_SEG + LIB32_INIT_8253 * 5
set_system_service_table:	jmp LIB32_SEG + LIB32_SET_SYSTEM_SERVICE_TABLE * 5

PROTECTED_END: