; setup.asm
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
        
;; 设置 #GP handler
        mov esi, GP_HANDLER_VECTOR
        mov edi, GP_handler
        call set_interrupt_handler        

;; 设置 #DB handler
        mov esi, DB_HANDLER_VECTOR
        mov edi, DB_handler
        call set_interrupt_handler

;; 设置 TSS 的 ESP0        
        mov esi, tss32_sel
        call get_tss_base
        mov DWORD [eax + 4], KERNEL_ESP

;; 为了完成实验, 关闭时间中断和键盘中断
        call disable_timer


;; 设置 TSS 的 IOBITMAP
        mov esi, MASTER_OCW1_PORT
        mov edi, 1                                                ; 不允许访问
        call set_IO_bitmap
        
                
; 进入 ring 3 完成实验
        push user_data32_sel | 0x3
        push esp
        push user_code32_sel | 0x3
        push DWORD user_entry
        retf

        jmp $
        

user_entry:
        mov ax, user_data32_sel | 0x3
        mov ds, ax
        mov es, ax
        

        mov esi, msg4
        call puts
        call print_flags_value
        call println

        
        mov esi, msg5
        call puts
        
;; 测试1: 读 port 0x21        
        in al, MASTER_OCW1_PORT                        ; 尝试读 port 0x21

        mov esi, msg6
        call puts        
        
;; 测试2: 写 port 0x21        
        mov al, 0x0f
        out MASTER_OCW1_PORT, al                        ; 尝试写 port 0x21
        
        mov esi, msg7
        call puts
        
        jmp $




msg1                db 'Now: CPL=0, eflags value is:', 0
msg2                db 'Now: test the #DB exception...', 0
msg3                db 'Now: modify the eflags.IOPL to level 2 from 0', 0
msg4                db 'Now: CPL=3, eflags value is:', 10, 0
msg5                db 'Now: try to read port 0x21', 10, 0
msg6                db 'Now: try to write port 0x21', 10, 0
msg7                db 'success!',
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
        bts DWORD [esp+8], 16                                        ; 设置 eflags.RF 为 1, 以便中断返回时, 继续执行
        iret

;-------------------------------------------
; GP_handler():  #GP handler
;-------------------------------------------
GP_handler:
        jmp do_GP_handler
gp_msg1                db '---> Now, enter the #GP handler. return address: 0x', 0
gp_msg3                db '<<< Now, set port 0x21 IOBITMAP to 0', 10, 0
do_GP_handler:        
        pop eax                                                        ;  忽略错误码
        mov esi, gp_msg1
        call puts
        mov esi, [esp]
        call print_dword_value
        call println        
        mov esi, gp_msg3
        call puts
;; 现在重新开启I/O可访问权限
        mov esi, MASTER_OCW1_PORT
        mov edi, 0                                                ; set port 0x21 IOBITMAP to 0
        call set_IO_bitmap
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



;--------------------------------------------------------
; set_IO_bitmap(int port, int value): 设置 IOBITMAP 中的值
; input:
;                esi - port(端口值), edi - value 设置的值
;---------------------------------------------------------
set_IO_bitmap:
        jmp do_set_IO_bitmap
gdt_pointer dw 0
            dd 0        
do_set_IO_bitmap:        
        push ebx
        push ecx
        str eax                                 ; 得到 TSS selector
        sgdt [gdt_pointer]                      ; 得到 GDT base
        and eax, 0xfffffff8
        add eax, [gdt_pointer + 2]              
        mov ebx, [eax+4]        
        and ebx, 0x00ff
        shl ebx, 16
        mov ecx, [eax+4]
        and ecx, 0xff000000 
        or ebx, ecx
        mov eax, [eax]                          ; 得到 TSS descriptor
        shr eax, 16
        or eax, ebx
        movzx ebx, WORD [eax+102]
        add eax, ebx                            ; 得到 IOBITMAP
        mov ebx, esi
        shr ebx, 3
        and esi, 7
        bt edi, 0
        jc set_bitmap
        btr DWORD [eax+ebx], esi                 ; 清位
        jmp do_set_IO_bitmap_done
set_bitmap:
        bts DWORD [eax+ebx], esi                ; 置位
do_set_IO_bitmap_done:        
        pop ecx
        pop ebx
        ret



;; 函数导入表

putc:                   jmp LIB32_SEG + LIB32_PUTC * 5
puts:                   jmp LIB32_SEG + LIB32_PUTS * 5
println:                jmp LIB32_SEG + LIB32_PRINTLN * 5
get_dword_hex_string:   jmp LIB32_SEG + LIB32_GET_DWORD_HEX_STRING * 5
hex_to_char:            jmp LIB32_SEG + LIB32_HEX_TO_CHAR * 5
print_dword_value       jmp LIB32_SEG + LIB32_PRINT_DWORD_VALUE * 5
get_tss_base            jmp LIB32_SEG + LIB32_GET_TSS_BASE * 5

PROTECTED_END: