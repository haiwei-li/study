%define video_current       LoaderBase+LOADER_BLOCK.CurrentVideo


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
        call __puts        
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
        call __puts
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
        call __print_decimal          	; 打印值    
        mov DWORD [point], 1
        fxch st2
        fstp DWORD [value]
        fstp DWORD [value]
        jmp do_print_float_loop
        
print_float_next:        
        cmp DWORD [point], 1
        je print_float_done
        mov esi, '0'
        call __putc
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
; dump_encodes():
; input:
;       esi - address, edi - bytes
;---------------------------------------------------------
__dump_encodes:
        push ecx
        push ebx
        mov ebx, esi
        mov ecx, edi
dump_encodes_loop:        
        movzx esi, BYTE [ebx]
        call __print_byte_value
        call __printblank
        inc ebx
        dec ecx
        jnz dump_encodes_loop
        pop ebx
        pop ecx
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




;******** lib32 模块的变量定义 ********
;;video_current   dd 0B8000h


        
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


