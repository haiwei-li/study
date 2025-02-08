; setup.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


%include "..\inc\support.inc"
%include "..\inc\protected.inc"

; 这是 protected 模块

        bits 32
        
        org PROTECTED_SEG - 2

PROTECTED_BEGIN:
protected_length        dw      PROTECTED_END - PROTECTED_BEGIN         ; protected 模块长度

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

;; 为了完成实验，关闭时间中断和键盘中断
        call disable_timer


;; 下面测试 #DB handler 的执行
        
; 开启 single debug 功能
        pushfd
        bts dword [esp], 8                                ; eflags.TF = 1
        popfd                                             ; 更新 eflags 寄存器
        
        mov eax, 1                                                ; test 1
        mov eax, 2                                                ; test 2
        mov eax, 3                                                ; test 3
        mov eax, 4                                                ; test 4
        mov eax, 5                                                ; test 5

        jmp $
        

user_entry:
        mov ax, user_data32_sel | 0x3
        mov ds, ax
        mov es, ax
        

        mov esi, msg4
        call puts
        call dump_flags_value
        call println

        
        mov esi, msg5
        call puts
        
;; 测试1: 读 port 0x21        
        in al, MASTER_OCW1_PORT                        ; 尝试读 port 0x21

        mov esi, msg6
        call puts        
        
;; 测试2: 写 port 0x21        
        mov al, 0x0f
        out MASTER_OCW1_PORT, al                ; 尝试写 port 0x21
        
        mov esi, msg7
        call puts
        
        jmp $




msg1                db 'Now: CPL=0, eflags value is:', 0
msg2                db 'Now: test the #DB exception...', 10,0
msg3                db 'Now: modify the eflags.IOPL to level 2 from 0', 0
msg4                db 'Now: CPL=3, eflags value is:', 10, 0
msg5                db 'Now: try to read port 0x21', 10, 0
msg6                db 'Now: try to write port 0x21', 10, 0
msg7                db 'success!',
value_address        dq 0, 0

        
;----------------------------------------
; DB_handler():  #DB handler
;----------------------------------------
DB_handler:
        jmp do_DB_handler
db_msg1            db '-----< Single-Debug information >-----', 10, 0        
db_msg2            db '>>>>> END <<<<<', 10, 0
eax_message        db 'eax: 0x          ', 0
ebx_message        db 'ebx: 0x          ', 0
ecx_message        db 'ecx: 0x          ', 0
edx_message        db 'edx: 0x          ', 0
esp_message        db 'esp: 0x          ', 0
ebp_message        db 'ebp: 0x          ', 0
esi_message        db 'esi: 0x          ', 0
edi_message        db 'edi: 0x          ', 0
eip_message        db 'eip: 0x          ', 0
return_address     dq 0, 0

register_message_table dd eax_message, ebx_message, ecx_message, edx_message  
                       dd esp_message, ebp_message, esi_message, edi_message, 0

do_DB_handler:        
;; 得到寄存器值
        pushad
        
        mov esi, db_msg1
        call puts
        
        lea ebx, [esp + 4 * 7]
        xor ecx, ecx

;; 停止条件        
        mov esi, [esp + 4 * 8]
        cmp esi, [return_address]
        je clear_TF
        
do_DB_handler_loop:        
        lea eax, [ecx*4]
        neg eax
        mov esi, [ebx + eax]
        mov edx, [register_message_table + ecx *4]
        lea edi, [edx + 7]
        call get_dword_hex_string
        mov esi, edx
        call puts
        
        inc ecx        
        test ecx, 3
        jnz do_DB_handler_tab
        call println
        jmp do_DB_handler_next
do_DB_handler_tab:        
        mov esi, DWORD '  '
        call putc
do_DB_handler_next:        
        cmp ecx, 8
        jb do_DB_handler_loop
        
        mov esi, [esp + 4 * 8]
        mov edi, eip_message+7
        call get_dword_hex_string
        mov esi, eip_message
        call puts
        call println
        mov eax, [esp + 4 * 8]
        mov [return_address], eax
        jmp do_DB_handler_done
clear_TF:
        btr DWORD [esp + 4 * 8 + 8], 8                  ; 清 TF 标志
        mov esi, db_msg2
        call puts
do_DB_handler_done:        
        bts DWORD [esp + 4 * 8 + 8], 16                 ; 设置 eflags.RF 为 1，以便中断返回时，继续执行
        popad
        iret

;-------------------------------------------
; GP_handler():  #GP handler
;-------------------------------------------
GP_handler:
        jmp do_GP_handler
gp_msg1             db '---> Now, enter the #GP handler. '
gp_msg2             db 'return address: 0x'
ret_address        dq 0, 0 
gp_msg3            db '<<< Now, set port 0x21 IOBITMAP to 0', 0
do_GP_handler:        
        pop eax                                            ;  忽略错误码
        mov esi, [esp]
        mov edi, ret_address
        call get_dword_hex_string
        mov esi, gp_msg1
        call puts
        call println        
        mov esi, gp_msg3
        call puts
        call println
;; 现在重新开启I/O可访问权限
        mov esi, MASTER_OCW1_PORT
        mov edi, 0                                        ; set port 0x21 IOBITMAP to 0
        call set_io_bitmap
        iret





%include "..\lib\creg.asm"
%include "..\lib\pic8259A.asm"


;; 函数导入表

%include "..\common\lib32_import_table.imt"


PROTECTED_END: