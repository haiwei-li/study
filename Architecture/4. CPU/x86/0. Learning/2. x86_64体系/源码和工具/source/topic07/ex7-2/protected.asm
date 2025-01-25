; protected.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


%include "..\inc\support.inc"
%include "..\inc\protected.inc"

; 这是 protected 模块

        bits 32
        
        org PROTECTED_SEG - 2

PROTECTED_BEGIN:
protected_length        dw        PROTECTED_END - PROTECTED_BEGIN                                ; protected 模块长度

entry:
        
;; 设置 #GP handler
        mov esi, GP_HANDLER_VECTOR
        mov edi, GP_handler
        call set_interrupt_handler        

;; 设置 #DB handler
        mov esi, DB_HANDLER_VECTOR
        mov edi, DB_handler
        call set_interrupt_handler

;; 设置 #AC handler
        mov esi, AC_HANDLER_VECTOR
        mov edi, AC_handler
        call set_interrupt_handler

;; 设置 #UD handler
        mov esi, UD_HANDLER_VECTOR
        mov edi, UD_handler
        call set_interrupt_handler
                
;; 设置 #NM handler
        mov esi, NM_HANDLER_VECTOR
        mov edi, NM_handler
        call set_interrupt_handler

;; 设置 TSS 的 ESP0        
        mov esi, tss32_sel
        call get_tss_base
        mov DWORD [eax + 4], 9FFFh
        
                
;; 关闭所有 8259中断
        call disable_8259


;==========================================================        

;; 打印 variable-rang 信息
        call enumerate_variable_rang

        mov esi, msg9
        call puts
        
;; 设置 variable-rang 
        mov esi, 0
        mov edi, 0
        mov eax, 1FFFFFFH
        mov edx, 0
        push DWORD 0
        push DWORD 0
        call set_variable_rang
        add esp, 8
        
        mov esi, 2000000H
        mov edi, 0
        mov eax, 2FFFFFFH
        mov edx, 0
        push DWORD 1
        push DWORD 0
        call set_variable_rang        
        add esp, 8
        
        mov esi, 3000000H
        mov edi, 0
        mov eax, 3FFFFFFH
        mov edx, 0
        push DWORD 2
        push DWORD 0
        call set_variable_rang        
        add esp, 8
        
;; 打印 variable-rang 信息
        call enumerate_variable_rang
        
                                        
; 进入 ring 3 代码
        push DWORD user_data32_sel | 0x3
        push esp
        push DWORD user_code32_sel | 0x3        
        push DWORD user_entry
        retf
        
        
no_support:
        mov esi, msg8
        call puts
        
        jmp $


user_entry:
        mov ax, user_data32_sel | 0x3
        mov ds, ax
        mov es, ax

        
        jmp $



msg8                db 'no support!', 10, 0
msg9                db 10, 'Now: set variable-rang', 10, 0



;-------------------------------------------------------------------------
; set_variable_rang(): 设置 variable_rang 区域
; input:
;                 esi: edi-物理基地址,  edx:eax 结束地址,  [esp+4]: variable_rang序号, [esp+8]: memory type
; 描述: 
;                这个函数使用了4个参数, 第3, 4个参数通过stack传递
;                esi:edi 这对寄存器提供基地址(64位值), 　edx:eax 这对寄存器提供结束地址(64位值)
; 例子: 
;                mov esi, 1000000H
;                mov edi, 0H
;                mov edx, 0
;                mov eax, 1FFFFFFH
;                push 0
;                push 06H
;                cal set_variable_rang
; 注意: 
;                这个函数使用了部分 enumerate_variable_rang() 的变量!!
;-------------------------------------------------------------------
set_variable_rang:
        jmp do_set_variable_rang
set_physbase    dq 0                        ; 需要设置的 base值(64位)
set_physlimit   dq 0                        ; 需要设置的 limit值(64位)
set_number      dd 0
set_type        dd 0
do_set_variable_rang:        
        push ecx
        push ebx
        push edx
        
;; 保存参数        
        mov [set_physbase], esi
        mov [set_physbase + 4], edi
        mov [set_physlimit], eax
        mov [set_physlimit + 4], edx
        mov eax, [esp + 20]
        mov [set_number], eax
        mov eax, [esp + 16]
        mov [set_type], eax
        
;; 检查输入的序号是否超限
        mov ecx, IA32_MTRRCAP
        rdmsr
        and eax, 0x0f
        mov [number], eax                       ; 存放 number
        cmp eax, [set_number]
        jb set_variable_rang_done               ; 如果超限, 什么都不做

;; 设置写入值
        mov edx, [set_physbase + 4]             ; 高位
        mov eax, [set_physbase]                 ; 低位
        and eax, 0FFFFF000H                     ; 清低 12位
        mov ebx, [set_type]
        and ebx, 0x0f
        or eax, ebx                             ; 设 memory type(注意, 没有检查合法性)
        mov ebx, [set_number]
        mov ecx, [mtrr_physbase_table + ebx * 4]                
        wrmsr                                   ; 写 IA32_MTRR_PHYSBASE 寄存器

;;;;; 下面计算 PhysMask 值　;;;;;;
        mov esi, set_physlimit
        mov edi, set_physbase
        call subtract64                         ; 使用64位的减法: limit - base
        push edx
        push eax
        
;; 得到 MAXPHYADDR 值
        call get_MAXPHYADDR
        mov [maxphyaddr], eax
        cmp eax, 40                             ; MAXPHYADDR = 40 ?
        je do_set_physmask
        cmp eax, 52                             ; MAXPHYADDR = 52 ?
        je maxphyaddr_52
        mov DWORD [maxphyaddr_value + 4], 0x0F          ; 设置 36 位地址的最高4位值
        jmp do_set_physmask
maxphyaddr_52:
        mov DWORD [maxphyaddr_value + 4], 0xFFFF        ; 设置 52 位地址的最高16位值

do_set_physmask:        
        mov esi, maxphyaddr_value                       ; 最大值
        mov edi, esp                                    ; 减差
        call subtract64
        and eax, 0FFFFF000H
        bts eax, 11                                      ; 设 valid = 1
        mov ebx, [set_number]        
        mov ecx, [mtrr_physmask_table + ebx * 4]
        wrmsr                                            ; 写 IA32_MTRR_PHYSMASK 寄存器
        
        add esp, 8                
set_variable_rang_done:
        pop edx 
        pop ebx
        pop ecx
        ret
        
        
        
;--------------------------------------------------------
; enumerate_variable_rang(): 枚举出当前所有的variable区域
;--------------------------------------------------------
enumerate_variable_rang:
        jmp do_enumerate_variable_rang
emsg1           db 'number of variable rang: 0x'
number          dd 0
nn              db '#', 0, 0, 0
physbase_msg    db 'rang: 0x', 0
physbase_value  dq 0, 0, 0
physlimit_msg   db ' - 0x', 0
physlimit_value dq 0, 0, 0
type_msg        db 'type: ', 0

mtrr_physbase_table        dd IA32_MTRR_PHYSBASE0, IA32_MTRR_PHYSBASE1, IA32_MTRR_PHYSBASE2, IA32_MTRR_PHYSBASE3, IA32_MTRR_PHYSBASE4
                           dd IA32_MTRR_PHYSBASE5, IA32_MTRR_PHYSBASE6, IA32_MTRR_PHYSBASE7, IA32_MTRR_PHYSBASE8, IA32_MTRR_PHYSBASE9
mtrr_physmask_table        dd IA32_MTRR_PHYSMASK0, IA32_MTRR_PHYSMASK1, IA32_MTRR_PHYSMASK2, IA32_MTRR_PHYSMASK3, IA32_MTRR_PHYSMASK4
                           dd IA32_MTRR_PHYSMASK5, IA32_MTRR_PHYSMASK6, IA32_MTRR_PHYSMASK7, IA32_MTRR_PHYSMASK8, IA32_MTRR_PHYSMASK9

emsg2           db 'MTRR disable', 10, 0
emsg3           db ' ---> ', 0
emsg4           db ' <invalid>', 0
;; 缺省为 40 位的最高地址值: 0xFF_FFFFFFFF
maxphyaddr_value        dd 0xFFFFFFFF, 0xFF
maxphyaddr              dd 0                
vcnt                    dd 0                        ; 保存数量值
physbase                dq 0                        ; 保存 PhysBase 值
type                    dd 0                        ; 保存 memory 类型
physmask                dq 0                        ; 保存 PhysMask 值
valid                   dd 0                        ; 保存 valid 位

do_enumerate_variable_rang:        
        push ecx
        push edx
        push ebp

;; 测试是否开启 MTRR 功能        
        mov ecx, IA32_MTRR_DEF_TYPE
        rdmsr                        
        bt eax, 11                                   ; MTRR enable ?
        jc do_enumerate_variable_rang_enable
        mov esi, emsg2
        call puts
        jmp do_enumerate_variable_rang_done
        
do_enumerate_variable_rang_enable:        
        xor ebp, ebp
        mov ecx, IA32_MTRRCAP
        rdmsr                                        ; 读 IA32_MTRRCAP 寄存器
        mov esi, eax                                
        and esi, 0x0f                                ; 得到 IA32_MTRRCAP.VCNT 值
        mov [vcnt], esi                              ; 保存 variable-rang 数量
        mov edi, number
        call get_byte_hex_string                     ; 写入 buffer 中
        mov esi, emsg1
        call puts
        call println
        cmp DWORD [vcnt], 0                           ; 如果 VCNT = 0
        je do_enumerate_variable_rang_done
        
;; 得到 MAXPHYADDR 值
        call get_MAXPHYADDR
        mov [maxphyaddr], eax
        cmp eax, 40                                    ; MAXPHYADDR = 40 ?
        je do_enumerate_variable_rang_loop
        cmp eax, 52                                    ; MAXPHYADDR = 52 ?
        je set_maxphyaddr_52
        mov DWORD [maxphyaddr_value + 4], 0x0F         ; 设置 36 位地址的最高4位值
        jmp do_enumerate_variable_rang_loop
set_maxphyaddr_52:
        mov DWORD [maxphyaddr_value + 4], 0xFFFF       ; 设置 52 位地址的最高16位值
        
do_enumerate_variable_rang_loop:
;; 打印序号        
        mov esi, ebp
        mov edi, nn + 1
        call get_byte_hex_string
        mov esi, nn
        call puts        
        mov esi, emsg3
        call puts
        
;; 打印  base 地址
        mov esi, physbase_msg
        call puts
        mov ecx, [mtrr_physbase_table + ebp * 4]       ; 得到 MTRR_PHYSBASE 寄存器地址
        rdmsr
        
        mov [physbase], eax
        mov [physbase + 4], edx
        and DWORD [physbase], 0xFFFFFFF0               ; 去掉 type 值
        and eax, 0xf0                                  ; 得到 type 值
        mov [type], eax
        mov ecx, [mtrr_physmask_table + ebp * 4]        ; 得到 MTRR_PHYSMASK 寄存器地址
        rdmsr
        btr eax, 11                                     ; 得到 valid 值
        mov [physmask], eax
        mov [physmask + 4], edx
        setc al
        movzx eax, al
        mov [valid], eax                                ; 保存 valid 值
;; 打印基址
        mov esi, physbase
        mov edi, physbase_value
        call get_qword_hex_string
        mov esi, physbase_value
        call puts
        mov esi, physlimit_msg
        call puts
;; 计算范围值
        mov esi, maxphyaddr_value
        mov edi, physmask
        call subtract64
        push edx
        push eax
        mov esi, esp
        mov edi, physbase
        call addition64
        push edx
        push eax
        mov esi, esp
        mov edi, physlimit_value
        call get_qword_hex_string
        add esp, 16
        mov esi, physlimit_value
        call puts

;; 是否 valid
        cmp DWORD [valid], 0
        jne print_memory_type
        mov esi, emsg4
        call puts
        jmp do_enumerate_variable_rang_next
        
print_memory_type:
        mov esi, ' '
        call putc
        mov eax, [type]        
        mov esi, [memory_type_table + eax * 4]
        call puts
        
do_enumerate_variable_rang_next:        
        call println        
        inc ebp
        cmp ebp, [vcnt]                                     ; 遍历 VCNT 次数
        jb do_enumerate_variable_rang_loop
        
do_enumerate_variable_rang_done:        
        pop ebp
        pop edx
        pop ecx
        ret




;------------------------------------------
; dump_fixed64K_rang(): 打印 fixed-rang 的类型
; input:
;                esi: low32, edi: hi32
;------------------------------------------
dump_fixed64K_rang:
        jmp do_dump_fixed64K_rang
byte0        db '00000-0FFFF: ', 0
byte1        db '10000-1FFFF: ', 0
byte2        db '20000-2FFFF: ', 0
byte3        db '30000-3FFFF: ', 0
byte4        db '40000-4FFFF: ', 0
byte5        db '50000-5FFFF: ', 0
byte6        db '60000-6FFFF: ', 0
byte7        db '70000-7FFFF: ', 0
t0           db 'Uncacheable', 0
t1           db 'WriteCombining', 0
t2           db 'WriteThrough', 0
t3           db 'WriteProtected', 0
t4           db 'WriteBack', 0
mtrr_table          dd byte0,byte1,byte2,byte3,byte4,byte5,byte6,byte7, -1
memory_type_table   dd t0, t1, 0, 0, t2, t3, t4
mtrr_value          dq 0        
do_dump_fixed64K_rang:        
        push ecx
        push ebx
        mov [mtrr_value], esi
        mov [mtrr_value+4], edi
        mov ebx, mtrr_table
        xor ecx, ecx
        
do_dump_fixed64K_rang_loop:        
        mov esi, [ebx + ecx * 4]
        cmp esi, -1
        jz do_dump_fixed64K_rang_done
        call puts                                                ; 打印信息
        movzx eax, BYTE [mtrr_value + ecx]
        mov esi, [memory_type_table + eax * 4]
        call puts
        call println
        inc ecx
        jmp do_dump_fixed64K_rang_loop
        
do_dump_fixed64K_rang_done:        
        pop ebx
        pop ecx
        ret


        

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

register_message_table        dd eax_message, ebx_message, ecx_message, edx_message  
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
        bts DWORD [esp + 4 * 8 + 8], 16                 ; 设置 eflags.RF 为 1, 以便中断返回时, 继续执行
        popad
        iret

;-------------------------------------------
; GP_handler():  #GP handler
;-------------------------------------------
GP_handler:
        jmp do_GP_handler
gp_msg1         db '---> Now, enter the #GP handler. '
gp_msg2         db 'return address: 0x'
ret_address     dq 0, 0 
gp_msg3         db 'skip STI instruction', 10, 0
do_GP_handler:        
        add esp, 4                                    ;  忽略错误码
        mov esi, [esp]
        mov edi, ret_address
        call get_dword_hex_string
        mov esi, gp_msg1
        call puts
        call println
        mov eax, [esp]
        cmp BYTE [eax], 0xfb                        ; 检查是否因为 sti 指令而产生 #GP 异常
        jne fix
        inc eax                                      ; 如果是的话, 跳过产生 #GP 异常的 sti 指令, 执行下一条指令
        mov [esp], eax
        mov esi, gp_msg3
        call puts
        jmp do_GP_handler_done
fix:
        mov eax, [esp+12]
        mov esi, [esp+4]                            ; 得到被中断代码的 cs
        test esi, 3
        jz fix_eip
        mov eax, [eax]
fix_eip:        
        mov [esp], eax                                ; 写入返回地址        
do_GP_handler_done:                
        iret

;----------------------------------------------
; UD_handler(): #UD handler
;----------------------------------------------
UD_handler:
        jmp do_UD_handler
ud_msg1  db '---> Now, enter the #UD handler', 10, 0        
do_UD_handler:
        mov esi, ud_msg1
        call puts
        mov eax, [esp+12]                        ; 得到 user esp
        mov eax, [eax]
        mov [esp], eax                          ; 跳过产生#UD的指令
        add DWORD [esp+12], 4                  ; pop 用户 stack
        iret
        
;----------------------------------------------
; NM_handler(): #NM handler
;----------------------------------------------
NM_handler:
        jmp do_NM_handler
nm_msg1 db '---> Now, enter the #NM handler', 10, 0        
do_NM_handler:        
        mov esi, nm_msg1
        call puts
        mov eax, [esp+12]                        ; 得到 user esp
        mov eax, [eax]
        mov [esp], eax                           ; 跳过产生#NM的指令
        add DWORD [esp+12], 4                   ; pop 用户 stack
        iret        

;-----------------------------------------------
; AC_handler(): #AC handler
;-----------------------------------------------
AC_handler:
        jmp do_AC_handler
ac_msg1  db '---> Now, enter the #AC exception handler <---', 10
ac_msg2  db 'exception location at 0x'
ac_location   dq 0, 0
do_AC_handler:        
        pusha
        mov esi, [esp+4+4*8]                        
        mov edi, ac_location
        call get_dword_hex_string
        mov esi, ac_msg1
        call puts
        call println
;; 现在 disable AC 功能
        btr DWORD [esp+12+4*8], 18                ; 清elfags image中的AC标志        
        popa
        add esp, 4                                 ; 忽略 error code        
        iret






%include "..\lib\pic8259A.asm"

;; 函数导入表
%include "..\common\lib32_import_table.imt"

PROTECTED_END: