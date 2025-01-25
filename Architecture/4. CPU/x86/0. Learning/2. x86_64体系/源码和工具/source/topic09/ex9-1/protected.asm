; protected.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


%include "..\inc\support.inc"
%include "..\inc\protected.inc"

; 这是 protected 模块

        bits 32
        
        org PROTECTED_SEG - 2

PROTECTED_BEGIN:
protected_length        dw        PROTECTED_END - PROTECTED_BEGIN           ; protected 模块长度

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


;################  实验代码  ###########################        

; SMRAM control
        SET_SMRAM_OPEN                       ; 置 D_OPEN 为 1, 打开 SMRAM 区域

; 将 SMI handler 写入 a8000 处
        mov ecx, CSEG_SMM_END - CSEG_SMM_BEGIN
        mov esi, CSEG_SMM_BEGIN
        mov edi, 0A8000h
        rep movsb

; 将 Tseg SMM 写入 2000000h 处
        mov ecx, TSEG_SMM_END - TSEG_SMM_BEGIN
        mov esi, TSEG_SMM_BEGIN
        mov edi, 2008000h
        rep movsb


;; 写 SMI_EN 寄存器的 APMC_EN 位
        call get_PMBASE
        mov edx, eax
        add edx, 30h                        ; SMI_EN 寄存器位置
        in eax, dx                          ; 读 DWORD
        bts eax, 5                          ; APMC_EN = 1
        out dx, eax                         ; 写 DWORD
        

;; 第1次触发 SMI#, 进入 SMI handler 在 0A8000h 处                
        mov dx, APM_CNT
        out dx, al
        
        
;; #### 实验: 给 SMI handler 传递参数 ########
        mov ebx, 100FFFCh                        ; 在 ebx 赋于 100FFFCh 给 SMI handler 传递参数
        mov al, 01                               ; 参数类型 1
        mov dx, APM_STS                         ; 通过 APM status 寄存器给 SMI handler 传递类型
        out dx, al
        
        
        
;; 第2次触发 SMI# 进入 SMI handler 在 2008000h 位置        
        mov dx, APM_CNT
        out dx, al        
        
;; *** 下面进行探测 SMRAM 区域的实验 ***        
;; 1. 当 D_OPEN = 1 的情况下, 进行探测 SMRAM 区域
        SET_SMRAM_CLOSE                                ; 关闭为了显示输出
        mov esi, msg12
        call puts
        SET_SMRAM_OPEN                                ; 打开进行探测
        call enumerate_smi_region

;; 由 SMI handler 返回        
        SET_SMRAM_CLOSE                               ; 清 D_OPEN 位, 关闭 SMRAM 区域


;; 2. 当 D_OPEN = 0 的情况下, 进行深测 SMRAM 区域

;; 探测 SMRAM 区域        
        mov esi, msg13
        call puts
        call enumerate_smi_region        
        

        mov dx, APM_STS
        in al, dx
        cmp al, 1
        jnz next

;; 下面的实验是在 SMI handler 里复制 State Save Map 信息到提供的位置上 ****
;; *** 打印 SMM State Save Map 区域信息(部分)        
        mov esi, msg14
        call puts
        
        mov ebx, 1000000h
;*** 输出 ES 信息        
        mov esi, es_msg
        call puts
        mov esi, selector_msg
        call puts
        mov si, WORD [ebx + 0FE00h]                   ; selector
        call print_word_value
        call printblank
        mov esi, attribute_msg
        call puts
        mov si, WORD [ebx + 0FE02h]                  ; attribute
        call print_word_value
        call printblank        
        mov esi, limit_msg
        call puts
        mov esi, DWORD [ebx + 0FE04h]                ; limit
        call print_dword_value
        call printblank        
        mov esi, base_msg
        call puts
        mov esi, DWORD [ebx + 0FE08h]                ; base[31:0]
        mov edi, DWORD [ebx + 0FE0Ch]                ; base[63:32]
        call print_qword_value
        call println
        
;*** 输出 CS 信息        
        mov esi, cs_msg
        call puts
        mov esi, selector_msg
        call puts
        mov si, WORD [ebx + 0FE10h]                   ; selector
        call print_word_value
        call printblank
        mov esi, attribute_msg
        call puts
        mov si, WORD [ebx + 0FE12h]                   ; attribute
        call print_word_value
        call printblank        
        mov esi, limit_msg
        call puts
        mov esi, DWORD [ebx + 0FE14h]                ; limit
        call print_dword_value
        call printblank        
        mov esi, base_msg
        call puts
        mov esi, DWORD [ebx + 0FE18h]                ; base[31:0]
        mov edi, DWORD [ebx + 0FE1Ch]                ; base[63:32]
        call print_qword_value
        call println        
        
;*** 输出 SS 信息        
        mov esi, ss_msg
        call puts
        mov esi, selector_msg
        call puts
        mov si, WORD [ebx + 0FE20h]                 ; selector
        call print_word_value
        call printblank
        mov esi, attribute_msg
        call puts
        mov si, WORD [ebx + 0FE22h]                 ; attribute
        call print_word_value
        call printblank        
        mov esi, limit_msg
        call puts
        mov esi, DWORD [ebx + 0FE24h]                ; limit
        call print_dword_value
        call printblank        
        mov esi, base_msg
        call puts
        mov esi, DWORD [ebx + 0FE28h]                ; base[31:0]
        mov edi, DWORD [ebx + 0FE2Ch]                ; base[63:32]
        call print_qword_value
        call println        
        
;*** 输出 DS 信息        
        mov esi, ds_msg
        call puts
        mov esi, selector_msg
        call puts
        mov si, WORD [ebx + 0FE30h]                ; selector
        call print_word_value
        call printblank
        mov esi, attribute_msg
        call puts
        mov si, WORD [ebx + 0FE32h]                 ; attribute
        call print_word_value
        call printblank        
        mov esi, limit_msg
        call puts
        mov esi, DWORD [ebx + 0FE34h]                ; limit
        call print_dword_value
        call printblank        
        mov esi, base_msg
        call puts
        mov esi, DWORD [ebx + 0FE38h]                ; base[31:0]
        mov edi, DWORD [ebx + 0FE3Ch]                ; base[63:32]
        call print_qword_value
        call println        
        call println
        
;*** 输出 GDTR 信息        
        mov esi, gdtr_msg
        call puts
        mov esi, base_msg
        call puts
        mov esi, DWORD [ebx + 0FE68h]                ; base[31:0]
        mov edi, DWORD [ebx + 0FE6Ch]                ; base[63:32]
        call print_qword_value
        call printblank                
        mov esi, limit_msg
        call puts        
        mov si, WORD [ebx + 0FE64h]                ; limit
        call print_word_value        
        call println
        
;*** 输出 IDTR 信息        
        mov esi, idtr_msg
        call puts
        mov esi, base_msg
        call puts
        mov esi, DWORD [ebx + 0FE88h]                ; base[31:0]
        mov edi, DWORD [ebx + 0FE8Ch]                ; base[63:32]
        call print_qword_value
        call printblank        
        mov esi, limit_msg
        call puts        
        mov si, WORD [ebx + 0FE84h]                  ; limit
        call print_dword_value        
        call println
                

;*** 输出 LDTR 信息        
        mov esi, ldtr_msg
        call puts
        mov esi, selector_msg
        call puts
        mov si, WORD [ebx + 0FE70h]               ; selector
        call print_word_value
        call printblank
        mov esi, attribute_msg
        call puts
        mov si, WORD [ebx + 0FE72h]                 ; attribute
        call print_word_value
        call printblank        
        mov esi, limit_msg
        call puts
        mov esi, DWORD [ebx + 0FE74h]                ; limit
        call print_dword_value
        call printblank        
        mov esi, base_msg
        call puts
        mov esi, DWORD [ebx + 0FE78h]                ; base[31:0]
        mov edi, DWORD [ebx + 0FE7Ch]                ; base[63:32]
        call print_qword_value
        call println
                

;*** 输出 TR 信息        
        mov esi, tr_msg
        call puts
        mov esi, selector_msg
        call puts
        mov si, WORD [ebx + 0FE90h]                 ; selector
        call print_word_value
        call printblank
        mov esi, attribute_msg
        call puts
        mov si, WORD [ebx + 0FE92h]                 ; attribute
        call print_word_value
        call printblank        
        mov esi, limit_msg
        call puts
        mov esi, DWORD [ebx + 0FE94h]                ; limit
        call print_dword_value
        call printblank        
        mov esi, base_msg
        call puts
        mov esi, DWORD [ebx + 0FE98h]                ; base[31:0]
        mov edi, DWORD [ebx + 0FE9Ch]                ; base[63:32]
        call print_qword_value
        call println
        call println
                        
; 打印 SMBASE 
        mov esi, smbase_msg
        call puts
        mov esi, [ebx + 0FF00h]                        
        call print_dword_value
        call println

; 打印 Rip
        mov esi, rip_msg
        call puts
        mov esi, [ebx + 0FF78h]        
        mov edi, [ebx + 0FF7Ch]
        call print_qword_value
        call println

; 打印 Rflags
        mov esi, rflags_msg
        call puts
        mov esi, [ebx + 0FF70h]
        mov edi, [ebx + 0FF74h]        
        call print_qword_value
        call println        

next:
                        
                                                
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




msg1                db 'Now: CPL=0, eflags value is:', 0
msg2                db 'Now: test the #DB exception...', 10,0
msg3                db 'Now: modify the eflags.IOPL to level 2 from 0', 0
msg4                db 'Now: CPL=3, eflags value is:', 10, 0
msg5                db 'Now: try to read port 0x21', 10, 0
msg6                db 'Now: try to write port 0x21', 10, 0
msg7                db 'success!', 10, 0
msg8                db 'no support!', 10, 0
msg9                db 10, 'Now: set variable-rang', 10, 0
msg10                db 10, 'Now: exit the system service', 10, 0
msg11                db 10,  '---> Now: set monitor/mwait to disable, and monitor line size <---', 10, 10, 0
msg12                db '---> Now: D_OPEN = 1 <---', 10, 0
msg13                db '---> Now: D_OPEN = 0 <---', 10, 0
msg14                db 10, 10, '>>>> SMM State Save Map information(partial) <<<<<', 10, 10, 0
value_address        dq 0, 0
mem32int             dd 0

selector_msg        db 'selector:', 0
attribute_msg       db 'attribute:', 0
limit_msg           db 'limit:', 0
base_msg            db 'base:', 0

es_msg              db '<ES:> ', 0
cs_msg              db '<CS:> ', 0
ss_msg              db '<SS:> ', 0
ds_msg               db '<DS:> ', 0
fs_msg               db '<FS:> ', 0
gs_msg               db '<GS:> ', 0
gdtr_msg             db '<GDTR:> ', 0
ldtr_msg             db '<LDTR:> ', 0
idtr_msg             db '<IDTR:> ', 0
tr_msg               db '<TR:>   ', 0

smbase_msg           db 'SMBASE: ', 0
rip_msg              db 'RIP:    ', 0
rflags_msg           db 'Rflags: ', 0


;####### 下面是 SMM 区域 #######

CSEG_SMM_BEGIN:

        bits 16        

;#
;# 这个 SMI handler 的目的是重定位在 200000h 位置上 ###
;#
cseg_smi_entry:
        mov ebx, 0AFEFCh                        ; SMM revision id
        mov al, [ebx]
        cmp al, 0x64                                ; 测试 SMM 版本
        je new_rev
        mov ebx, 0AFEF8h
        jmp set_SMBASE
new_rev:
        mov ebx, 0AFF00h
set_SMBASE:        
        mov eax, 2000000h                        ; 32M 边界
        mov [ebx], eax                            ; 新的 SMBASE

;; 测试打开 CR0.PE = 1
;        db 0x66
;        lgdt [DWORD gdt_pointer- cseg_smi_entry + 0xa8000]
;        mov eax, cr0
;        bts eax, 0
;        mov cr0, eax        
;        jmp DWORD 08:smi_next-cseg_smi_entry + 0xa8000
;        bits 32
;smi_next:
;        mov ax, 0x10
;        mov ds, ax        

; 测试调用中断
;        int 13h                

; 测试 jmp far
        ;jmp DWORD 0:0x2008000                ; 远调用
        
;; 测试 SMM 里的中断调用        
        ;db 0x66
        ;lidt [DWORD smm_ivt - cseg_smi_entry + 0xa8000]
        ;int 0

;; 测试 SMM 里的单步调试        
;        pushfd
;        bts DWORD [esp], 8
;        popfd
;        mov eax, 1
;        mov eax, 2

;; 测试 I/O restart
;        mov BYTE [DWORD 0AFEC8h], 0FFh

;; 测试 CR0/CR4
;        mov eax, [DWORD 0A0000h + 0FF58h]                ; CR0 image
;        btr eax, 30                                                                ; CR0.CD = 0
;        bts eax, 29                                                                ; CR0.NW = 1
;        mov [DWORD 0A0000h + 0FF58h], eax                ; write CR0 image
        rsm

smm_ivt        dw 0x3ff
                dd vector0 -cseg_smi_entry + 0xa8000
        
IVT:
vector0        dw        8000H                        ;; 哈!! vector 0 是转到 SMI handler 入口点
               dw         0A000H

GDT:
                                  dq 0
kernel_code32_desc                dq 0x00cf9a000000ffff                ; non-conforming, accessed, DPL=0, P=1
kernel_data32_desc                dq 0x00cf92000000ffff                ; DPL=0, P=1, writeable/accessed, expand-up
GDT_END:

gdt_pointer:
        dw GDT_END - GDT -1
        dd GDT-cseg_smi_entry + 0xa8000
                                
CSEG_SMM_END:





TSEG_SMM_BEGIN:
;#
;### 这个是最终的 SMI handler
;#

tseg_smi_entry:
        mov dx, APM_STS
        in al, dx                          ; 读参数类型
        cmp al, 01                         ; 是否为类型 1
        jnz smi_handler_done
        
        mov ebx, 200FEFCh                ; SMM revision id 的位置
        cmp byte [ebx], 64h                ; 测试是否为版本 64h
        je rev_64h
        mov ebx, 2007FDCh                ; Intel 版本的 ebx 寄存器位置
        jmp read_ebx
rev_64h:        
        mov ebx, 200FFE0h                ; AMD64 版本的 rbx 寄存器位置
read_ebx:        
        mov edi, [ebx]                   ; 读取 ebx 寄存器的值(传递过的参数-栈底)
        
;; 下面是复制 SMI handler 的 state save 区域到目标位置上(由ebx寄存器传过来的参数)
        mov esi, 200FFFCh                ; save 区域的起始位置(栈底)
        mov ecx, (2010000h-200FC00h)/4
        std
        db 0x67                  ; address size override 操作
        rep movsd
        
        mov al, 01
smi_handler_done:
        mov dx, APM_STS
        out dx, al
        rsm                
TSEG_SMM_END:                




;###############################

        bits 32

enumerate_smi_region:
        jmp do_enumerate_smi_region
es_msg1        db 'rsm instruction at region: '
es_value dq 0, 0
es_msg2 db ' address: 0x', 0
smi_region: times 10 dd 0, 0                ; 定义 10 个变量保存 region 和 address
do_enumerate_smi_region:
        push ebx
        push ecx
        push edx
        
;; 清变量
        mov edi, smi_region
        xor eax, eax
        mov ecx, 20
        rep stosd
                
        mov ebx, 0x30000                      ;; 从 300000H 位置开始探测
        xor ecx, ecx
        xor edx, edx
do_enumerate_smi_region_loop:
        mov ax, [ebx + ecx]
        cmp ax, 0xaa0f                        ; 查找 rsm 指令
        jne enumerate_smi_region_next
        ;; 保存 region 和 address
        mov [smi_region + edx * 4], ebx
        lea esi, [ebx + ecx]
        mov [smi_region + edx * 4 + 4], esi
        add edx, 2
        jmp enumerate_smi_region_next_region
enumerate_smi_region_next:
        inc ecx
        cmp ecx, 8000h + 7C00h
        jb do_enumerate_smi_region_loop
enumerate_smi_region_next_region:
        xor ecx, ecx
        add ebx, 0x10000
        cmp ebx, 0x10000000
        jb do_enumerate_smi_region_loop
        
;; 打印探测结果        
        SET_SMRAM_CLOSE                          ; 关闭 SMRAM 为了打印探测结果
        xor edx, edx        
enumerate_smi_region_result:        
        mov eax, [smi_region + edx * 4]
        mov ebx, [smi_region + edx * 4 + 4]
        test eax, eax
        jz enumerate_smi_region_done
        mov esi, eax
        mov edi, es_value
        call get_dword_hex_string
        mov esi, es_msg1
        call puts
        mov esi, es_msg2
        call puts
        mov esi, ebx
        call print_value
        add edx, 2
        jmp enumerate_smi_region_result
        
enumerate_smi_region_done:
        pop edx
        pop ecx
        pop ebx
        ret


;------------------------------------------
; sys_service():  system service entery
;-----------------------------------------
sys_service:
        jmp do_syservice
smsg1        db '---> Now, enter the system service', 10, 0
do_syservice:        
        mov esi, smsg1
        call puts
        sysexit


;----------------------------------------
; DB_handler():  #DB handler
;----------------------------------------
DB_handler:
        jmp do_DB_handler
db_msg1           db '-----< Single-Debug information >-----', 10, 0        
db_msg2           db '>>>>> END <<<<<', 10, 0
eax_message        db 'eax: 0x          ', 0
ebx_message        db 'ebx: 0x          ', 0
ecx_message        db 'ecx: 0x          ', 0
edx_message        db 'edx: 0x          ', 0
esp_message        db 'esp: 0x          ', 0
ebp_message        db 'ebp: 0x          ', 0
esi_message        db 'esi: 0x          ', 0
edi_message        db 'edi: 0x          ', 0
eip_message db 'eip: 0x          ', 0
return_address dq 0, 0

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
        btr DWORD [esp + 4 * 8 + 8], 8             ; 清 TF 标志
        mov esi, db_msg2
        call puts
do_DB_handler_done:        
        bts DWORD [esp + 4 * 8 + 8], 16            ; 设置 eflags.RF 为 1, 以便中断返回时, 继续执行
        popad
        iret

;-------------------------------------------
; GP_handler():  #GP handler
;-------------------------------------------
GP_handler:
        jmp do_GP_handler
gp_msg1                db '---> Now, enter the #GP handler. '
gp_msg2                db 'return address: 0x'
ret_address        dq 0, 0 
gp_msg3                db 'skip STI instruction', 10, 0
do_GP_handler:        
        add esp, 4                                                        ;  忽略错误码
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
        mov esi, [esp+4]                                ; 得到被中断代码的 cs
        test esi, 3
        jz fix_eip
        mov eax, [eax]
fix_eip:        
        mov [esp], eax                                  ; 写入返回地址        
do_GP_handler_done:                
        iret

;----------------------------------------------
; UD_handler(): #UD handler
;----------------------------------------------
UD_handler:
        jmp do_UD_handler
ud_msg1                db '---> Now, enter the #UD handler', 10, 0        
do_UD_handler:
        mov esi, ud_msg1
        call puts
        mov eax, [esp+12]                        ; 得到 user esp
        mov eax, [eax]
        mov [esp], eax                           ; 跳过产生#UD的指令
        add DWORD [esp+12], 4                   ; pop 用户 stack
        iret
        
;----------------------------------------------
; NM_handler(): #NM handler
;----------------------------------------------
NM_handler:
        jmp do_NM_handler
nm_msg1                db '---> Now, enter the #NM handler', 10, 0        
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
;; 现在 disable        AC 功能
        btr DWORD [esp+12+4*8], 18                ; 清elfags image中的AC标志        
        popa
        add esp, 4                                 ; 忽略 error code        
        iret


;********* include 模块 ********************
%include "..\lib\creg.asm"
%include "..\lib\cpuid.asm"
%include "..\lib\msr.asm"
%include "..\lib\pci.asm"
%include "..\lib\pic8259A.asm"

;; 函数导入表
%include "..\common\lib32_import_table.imt"

PROTECTED_END: