; setup.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


%include "..\inc\support.inc"
%include "..\inc\protected.inc"

; 这是 protected 模块

        bits 32
        
        org PROTECTED_SEG - 2

PROTECTED_BEGIN:
protected_length        dw      PROTECTED_END - PROTECTED_BEGIN       ; protected 模块长度

entry:
        
;; 设置 #GP handler
        mov esi, GP_HANDLER_VECTOR
        mov edi, GP_handler
        call set_interrupt_handler        

;; 设置 #DB handler
        mov esi, DB_HANDLER_VECTOR
        mov edi, DB_handler
        call set_interrupt_handler

;; 为了完成实验, 关闭时间中断和键盘中断
        call disable_timer

;; 测试1: 在 CPL=0 的情况下改变 IOPL值, 从 0 改变为 3
        mov esi, msg1
        call puts
        call println
        call print_flags_value
        call println
        mov esi, msg3
        call puts
        call println
        
        pushfd                                                  ; get eflags
        or DWORD [esp], 0x3000                                  ; 将 IOPL = 3
        popfd                                                   ; modify the IOPL
        
        call print_flags_value
        call println
        call println
        
        
; 进入 ring 3 完成实验
        push user_data32_sel | 0x3
        push esp
        push user_code32_sel | 0x3
        push DWORD user_entry
        retf


        mov esi, msg2
        call puts
        call println
        call println
        
; 开启 single debug
        pushfd
        bts dword [esp], 8                                ; set eflags.TF
        popfd
        
        mov eax, 1                                                ;测试1
        mov eax, 2                                                ;测试2
        mov eax, 3                                                ;测试3
        mov eax, 4                                                ;测试4
        mov eax, 5

        jmp $
        

user_entry:
        mov ax, user_data32_sel | 0x3
        mov ds, ax
        mov es, ax
        

        mov esi, msg4
        call puts
        call println
        call print_flags_value
        call println
        mov esi, msg5
        call puts
        call println
        pushfd                                        ; get eflags
        or DWORD [esp], 0x3200                        ; 尝试将 IOPL 改为 0, IF 改变 1
        popfd                                         ; 修改 eflags
        
        call print_flags_value
        
        jmp $




msg1                db 'Now: CPL=0, eflags value is:', 0
msg2                db 'Now: test the #DB exception...', 0
msg3                db 'Now: modify the eflags.IOPL to level 3 from 0', 0
msg4                db 'Now: CPL=3, eflags value is:', 0
msg5                db 'Now: modify the eflags.IOPL to level 0 from 3, and modify eflags.IF to 1', 0
value_address        dq 0, 0

;---------------------------------------
; print_flags_value()
;---------------------------------------
print_flags_value:
        jmp do_print_flags_value
pfv_msg1        db '<eflags>:', 0
cf              db 'c:', 0
pf              db 'p:', 0
af              db 'a:', 0
zf              db 'z:', 0
sf              db 's:', 0 
tf              db 't:', 0
if              db 'i:', 0
df              db 'd:', 0
of              db 'o:', 0
iopl            db 'IOPL:', 0
nt              db 'NT:', 0
rf              db 'r:', 0
vm              db 'VM:', 0
ac              db 'AC:', 0
vif             db 'VIF:', 0
vip             db 'VIP:', 0
id              db 'ID:', 0

flags_value: times 22 dw 0
flags_table: dd cf, 0, pf, 0, af, 0, zf, sf, tf, if, df, of, iopl, nt, 0, rf, vm, ac, vif, vip, id, -1

do_print_flags_value:        
        push ebx
        push ecx
        push edx
        pushfd                                
        pop edx                                ; 得到 eflags
        
        mov esi, pfv_msg1
        call puts
        call println
        xor ecx, ecx
do_print_flags_value_loop:        
        mov esi, [flags_table+ecx*4]
        cmp esi, -1
        jz do_print_flags_value_done
        cmp esi, 0
        jz do_print_flags_value_next
        call puts
        
        cmp ecx, 12
        jz print_iopl                        ; IOPL 域
        bt edx, ecx
        setc bl
        movzx ebx, bl
        mov esi, ebx
        jmp print_value
print_iopl:
        inc ecx
        mov esi, edx
        shr esi, 12
        and esi, 3
print_value:        
        call hex_to_char
        mov esi, eax
        call putc        
        mov esi, DWORD ' '
        call putc
        
do_print_flags_value_next:        
        inc ecx
        jmp do_print_flags_value_loop
        
do_print_flags_value_done:        
        call println
        pop edx
        pop ecx
        pop ebx
        ret

;----------------------------------------------
; init_8253() - init 8253-PIT controller
;----------------------------------------------        
init_8253:
; set freq
        mov al, 0x36                       ; set to 100Hz
        out PIT_CONTROL_PORT, al
; set counter
        mov ax, 1193180 / 100                 ; 100Hz
        out PIT_COUNTER0_PORT, al
        mov al, ah
        out PIT_COUNTER0_PORT, al
        ret


;-------------------------------------------
; disable_timer(): 关闭时间和键盘中断
;-------------------------------------------
disable_timer:
        in al, MASTER_OCW1_PORT
        or al, 3
        out MASTER_OCW1_PORT, al
        ret
        
;----------------------------------------
; DB_handler():  #DB handler
;----------------------------------------
DB_handler:
        jmp do_DB_handler
db_msg1                db '---> Now,enter the #DB handler', 0        
db_msg2                db 'return address: 0x'
return_address         dq 0, 0

do_DB_handler:        
        mov esi, db_msg1
        call puts
        call println
        mov esi, [esp]
        mov edi, return_address
        call get_dword_hex_string
        mov esi, db_msg2
        call puts
        call println
        bts DWORD [esp+8], 16                             ; 设置 eflags.RF 为 1, 以便中断返回时, 继续执行
        iret

;-------------------------------------------
; GP_handler():  #GP handler
;-------------------------------------------
GP_handler:
        jmp do_GP_handler
gp_msg1         db '---> Now, enter the #GP handler'
gp_msg2         db 'return address: 0x'
ret_address     dq 0, 0 
do_GP_handler:        
        mov esi, [esp]
        mov edi, ret_address
        call get_dword_hex_string
        mov esi, gp_msg1
        call puts
        call println        
        iret


;------------------------------------------------------
; set_interrupt_handler(int vector, void(*)()handler)
; input:
;                esi: vector,  edi: handler
;------------------------------------------------------
set_interrupt_handler:
        jmp do_set_interrupt_handler
IDT_POINTER     dw 0
                dd 0
                        
do_set_interrupt_handler:
        sidt [IDT_POINTER]        
        mov eax, [IDT_POINTER+2]
        mov [eax+esi*8], di                                     ; set entry[15:0]
        mov DWORD [eax+esi*8+2], kernel_code32_sel              ; set selector
        mov DWORD [eax+esi*8+5], 0x80 | INTERRUPT_GATE32        ; Type=interrupt gate, P=1, DPL=0
        shr edi, 16
        mov [eax+esi*8+6], di                                   ; set entry[31:16]
        ret



;; 函数导入表

putc:                   jmp LIB32_SEG + LIB32_PUTC * 5
puts:                   jmp LIB32_SEG + LIB32_PUTS * 5
println:                jmp LIB32_SEG + LIB32_PRINTLN * 5
get_dword_hex_string:   jmp LIB32_SEG + LIB32_GET_DWORD_HEX_STRING * 5
hex_to_char:            jmp LIB32_SEG + LIB32_HEX_TO_CHAR * 5

PROTECTED_END: