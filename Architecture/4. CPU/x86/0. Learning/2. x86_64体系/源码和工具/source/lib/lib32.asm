; lib32.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


%include "..\inc\lib.inc"
%include "..\inc\support.inc"
%include "..\inc\protected.inc"

        bits 32
        
        org LIB32_SEG - 2

lib32_length        dw        LIB32_END - $

;*
;* 说明: 
;*      1. 下面是 lib32 库函数的导出表
;*      2. 由嵌入到 protected.asm 模块的导入表 lib32_import_table.imt 所使用
;*      3. 导出表是一个跳转表, 跳转到最终的函数代码
;*      4. 每条跳转都是 5 个字节宽, 由导入表计算出地址

putc:                           jmp     DWORD __putc
println:                        jmp     DWORD __println
puts:                           jmp     DWORD __puts
get_dword_hex_string:           jmp     DWORD __get_dword_hex_string
hex_to_char:                    jmp     DWORD __hex_to_char
lowers_to_uppers:               jmp     DWORD __lowers_to_uppers
dump_flags:                     jmp     DWORD __dump_flags
uppers_to_lowers:               jmp     DWORD __uppers_to_lowers
strlen:                         jmp     DWORD __strlen
test_println:                   jmp     DWORD __test_println
reverse:                        jmp     DWORD __reverse
get_byte_hex_string:            jmp     DWORD __get_byte_hex_string
get_qword_hex_string:           jmp     DWORD __get_qword_hex_string
subtract64:                     jmp     DWORD __subtract64
addition64:                     jmp     DWORD __addition64
print_value:                    jmp     DWORD __print_value
printblank:                     jmp     DWORD __printblank
print_half_byte_value:          jmp     DWORD __print_half_byte_value
; 下面两个是保留位
RESERVED_0                      jmp     DWORD __reserved_func
RESERVED_1                      jmp     DWORD __reserved_func
set_interrupt_handler:          jmp     DWORD __set_interrupt_handler
set_IO_bitmap:                  jmp     DWORD __set_IO_bitmap
get_MAXPHYADDR:                 jmp     DWORD __get_MAXPHYADDR
print_byte_value:               jmp     DWORD __print_byte_value
print_word_value:               jmp     DWORD __print_word_value
print_dword_value:              jmp     DWORD __print_dword_value
print_qword_value:              jmp     DWORD __print_qword_value
set_call_gate:                  jmp     DWORD __set_call_gate
get_tss_base:                   jmp     DWORD __get_tss_base
write_gdt_descriptor:           jmp     DWORD __write_gdt_descriptor
read_gdt_descriptor:            jmp     DWORD __read_gdt_descriptor
get_tr_base:                    jmp     DWORD __get_tr_base
system_service:                 jmp     DWORD __system_service
set_user_interrupt_handler:     jmp     DWORD __set_user_interrupt_handler
sys_service_enter:              jmp     DWORD __sys_service_enter
set_sysenter:                   jmp     DWORD __set_sysenter
conforming_lib32_service:       jmp     DWORD __conforming_lib32_service
clib32_service_enter:           jmp     DWORD __clib32_service_enter
set_ldt_descriptor:             jmp     DWORD __set_ldt_descriptor
move_gdt:                       jmp     DWORD __move_gdt
set_clib32_service:             jmp     DWORD __set_clib32_service_table
print_dword_decimal:            jmp     DWORD __print_decimal
print_dword_float:              jmp     DWORD __print_dword_float
print_qword_float:              jmp     DWORD __print_qword_float
print_tword_float:              jmp     DWORD __print_tword_float
set_system_service_table        jmp     DWORD __set_system_service_table
set_video_current               jmp     DWORD __set_video_current
get_video_current               jmp     DWORD __get_video_current
mul64:                          jmp     DWORD __mul64

;*
;* 下面是 lib32 库函数的实现
;*

__reserved_func:        
        ret


;-----------------------------------------
; strlen(): 得取字符串长度
; input:
;                esi: string
; output:
;                eax: length of string
;------------------------------------------
__strlen:
        mov eax, -1
        test esi, esi
        jz strlen_done
strlen_loop:
        inc eax
        cmp BYTE [esi + eax], 0
        jnz strlen_loop
strlen_done:        
        ret
        
        
;---------------------------------------------------
; memcpy(): 复制字符
; input:
;                esi: 源buffer edi:目标buffer [esp+4]: 字节数
;---------------------------------------------------
__memcpy:
        push es
        push ecx
        mov ax, ds
        mov es, ax
        mov ecx, [esp + 12]                        ; length
        shr ecx, 2
        rep movsd
        mov ecx, [esp + 12]
        and ecx, 3
        rep movsb
        pop ecx
        pop es
        ret

;----------------------------------------------
; reverse():        按bit反转
; input:
;                esi: DWORD value
; ouput:
;                eax: reverse of value
;------------------------------------------
__reverse:
        push ecx
        xor eax, eax
do_reverse:
        bsr ecx, esi
        jz reverse_done
        btr esi, ecx
        neg ecx
        add ecx, 31
        bts eax, ecx
        jmp do_reverse
reverse_done:        
        pop ecx
        ret



;------------------------------------------
; __get_current_row()
;------------------------------------------
__get_current_row:
        push ebx
        mov eax, [video_current]
        sub eax, 0xb8000
        mov bl, 80*2
        div bl
        movzx eax, al
        pop ebx
        ret


;------------------------------------------
; __get_current_column()
;------------------------------------------
__get_current_column:
        push ebx
        mov eax, [video_current]
        sub eax, 0xb8000
        mov bl, 80*2
        div bl
        movzx eax, ah
        pop ebx
        ret


;--------------------------------------------
; test_println():        测试是否需要打印换行符
; input:
;                esi: string
; output:
;                eax: 1(需要), 0(不需要)
;--------------------------------------------
__test_println:
        push ecx
        call __strlen                ; 得到字符串长度
        mov ecx, eax
        shl ecx, 1                        ; len * 2
        call __get_current_column
        neg eax
        add eax, 80*2
        cmp eax, ecx
        setb al
        movzx eax, al
        pop ecx
        ret
        
;-------------------------------------------
; write_char(char c): 往 video 里写入一个字符
; input:
;                esi: 字符
;-------------------------------------------
__write_char:
        push ebx
        mov ebx, video_current
        or si, 0F00h
        cmp si, 0F0Ah                                ; LF
        jnz do_wirte_char
        call __get_current_column
        neg eax
        add eax, 80*2
        add eax, [ebx]
        jmp do_write_char_done
        
do_wirte_char:        
        mov eax, [ebx]
        cmp eax, 0B9FF0h
        ja do_write_char_done
        mov [eax], si
        add eax, 2
do_write_char_done:        
        mov [ebx], eax
        pop ebx
        ret
        

;--------------------------------
; putc(): 打印一个字符
; input: 
;                esi: char
;--------------------------------
__putc:
        and esi, 0x00ff
        call __write_char
        ret

;--------------------------------
; println(): 打印换行
;--------------------------------
__println:
        mov si, 10
        call __putc
        ret
;------------------------------
; printblank(): 打印一个空格
;-----------------------------
__printblank:
        mov si, ' '
        call __putc
        ret        

;--------------------------------
; puts(): 打印字符串信息
; input: 
;                esi: message
;--------------------------------
__puts:
        push ebx
        mov ebx, esi
        test ebx, ebx
        jz do_puts_done

do_puts_loop:        
        mov al, [ebx]
        test al, al
        jz do_puts_done
        mov esi, eax
        call __putc
        inc ebx
        jmp do_puts_loop

do_puts_done:        
        pop ebx
        ret        


;-----------------------------------------
; hex_to_char(): 将 Hex 数字转换为 Char 字符
; input:
;                esi: Hex number
; ouput:
;                eax: Char
;----------------------------------------
__hex_to_char:
        jmp do_hex_to_char
@char        db '0123456789ABCDEF', 0

do_hex_to_char:        
        push esi
        and esi, 0x0f
        movzx eax, BYTE [@char+esi]
        pop esi
        ret

;--------------------------------------
; dump_hex() : 打印 hex 串
; input:
;        esi: value
;--------------------------------------
__dump_hex:
        push ecx
        push esi
        mov ecx, 8                                        ; 8 个 half-byte
do_dump_hex_loop:
        rol esi, 4                                        ; 高4位 --> 低 4位
        mov edi, esi
        call __hex_to_char
        mov esi, eax
        call __putc
        mov esi, edi
        dec ecx
        jnz do_dump_hex_loop
        pop esi
        pop ecx
        ret

;---------------------------------------
; print_value(): 打印值
;---------------------------------------
__print_value:
        call __dump_hex
        call __println
        ret
        
__print_half_byte_value:
        call __hex_to_char
        mov esi, eax
        call __putc
        ret

;------------------------
; print_decimal(): 打印十进制数
; input:
;                esi - 32 位值
;-------------------------
__print_decimal:
        jmp do_print_decimal
quotient        dd 0                        ; 商
remainder        dd 0                        ; 余数
value_table: times 20 db 0
do_print_decimal:        
        push edx
        push ecx
        mov eax, esi                        ; 初始商值
        mov [quotient], eax        
        mov ecx, 10
        lea esi, [value_table+19]        
        
do_print_decimal_loop:
        dec esi                              ; 指向 value_table
        xor edx, edx
        div ecx                              ; 商/10
        test eax, eax                        ; 商 == 0 ?
        cmovz edx, [quotient]
        mov [quotient], eax
        lea edx, [edx + '0']        
        mov [esi], dl                        ; 写入余数值
        jnz do_print_decimal_loop
        
do_print_decimal_done:
        call puts        
        pop ecx
        pop edx
        ret        


;--------------------------------------
; print_dword_float(): 打印单精度值
; input:
;       esi - float 地址值
;-------------------------------------
__print_dword_float:
        fnsave [fpu_image32]
        finit
        fld DWORD [esi]
        call __print_float
        frstor [fpu_image32]        
        ret
            
;--------------------------------------
; print_qword_float(): 打印双精度值
; input:
;       esi - double float 地址值
;-------------------------------------
__print_qword_float:
        fnsave [fpu_image32]
        finit
        fld QWORD [esi]
        call __print_float
        frstor [fpu_image32]        
        ret

;--------------------------------------
; 打印扩展双精度值
;-------------------------------------
__print_tword_float:
        fnsave [fpu_image32]
        finit
        fld TWORD [esi]
        call __print_float
        frstor [fpu_image32]        
        ret
                
;-------------------------------------------
; 打印小数点前的值
;-------------------------------------------     
__print_point:
        jmp do_print_point
digit_array times 200 db 0       
do_print_point:        
        push ebx
        lea ebx, [digit_array + 98]
        mov BYTE [ebx], '.'
print_point_loop:        
;; 当前: 
;; st(3) = 10.0
;; st(2) = 1.0
;; st(1) = 余数值
;; st(0) = point 值
        dec ebx
        fdiv st0, st3           ; value / 10
        fld st2
        fld st1
        fprem                   ; 求余数
        fsub st2, st0
        fmul st0, st5
        fistp DWORD [value]
        mov eax, [value]
        add eax, 0x30
        mov BYTE [ebx], al  
        fstp DWORD [value]      
        fldz
        fcomip st0, st1         ; 余数小于 0
        jnz print_point_loop

print_point_done:        
        fstp DWORD [value]
        mov esi, ebx
        call puts
        pop ebx
        ret    
                
;--------------------
; 打印浮点数
;--------------------        
__print_float:
        jmp do_print_float
value           dd 0     
f_value         dt 10.0
point           dd 0
do_print_float:        
        fld TWORD [f_value]             ; st2
        fld1                            ; st1
        fld st2                         ; st0
        fprem                           ; st0/st1, 取余数
        fld st3
        fsub st0, st1
        call __print_point
        
        mov DWORD [point], 0                
;; 当前: 
;; st(2) = 10.0
;; st(1) = 1.0
;; st(0) = 余数值        
do_print_float_loop:        
        fldz
        fcomip st0, st1                 ; 余数是否为 0
        jz print_float_next
        fmul st0, st2                   ; 余数 * 10
        fld st1                         ; 1.0
        fld st1                         ; 余数 * 10
        fprem                           ; 取余数
        fld st2
        fsub st0, st1
        fistp DWORD [value]
        mov esi, [value]
        call print_dword_decimal          ; 打印值    
        mov DWORD [point], 1
        fxch st2
        fstp DWORD [value]
        fstp DWORD [value]
        jmp do_print_float_loop
        
print_float_next:        
        cmp DWORD [point], 1
        je print_float_done
        mov esi, '0'
        call putc
print_float_done:        
        ret        


;;---------------------------
;; 打印一个 byte
;------------------------------        
__print_byte_value:
        push ebx
        push esi
        mov ebx, esi
        shr esi, 4
        call __hex_to_char
        mov esi, eax
        call __putc
        mov esi, ebx
        call __hex_to_char
        mov esi, eax
        call __putc
        pop esi
        pop ebx
        ret
        
        
__print_word_value:
        push ebx
        push esi
        mov ebx, esi
        shr esi, 8
        call __print_byte_value
        mov esi, ebx
        call __print_byte_value
        pop esi                
        pop ebx
        ret        

__print_dword_value:
        push ebx
        push esi
        mov ebx, esi
        shr esi, 16
        call __print_word_value
        mov esi, ebx
        call __print_word_value
        pop esi
        pop ebx
        ret

;--------------------------
; print_qword_value()
; input:
;                edi:esi - 64 位值
;--------------------------
__print_qword_value:
        push ebx
        push esi
        mov ebx, esi
        mov esi, edi
        call __print_dword_value
        mov esi, ebx
        call __print_dword_value
        pop esi
        pop ebx
        ret        
        
;-------------------------------------------
; letter():  测试是否为字母
; input:
;                esi: char
; output:
;                eax: 1(是字母), 0(不是字母)
;-------------------------------------------
__letter:
        and esi, 0xff
        cmp esi, DWORD 'z'
        setbe al
        ja test_letter_done
        cmp esi, DWORD 'A'
        setae al
        jb test_letter_done
        cmp esi, DWORD 'Z'
        setbe al
        jbe test_letter_done
        cmp esi, DWORD 'a'
        setae al
test_letter_done:
        movzx eax, al
        ret

;---------------------------------------
; lowercase(): 测试是否为小写字母
; input:
;                esi: char
; output:
;                1: 是,  0不是
;----------------------------------------
__lowercase:
        and esi, 0xff
        cmp esi, DWORD 'z'
        setbe al        
        ja test_lowercase_done
        cmp esi, DWORD 'a'
        setae al
test_lowercase_done:
        movzx eax, al        
        ret
        
;---------------------------------------
; uppercase(): 测试是否为大写字母
; input:
;                esi: char
; output:
;                1: 是,  0不是
;----------------------------------------
__uppercase:
        and esi, 0xff
        cmp esi, DWORD 'Z'
        setbe al        
        ja test_uppercase_done
        cmp esi, DWORD 'A'
        setae al
test_uppercase_done:
        movzx eax, al        
        ret

;-----------------------------------------
; digit(): 测试是否为数字
; input:
;                esi: char
; output: 
;                eax: 1-yes, 0-no
;-----------------------------------------
__digit:
        and esi, 0xff
        xor eax, eax
        cmp esi, DWORD '0'
        setae al
        jb test_digit_done        
        cmp esi, DWORD '9'
        setbe al
test_digit_done:
        movzx eax, al
        ret        
        
        
;----------------------------------------------------------------------
; lower_upper():        大小写字母的转换
; input:
;                esi:需要转换的字母,  edi: 1 (小字转换为大写), 0 (大写转换为小写)
; output:
;                eax: result letter
;---------------------------------------------------------------------
__lower_upper:
        push ecx
        mov ecx, DWORD ('a' - 'A')
        call __letter
        test eax, eax
        jz do_lower_upper_done                   ; 如果不是字母
        bt edi, 0
        jnc set_lower_upper                      ; 1?
        neg ecx                                 ; 小写转大写: 减
set_lower_upper:                
        add esi, ecx
do_lower_upper_done:                
        mov eax, esi
        pop ecx
        ret

;---------------------------------------------------
; upper_to_lower(): 大写字母转小写字母
; input:
;                esi: 需要转换的字母
; output:
;                eax: 小写字母
;---------------------------------------------------
__upper_to_lower:
        call __uppercase                        ; 是否为大写字母
        test eax, eax
        jz do_upper_to_lower_done        ; 如果不是就不改变
        mov eax, DWORD ('a' - 'A')
do_upper_to_lower_done:        
        add eax, esi
        ret
        
;---------------------------------------------------
; lower_to_upper(): 小写字母转大写字母
; input:
;                esi: 需要转换的字母
; output:
;                eax: 大写字母
;---------------------------------------------------
__lower_to_upper:
        call __lowercase                        ; 是否为小写字母
        test eax, eax
        jz do_lower_to_upper_done        ; 如果不是就不改变
        mov eax, DWORD ('a' - 'A')
        neg eax
do_lower_to_upper_done:        
        add eax, esi                                
        ret
                
;---------------------------------------------------
; lowers_to_uppers(): 小写串转换为大写串
; input:
;                esi: 源串,  edi:目标串        
;---------------------------------------------------
__lowers_to_uppers:
        push ecx
        push edx
        
        mov ecx, esi
        mov edx, edi
        test ecx, ecx
        jz do_lowers_to_uppers_done
        test edx, edx
        jz do_lowers_to_uppers_done
        
do_lowers_to_uppers_loop:
        movzx esi, BYTE [ecx]
        test esi, esi
        jz do_lowers_to_uppers_done
        call __lower_to_upper
        mov BYTE [edx], al
        inc edx
        inc ecx
        jmp do_lowers_to_uppers_loop
        
do_lowers_to_uppers_done:        
        pop edx
        pop ecx
        ret

;---------------------------------------------------
; uppers_to_lowers(): 大写串转换为小写串
; input:
;                esi: 源串,  edi:目标串        
;---------------------------------------------------
__uppers_to_lowers:
        push ecx
        push edx
        
        mov ecx, esi
        mov edx, edi
        test ecx, ecx
        jz do_uppers_to_lowers_done
        test edx, edx
        jz do_uppers_to_lowers_done
        
do_uppers_to_lowers_loop:
        movzx esi, BYTE [ecx]
        test esi, esi
        jz do_uppers_to_lowers_done
        call __upper_to_lower
        mov BYTE [edx], al
        inc edx
        inc ecx
        jmp do_uppers_to_lowers_loop
        
do_uppers_to_lowers_done:        
        pop edx
        pop ecx
        ret

;--------------------------------------------------------------
; get_qword_hex_string(): 将 QWORD 转换为字符串
; input:
;                esi: 指令 QWORD 值的指针, edi: buffer(最少需要17bytes)
;--------------------------------------------------------------
__get_qword_hex_string:
        push ecx
        push esi
        mov ecx, esi
        mov esi, [ecx + 4]                        ; dump 高 32 位
        call __get_dword_hex_string
        mov esi, [ecx]
        call __get_dword_hex_string
        pop esi
        pop ecx
        ret

;-------------------------------------------------
; get_dword_hex_string(): 将数 (DWORD) 转换为字符串
; input:
;                esi: 需转换的数(dword size)
;                edi: 目标串 buffer(最短需要 9 bytes, 包括 0)
;---------------------------------------------------
__get_dword_hex_string:
        push ecx
        push esi
        mov ecx, 8                                        ; 8 个 half-byte
do_get_dword_hex_string_loop:
        rol esi, 4                                        ; 高4位 --> 低 4位
        call __hex_to_char
        mov byte [edi], al
        inc edi
        dec ecx
        jnz do_get_dword_hex_string_loop
        mov byte [edi], 0
        pop esi
        pop ecx
        ret        

;----------------------------------------------------
; get_byte_hex_string(): 将 BYTE 转换为字符串
; input:
;                esi: BYTE 值, edi: buffer(最短需要3个)
;----------------------------------------------------
__get_byte_hex_string:
        push ecx
        push esi
        mov ecx, esi
        shr esi, 4
        call __hex_to_char
        mov BYTE [edi], al
        inc edi
        mov esi, ecx
        call __hex_to_char
        mov BYTE [edi], al
        inc edi
        mov BYTE [edi], 0
        pop esi
        pop ecx
        ret

;---------------------------------------------------------
; dump_flags():                打印 32 位的寄存器标记值
; description:
;                这个函数用来根据输入一 mask 值和对应的 flags字符串
;                如果 bit被mask, 打印大写串, 否则打印小写串
; example:
;                CPUID.EAX=01H 返回的 EDX 寄存器含有处理器支持的扩展功能
;                如果 EDX 的位中, 支持就打印大写, 不支持就打印小写
;                mov esi, edx                        ;; CPUID.EAX=01H 返回的 edx寄存器
;                mov edi, edx_flags
;                call dump_flags
; input:
;                esi: 寄存器值, edi: flags串
;---------------------------------------------------------
__dump_flags:
        push ebx
        push edx
        push ecx
        mov ecx, esi
        mov ebx, edi
do_dump_flags_loop:        
        mov edx, [ebx]
        cmp edx, -1                                 ; 结束标志 0xFFFFFFFF
        je do_dump_flags_done
        shr ecx, 1
        setc al
        test edx, edx
        jz dump_flags_next
        mov esi, edx                                        ; 源串
        mov edi, edx                                        ; 目标串
        test al, al
        jz do_dump_flags_disable                ; 被清位就大写转小写
        call __lowers_to_uppers                        ; 被置位就小写转大写
        jmp print_flags_msg        
do_dump_flags_disable:                                
        call __uppers_to_lowers
print_flags_msg:
        mov esi, edx
        call __test_println                                ; 测试是否需要换行
        test eax, eax
        jz skip_ln
        call println
skip_ln:        
        mov esi, edx                                        ; 打印 flags 信息
        call __puts
        mov esi, DWORD ' '
        call __putc
dump_flags_next:        
        add ebx, 4
        jmp do_dump_flags_loop                
                
do_dump_flags_done:        
        pop ecx
        pop edx
        pop ebx
        ret

;__dump_flags:
;        push ebp
;        push ecx
;        push edx
;        push ebx
;        mov ecx, 0
;        mov ebx, edi                                ; flags 字符串
;        mov edx, esi
;do_dump_flags_loop:
;        mov ebp, [ebx + ecx * 4]
;        cmp ebp, -1                                        ; 测试结束符 0xFFFFFFFF
;        je do_dump_flags_done
;        test ebp, ebp
;        jnz dump_flags_next
;        inc ecx
;        jmp do_dump_flags_loop
;dump_flags_next:        
;        mov esi, ebp        
;        mov edi, ebp
;        bt edx, ecx
;        jnc do_dump_flags_disable                ; 被清位就大写转小写
;        call __lowers_to_uppers                        ; 被置位就小写转大写
;        jmp print_flags_msg        
;do_dump_flags_disable:                                
;        call __uppers_to_lowers
;print_flags_msg:
;        mov esi, ebp
;        call __test_println                                ; 测试是否需要换行
;        test eax, eax
;        jz skip_ln
;        call println
;skip_ln:        
;        mov esi, ebp                                        ; 打印 flags 信息
;        call __puts
;        mov esi, DWORD ' '
;        call __putc
;        inc ecx
;        jmp do_dump_flags_loop        

;do_dump_flags_done:        
;        pop ebx
;        pop edx
;        pop ecx
;        pop ebp
;        ret


;----------------------------------------------
; get_MAXPHYADDR(): 得到 MAXPHYADDR 值
; output:
;                eax: MAXPHYADDR
;----------------------------------------------
__get_maxphyaddr:
__get_MAXPHYADDR:
        push ecx
        mov ecx, 32
        mov eax, 80000000H
        cpuid
        cmp eax, 80000008H
        jb test_pse36                                                ; 不支持 80000008H leaf
        mov eax, 80000008H
        cpuid
        movzx ecx, al                                                ; MAXPHYADDR 值
        jmp do_get_MAXPHYADDR_done
test_pse36:        
        mov eax, 01H
        cpuid
        bt edx, 17                                                        ; PSE-36 support ?
        jnc do_get_MAXPHYADDR_done
        mov ecx, 36

do_get_MAXPHYADDR_done:        
        mov eax, ecx
        pop ecx
        ret
        
        
;--------------------------------------------
; subtract64(): 64位的减法
; input:
;                esi: 被减数地址,  edi: 减数地址
; ouput:
;                edx:eax 结果值
;--------------------------------------------
__subtract64:
        mov eax, [esi]
        sub eax, [edi]
        mov edx, [esi + 4]
        sbb edx, [edi + 4]
        ret
        
;----------------------------------------
; addition64(): 64位加法
; input:
;                esi: 被加数地址,  edi: 加数地址
; ouput:
;                edx:eax 结果值
;---------------------------------------
__addition64:
        mov eax, [esi]
        add eax, [edi]
        mov edx, [esi + 4]
        adc edx, [edi + 4]
        ret
        
;------------------------------------------------------        
; mul64(): 64位乘法
; input:
;       esi: 被乘数地址, edi: 乘数地址, ebp: 结果值地址
; 描述: 
; c3:c2:c1:c0 = a1:a0 * b1:b0
;(1) a0*b0 = d1:d0
;(2) a1*b0 = e1:e0
;(3) a0*b1 = f1:f0
;(4) a1*b1 = h1:h0
;
;               a1:a0
; *             b1:b0
;----------------------
;               d1:d0
;            e1:e0
;            f1:f0
; +       h1:h0
;-----------------------
; c0 = b0
; c1 = d1 + e0 + f0
; c2 = e1 + f1 + h0 + carry
; c3 = h1 + carry
;------------------------------------------------------------
__mul64:
        jmp do_mul64
c2_carry        dd 0        
c3_carry        dd 0
temp_value      dd 0
do_mul64:        
        push ecx
        push ebx
        push edx
        mov eax, [esi]                  ; a0
        mov ebx, [esi + 4]              ; a1        
        mov ecx, [edi]                  ; b0
        mul ecx                         ; a0 * b0 = d1:d0, eax = d0, edx = d1
        mov [ebp], eax                  ; 保存 c0
        mov ecx, edx                    ; 保存 d1
        mov eax, [edi]                  ; b0
        mul ebx                         ; a1 * b0 = e1:e0, eax = e0, edx = e1
        add ecx, eax                    ; ecx = d1 + e0
        mov [temp_value], edx           ; 保存 e1
        adc DWORD [c2_carry], 0         ; 保存 c2 进位
        mov ebx, [esi]                  ; a0
        mov eax, [edi + 4]              ; b1
        mul ebx                         ; a0 * b1 = f1:f0
        add ecx, eax                    ; d1 + e0 + f0
        mov [ebp + 4], ecx              ; 保存 c1
        adc DWORD [c2_carry], 0         ; 增加 c2 进位
        add [temp_value], edx           ; e1 + f1
        adc DWORD [c3_carry], 0         ; 保存 c3 进位
        mov eax, [esi + 4]              ; a1
        mul ebx                         ; a1 * b1 = h1:h0
        add [temp_value], eax           ; e1 + f1 + h0
        adc DWORD [c3_carry], 0         ; 增加 c3 进位
        mov eax, [c2_carry]             ; 读取 c2 进位值
        add eax, [temp_value]           ; e1 + f1 + h0 + carry
        mov [ebp + 8], eax              ; 保存 c2
        add edx, [c3_carry]             ; h1 + carry
        mov [ebp + 12], edx             ; 保存 c3
        pop edx
        pop ebx
        pop ecx
        ret
        
        
;;########### 下面是系统相关的 lib 代码 ###########
        
;------------------------------------------------------
; set_interrupt_handler(int vector, void(*)()handler)
; input:
;       esi: vector,  edi: handler
;------------------------------------------------------
__set_interrupt_handler:
        sidt [__idt_pointer]        
        mov eax, [__idt_pointer + 2]
        mov [eax + esi * 8 + 4], edi                            ; set offset [31:16]
        mov [eax + esi * 8], di                                 ; set offset[15:0]
        mov DWORD [eax + esi * 8 + 2], kernel_code32_sel        ; set selector
        mov WORD [eax + esi * 8 + 5], 80h | INTERRUPT_GATE32    ; Type=interrupt gate, P=1, DPL=0
        ret

;------------------------------------------------------
; set_user_interrupt_handler(int vector, void(*)()handler)
; input:
;       esi: vector,  edi: handler
;------------------------------------------------------
__set_user_interrupt_handler:
        sidt [__idt_pointer]        
        mov eax, [__idt_pointer + 2]
        mov [eax + esi * 8 + 4], edi                           ; set offset [31:16]
        mov [eax + esi * 8], di                                ; set offset [15:0]
        mov DWORD [eax + esi * 8 + 2], kernel_code32_sel       ; set selector
        mov WORD [eax + esi * 8 + 5], 0E0h | INTERRUPT_GATE32  ; Type=interrupt gate, P=1, DPL=3
        ret
        

;------------------------------------------------------
; move_gdt(): 将 GDT 表定在某个位置上
; input:
;       esi: address
;--------------------------------------------------------
__move_gdt:
        push ecx
        push esi                                ; GDT' base
        mov edi, esi
        sgdt [__gdt_pointer]
        mov esi, [__gdt_pointer + 2]
        movzx ecx, WORD [__gdt_pointer]
        push cx                                 ; GDT's limit
        rep movsb
        lgdt [esp]                                ;
        add esp, 6
        pop ecx
        ret

;---------------------------------------------------------
; read_gdt_descriptor()
; input:        
;       esi: vector
; ouput:
;       edx:eax - descriptor
;---------------------------------------------------------
__read_gdt_descriptor:
        sgdt [__gdt_pointer]
        mov eax, [__gdt_pointer + 2]
        and esi, 0FFF8h        
        mov edx, [eax + esi + 4]        
        mov eax, [eax + esi]
        ret

;---------------------------------------------------------
; write_gdt_descriptor()
; input:        
;       esi: vector     edx:eax - descriptor
;---------------------------------------------------------
__write_gdt_descriptor:
        sgdt [__gdt_pointer]
        mov edi, [__gdt_pointer + 2]
        and esi, 0FFF8h        
        mov [edi + esi], eax
        mov [edi + esi + 4], edx
        ret
                
        
;-------------------------------------------------------
; get_tss_base(): 获得 TSS 区域基地址
; input:
;                esi: TSS selector
; output:
;                eax: base of TSS
;------------------------------------------------------
__get_tss_base:
        push edx
        call __read_gdt_descriptor
        shrd eax, edx, 16                                ; base[23:0]
        and eax, 0x00FFFFFF
        and edx, 0xFF000000                              ; base[31:24]
        or eax, edx                                
        pop edx
        ret

;-----------------------------------------------------
; get_tr_base(): 返回 TR.base
;-----------------------------------------------------        
__get_tr_base:
        str esi
        call __get_tss_base
        ret


;------------------------------------------------------------------------
; set_call_gate(int selector, long address, int count)
; input:
;                esi: selector,  edi: address, eax: count
; 注意: 
;                这里将 call gate 的权限设为 3 级, 从用户代码可以调用
;--------------------------------------------------------------------------
__set_call_gate:
        push ebx
        sgdt [__gdt_pointer]
        mov ebx, [__gdt_pointer + 2]
        and esi, 0FFF8h
        mov [ebx + esi + 4], edi                        ; offset [31:16]
        mov [ebx + esi], di                             ; offset[15:0]
        mov WORD [ebx + esi + 2], KERNEL_CS             ; selector
        and eax, 01Fh                                   ; count
        mov [ebx + esi + 4], al
        mov BYTE [ebx + esi + 5], 0E0h | CALL_GATE32    ; type=call_gate32, DPL=3
        pop ebx
        ret
        

;----------------------------------------------------
; set_ldt_descriptor()
; input:
;       esi: selector, edi: address,  eax: limit
;----------------------------------------------------
__set_ldt_descriptor:
        push ebx
        sgdt [__gdt_pointer]
        mov ebx, [__gdt_pointer + 2]
        and esi, 0FFF8h
        mov [ebx + esi + 4], edi                ; 写 base [31:24]
        mov [ebx + esi], cx                     ; 写 limit [15:0]
        mov [ebx + esi + 2], edi                ; 写 base [23:0]
        mov BYTE [ebx + esi + 5], 82h           ; type=LDT, P=1, DPL=0
        shr eax, 16
        and eax, 0Fh
        mov [ebx + esi + 6], al                 ; 写 limit [19:16]
        pop ebx
        ret


;--------------------------------------------------------
; set_IO_bitmap(int port, int value): 设置 IOBITMAP 中的值
; input:
;       esi - port(端口值), edi - value 设置的值
;---------------------------------------------------------
__set_IO_bitmap:
        push ebx
        push ecx
        str eax                                  ; 得到 TSS selector
        and eax, 0FFF8h
        sgdt [__gdt_pointer]                     ; 得到 GDT base
        add eax, [__gdt_pointer + 2]             ;
        mov ebx, [eax + 4]        
        and ebx, 0FFh
        shl ebx, 16
        mov ecx, [eax + 4]
        and ecx, 0FF000000h
        or ebx, ecx
        mov eax, [eax]                            ; 得到 TSS descriptor
        shr eax, 16
        or eax, ebx
        movzx ebx, WORD [eax + 102]
        add eax, ebx                              ; 得到 IOBITMAP
        mov ebx, esi
        shr ebx, 3
        and esi, 7
        bt edi, 0
        jc set_bitmap
        btr DWORD [eax + ebx], esi               ; 清位
        jmp do_set_IO_bitmap_done
set_bitmap:
        bts DWORD [eax + ebx], esi               ; 置位
do_set_IO_bitmap_done:        
        pop ecx
        pop ebx
        ret

;-----------------------------------------------------
; set_sysenter(): 设置系统的 sysenter/sysexit 使用环境
;-----------------------------------------------------
__set_sysenter:
        xor edx, edx
        mov eax, KERNEL_CS
        mov ecx, IA32_SYSENTER_CS
        wrmsr                                                        ; 设置 IA32_SYSENTER_CS
        mov eax, PROCESSOR_KERNEL_ESP
        mov ecx, IA32_SYSENTER_ESP                
        wrmsr                                                        ; 设置 IA32_SYSENTER_ESP
        mov eax, __sys_service
        mov ecx, IA32_SYSENTER_EIP
        wrmsr                                                        ; 设置 IA32_SYSENTER_EIP
        ret

;---------------------------------------------------
; sys_service_enter(): 快速切入 service 的 stub 函数
;---------------------------------------------------
__sys_service_enter:
        push ecx
        push edx
        mov ecx, esp                                            ; 返回代码的 ESP 值 
        mov edx, return_address                                 ; 返回代码的 EIP 值
        sysenter                                                ; 进入 0 级 service
return_address:
        pop edx
        pop ecx
        ret

;--------------------------------------------------------
; sys_service(): 使用 sysenter/sysexit 版本的系统服务例程
; input:
;                eax: 系统服务例程号
;--------------------------------------------------------
__sys_service:
        push ecx                                                ; 保存返回 esp 值
        push edx                                                ; 保存返回 eip 值
        mov eax, [system_service_table + eax * 4]
        call eax                                                ; 调用系统服务例程        
        pop edx
        pop ecx
        sysexit
        
        
;-------------------------------------------------------
; system_service(): 系统服务例程,使用中断0x40号调用进入　
; input:
;                eax: 系统服务例程号
;--------------------------------------------------------
__system_service:
        mov eax, [system_service_table + eax * 4]
        call eax                                ; 调用系统服务例程
        iret

;-------------------------------------------------------
; set_system_service_table(): 设置中断调用函数
; input:
;       esi: 功能号, 　edi: 服务例程
;-------------------------------------------------------
__set_system_service_table:
        mov [system_service_table + esi * 4], edi
        ret

;-----------------------------
; set_video_current():
; input:
;       esi: video current
;------------------------------
__set_video_current:
        mov DWORD [video_current], esi
        ret

;------------------------------
; get_video_current();
;------------------------------
__get_video_current:
        mov eax, [video_current]        
        ret



; 加入 conforming_lib32.asm 库
%include "..\lib\conforming_lib32.asm"


;******** lib32 模块的变量定义 ********
video_current   dd 0B8000h


;******** 系统服务例程函数表 ***************
system_service_table:
        dd __puts                                       ; 0 号
        dd __read_gdt_descriptor                        ; 1 号
        dd __write_gdt_descriptor                       ; 2 号
        dd 0                                            ; 3 号
        dd 0                                            ; 4 号
        dd 0                                            ; 5 号
        dd 0                                            ; 6 号
        dd 0
        dd 0
        dd 0

        
;; 共 28 个字节
fpu_image32:
x87env32:
control_word    dd 0
status_word     dd 0
tag_word        dd 0
ip_offset       dd 0
ip_selector     dw 0
opcode          dw 0
op_offset       dd 0
op_selector     dd 0

;; FSAVE/FNSAVE, FRSTOR 指令的附加映像
;; 定义 8 个 80 位的内存地址保存 data 寄存器值
r0_value        dt 0.0
r1_value        dt 0.0
r2_value        dt 0.0
r3_value        dt 0.0
r4_value        dt 0.0
r5_value        dt 0.0
r6_value        dt 0.0
r7_value        dt 0.0

;; 定义 32 位的 GPRs 上下文存储区
lib32_context  times 10 dd 0


; GDT 表指针
__gdt_pointer:
                dw 0                        ; GDT limit 值
                dd 0                        ; GDT base 值

; IDT 表指针
__idt_pointer:
                dw 0                        ; IDT limit 值
                dd 0                        ; IDT base 值
                        
                                                
LIB32_END:        

; 
; 这是 protected mode 下使用的库