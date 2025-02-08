;*************************************************
;* crt.asm                                       *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************



;-----------------------------------------
; clear_4k_page32(): 清4K页面
; input:  
;       esi: address
; output;
;       none
; 描述: 
;       1) 一次清 4K 页面
;       2) 地址在 4K 边界上
;       3) 需开启 SSE 指令支持    
;------------------------------------------        
clear_4k_page32:
        push esi
        
        test esi, esi
        mov eax, 4096
        jz clear_4k_page32.done
        
        and esi, 0FFFFF000h
        pxor xmm0, xmm0       
clear_4k_page32.loop:        
        movdqa [esi + eax - 16], xmm0
        movdqa [esi + eax - 32], xmm0
        movdqa [esi + eax - 48], xmm0
        movdqa [esi + eax - 64], xmm0
        movdqa [esi + eax - 80], xmm0
        movdqa [esi + eax - 96], xmm0
        movdqa [esi + eax - 112], xmm0
        movdqa [esi + eax - 128], xmm0
        sub eax, 128
        jnz clear_4k_page32.loop
        
clear_4k_page32.done:
        pop esi
        ret



;-----------------------------------------
; clear_4k_buffer32(): 清 4K 内存
; input:  
;       esi: address
; output;
;       none
; 描述: 
;       1) 一次清 4K 页面
;       2) 地址在 4K 边界上
;       3) 使用 GPI 指令处理
;-----------------------------------------
clear_4k_buffer32:
        push esi
        push edi
        mov edi, esi
        mov esi, 1000h
        call zero_memory32
        pop edi
        pop esi
        ret



;-----------------------------------------
; clear_4k_page_n32(): 清 n个 4K页面
; input:  
;       esi - address
;       edi - count
; output;
;       none
;------------------------------------------   
clear_4k_page_n32:
        call clear_4k_page32
        add esi, 4096
        dec edi
        jnz clear_4k_page_n32
        ret        


;-----------------------------------------
; clear_4k_buffer_n32(): 清 n个 4K 内存块
; input:  
;       esi - address
;       edi - count
; output;
;       none
;------------------------------------------ 
clear_4k_buffer_n32:
        call clear_4k_buffer32
        add esi, 4096
        dec edi
        jnz clear_4k_buffer_n32
        ret        
        
        
;-----------------------------------------
; zero_memory32()
; input:
;       esi - size
;       edi - buffer address
; 描述: 
;       将内存块清 0
;-----------------------------------------
zero_memory32:
        push ecx
        
        test edi, edi
        jz zero_memory32.done
        
        xor eax, eax
        
        ;;
        ;; 检查 count > 4 ?
        ;;
        cmp esi, 4
        jb zero_memory32.@1
        
        ;;
        ;; 先写入首 4 字节
        ;;
        mov [edi], eax
        
        ;;
        ;; 计算调整到 DWORD 边界上的差额, 原理等于 4 - dest & 03
        ;; 1) 例如: [2:0] = 011B(3)
        ;; 2) 取反后 = 100B(4)
        ;; 3) 加1后 = 101B(5)        
        ;; 4) 在32位下与03后 = 001B(1), 即差额为 1
        ;;
        mov ecx, esi                                    ; 原 count
        mov esi, edi                                    ; 原 dest
        not esi
        inc esi
        and esi, 03                                     ; 在 32 位下与 03h
        sub ecx, esi                                    ; count = 原 count - 差额

        ;;
        ;; dest 向上调整到 DWORD 边界
        ;;
        add edi, esi                                    ; dest = dest + 差额
        mov esi, ecx
           
        ;;
        ;; 在 32 位下, 以 DWORD 为单位
        ;; 
        shr ecx, 2
        rep stosd

zero_memory32.@1:                     
        ;;
        ;; 一次 1 字节, 写入剩余字节数
        ;;
        mov ecx, esi
        and ecx, 03h
        rep stosb
        
zero_memory32.done:        
        pop ecx
        ret   
        


;-------------------------------------------------
; strlen32(): 得取字符串长度
; input:
;       esi - string
; output:
;       eax - length of string
;-------------------------------------------------
strlen32:
        push ecx
        xor eax, eax
        ;;
        ;; 输入的 string = NULL 时, 返回 0 值
        ;;
        test esi, esi
        jz strlen32.done
        
        ;;
        ;; 测试是否支持 SSE4.2 指令, 以及是否开启 SSE 指令执行
        ;; 选择使用 SSE4.2 版本的 strlen 指令
        ;;
        cmp DWORD [gs: PCB.SSELevel], SSE4_2
        jb strlen32.legacy
        test DWORD [gs: PCB.InstructionStatus], INST_STATUS_SSE
        jnz sse4_strlen + 1                             ; 转入执行 sse4_strlen() 


strlen32.legacy:

        ;;
        ;; 使用 legacy 方式
        ;;
        xor ecx, ecx
        mov edi, esi
        dec ecx                                         ; ecx = 0FFFFFFFFh
        repne scasb                                     ; 循环查找 0 值
        sub eax, ecx                                    ; 0 - ecx
        dec eax
strlen32.done:
        pop ecx
        ret        
        
        


;-------------------------------------------------
; memcpy32(): 复制内存块
; input:
;       esi - source
;       edi - dest 
;       ecx - count
; output:
;       none
;-------------------------------------------------
memcpy32:
        push ecx
        mov eax, ecx
        shr ecx, 2
        rep movsd
        mov ecx, eax
        and ecx, 3
        rep movsb
        pop ecx
        ret        
        
;-------------------------------------------------
; strcopy()
; input:
;       esi - sourece
;       edi - dest
; output:
;       none
;-------------------------------------------------
strcpy:
        REX.Wrxb
        test esi, esi
        jz strcpy.done
        REX.Wrxb
        test edi, edi
        jz strcpy.done        
strcpy.loop:        
        mov al, [esi]
        test al, al
        jz strcpy.done
        mov [edi], al
        REX.Wrxb
        INCv esi
        REX.Wrxb
        INCv edi
        jmp strcpy.loop
strcpy.done:        
        ret




;-------------------------------------------------
; bit_swap32(): 交换 dword 内的位
; input:
;       esi - source
; output:
;       eax - dest
; 描述:
;       dest[31] <= source[0]
;       ... ...
;       dest[0]  <= source[31]
;-------------------------------------------------        
bit_swap32:
        push ecx
        mov ecx, 32
        xor eax, eax
        
        ;;
        ;; 循环移动 1 位值
        ;;
bit_swap32.loop:        
        shl esi, 1                              ; esi 高位移出到 CF
        rcr eax, 1                              ; CF 移入 eax 高位
        ;;
        ;; 注意: 
        ;;      1) 使用 FF /1 的 dec 指令, 避免在 64-bit 模式下变为 REX prefix
        ;;
        DECv ecx
        jnz bit_swap32.loop
        pop ecx
        ret


;-------------------------------------------------
; clear_screen()
; input:
;       esi - row
;       edi - column
; output:
;       none
; 描述: 
;       1) 从 (row, column) 位置开始清空屏幕
;-------------------------------------------------
clear_screen:
        push ebp
        push ecx
        push edx

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif   

        mov eax, 80 * 2
        mul esi
        lea ecx, [eax + edi * 2]                        ; ecx = (row * 80 + column) * 2
        mov esi, 80 * 2 * 25                            ; 整个屏幕 size
        sub esi, ecx                                    ; 剩余 size        
        REX.Wrxb
        mov edi, [ebp + PCB.LsbBase]
        REX.Wrxb
        mov edi, [edi + LSB.LocalVideoBufferHead]       
        REX.Wrxb
        add edi, ecx
        call zero_memory
        
        ;;
        ;; 如果拥有焦点, 则清 target video buffer
        ;;
        mov eax, [ebp + PCB.ProcessorIndex]             ; eax = index
        REX.Wrxb
        mov ebp, [ebp + PCB.SdaBase]                    ; ebp = SDA
        cmp [ebp + SDA.InFocus], eax
        jne clear_screen.done
        mov esi, 80 * 2 * 25
        sub esi, ecx
        REX.Wrxb
        mov edi, [ebp + SDA.VideoBufferHead]
        REX.Wrxb
        add edi, ecx
        call zero_memory
        
clear_screen.done:        
        pop edx
        pop ecx
        pop ebp
        ret



;-------------------------------------------------
; video_buffer_row():
; input:
;       none
; output:
;       eax - row
; 描述:
;       1) 得到 video buffer 当前位置的行号
;       2) 不修改 esi 值, 以便后续使用
;-------------------------------------------------
video_buffer_row:
        push ebx
        push edx
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif   
        
        REX.Wrxb
        mov ebx, [ebp + PCB.LsbBase]                    ; ebx = LSB
        REX.Wrxb
        mov eax, [ebx + LSB.LocalVideoBufferPtr]        ; eax = LocalVideoBufferPtr
        REX.Wrxb
        sub eax, [ebx + LSB.LocalVideoBufferHead]       ; VideoBufferPtr - VideoBufferHead
        mov ebx, 80 * 2
        xor edx, edx
        div ebx                                          ; (VideoBufferPtr - VideoBufferHead) / (80 * 2)
        pop ebp
        pop edx
        pop ebx
        ret
        


        
        
;-------------------------------------------------
; video_buffer_column():
; input:
;       none
; output:
;       eax - column
; 描述:
;       1) 得到 video buffer 当前位置的列号
;       2) 不修改 esi 值, 以便后续使用
;-------------------------------------------------      
video_buffer_column:
        push ebx
        push edx
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif   

        REX.Wrxb
        mov ebx, [ebp + PCB.LsbBase]                    ; ebx = LSB        
        REX.Wrxb
        mov eax, [ebx + LSB.LocalVideoBufferPtr]        ; eax = LocalVideoBufferPtr
        REX.Wrxb
        sub eax, [ebx + LSB.LocalVideoBufferHead]       ; VideoBufferPtr - VideoBufferHead
        mov ebx, 80 * 2
        xor edx, edx
        div ebx                                         ; (VideoBufferPtr - VideoBufferHead) / (80 * 2)        
        mov eax, edx                                    ; edx = column
        pop ebp 
        pop edx
        pop ebx        
        ret  






;-------------------------------------------------
; set_video_buffer()
; input:
;       esi - row
;       edi - column
; output:
;       none
; 描述: 
;       1) 设置 video buffer 位置
;-------------------------------------------------
set_video_buffer:
        push ebp
        push ebx
        push ecx
        push edx

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif 
        
        ;;
        ;; 检查是否超出范围
        ;;
        cmp esi, 25
        jae set_video_buffer.done
        cmp edi, 80
        jae set_video_buffer.done
        
        ;;
        ;; eax = (row * 80 + column) * 2
        ;;
        mov eax, 80 * 2
        mul esi
        REX.Wrxb
        lea eax, [eax + edi * 2]
        
        ;;
        ;; TargetBufferPtr = (row * 80 + column) * 2 + B8000h
        ;;
        REX.Wrxb
        lea ecx, [eax + 0B8000h]
        
        ;;
        ;; VideoBufferPtr = (row * 80 + column) * 2 + VideoBufferHead
        ;;
        REX.Wrxb
        mov ebx, [ebp + PCB.LsbBase]                    ; ebx = LSB
        REX.Wrxb
        add eax, [ebx + LSB.LocalVideoBufferHead]
        
        ;;
        ;; 更新 VideoBufferPtr
        ;;
        REX.Wrxb
        mov [ebx + LSB.LocalVideoBufferPtr], eax
        
        ;;
        ;; 如果当前处理器拥有焦点, 则更新 target video buffer
        ;;
        REX.Wrxb
        mov ebx, [ebp + PCB.SdaBase]                    ; ebx = SDA
        mov esi, [ebp + PCB.ProcessorIndex]
        cmp [ebx + SDA.InFocus], esi
        jne set_video_buffer.done

        ;;
        ;; 更新 target video buffer ptr
        ;;
        REX.Wrxb
        mov [ebx + SDA.VideoBufferPtr], ecx
        
set_video_buffer.done:        
        pop edx
        pop ecx
        pop ebx
        pop ebp
        ret        
        


                
        
;-------------------------------------------------
; check_new_line()
; input:
;       esi - string
; output:
;       0 - no, otherwise yes.
; 描述:
;       根据提供的字符串, 检查是否需要转换
;-------------------------------------------------          
check_new_line:
        push ebp
        push ecx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        
        call strlen
        mov ecx, eax                            ; 字符串长度
        shl ecx, 1                              ; length * 2
        call video_buffer_column
        neg eax
        add eax, 80 * 2
        cmp eax, ecx
        jae check_new_line.done
        ;;
        ;; 换行
        ;;
        REX.Wrxb
        mov ecx, [ebp + PCB.LsbBase]
        REX.Wrxb
        add [ecx + LSB.LocalVideoBufferPtr], eax
        
        ;;
        ;; 如果当前拥有焦点, 则更新 target video buffer
        ;;
        mov ecx, [ebp + PCB.ProcessorIndex]
        REX.Wrxb
        mov ebp, [ebp + PCB.SdaBase]
        cmp [ebp + SDA.InFocus], ecx
        jne check_new_line.done
        
        add [ebp + SDA.VideoBufferPtr], eax
  
check_new_line.done:        
        pop ecx
        pop ebp
        ret        



        


;-------------------------------------------------
; write_char()
; input:
;       esi - 字符
; output:
;       none
; 描述:
;       1) 向 video buffer 写入提供的一个字符
;       2) 在 64-bit 模式下复用
;-------------------------------------------------          
write_char:
        push ebx
        push ecx
        push edx
        push ebp

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        
        or si, 0F00h                                            ; si = 字符
        
        ;;
        ;; 读当前 LocalVideoBufferPtr
        ;;
        REX.Wrxb
        mov ebx, [ebp + PCB.LsbBase]                            ; ebx = LSB        
        REX.Wrxb
        mov ecx, [ebx + LSB.LocalVideoBufferPtr]                ; LocalVideoBufferPtr
        REX.Wrxb
        mov edi, [ebx + LSB.LocalVideoBufferHead]               ; edi = BufferHead
        REX.Wrxb
        sub ecx, edi                                            ; ecx = index
        
        ;;
        ;; 检查是否拥有焦点
        ;;
        mov eax, SDA.InFocus
        mov eax, [fs: eax]
        cmp eax, [ebp + PCB.ProcessorIndex]
        sete dl                                                 ; dl = 1 时, 拥有焦点
        
        REX.Wrxb
        mov ebp, [ebp + PCB.SdaBase]                            ; ebp = SDA
        
        
        ;;
        ;; 检查是否为换行符
        ;;
        cmp si, 0F0Ah
        jne write_char.@1

        ;;
        ;; 处理换行: 
        ;; 1) 计算新行所写的位置, 更新 video buffer 指针为下一个字符所写位置
        ;;
        call video_buffer_column                                ; 得到当前 column 值
        neg eax
        add eax, 80 * 2                                         ; 满行差额 = (80 * 2) - column
        add ecx, eax                                            ; index + 满行差额
        jmp write_char.update

write_char.@1:
        
        ;;
        ;; 检查是否为 HT 符(水平TAB键)
        ;;
        cmp si, 0F09h
        jne write_char.next
        ;;
        ;; 处理TAB键: 
        ;; 检查上一个字符是否为 TAB 键
        ;; 1) 是, buffer pointer 加上 10h
        ;; 2) 否, buffer pointer 加上 0Fh
        ;;
        add ecx, 0Fh
        cmp BYTE [ebx + LSB.LocalVideoBufferLastChar], 09
        jne write_char.@2
        INCv ecx
        
write_char.@2:        
        ;;
        ;; 调整到 8 * 2 个字符边界
        ;;
        and ecx, 0FFFFFFF0h
        jmp write_char.update
        
        
write_char.next:        
        ;;
        ;; 检查是否超过一屏(25 * 80)
        ;;
        cmp ecx, (25 * 80 * 2)
        jae write_char.update
        
        ;;
        ;; 写 video buffer
        ;;
        mov [edi + ecx], si                                     ; 向 BufferHead[Index] 写入字符
        
        ;;
        ;; 如果当前拥有焦点, 写入 target video buffer
        ;;
        test dl, dl
        jz write_char.next.@0
        REX.Wrxb
        mov eax, [ebp + SDA.VideoBufferHead]
        mov [eax + ecx], si
        
write_char.next.@0:        
        add ecx, 2                                              ; 指向下一个字符位置
        
        
write_char.update:        
        ;;
        ;; 更新 video buffer 指针, 指向指一个字符位置
        ;;
        REX.Wrxb
        add edi, ecx
        REX.Wrxb
        mov [ebx + LSB.LocalVideoBufferPtr], edi                ; 保存 Buffer Ptr
        mov [ebx + LSB.LocalVideoBufferLastChar], si            ; 更新上一个字符
        
        ;;
        ;; 如果当前拥有焦点, 则更新 target video buffer
        ;;
        test dl, dl
        jz write_char.done
               
        ;; 
        ;; 更新 target video buffer 记录
        ;;
        REX.Wrxb
        add ecx, [ebp + SDA.VideoBufferHead]
        mov [ebp + SDA.VideoBufferLastChar], si
        REX.Wrxb
        mov [ebp + SDA.VideoBufferPtr], ecx
        
write_char.done:
        pop ebp
        pop edx
        pop ecx
        pop ebx
        ret
        



        
        
;-------------------------------------------------
; putc()
; input:
;       esi - 字符
; output:
;       none
; 描述:
;       1) 向 video buffer 打印一个字符
;-------------------------------------------------        
putc:
        and esi, 0FFh
        jmp write_char




;-------------------------------------------------
; println()
; input:
;       none
; output:
;       none
; 描述:
;       打印换行
;------------------------------------------------
println:
        mov si, 10
        jmp putc
        
        
;-------------------------------------------------
; print_tab()
; input:
;       none
; output:
;       none
; 描述:
;       打印 TAB 键
;------------------------------------------------
print_tab:
        mov si, 09
        jmp putc


;-------------------------------------------------
; printblank()
; input:
;       none
; output:
;       none
; 描述:
;       打印一个空格
;-------------------------------------------------   
printblank:
        mov si, ' '
        jmp putc
        
        
           
;-------------------------------------------------
; print_chars()
; input:
;       esi - char
;       edi - count
; output:
;       none
; 描述: 
;       1) 打印若干个字符
;-------------------------------------------------
print_chars:
        push ebx
        push ecx
        mov ebx, esi
        mov ecx, edi
print_chars.@0:   
        mov esi, ebx     
        call putc
        ;;
        ;; 注意: 
        ;;      1) 使用 FF /1 的 dec 指令, 避免在 64-bit 模式下变为 REX prefix
        ;;
        DECv ecx    
        jnz print_chars.@0
        pop ecx
        pop ebx
        ret


;-------------------------------------------------
; print_space()
; input:
;       esi - 数量
; output:
;       none
; 描述:
;       打印数个空格
;-------------------------------------------------
print_space:       
        mov edi, esi
        mov esi, ' '
        jmp print_chars
        


;-------------------------------------------------
; puts()
; input:
;       esi - string
; output:
;       none
; 描述:
;       打印字符串
;-------------------------------------------------
puts:
        push ebx
        push ecx
        
        ;;
        ;; 字符 flag
        ;;
        xor ecx, ecx
        
        REX.Wrxb
        mov ebx, esi
        REX.Wrxb
        test esi, esi
        jz puts.done
        
puts.loop:
        mov al, [ebx]
        test al, al
        jz puts.done
        
        ;;
        ;; 检查上一个字符是否为 '\'
        ;;
        test ecx, CHAR_FLAG_BACKSLASH
        jz puts.@0
       
        ;;
        ;; 检查是否为 n
        ;;
        cmp al, 'n'
        je puts.@01
        
        mov esi, '\'
        call putc
        mov al, [ebx]
        and ecx, ~CHAR_FLAG_BACKSLASH
        jmp puts.@1        
        
puts.@01:
        mov esi, 10
        call putc
        and ecx, ~CHAR_FLAG_BACKSLASH
        jmp puts.next        


puts.@0:        
        ;;
        ;; 检查是否为 '\' 字符
        ;;
        cmp al, '\'
        jne puts.@1
        
        or ecx, CHAR_FLAG_BACKSLASH                             ; 记录反斜杠
        jmp puts.next


puts.@1:
        ;;
        ;; 打印字符
        ;;        
        mov esi, eax
        call putc 

puts.next:        
        ;;
        ;; 注意: 
        ;;      1) 使用 FF /0 的 inc 指令, 避免在 64-bit 模式下变为 REX prefix
        ;;        
        REX.Wrxb
        INCv ebx
        jmp puts.loop
        
puts.done:     
        pop ecx   
        pop ebx
        ret
        
        


;-------------------------------------------------
; hex_to_char()
; input:
;       esi - hex number
; output:
;       eax - char
; 描述:
;       将十六进制数字转为字符
;-------------------------------------------------        
hex_to_char:
        mov eax, esi
        and eax, 0Fh
        movzx eax, BYTE [crt.chars + eax]        
        ret
        

;-------------------------------------------------
; byte_to_string():
; intput:
;       esi - byte
;       edi - buffer
; output:
;       none
;-------------------------------------------------
byte_to_string:
        REX.Wrxb
        test edi, edi
        jz byte_to_string.done        
        mov eax, esi
        shr eax, 4
        and eax, 0Fh
        movzx eax, BYTE [crt.chars + eax]  
        mov [edi], al
        REX.Wrxb
        INCv edi      
        and esi, 0Fh
        movzx eax, BYTE [crt.chars + esi]
        mov [edi], al
        REX.Wrxb
        INCv edi      
        mov BYTE [edi], 'H'
        REX.Wrxb
        INCv edi        
byte_to_string.done:        
        ret
        
                
;-------------------------------------------------
; dword _to_string():
; intput:
;       esi - DWORD
;       edi - buffer
; output:
;       none
;-------------------------------------------------
dword_to_string:
        push ecx
        REX.Wrxb
        test edi, edi
        jz dword_to_string.done
        mov ecx, 8
dword_to_string.loop:
        shld eax, esi, 4
        shl esi, 4
        and eax, 0Fh
        movzx eax, BYTE [crt.chars + eax]  
        mov [edi], al
        REX.Wrxb
        INCv edi      
        DECv ecx
        jnz dword_to_string.loop
        mov BYTE [edi], 'H'
        REX.Wrxb
        INCv edi
dword_to_string.done:        
        pop ecx
        ret



;-------------------------------------------------
; print_hex_value()
; input:
;       esi - value
; output:
;       none
; 描述:
;       打印十六进制数
;-------------------------------------------------
print_hex_value:
        push ecx
        push ebx
        push esi
        mov ecx, 8
print_hex_value.loop:        
        rol esi, 4
        mov ebx, esi
        call hex_to_char
        mov esi, eax
        call putc
        mov esi, ebx
        ;;
        ;; 注意: 
        ;;      1) 使用 FF /1 的 dec 指令, 避免在 64-bit 模式下变为 REX prefix
        ;;
        DECv ecx        
        jnz print_hex_value.loop
        pop esi
        pop ebx
        pop ecx
        ret



;-------------------------------------------------
; print_half_byte()
; input:
;       esi - value
; output:
;       none
; 描述:
;       打印半个字节(4位值)
;-------------------------------------------------
print_half_byte:
        call hex_to_char
        mov esi, eax
        call putc
        ret
        

;-------------------------------------------------
; print_decimal()
; input:
;       esi - value
; output:
;       none
; 描述:
;       打印十进制数
;-------------------------------------------------
print_decimal32:
print_dword_decimal:
        push ebp
        push edx
        push ecx
        push ebx
        
        REX.Wrxb
        mov ebp, esp
        REX.Wrxb
        sub esp, 64
        
        ;;
        ;; 定义两个变量:
        ;; 1) quotient: 用来保存每次除10后的商
        ;; 2) digit_array: 用来保存每次除10后的余数字符串
        ;;
%define QUOTIENT_OFFSET                 8
%define DIGIT_ARRAY_OFFSET              9

        mov eax, esi
        REX.Wrxb
        lea ebx, [ebp - QUOTIENT_OFFSET]
        mov [ebx], eax                                  ; 初始商值
        mov BYTE [ebp - DIGIT_ARRAY_OFFSET], 0          ; 0
        mov ecx, 10                                     ; 除数
        
        ;;
        ;; 指向数组尾部, 从数组后面往前写
        ;;
        REX.Wrxb
        lea esi, [ebp - DIGIT_ARRAY_OFFSET]

print_decimal.loop:
        REX.Wrxb
        DECv esi                                ; 指向下一个位置, 向前写
        xor edx, edx
        div ecx                                 ; value / 10
        
        ;;
        ;; 检查商是否为 0, 为 0 时, 除 10 结束
        ;;
        test eax, eax
        cmovz edx, [ebx]
        mov [ebx], eax
        lea edx, [edx + '0']                    ; 余数转化为字符, 使用 lea 指令, 避免使用 add 指令(不改变eflags)
        mov [esi], dl                           ; 写入余数字符
        jnz print_decimal.loop
        
        ;;
        ;; 下面打印出数字串
        ;;
        call puts
        
        
%undef QUOTIENT_OFFSET
%undef DIGIT_ARRAY_OFFSET

        REX.Wrxb
        mov esp, ebp        
        pop ebx
        pop ecx
        pop edx
        pop ebp
        ret




;---------------------------------------------------------------
; print_dword_float()
; input:
;       esi - 浮点数地址值(单精度值)
; output:
;       none
; 描述:
;       esi 提供需要打印浮点数的地址, 函数将加载到 FPU stack 中
;--------------------------------------------------------------
print_dword_float:
        fnsave [gs: PCB.FpuStateImage]
        finit
        fld DWORD [esi]
        call print_float
        frstor [gs: PCB.FpuStateImage]
        ret



;---------------------------------------------------------------
; print_qword_float()
; input:
;       esi - 浮点数地址值(双精度值)
; output:
;       none
; 描述:
;       esi 提供需要打印浮点数的地址, 函数将加载到 FPU stack 中
;--------------------------------------------------------------
print_qword_float:
        fnsave [gs: PCB.FpuStateImage]
        finit
        fld QWORD [esi]
        call print_float
        frstor [gs: PCB.FpuStateImage]
        ret


;---------------------------------------------------------------
; print_tword_float()
; input:
;       esi - 浮点数地址值(扩展双精度值)
; output:
;       none
; 描述:
;       esi 提供需要打印浮点数的地址, 函数将加载到 FPU stack 中
;--------------------------------------------------------------
print_tword_float:
        fnsave [gs: PCB.FpuStateImage]
        finit
        fld TWORD [esi]
        call print_float
        frstor [gs: PCB.FpuStateImage]
        ret
        
        
        


;-------------------------------------------------
; print_float()
; input:
;       esi - value
; output:
;       none
; 描述:
;       打印浮点数的小数点前的值
;-------------------------------------------------
print_float:
        ;;
        ;; 准备工作, 加载常数值
        ;;
        fld TWORD [crt.float_const10]                   ; 加载浮点数 10.0 值　
        fld1                                            ; 加载浮点数 1
        fld st2                                         ; 复制 value 到 st0
        
        ;;
        ;; 当前 FPU stack 状态: 
        ;; ** 1) st0    - float value
        ;; ** 2) st1    - 1.0
        ;; ** 3) st2    - 10.0
        ;;                
        fprem                                           ; st0/st1, 取余数值
        fld st3                                         ; 复制 float value
        fsub st0, st1                                   ; st0 的结果为小数点前面的值
        
        ;;
        ;; 下面先打印小数点前面的值
        ;; 
        call print_point
        
        mov DWORD [crt.point], 0
        
        ;;
        ;; 当前 FPU stack 状态: 
        ;; st(2) = 10.0
        ;; st(1) = 1.0
        ;; st(0) = 余数值 
        ;;

print_float.loop:
        fldz
        fcomip st0, st1                                 ; 检查余数是否为 0
        jz print_float.next
        fmul st0, st2                                   ; 余数 * 10
        fld st1                                         ; 1.0
        fld st1                                         ; 余数 * 10
        fprem                                           ; 取余数
        fld st2
        fsub st0, st1
        fistp DWORD [crt.value]
        mov esi, [crt.value]
        call print_dword_decimal                        ; 打印值    
        mov DWORD [crt.point], 1
        fxch st2
        fstp DWORD [crt.value]
        fstp DWORD [crt.value]        
        jmp print_float.loop

print_float.next:
        cmp DWORD [crt.point], 1
        je print_float.done
        mov esi, '0'
        call putc

print_float.done:
        ret




;-------------------------------------------------
; print_point()
; input:
;       esi - value
; output:
;       none
; 描述:
;       打印浮点数的小数点前的值
;-------------------------------------------------
print_point:
        push ebx
        lea ebx, [crt.digit_array + 98]
        mov BYTE [ebx], '.'

print_point.loop:
        ;;
        ;; 当前状态: 
        ;; st(3) = 10.0
        ;; st(2) = 1.0
        ;; st(1) = 余数值
        ;; st(0) = point 值
        ;;
        dec ebx
        fdiv st0, st3                           ; value / 10
        fld st2
        fld st1
        fprem                                   ; 求余数
        fsub st2, st0
        fmul st0, st5
        fistp DWORD [crt.value]
        mov eax, [crt.value]
        add eax, 30h
        mov BYTE [ebx], al  
        fstp DWORD [crt.value]      
        fldz
        fcomip st0, st1                         ; 余数小于 0
        jnz print_point.loop

print_point.done:        
        fstp DWORD [crt.value]
        mov esi, ebx
        call puts
        pop ebx
        ret




;-------------------------------------------------
; print_byte_value()
; input:
;       esi - value
; output:
;       none
; 描述:
;       打印一个 byte 值
;-------------------------------------------------
print_byte_value:
        push ebx
        push esi
        mov ebx, esi
        shr esi, 4
        call hex_to_char
        mov esi, eax
        call putc
        mov esi, ebx
        call hex_to_char
        mov esi, eax
        call putc
        pop esi
        pop ebx
        ret        


;-------------------------------------------------
; print_word_value()
; input:
;       esi - value
; output:
;       none
; 描述:
;       打印一个 word 值
;-------------------------------------------------
print_word_value:
        push ebx
        push esi
        mov ebx, esi
        shr esi, 8
        call print_byte_value
        mov esi, ebx
        call print_byte_value
        pop esi                
        pop ebx
        ret  


;-------------------------------------------------
; print_dword_value()
; input:
;       esi - value
; output:
;       none
; 描述:
;       打印一个 dword 值
;-------------------------------------------------        
print_dword_value:
        push ebx
        push esi
        mov ebx, esi
        shr esi, 16
        call print_word_value
        mov esi, ebx
        call print_word_value
        pop esi
        pop ebx
        ret
        

;-------------------------------------------------
; print_qword_value()
; input:
;       edi:esi - 64 位 value
; output:
;       none
; 描述:
;       打印一个 qword 值
;-------------------------------------------------         
print_qword_value:
        push ebx
        push esi
        mov ebx, esi
        mov esi, edi
        call print_dword_value
        mov esi, ebx
        call print_dword_value
        pop esi
        pop ebx
        ret  
        
        
;-------------------------------------------------
; is_letter()
; input:
;       esi - 字符
; output:
;       1 - yes, 0 - no
; 描述:
;       判断字符是否为字母
;------------------------------------------------- 
is_letter:
        and esi, 0FFh
        cmp esi, DWORD 'z'
        setbe al
        ja is_letter.done
        cmp esi, DWORD 'A'
        setae al
        jb is_letter.done
        cmp esi, DWORD 'Z'
        setbe al
        jbe is_letter.done
        cmp esi, DWORD 'a'
        setae al
is_letter.done:
        movzx eax, al
        ret
        
        
;-------------------------------------------------
; is_lowercase()
; input:
;       esi - 字符
; output:
;       1 - yes, 0 - no
; 描述:
;       判断字符是否为小写字母
;------------------------------------------------- 
is_lowercase:
        and esi, 0FFh
        cmp esi, DWORD 'z'
        setbe al        
        ja is_lowercase.done
        cmp esi, DWORD 'a'
        setae al
is_lowercase.done:
        movzx eax, al
        ret


;-------------------------------------------------
; is_uppercase()
; input:
;       esi - 字符
; output:
;       1 - yes, 0 - no
; 描述:
;       判断字符是否为大写字母
;-------------------------------------------------
is_uppercase:
        and esi, 0FFh
        cmp esi, DWORD 'Z'
        setbe al        
        ja is_uppercase.done
        cmp esi, DWORD 'A'
        setae al
is_uppercase.done:
        movzx eax, al        
        ret
        
        
 
;-------------------------------------------------
; is_digit()
; input:
;       esi - 字符
; output:
;       1 - yes, 0 - no
; 描述:
;       判断字符是否为数字
;-------------------------------------------------
is_digit:
        and esi, 0FFh
        xor eax, eax
        cmp esi, DWORD '0'
        setae al
        jb is_digit.done        
        cmp esi, DWORD '9'
        setbe al
is_digit.done:        
        ret




;-------------------------------------------------
; lower_to_upper()
; input:
;       esi - 字符
; output:
;       eax - 结果
; 描述:
;       小写字母转换为大写字母
;-------------------------------------------------
lower_to_upper:
        call is_lowercase
        test eax, eax
        jz lower_to_upper.done        
        mov eax, 'a' - 'A'
        neg eax
lower_to_upper.done:        
        add eax, esi
        ret


;-------------------------------------------------
; upper_to_lower()
; input:
;       esi - 字符
; output:
;       eax - 结果
; 描述:
;       大写字母转换为小写字母
;-------------------------------------------------
upper_to_lower:
        call is_uppercase
        test eax, eax
        jz upper_to_lower.done
        mov eax, 'a' - 'A'
upper_to_lower.done:
        add eax, esi
        ret


;-------------------------------------------------
; letter_convert()
; input:
;       esi - 字符
;       edi - 选择(1: 转换为大写, 0: 转换为小写)
; output:
;       eax - 结果
; 描述:
;       根据选择进行转换
;-------------------------------------------------
letter_convert:
        test edi, edi
        mov edi, lower_to_upper
        mov eax, upper_to_lower
        cmovz eax, edi
        jmp eax




;-------------------------------------------------
; lowers_to_uppers()
; input:
;       esi - 源串地址
;       edi - 目标串地址
; output:
;       none
; 描述:
;       小写串转换为大写串
;-------------------------------------------------
lowers_to_uppers:
        mov eax, lower_to_upper                         ; 小写转大写函数
        jmp do_string_convert


;-------------------------------------------------
; uppers_to_lowers()
; input:
;       esi - 源串地址
;       edi - 目标串地址
; output:
;       none
; 描述:
;       大写串转换为小写串
;-------------------------------------------------
uppers_to_lowers:
        mov eax, lower_to_upper                         ; 大写转小写函数


do_string_convert:
        push ecx
        push edx
        ;;
        ;; 检查源串/目标串地址
        ;;
        test esi, esi
        jz do_string_convert.done
        test edi, edi
        jz do_string_convert.done
        
        mov ecx, esi
        mov edx, edi
        mov edi, eax
        
        ;;
        ;; 逐个字符进行转换
        ;;
do_string_convert.loop:
        movzx esi, BYTE [ecx]
        test esi, esi
        jz do_string_convert.done
        call edi                                        ; 调用转换函数
        mov [edx], al
        inc edx
        inc ecx
        jmp do_string_convert.loop
        
do_string_convert.done:        
        pop edx
        pop ecx
        ret



;-------------------------------------------------
; dump_encodes()
; input:
;       esi - 需要打印的地址
;       edi - 字节数
; output:
;       none
; 描述:
;       将提供的地址内的字节打印出来
;-------------------------------------------------
dump_encodes:
        push ecx
        push ebx
        mov ebx, esi
        mov ecx, edi
dump_encodes.loop:        
        movzx esi, BYTE [ebx]
        call print_byte_value
        call printblank
        inc ebx
        dec ecx
        jnz dump_encodes.loop
        pop ebx
        pop ecx
        ret



;-------------------------------------------------
; puts_with_select()
; input:
;       esi - 字符串
;       edi - select code(select[0] = 1: 大写, 0 : 小写)
; output:
;       none
; 描述: 
;       根据提供的 select[0] 选择打印大写或小写
;       
;-------------------------------------------------
puts_with_select:
        push ebx
        push edx
        mov ebx, esi
        test esi, esi
        jz puts_with_select.done
        
        ;;
        ;; 选择相应转换函数
        ;;
        bt edi, 0
        mov edx, lower_to_upper
        mov eax, upper_to_lower
        cmovc edx, eax
        
        ;;
        ;; 先转换后打印
        ;;
puts_with_select.loop:        
        movzx esi, BYTE [ebx]
        test esi, esi
        jz puts_with_select.done
        call edx
        mov esi, eax
        call putc
        inc ebx
        jmp puts_with_select.loop
        
puts_with_select.done:        
        pop edx
        pop ebx
        ret





;-------------------------------------------------
; dump_string_with_mask()
; input:
;       esi - mask flags 值(最大32位)
;       edi - 字符串数组
; output:
;       none
; 描述:
;       根据提供的 mask flags 值, 来打印 edi 内的值
;       1) mask flags 置位, 则打印大写串
;       2) mask flags 清位, 则打印小写串
; 示例: 
;       CPUID.01H:EDX 返回 01 leaf 的功能支持位
;       mov esi, edx
;       mov edi, edx_flags
;       call print_string_with_mask
;-------------------------------------------------
dump_string_with_mask:
        push ebx
        push edx
        push ecx
        mov edx, esi
        mov ebx, edi
dump_string_with.loop:        
        ;;
        ;; 取 mask flags 的 MSB 位放到 edi LSB 中, 作为 select code
        ;;
        shl edx, 1
        rcr edi, 1
        ;;
        ;; 检查字符串数组内的结束标志 -1
        ;;
        mov ecx, [ebx]                          ; 读字符串指针
        cmp ecx, -1
        je dump_string_with_mask.done
        mov esi, ecx
        call check_new_line                     ; 检查是否需要换行
        mov esi, ecx
        call puts_with_select                   ; 选择打印大写/小写
        call printblank                         ; 打印空格
        add ebx, 4
        jmp dump_string_with.loop
dump_string_with_mask.done:
        pop ecx
        pop edx
        pop ebx
        ret        
        
  

;-------------------------------------------------
; subtract64()
; input:
;       edx:eax - 被减数
;       ecx:ebx - 减数
; output:
;       edx:eax - 结果
;-------------------------------------------------        
subtract64:
sub64:
        sub eax, ebx
        sbb edx, ecx
        ret

;-------------------------------------------------
; subtract64_with_address()
; input:
;       esi - 被减数地址
;       edi - 减数地址
; output:
;       edx:eax - 结果
;-------------------------------------------------        
subtract64_with_address:
        mov eax, [esi]
        sub eax, [edi]
        mov edx, [esi + 4]
        sbb edx, [edi + 4]        
        ret
        
;-------------------------------------------------
; decrement64(): 64 位减 1
; input:
;       edx:eax - 被减数
; output:
;       edx:eax - 结果
;-------------------------------------------------
decrement64:
dec64:
        sub eax, 1
        sbb edx, 0
        ret  
        

        
;-------------------------------------------------
; addition64()
; input:
;       edx:eax - 被加数
;       ecx:ebx - 加数
; output:
;       edx:eax - 结果
;-------------------------------------------------  
addition64:
add64:
        add eax, ebx
        adc edx, ecx
        ret


;-------------------------------------------------
; addition64_with_address()
; input:
;       esi - 被减数地址
;       edi - 减数地址
; output:
;       edx:eax - 结果
;-------------------------------------------------        
addition64_with_address:
        mov eax, [esi]
        sub eax, [edi]
        mov edx, [esi + 4]
        sbb edx, [edi + 4]        
        ret


;------------------------------------------------- 
; increment64(): 64 位加 1
; input:
;       edx:eax - 被加数
; output:
;       edx:eax - 结果
;------------------------------------------------- 
increment64:
inc64:
        add eax, 1
        adc edx, 0
        ret
        


;------------------------------------------------- 
; division64(): 两个 64 位数相除
; input:
;       edx:eax - 被除数
;       ecx:ebx - 除数
; output:
;       edx:eax - 商
;------------------------------------------------- 
division64:
        push edi
        sub esp, 16
        mov [esp], eax                                          ; dividend low
        mov [esp + 4], edx                                      ; dividend high
        mov [esp + 8], ebx                                      ; divisor low
        mov [esp + 12], ecx                                     ; divisor high
        mov edi, ecx
        shr edx, 1
        rcr eax, 1                                              ; edx:eax >> 1
        ror edi, 1
        rcr ebx, 1                                              ; edi:ebx >> 1
        bsr ecx, ecx
        shrd ebx, edi, cl
        shrd eax, edx, cl
        shr edx, cl
        rol edi, 1
        div ebx
        mov ebx, [esp]
        mov ecx, eax
        imul edi, eax
        mul DWORD [esp + 8]
        add edx, edi
        sub ebx, eax
        mov eax, ecx
        mov ecx, [esp + 4]
        sbb ecx, edx
        sbb eax, 0
        xor edx, edx
        mov ebx, [esp + 8]
        mov ecx, [esp + 12]        
        add esp, 16
        pop edi
        ret

;------------------------------------------------- 
; division64_32(): 64 位除以 32 位数
; input:
;       edx:eax - 被除数
;       ebx - 除数
; output:
;       edx:eax - 商
;------------------------------------------------- 
division64_32:
        cmp edx, ebx
        jae double_divsion
        ;
        ; 直接进行 edx:eax / ebx,  edx:eax = 商
        ;
        div ebx
        xor edx, edx
        jmp division64_32.done
        
double_divsion:
        ;
        ; 需要进行两次除运算
        ;
        push ecx
        mov ecx, eax                                            ; 保存 dividend low
        mov eax, edx                                            ; dividend high
        xor edx, edx                                            ; 
        div ebx                                                 ; 先进行 dividend 高位相除
        xchg eax, ecx                                           ; ecx = quotient high, eax = dividend low
        div ebx                                                 ; 进行 dividend 低位相除
        mov edx, ecx                                            ; edx:eax = quotient    
        pop ecx
division64_32.done:        
        ret


;------------------------------------------------------        
; mul64(): 64位乘法
; input:
;       esi: 被乘数地址
;       edi: 乘数地址
;       ebp: 结果值地址
;
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
                

;------------------------------------------------------  
; cmp64():
; input:
;       edx:eax
;       ecx:ebx
; output:
;       eflags
; 描述: 
;       执行64位数的比较操作
;------------------------------------------------------  
cmp64:
        ;;
        ;; 先比较高 32 位, 不相等时, 再比较低 32 位
        ;;
        cmp edx, ecx
        jne cmp64.done
        cmp eax, ebx
cmp64.done:        
        ret


                
;------------------------------------------------------  
; shl64()
; input:
;       edx:eax - 64 位值
;       ecx - count
; output:
;       edx:eax - 结果
; 描述: 
;       执行 64 位的左移
;------------------------------------------------------ 
shl64:
        and ecx, 63                                     ; 执行最大 63 位移动
        
        cmp ecx, 32
        jae shl64_64
        
        ;;
        ;; 向左移动小于 32 位数
        ;; 
        shld edx, eax, cl                               ; edx:eax << n
        shl eax, cl
        
        jmp shl64.done


shl64_64:
        ;;
        ;; 向左移动 32 位数, 或者超过 32 位
        ;; 1) n = 32 时:  edx:eax << 32, 结果为 eax:0
        ;; 2) n > 32 时:  edx:eax << n,  结果为 eax<<(n-32):0
        ;;
        mov edx, eax                                    ; eax 移入 edx
        xor eax, eax                                    ; 低 32 位为 0
        and ecx, 31                                     ; 取 32 余数值, 结果为 64 - n 
        shl edx, cl                                     ; 当 n = 32 时:  cl = 0
                                                        ; 当 n > 32 时:  32 > cl > 0
shl64.done:
        ret        



;------------------------------------------------------  
; shr64()
; input:
;       edx:eax - 64 位值
;       ecx - count
; output:
;       edx:eax - 结果
; 描述: 
;       执行 64 位的右移
;------------------------------------------------------ 
shr64:
        and ecx, 63                                     ; 执行最大 63 位移动
        
        cmp ecx, 32
        jae shr64_64
        
        ;;
        ;; 向右移动小于 32 位数
        ;; 
        shrd eax, edx, cl                               ; edx:eax >> n
        shr edx, cl
        
        jmp shr64.done


shr64_64:
        ;;
        ;; 向右移动 32 位数, 或者超过 32 位
        ;; 1) n = 32 时:  edx:eax >> 32, 结果为 0:edx
        ;; 2) n > 32 时:  edx:eax >> n,  结果为 0:edx>>(n-32)
        ;;
        mov eax, edx                                    ; edx 移入 eax
        xor edx, edx                                    ; 高 32 位为 0
        and ecx, 31                                     ; 取 32 余数值, 结果为 64 - n 
        shr eax, cl                                     ; 当 n = 32 时:  cl = 0
                                                        ; 当 n > 32 时:  32 > cl > 0
shr64.done:
        ret        



;------------------------------------------------------
; locked_xadd64():
; input:
;       esi - 被加数地址　
;       edx:eax - 加数
; output:
;       edx:eax - 返回被加数原值
; 描述: 
;       1) 执行 lock 的 64 位数相加, 结果保存在目标操作数里
;       2) 目标操作数是内存
;       3) 函数返回目标操作数原值
;------------------------------------------------------
locked_xadd64:
        push ecx
        push ebx
        push ebp


        ;;
        ;; 检查是否支持 cmpxchg8b 指令
        ;;
        bt DWORD [gs: PCB.FeatureEdx], 8                ; CPUID.01H:EDX[8].CMPXCHG8B 位
        jc locked_xadd64.ok
        
        ;;
        ;; 不支持 cmpxchg8b 指令时, 直接执行两次 xadd 指令
        ;; 警告: 
        ;;      1) 在这种情况下, 并不能真正地执行 64 位的原子 xadd 操作
        ;;
        lock xadd [esi], eax
        lock xadd [esi + 4], edx
        
        jmp locked_xadd64.done
        
        
        ;;
        ;; 下面使用 cmpxchg8b 指令, 可以实现在 32 位下对 64 位数进行原子 xadd 操作
        ;;
locked_xadd64.ok:

        mov ebp, eax
        mov edi, edx                                    ; edi:ebp 保存加数
        ;;
        ;; 取原值进行相加
        ;;
        mov eax, [esi]
        mov edx, [esi + 4]                              ; edx:eax = 原值
                
                
locked_xadd64.loop:
        mov ebx, ebp
        mov ecx, edi                                    ; ecx:ebx = 加数
        add ebx, eax
        adc ecx, edx                                    ; ecx:ebx = edx:eax + ecx:ebx
                                                        ; edx:eax = 原值
       
       ;;
       ;; 执行 edx:eax 与 [esi] 比较, 并且交换
       ;; 1) edx;eax == [esi] 时: [esi] = ecx:ebx
       ;; 2) edx:eax != [esi] 时: edx:eax = [esi]
       ;;
        lock cmpxchg8b [esi]                            ; [esi] = ecx:ebx
        
        ;;
        ;; 检查 [esi] 内的原值是否已经被修改
        ;; 注意: 
        ;; 1) 在执行"回写"目标操作数之前, "可能"已经被其它代码修改了 [esi] 内的原值
        ;; 2) 因此: 必须检查原值是否相等！
        ;; 3) 当原值已经被修改时, 需要重新加载 [esi] 原值, 再进行"相加", "回写"操作
        ;;
        jne locked_xadd64.loop                          ; [esi] 原值与 edx:eax 不相等时, 重复操作 
locked_xadd64.done:        
        pop ebp
        pop ebx
        pop ecx
        ret





;------------------------------------------------------
; delay_with_us32()
; input:
;       esi - 延时 us 数
; output:
;       none
; 描述:
;       1) 执行延时操作
;       2) 延时的单位为us(微秒)
;------------------------------------------------------
delay_with_us32:
        push edx
        ;;
        ;; 计算 ticks 数 = us 数 * ProcessorFrequency
        ;;
        mov eax, [gs: PCB.ProcessorFrequency]
        mul esi
        mov edi, edx
        mov esi, eax

        ;;
        ;; 计算目标 ticks 值
        ;;
        rdtsc
        add esi, eax
        adc edi, edx                            ; edi:esi = 目标 ticks 值
        
        ;;
        ;; 循环比较当前 tick 与 目标 tick
        ;;
delay_with_us32.loop:
        rdtsc
        cmp edx, edi
        jne delay_with_us32.@0
        cmp eax, esi
delay_with_us32.@0:
        pause
        jb delay_with_us32.loop

        pop edx
        ret


;------------------------------------------------------
; start_lapic_timer()
; input:
;       esi - 时间(单位为 us)
;       edi - 定时模式
;       eax - 回调函数
; output:
;       none
; 描述: 
;       1) 启动 local apic timer
; 参数: 
;       esi - 提供定时时间, 单位为 us
;       edi - LAPIC_TIMER_ONE_SHOT, 使用一次性定时
;             LAPIC_TIMER_PERIODIC, 使用周期性定时
;       eax - 提供一个回调函数
;------------------------------------------------------
start_lapic_timer:
        push ebp
        push ebx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif  
        REX.Wrxb
        mov ebx, [ebp + PCB.LsbBase]
        
        
        mov [ebx + LSB.LapicTimerRequestMask], edi
        REX.Wrxb
        mov [ebx + LSB.LapicTimerRoutine], eax
        mov eax, [ebp + PCB.LapicTimerFrequency]
        mul esi
        mov esi, eax   
        REX.Wrxb
        mov eax, [ebp + PCB.LapicBase]
        
        cmp edi, LAPIC_TIMER_PERIODIC        
        mov edi, TIMER_ONE_SHOT | LAPIC_TIMER_VECTOR        
        jne start_lapic_timer.@0        
        mov edi, TIMER_PERIODIC | LAPIC_TIMER_VECTOR
        
start_lapic_timer.@0:        
        mov [eax + LVT_TIMER], edi
        mov [eax + TIMER_ICR], esi
        pop ebx
        pop ebp
        ret


;------------------------------------------------------
; stop_lapic_timer()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 停止 local apic timer
;------------------------------------------------------
stop_lapic_timer:
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif  

        REX.Wrxb
        mov eax, [ebp + PCB.LapicBase]
        mov DWORD [eax + TIMER_ICR], 0
        
        pop ebp        
        ret




;------------------------------------------------------
; clock()
; input:
;       esi - row
;       edi - column
; output:
;       none
; 描述: 
;       1) 在(row,column) 位置上显示时钟
;------------------------------------------------------
clock:
        push ebp        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif  
        REX.Wrxb
        mov ebp, [ebp + PCB.LsbBase]                    ; LSB
        
        call set_video_buffer
        
        ;;
        ;; 显示小时数
        ;;
        mov eax, print_byte_value
        mov edi, print_dword_decimal
        mov esi, [ebp + LSB.Hour]
        cmp esi, 9
        cmova eax, edi
        call eax
        mov esi, ':'
        call putc
        ;;
        ;; 显示分钟数
        ;;
        mov eax, print_byte_value
        mov edi, print_dword_decimal
        mov esi, [ebp + LSB.Minute]
        cmp esi, 9
        cmova eax, edi
        call eax
        mov esi, ':'
        call putc
        ;;
        ;; 显示秒钟数
        ;;
        mov eax, print_byte_value
        mov edi, print_dword_decimal
        mov esi, [ebp + LSB.Second]
        cmp esi, 9
        cmova eax, edi
        call eax  
        pop ebp
        ret




;------------------------------------------------------
; send_init_command()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 向所有处理器发送 INIT 消息(包括BSP)
;       2) 此函数引发处理器 INIT RESET
; 注意: 
;       1) INIT RESET 下, MSR 不改变!
;       2) BSP 执行 boot, 所有 AP 等待 SIPI 消息!
;------------------------------------------------------
send_init_command:

        test DWORD [gs: PCB.ProcessorStatus], CPU_STATUS_PG
        mov eax, [gs: PCB.LapicBase]
        cmovz eax, [gs: PCB.LapicPhysicalBase]
        ;;
        ;; 向所有处理器广播 INIT
        ;;
        mov DWORD [ebx + ICR1], 0FF000000h
        mov DWORD [ebx + ICR0], 00004500h           
        hlt
        ret


;----------------------------------------------
; raise_tpl()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 提升 TPL(Task Priority Level)一级
;----------------------------------------------
raise_tpl:
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif        
        movzx esi, BYTE [ebp + PCB.CurrentTpl]                  ; 读取当前的 TPL
        mov [ebp + PCB.PrevTpl], esi                            ; 保存为 PrevTpl
        INCv esi                                                ; 提升一级
        jmp do_modify_tpl


;----------------------------------------------
; lower_tpl()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 降低 TPL(Task Priority Level)一级
;----------------------------------------------        
lower_tpl:
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif 
        movzx esi, BYTE [ebp + PCB.CurrentTpl]                  ; 读取当前 TPL
        mov [ebp + PCB.PrevTpl], esi                            ; 保存为 PrevTpl
        DECv esi                                                ; 降低一级
        jmp do_modify_tpl



;----------------------------------------------
; change_tpl()
; input:
;       esi - TPL
; output:
;       none
; 描述: 
;       1)修改 TPL(Task Priority Level)
;----------------------------------------------  
change_tpl:
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif 

        movzx eax, BYTE [ebp + PCB.CurrentTpl]                  ; 读取当前 TPL
        mov [ebp + PCB.PrevTpl], eax                            ; 保存为 PrevTpl        
        jmp do_modify_tpl
        

;----------------------------------------------
; recover_tpl()
; input:
;       none
; output:
;       none
; 描述: 
;       1)恢复原 TPL(Task Priority Level)
;----------------------------------------------        
recover_tpl:
        push ebp
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif 

        movzx esi, BYTE [ebp + PCB.PrevTpl]                     ; 读取原 TPL
        jmp do_modify_tpl



;-------------------------------------------
; do_modity_tpl()
; input:
;       esi - TPL
; output:
;       none
;-------------------------------------------
do_modify_tpl:        
        and esi, 0FFh
        mov [ebp + PCB.CurrentTpl], esi                         ; 新的 CurrentTpl 值
        shl esi, 4
        REX.Wrxb
        mov eax, [ebp + PCB.LapicBase]
        mov [eax + LAPIC_TPR], esi                              ; 写入 local APIC TPR
do_modity_tpl.end:        
        pop ebp
        ret




;----------------------------------------------
; read_keyboard()
; input:
;       none
; output:
;       eax - scan code
; 描述: 
;       1) 等待按建, 返回一个扫描码
;       2) 此函数最后将关闭键盘
;----------------------------------------------
read_keyboard:
        push ebp
        push ebx
        push ecx
        pushf

        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif  


        ;;
        ;; 打开 keyboard
        ;;
%ifdef REAL
        call lower_tpl
%else
        call enable_8259_keyboard
%endif

        ;;        
        ;; 读处理器的 LocalKeyBufferPtr 值
        ;;
        REX.Wrxb
        mov ebp, [ebp + PCB.LsbBase]        
        REX.Wrxb
        mov ebx, [ebp + LSB.LocalKeyBufferPtr]

       
        ;;
        ;; 打开中断允许
        ;;
        sti        
               
        ;;
        ;; 等待...
        ;; 直到 LocalKeyBufferPtr 发生改变时退出!
        ;;       
                
        WAIT_UNTIL_NEQ          [ebp + LSB.LocalKeyBufferPtr], ebx
                

        ;;
        ;; 屏蔽 keyboard
        ;;
%ifdef REAL
        call raise_tpl
%else        
        call disable_8259_keyboard
%endif


        ;;
        ;; 读键盘扫描码
        ;;
        REX.Wrxb
        mov ebx, [ebp + LSB.LocalKeyBufferPtr]
        movzx eax, BYTE [ebx]

read_keyboard.done:        
        popf
        pop ecx
        pop ebx
        pop ebp 
        ret
        
        
        
;----------------------------------------------
; wait_a_key()
; input:
;       none
; output:
;       eax - 扫描码
; 描述: 
;       1) 等待按键, 返回一个扫描码
;       2) wait_a_key()是已经打开键盘时使用
;       3)read_keyboard() 内部打开键盘, 无需已经开启键盘
;----------------------------------------------
wait_a_key:
        push ebp
        push ecx

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif  
        
        REX.Wrxb
        mov ebp, [ebp + PCB.LsbBase]
               
        ;;
        ;; 读原 KeyBufferPtr 值
        ;;
        xor eax, eax        
                
        ;;
        ;; 在 x64 下, lock xadd [ebp + LSB.LocalKeyBufferPtr], rax
        ;; 在 x86 下, lock xadd [ebp + LSB.LocalKeybufferPtr], eax
        ;;
        PREFIX_LOCK
        REX.Wrxb
        xadd [ebp + LSB.LocalKeyBufferPtr], eax

        ;;
        ;; 等待...
        ;; 直到 KeyBufferPtr 发生改变时退出!
        ;;       
                
        WAIT_UNTIL_NEQ          [ebp + LSB.LocalKeyBufferPtr], eax
        

        ;;
        ;; 读键盘扫描码
        ;;
        REX.Wrxb
        mov eax, [ebp + LSB.LocalKeyBufferPtr]
        movzx eax, BYTE [eax]        

wait_a_key.done:                
        pop ecx
        pop ebp
        ret

        
        
        

;----------------------------------------------
; wait_esc_for_reset()
; input:
;       none
; output:
;       none
; 描述:
;       1) 等待按下 <ESC> 键重启
;       2) 此函数使用 CPU hard reset 操作重启
;       3) 往 target video buffer 打印
;---------------------------------------------
wait_esc_for_reset:
        push ebp

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif 

        
        ;;
        ;; 定位在 (24,0)
        ;;
        ;mov esi, 24
        ;mov edi, 0
        ;call set_video_buffer
        
        mov esi, Ioapic.WaitResetMsg
        call puts
        
        ;;
        ;; 等待按 <ESC> 键
        ;;
wait_esc_for_reset.loop:
        call read_keyboard 
        cmp al, SC_ESC                                  ; 是否为 <ESC> 键
        jne wait_esc_for_reset.loop
        
wait_esc_for_reset.next:

        ;;
        ;; 执行 CPU RESET 操作
        ;; 1) 在真实机器上使用 INIT RESET
        ;; 2) 在vmware 上使用 CPU RESET
        ;;
        
%ifdef REAL
        ;;
        ;; 使用 INIT RESET 类型
        ;;
        test DWORD [ebp + PCB.ProcessorStatus], CPU_STATUS_PG
        REX.Wrxb
        mov eax, [ebp + PCB.LapicBase]
        REX.Wrxb
        cmovz eax, [ebp + PCB.LapicPhysicalBase]
        ;;
        ;; 向所有处理器广播 INIT
        ;;
        mov DWORD [eax + ICR1], 0FF000000h
        mov DWORD [eax + ICR0], INIT_DELIVERY  
        
%else        
        
        ;;
        ;; 执行 CPU hard reset 操作
        ;;
        RESET_CPU 

%endif        
        ret
        



        
                
;------------------------------------------------------
; get_spin_lock()
; input:
;       esi - lock
; output:
;       none
; 描述:
;       1) 此函数用来获得自旋锁
;       2) 输入参数为 spin lock 地址
;------------------------------------------------------
get_spin_lock:
        ;;
        ;; 自旋锁操作方法说明:
        ;; 1) 使用 bts 指令, 如下面指令序列
        ;;    lock bts DWORD [esi], 0
        ;;    jnc AcquireLockOk
        ;;
        ;; 2) 本例中使用 cmpxchg 指令
        ;;    lock cmpxchg [esi], edi
        ;;    jnc AcquireLockOk
        ;;    
        
        xor eax, eax
        mov edi, 1        
        
        ;;
        ;; 尝试获取 lock
        ;;
get_spin_lock.acquire:
        lock cmpxchg [esi], edi
        je get_spin_lock.done

        ;;
        ;; 获取失败后, 检查 lock 是否开放(未上锁)
        ;; 1) 是, 则再次执行获取锁, 并上锁
        ;; 2) 否, 继续不断地检查 lock, 直到 lock 开放
        ;;
get_spin_lock.check:        
        mov eax, [esi]
        test eax, eax
        jz get_spin_lock.acquire
        pause
        jmp get_spin_lock.check
        
get_spin_lock.done:                
        ret


;------------------------------------------------------
; get_spin_lock_with_count()
; input:
;       esi - lock
;       edi - count
; output:
;       0 - successful, 1 - failure
; 描述:
;       1) 此函数用来获得自旋锁, 
;       2) 输入参数 esi 为 spin lock 地址
;       3) 输入参数 edi 为 计数值
;------------------------------------------------------
get_spin_lock_with_count:
        push ecx
        ;;
        ;; 自旋锁操作方法说明:
        ;; 1) 使用 bts 指令, 如下面指令序列
        ;;    lock bts DWORD [esi], 0
        ;;    jnc AcquireLockOk
        ;;
        ;; 2) 本例中使用 cmpxchg 指令
        ;;    lock cmpxchg [esi], edi
        ;;    jnc AcquireLockOk
        ;;    
        mov ecx, edi
        xor eax, eax
        mov edi, 1        
        
        ;;
        ;; 尝试获取 lock
        ;;
get_spin_lock_with_count.acquire:
        lock cmpxchg [esi], edi
        je get_spin_lock_with_count.done

        ;;
        ;; 获取失败后, 检查 lock 是否开放(未上锁)
        ;; 1) 是, 则再次执行获取锁, 并上锁
        ;; 2) 否, 继续不断地检查 lock, 直到 lock 开放
        ;;
get_spin_lock_with_count.check:        
        dec ecx
        jz get_spin_lock_with_count.done
        mov eax, [esi]
        test eax, eax
        jz get_spin_lock_with_count.acquire
        pause
        jmp get_spin_lock_with_count.check
        
get_spin_lock_with_count.done:     
        pop ecx
        ret





        
;-----------------------------------------------------
; dump_memory()
; input:
;       esi - buffer
; output:
;       none
; 描述: 
;       1) 打印 buffer 数据
;       2) <UP>键向上翻, <DOWN>向下翻, <ESC>退出
;-----------------------------------------------------
dump_memory:
        push ebx
        push edx
        
        REX.Wrxb
        mov ebx, esi
        REX.Wrxb
        mov edx, esi

dump_memory.@0:        
        mov esi, 2
        mov edi, 0
        call set_video_buffer
        
        ;;
        ;; 打印头部
        ;;
        mov esi, 10
        call print_space
        
        xor ecx, ecx
        
dump_memory.Header:        
        mov esi, ecx
        call print_byte_value
        call printblank
        INCv ecx
        cmp ecx, 16
        jb dump_memory.Header
        call println
        mov esi, 10
        call print_space
        mov esi, '-'
        mov edi, 16 * 3 - 1
        call print_chars
        call println

        ;;
        ;; 打印 buffer 内容
        ;;
        xor ecx, ecx
        
dump_memory.@1:
        lea esi, [ebx + ecx]
        call print_dword_value
        mov esi, ':'
        call putc
        mov esi, ' '
        call putc
        
dump_memory.@2:        
        movzx esi, BYTE [ebx + ecx]
        call print_byte_value
        call printblank
        INCv ecx
        mov eax, ecx
        and eax, 0Fh
        test eax, eax
        jnz dump_memory.@2
        call println
        cmp ecx, 256
        jb dump_memory.@1
        
        ;;
        ;; 控制键盘
        ;;
        mov esi, 24
        mov edi, 0
        call set_video_buffer
        mov esi, Status.Msg1
        call puts

dump_memory.@3:        
        call read_keyboard
        cmp al, SC_ESC                          ; 是否为 <Esc>
        je dump_memory.@4
        cmp al, SC_PGUP                         ; 是否为 <PageUp>
        jne dump_memory.CheckPageDown
        REX.Wrxb
        sub ebx, 256
        REX.Wrxb
        cmp ebx, edx
        REX.Wrxb
        cmovb ebx, edx
        xor ecx, ecx
        jmp dump_memory.@0

dump_memory.CheckPageDown:
        cmp al, SC_PGDN                         ; 是否为 <PageDown>
        jne dump_memory.@3
        REX.Wrxb
        add ebx, 256
        xor ecx, ecx
        jmp dump_memory.@0
        
dump_memory.@4:
        ;;
        ;; 执行 CPU hard reset 操作
        ;;
        RESET_CPU        
        pop edx                
        pop ebx
        ret




;-----------------------------------------------------
; get_usable_processor_index()
; input:
;       none
; output:
;       eax - processor index
;-----------------------------------------------------
get_usable_processor_index:
        ;;
        ;; 在 UsableProcessorMask 里找到一个可用的 processor index 值
        ;;
        mov eax, SDA.UsableProcessorMask
        mov eax, [fs: eax]
        bsf eax, eax
        ret
        
        

        
;-----------------------------------------------------
; report_system_status()
; input:
;       none
; output:
;       none
;-----------------------------------------------------                        
report_system_status:
        ;;
        ;; 定位在 0,0 位置上
        ;;
        mov esi, 0
        mov edi, 0
        call set_video_buffer
        
        ;;
        ;; 打印 [Cpus]
        ;;
        mov esi, Status.CpusMsg
        call puts
        mov esi, SDA.ProcessorCount
        mov esi, [fs: esi]
        call print_dword_decimal
        mov esi, ' '
        call putc
        
        ;;
        ;; 打印 [Cpu model]
        ;;
        mov esi, Status.CpuModelMsg
        call puts
        mov esi, PCB.DisplayModel
        movzx esi, WORD [gs: esi]
        call print_word_value
        mov esi, ' '
        call putc
        
        ;;
        ;; 打印 [Stage]
        ;;
        mov esi, Status.StageMsg
        call puts
        mov esi, SDA.ApLongmode
        mov esi, [fs: esi]
        add esi, 2
        call print_dword_decimal
        mov esi, ' '
        call putc
        
        ;;
        ;; 打印 [Cpu id]
        ;;
        mov esi, Status.CpuIdMsg
        call puts
        mov esi, PCB.ProcessorIndex
        mov esi, [gs: esi]
        call print_dword_decimal
        mov esi, ' '
        call putc
        
        
        ;;
        ;; 打印 [VMX]
        ;;
        mov esi, Status.VmxMsg
        call puts
        mov esi, PCB.ProcessorStatus
        mov eax, Status.EnableMsg
        test DWORD [gs: esi], CPU_STATUS_VMXON
        mov esi, Status.DisableMsg
        cmovnz esi, eax
        call puts
        mov esi, ' '
        call putc
        
        ;;
        ;; 打印 [Host/Guest]
        ;;
        mov esi, Status.EptMsg
        call puts
        ;;
        ;; 检查 guest 标志值
        ;;
        mov esi, PCB.EptEnableFlag
        cmp BYTE [gs: esi], 1
        mov esi, Status.EnableMsg
        mov eax, Status.DisableMsg
        cmovne esi, eax
        call puts
        call println        
        ret



;-----------------------------------------------------
; update_system_status()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 更新系统状态到 local video buffer 里
;-----------------------------------------------------                        
update_system_status:
        ;;
        ;; 定位在 0,0 位置上
        ;;
        mov esi, 0
        mov edi, 0
        call set_video_buffer

        ;;
        ;; 打印 [Cpu id]
        ;;
        mov esi, Status.CpuIdMsg
        call puts
        mov esi, PCB.ProcessorIndex
        mov esi, [gs: esi]
        call print_dword_decimal
        mov esi, ' '
        call putc
               
        ;;
        ;; 打印 [Stage]
        ;;
        mov esi, Status.StageMsg
        call puts
        mov esi, SDA.ApLongmode
        mov esi, [fs: esi]
        add esi, 2
        call print_dword_decimal
        mov esi, ' '
        call putc
        
        ;;
        ;; 打印 [Cpus]
        ;;
        mov esi, Status.CpusMsg
        call puts
        mov esi, SDA.ProcessorCount
        mov esi, [fs: esi]
        call print_dword_decimal
        mov esi, ' '
        call putc
        
        ;;
        ;; 打印 [Cpu model]
        ;;
        mov esi, Status.CpuModelMsg
        call puts
        mov esi, PCB.DisplayModel
        movzx esi, WORD [gs: esi]
        call print_word_value
        mov esi, ' '
        call putc
                
        ;;
        ;; 打印 [VMX]
        ;;
        mov esi, Status.VmxMsg
        call puts
        mov esi, PCB.ProcessorStatus
        mov eax, Status.EnableMsg
        test DWORD [gs: esi], CPU_STATUS_VMXON
        mov esi, Status.DisableMsg
        cmovnz esi, eax
        call puts
        mov esi, ' '
        call putc
        
        ;;
        ;; 打印 [Ept]
        ;;
        mov esi, Status.EptMsg
        call puts
        
        ;;
        ;; 检查 Ept enable 标志
        ;;
        mov esi, PCB.EptEnableFlag
        cmp BYTE [gs: esi], 1
        mov esi, Status.EnableMsg
        mov eax, Status.DisableMsg
        cmovne esi, eax
        call puts
        call printblank
        call println        
        ret
        



                
        
%include "..\lib\sse.asm"




